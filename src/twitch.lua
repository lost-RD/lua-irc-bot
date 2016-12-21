--[[ This is the file that you run, e.g.
luajit twitch.lua
It's a bit messy for now but I'll clean it up
]]

-- Loading modules
-- 30log will be made redundant by LuaSQL
local class = require "30log"
local irc = require "irc"
local dcc = require "irc.dcc"

-- Debug flag
irc.DEBUG = true

-- Get local IP?
local ip_prog = io.popen("get_ip")
local ip = ip_prog:read()
ip_prog:close()
irc.set_ip(ip)

-- TODO Move this to another file
function string:split(delimiter)
  local result = { }
  local from  = 1
  local delim_from, delim_to = string.find( self, delimiter, from  )
  while delim_from do
    table.insert( result, string.sub( self, from , delim_from-1 ) )
    from  = delim_to + 1
    delim_from, delim_to = string.find( self, delimiter, from  )
  end
  table.insert( result, string.sub( self, from  ) )
  return result
end

-- Print channel members of all connected channels
local function print_state()
	for chan in irc.channels() do
		print(chan..": Channel ops: "..table.concat(chan:ops(), " "))
		print(chan..": Channel voices: "..table.concat(chan:voices(), " "))
		print(chan..": Channel normal users: "..table.concat(chan:users(), " "))
		print(chan..": All channel members: "..table.concat(chan:members(), " "))
	end
end

-- Callback on connect
local function on_connect()
	print("Joining channel #lost_rd...")
	irc.join("#lost_rd")
end
irc.register_callback("connect", on_connect)

-- Callback on bot join
local function on_me_join(chan)
	print("Join to " .. chan .. " complete.")
	print(chan .. ": Channel type: " .. chan.chanmode)
	if chan.topic.text and chan.topic.text ~= "" then
		print(chan .. ": Channel topic: " .. chan.topic.text)
		print("  Set by " .. chan.topic.user ..
			  " at " .. os.date("%c", chan.topic.time))
	end
	if chan.name == "#lost_rd" then
		irc.act(chan.name, "is here, beep boop bzzt")
	end
	print_state()
end
irc.register_callback("me_join", on_me_join)

-- Callback on user join
local function on_join(chan, user)
	print("I saw a join to " .. chan)
	if tostring(user) ~= "lost_rd" then
		irc.say(tostring(chan), "Hi, " .. user)
	end
	print_state()
end
irc.register_callback("join", on_join)

-- Callback on user part
-- Not sure if useful for Twitch chat
local function on_part(chan, user, part_msg)
	print("I saw a part from " .. chan.name .. " saying " .. part_msg)
	print_state()
end
irc.register_callback("part", on_part)

-- Callback on nick change
-- Not useful for Twitch chat
local function on_nick_change(new_nick, old_nick)
	print("I saw a nick change: "  ..  old_nick .. " -> " .. new_nick)
	print_state()
end
irc.register_callback("nick_change", on_nick_change)

-- Callback on kick
-- Not sure if useful for Twitch chat
local function on_kick(chan, user)
	print("I saw a kick in " .. chan)
	print_state()
end
irc.register_callback("kick", on_kick)

-- Callback on user quit
-- Not sure if useful for Twitch chat
local function on_quit(chan, user)
	print("I saw a quit from " .. chan)
	print_state()
end
irc.register_callback("quit", on_quit)

-- WHOIS
-- Not sure if useful
local function whois_cb(cb_data)
	print("WHOIS data for " .. cb_data.nick)
	if cb_data.user then print("Username: " .. cb_data.user) end
	if cb_data.host then print("Host: " .. cb_data.host) end
	if cb_data.realname then print("Realname: " .. cb_data.realname) end
	if cb_data.server then print("Server: " .. cb_data.server) end
	if cb_data.serverinfo then print("Serverinfo: " .. cb_data.serverinfo) end
	if cb_data.away_msg then print("Awaymsg: " .. cb_data.away_msg) end
	if cb_data.is_oper then print(nick .. "is an IRCop") end
	if cb_data.idle_time then print("Idletime: " .. cb_data.idle_time) end
	if cb_data.channels then
		print("Channel list for " .. cb_data.nick .. ":")
		for _, channel in ipairs(cb_data.channels) do print(channel) end
	end
end

-- Server version
-- Doubt useful
local function serverversion_cb(cb_data)
	print("VERSION data for " .. cb_data.server)
	print("Version: " .. cb_data.version)
	print("Comments: " .. cb_data.comments)
end

-- Ping "cb"
-- Don't know what "cb" is
local function ping_cb(cb_data)
	print("CTCP PING for " .. cb_data.nick)
	print("Roundtrip time: " .. cb_data.time .. "s")
end

-- Time "cb"
local function time_cb(cb_data)
	print("CTCP TIME for " .. cb_data.nick)
	print("Localtime: " .. cb_data.time)
end

-- Version "cb"
local function version_cb(cb_data)
	print("CTCP VERSION for " .. cb_data.nick)
	print("Version: " .. cb_data.version)
end

-- Server time "cb"
local function stime_cb(cb_data)
	print("TIME for " .. cb_data.server)
	print("Server time: " .. cb_data.time)
end

-- Callback for every message typed in the channel
-- TODO make this modular
local function on_channel_msg(chan, from, msg)
	if from == "lost_rd" then
		if msg == "shoo l2d2" then
			irc.part(chan.name)
			return
		elseif msg:sub(1, 3) == "op " then
			chan:op(msg:sub(4))
			return
		elseif msg:sub(1, 5) == "deop " then
			chan:deop(msg:sub(6))
			return
		elseif msg:sub(1, 6) == "voice " then
			chan:voice(msg:sub(7))
			return
		elseif msg:sub(1, 8) == "devoice " then
			chan:devoice(msg:sub(9))
			return
		elseif msg:sub(1, 5) == "kick " then
			chan:kick(msg:sub(6))
			return
		elseif msg:sub(1, 5) == "send " then
			dcc.send(from, msg:sub(6))
			return
		elseif msg:sub(1, 6) == "whois " then
			irc.whois(whois_cb, msg:sub(7))
			return
		elseif msg:sub(1, 8) == "sversion" then
			irc.server_version(serverversion_cb)
			return
		elseif msg:sub(1, 5) == "ping " then
			irc.ctcp_ping(ping_cb, msg:sub(6))
			return
		elseif msg:sub(1, 5) == "time " then
			irc.ctcp_time(time_cb, msg:sub(6))
			return
		elseif msg:sub(1, 8) == "version " then
			irc.ctcp_version(version_cb, msg:sub(9))
			return
		elseif msg:sub(1, 5) == "stime" then
			irc.server_time(stime_cb)
			return
		elseif msg:sub(1, 6) == "trace " then
			irc.trace(trace_cb, msg:sub(7))
			return
		elseif msg:sub(1, 5) == "trace" then
			irc.trace(trace_cb)
			return
		end
	end

	if msg:sub(1, 11) == "hello l2d2!" then
		irc.say(chan.name, "hello "..from.."!")
		return
	end

	if msg:sub(1,1) == "!" then
		print("command detected")
		local _, i = msg:find("![a-z0-9]+")
		local cmd, arg = msg:sub(2,i), msg:sub(i+1)
		local i, j = arg:find("[a-z0-9/]+")
		if i and j then
			print(i,j)
			arg = string.sub(arg, i)
		else
			arg = nil
		end
		print(cmd, arg)
		if cmd == "mod" then
			print("mod command detected")
			if admins:isMember(from) then
				if mods:isMember(arg) then
					irc.say(chan.name, arg.." is already a mod!")
				else
					mods:addMember(arg)
					if mods:isMember(arg) then
						irc.say(chan.name, arg.." is now a mod!")
					end
				end
			else
				print(from.."is not an admin")
			end
		end
		if cmd == "unmod" then
			print("unmod command detected")
			if admins:isMember(from) then
				if not mods:isMember(arg) then
					irc.say(chan.name, arg.." is not a mod.")
				else
					if not admins:isMember(arg) then
						mods:removeMember(arg)
						if not mods:isMember(arg) then
							irc.say(chan.name, arg.." is no longer a mod.")
						end
					else
						irc.say(chan.name, arg.." is an admin and cannot be unmodded.")
					end
				end
			else
				print(from.."is not an admin")
			end
		end
		if cmd == "l2d2" then
			print("mod command detected")
			if admins:isMember(from) then
				irc.say(chan.name, arg)
			else
				print(from.."is not an admin")
			end
		end
		if cmd == "roll" then
			if type(tonumber(arg)) == "number" then
				arg = tonumber(arg)
				if (arg > 1) and (arg%1==0) then
					local n = math.random(1,arg)
					irc.say(chan.name, tostring(n))
				end
			end
		end
		if cmd == "peeps" then
			if mods:isMember(from) then
				irc.say(chan.name, table.concat(chan:members(), ", "))
			end
		end
		if cmd == "maxmeme" then
			if from == "siberianpns" or from == "lost_rd" then
				irc.say(chan.name, "MAXIMUM")
				irc.say(chan.name, "E")
				irc.say(chan.name, "M")
				irc.say(chan.name, "E")
			end
		end
	end
end
irc.register_callback("channel_msg", on_channel_msg)

-- Callback on whisper (/w)
-- Useful for administration of the bot that the users shouldn't see
local function on_private_msg(from, msg)
	if from == "lost_rd" then
		if msg == "leave" then
			irc.quit("gone")
			return
		elseif msg:sub(1, 5) == "send " then
			dcc.send(from, msg:sub(6))
			return
		end
	end
	if from == "jtv" then
		print("---"..msg:sub(1,33).."---")
		if msg:sub(1,33) == "The moderators of this room are: " then
			for w in string.gmatch(msg:sub(34), "[a-z0-9_]+") do
				print(w)
			end
		end
	end
end
irc.register_callback("private_msg", on_private_msg)

-- Callback on act (/me)?
local function on_channel_act(chan, from, msg)
	--irc.act(chan.name, "jumps on " .. from)
end
irc.register_callback("channel_act", on_channel_act)

-- Callback on private act
-- Doubt useful
local function on_private_act(from, msg)
	irc.act(from, "jumps on you")
end
irc.register_callback("private_act", on_private_act)

-- Callback on op
-- Might be invoked when a user is modded
local function on_op(chan, from, nick)
	print(nick .. " was opped in " .. chan .. " by " .. from)
	print_state()
end
irc.register_callback("op", on_op)

-- Callback on deop
-- Might be invoked when mod is unmodded
local function on_deop(chan, from, nick)
	print(nick .. " was deopped in " .. chan .. " by " .. from)
	print_state()
end
irc.register_callback("deop", on_deop)

-- Callback on voice
-- Might be invoked when a user is modded
local function on_voice(chan, from, nick)
	print(nick .. " was voiced in " .. chan .. " by " .. from)
	print_state()
end
irc.register_callback("voice", on_voice)

-- Callback on devoice
-- Might be invoked when mod is unmodded
local function on_devoice(chan, from, nick)
	print(nick .. " was devoiced in " .. chan .. " by " .. from)
	print_state()
end
irc.register_callback("devoice", on_devoice)

-- Callback on dcc send
-- Invoked when the bot sends a message?
local function on_dcc_send()
	return true
end
irc.register_callback("dcc_send", on_dcc_send)

-- Initialise a class for groups such as Moderators, Admins
-- This will be replaced with calls to database
Group = class("Group")
function Group:init(name, tMembers)
	if tMembers then
		self.members = {}
	end
	for k,v in pairs(tMembers) do
		self.members[v] = true
	end
	self.label = name
end
function Group:printMembers()
	print(self.label..":")
	for k,v in pairs(self.members) do
		print(k)
	end
end
function Group:isMember(username)
	if self.members[username] then
		print(username.." is a member of "..self.label)
		return true
	end
	print(username.." is not a member of "..self.label)
	return false
end
function Group:addMember(username)
	self.members[username] = true
end
function Group:removeMember(username)
	self.members[username] = nil
end

-- Add admins and mods to the groups
-- This will be replaced with database calls
admins = Group:new("admins", {"lost_rd"})
admins:printMembers()
mods = Group:new("mods", {"lost_rd", "lost_r2d2"})
mods:printMembers()

-- Grab the Twitch authentication key from a file that won't be uploaded to git
passkey = require "passkey"

-- Finally, connect the bot to the network
--irc.connect{network = "irc.freenode.net", nick = "doylua"}
irc.connect{
	network = "irc.twitch.tv",
	nick = "lost_r2d2",
	pass = passkey,
}