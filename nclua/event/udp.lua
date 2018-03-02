--[[ nclua.event.udp -- The TCP event class.
     Copyright (C) 2013-2018 PUC-Rio/Laboratorio TeleMidia

This file is part of NCLua.

NCLua is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 2 of the License, or
(at your option) any later version.

NCLua is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
License for more details.

You should have received a copy of the GNU General Public License
along with NCLua.  If not, see <https://www.gnu.org/licenses/>.  ]]--

local udp

local assert = assert
local print = print
local type = type

local check = require ('nclua.event.check')
local engine = require ('nclua.event.engine')
local socket = require ('nclua.event.udp_socket')
_ENV = nil

do
   udp = engine:new ()
   udp.class = 'udp'
end

-- Default buffer size (in bytes) of receive requests.
local RECEIVE_BUFSIZE = 4096

-- Checks if object SOCK is a socket; if CONNECTED is true, checks if SOCK
-- is connected.  Returns SOCK if successful, otherwise throws an error.
local function check_socket (prefix, name, sock, connected)
   if not socket:is_socket (sock) then
      check.throw_bad_type (prefix, name, 'socket', type (sock))
   end
   if connected and not sock:is_connected () then
      check.throw_bad (prefix, name, 'socket %s not connected', sock)
   end
   return sock
end

local function check_arg_socket (...)
   check_socket (check.ERR_ARG_PREFIX, ...)
end

local function check_event_socket (...)
   check_socket (check.ERR_EVENT_PREFIX, ...)
end

---
-- Checks if event EVT is a valid UDP event.
-- Returns EVT if successful, otherwise throws an error.
--
function udp:check (evt)
    assert (evt.class == udp.class)
    check.event.option ('type', evt.type, {'bind', 'data', 'unbind'})
    if evt.type == 'bind' then
        check.event.number ('localport', evt.localport)
    elseif evt.type == 'data' then
        check.event.string ('host', evt.host)
        check.event.number ('port', evt.port)
        check.event.string ('value', evt.value)
    elseif evt.type == 'unbind' then
--      check_event_socket ('connection', evt.connection, true)
    end 

    print("UDP CHECK END")
    return evt
end

---
-- Builds a UDP event filter according to the given parameters.
-- Returns a new filter if successful, otherwise throws an error.
--
function udp:filter (class)
    print("UDP FILTER:", class)
    assert (class == udp.class)
    print("UDP FILTER END")
    return {class=class}
end

-- Dispatch TCP event EVT.
local function dispatch (evt)
    evt.class = udp.class
    tcp.OUTQ:enqueue (evt)
 end

local function data_received (from_, port_, value_)
    print("local data received! from:", from_,"port:", port_,"value:", value_,"\n")
   -- dispatch {class='udp', type='data', from=from_, port=port_, value=value_}
 end

local function error_handler(errmsg)
    print("error handler: msg:", errmsg)
 end

---
-- Cycles the UDP engine once.
--
function udp:cycle ()
   while not udp.INQ:is_empty () do
      local evt = udp.INQ:dequeue ()
      assert (evt.class == udp.class)
      
        if evt.type == 'bind' then
            local localport = assert (evt.localport)
            local sock = assert (socket.new (evt.timeout or 0))
            sock:bind (localport, data_received, error_handler)
        elseif evt.type == 'data' then
            local host = assert (evt.host)
            local port = assert (evt.port)
            local value = assert (evt.value)
            -- ver isso depois
            local sock = assert (socket.new (evt.timeout or 0))
            sock:send (host, port, value, error_handler)  
        end

      udp.OUTQ:enqueue (evt)    -- echo back
   end
end

return udp
