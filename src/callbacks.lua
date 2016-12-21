-- Using this file to reduce clutter in twitch.lua

local M = {
	-- Callback on connect
	function on_connect()
		print("Joining channel #lost_rd...")
		irc.join("#lost_rd")
	end,
	
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
	end,
	
	-- Callback on user join
	local function on_join(chan, user)
		print("I saw a join to " .. chan)
		if tostring(user) ~= "lost_rd" then
			irc.say(tostring(chan), "Hi, " .. user)
		end
		print_state()
	end,

	-- Callback on user part
	-- Not sure if useful for Twitch chat
	local function on_part(chan, user, part_msg)
		print("I saw a part from " .. chan.name .. " saying " .. part_msg)
		print_state()
	end,

	-- Callback on nick change
	-- Not useful for Twitch chat
	local function on_nick_change(new_nick, old_nick)
		print("I saw a nick change: "  ..  old_nick .. " -> " .. new_nick)
		print_state()
	end,

	-- Callback on kick
	-- Not sure if useful for Twitch chat
	local function on_kick(chan, user)
		print("I saw a kick in " .. chan)
		print_state()
	end,

	-- Callback on user quit
	-- Not sure if useful for Twitch chat
	local function on_quit(chan, user)
		print("I saw a quit from " .. chan)
		print_state()
	end,

	-- Callback on act (/me)?
	local function on_channel_act(chan, from, msg)
		--irc.act(chan.name, "jumps on " .. from)
	end,

	-- Callback on private act
	-- Doubt useful
	local function on_private_act(from, msg)
		irc.act(from, "jumps on you")
	end,

	-- Callback on op
	-- Might be invoked when a user is modded
	local function on_op(chan, from, nick)
		print(nick .. " was opped in " .. chan .. " by " .. from)
		print_state()
	end,

	-- Callback on deop
	-- Might be invoked when mod is unmodded
	local function on_deop(chan, from, nick)
		print(nick .. " was deopped in " .. chan .. " by " .. from)
		print_state()
	end,

	-- Callback on voice
	-- Might be invoked when a user is modded
	local function on_voice(chan, from, nick)
		print(nick .. " was voiced in " .. chan .. " by " .. from)
		print_state()
	end,

	-- Callback on devoice
	-- Might be invoked when mod is unmodded
	local function on_devoice(chan, from, nick)
		print(nick .. " was devoiced in " .. chan .. " by " .. from)
		print_state()
	end,

	-- Callback on dcc send
	-- Invoked when the bot sends a message?
	local function on_dcc_send()
		return true
	end
}

return M