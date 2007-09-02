---
-- Implementation of the DCC protocol
-- initialization {{{
local base =      _G
local irc =       require 'irc'
local irc_debug = require 'irc.debug'
local misc =      require 'irc.misc'
local socket =    require 'socket'
local coroutine = require 'coroutine'
local io =        require 'io'
local string =    require 'string'
-- }}}

---
-- This module implements the DCC protocol. File transfers (DCC SEND) are
-- handled, but DCC CHAT is not, as of yet.
module 'irc.dcc'

-- defaults {{{
FIRST_PORT = 1028
LAST_PORT = 5000
-- }}}

-- private functions {{{
-- send_file {{{
-- TODO: no reason to be sending the size parameter all over the place when we
-- only need it in this function. also, should probably seek to the beginning
-- of the file before sending it.
--
-- Sends a file to a remote user, after that user has accepted our DCC SEND
-- invitation
-- @param sock        Socket to send the file on
-- @param file        Lua file object corresponding to the file we want to send
-- @param size        Size of the file to send
-- @param packet_size Size of the packets to send the file in
local function send_file(sock, file, size, packet_size)
    local bytes = 0
    while true do
        local packet = file:read(packet_size)
        if not packet then break end
        bytes = bytes + packet:len()
        local index = 1
        while true do
            sock:send(packet, index)
            local new_bytes = misc.int_to_str(sock:receive(4))
            if new_bytes ~= bytes then
                index = packet_size - bytes + new_bytes + 1
            else
                break
            end
        end
        if bytes >= size then break end
        coroutine.yield(true)
    end
    file:close()
    sock:close()
    irc._unregister_socket(sock, 'w')
    return true
end
-- }}}

-- handle_connect {{{
--
-- Handle the connection attempt by a remote user to get our file. Basically
-- just swaps out the server socket we were listening on for a client socket
-- that we can send data on
-- @param ssock Server socket that the remote user connected to
-- @param file  Lua file object corresponding to the file we want to send
-- @param size  Size of the file to send
-- @param packet_size Size of the packets to send the file in
local function handle_connect(ssock, file, size, packet_size)
    packet_size = packet_size or 1024
    local sock = ssock:accept()
    sock:settimeout(0.1)
    ssock:close()
    irc._unregister_socket(ssock, 'r')
    irc._register_socket(sock, 'w',
                         coroutine.wrap(function(sock)
                             return send_file(sock, file, size, packet_size)
                         end))
    return true
end
-- }}}

-- accept_file {{{
--
-- Accepts a file from a remote user which has offered it to us.
-- @param sock        Socket to receive the file on
-- @param file        Lua file object corresponding to the file we want to save
-- @param size        Size of the file we are receiving
-- @param packet_size Size of the packets to receive the file in
local function accept_file(sock, file, size, packet_size)
    local bytes = 0
    while true do
        local packet, err, partial_packet = sock:receive(packet_size)
        if not packet and err == "timeout" then packet = partial_packet end
        if not packet then break end
        if packet:len() == 0 then break end
        bytes = bytes + packet:len()
        sock:send(misc.str_to_int(bytes))
        file:write(packet)
        coroutine.yield(true)
    end
    file:close()
    sock:close()
    irc._unregister_socket(sock, 'r')
    return true
end
-- }}}
-- }}}

-- public functions {{{
-- send {{{
---
-- Offers a file to a remote user.
-- @param nick     User to offer the file to
-- @param filename Filename to offer
-- @param port     Port to accept connections on (optional, defaults to
--                 choosing an available port between FIRST_PORT and LAST_PORT
--                 above)
function send(nick, filename, port)
    port = port or FIRST_PORT
    local sock = base.assert(socket.tcp())
    repeat
        err, msg = sock:bind('*', port)
        port = port + 1
    until msg ~= "address already in use" and port <= LAST_PORT + 1
    base.assert(err, msg)
    base.assert(sock:listen(1))
    local ip = misc.ip_str_to_int(irc.get_ip())
    local file = base.assert(io.open(filename))
    local size = file:seek("end")
    file:seek("set")
    irc._register_socket(sock, 'r',
                         coroutine.wrap(function(sock)
                             return handle_connect(sock, file, size)
                         end))
    filename = misc.basename(filename)
    if filename:find(" ") then filename = '"' .. filename .. '"' end
    irc.send("PRIVMSG", nick, {"DCC SEND " .. filename .. " " ..
             ip .. " " .. port - 1 .. " " .. size})
end
-- }}}

-- accept {{{
-- TODO: this shouldn't be a public function
--
-- Accepts a file offer from a remote user. Called when the on_dcc callback
-- retuns true.
-- @param filename    Name to save the file as
-- @param address     IP address of the remote user
-- @param port        Port to connect to at the remote user
-- @param size        Size of the file that the remote user is offering
-- @param packet_size Size of the packets the remote user will be sending
function accept(filename, address, port, size, packet_size)
    packet_size = packet_size or 1024
    local sock = base.assert(socket.tcp())
    base.assert(sock:connect(misc.ip_int_to_str(address), port))
    sock:settimeout(0.1)
    local file = base.assert(io.open(misc.get_unique_filename(filename), "w"))
    irc._register_socket(sock, 'r',
                         coroutine.wrap(function(sock)
                             return accept_file(sock, file, size, packet_size)
                         end))
end
-- }}}
-- }}}
