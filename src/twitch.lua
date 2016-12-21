--[[ This is the file that you run, e.g.
luajit twitch.lua
It's a bit messy for now but I'll clean it up
]]

-- Loading modules
-- 30log will be made redundant by LuaSQL
local class = require "30log"
local irc = require "irc"
local dcc = require "irc.dcc"
local callbacks = require "callbacks"
local utils = require "utils"

broadcaster_name = "lost_rd"
broadcaster_channel = "#"..broadcaster_name
bot_name = "lost_r2d2"

-- Debug flag
irc.DEBUG = true

-- Get local IP?
local ip_prog = io.popen("get_ip")
local ip = ip_prog:read()
ip_prog:close()
irc.set_ip(ip)

irc.register_callback("connect", callbacks.on_connect)
irc.register_callback("me_join", callbacks.on_me_join)
irc.register_callback("join", callbacks.on_join)
irc.register_callback("part", callbacks.on_part)
irc.register_callback("nick_change", callbacks.on_nick_change)
irc.register_callback("kick", callbacks.on_kick)
irc.register_callback("quit", callbacks.on_quit)
irc.register_callback("channel_act", callbacks.on_channel_act)
irc.register_callback("private_act", callbacks.on_private_act)
irc.register_callback("op", callbacks.on_op)
irc.register_callback("deop", callbacks.on_deop)
irc.register_callback("voice", callbacks.on_voice)
irc.register_callback("devoice", callbacks.on_devoice)
irc.register_callback("dcc_send", callbacks.on_dcc_send)

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
	if from == broadcaster_name then
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
			if from == broadcaster_name then
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
	if from == broadcaster_name then
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
admins = Group:new("admins", {broadcaster_name})
admins:printMembers()
mods = Group:new("mods", {broadcaster_name, bot_name})
mods:printMembers()

-- Grab the Twitch authentication key from a file that won't be uploaded to git
passkey = require "passkey"

-- Finally, connect the bot to the network
--irc.connect{network = "irc.freenode.net", nick = "doylua"}
irc.connect{
	network = "irc.twitch.tv",
	nick = bot_name,
	pass = passkey,
}