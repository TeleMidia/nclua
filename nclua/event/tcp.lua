--[[ nclua.event.tcp -- The TCP event class.
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

local tcp

local assert = assert
local type = type

local check = require ('nclua.event.check')
local engine = require ('nclua.event.engine')
local socket = require ('nclua.event.tcp_socket')
_ENV = nil

do
   tcp = engine:new ()
   tcp.class = 'tcp'
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
-- Checks if event EVT is a valid TCP event.
-- Returns EVT if successful, otherwise throws an error.
--
function tcp:check (evt)
   assert (evt.class == tcp.class)
   check.event.option ('type', evt.type, {'connect', 'data', 'disconnect'})
   if evt.type == 'connect' then
      check.event.string ('host', evt.host)
      check.event.number ('port', evt.port)
      check.event.number ('timeout', evt.timeout, 0)

   elseif evt.type == 'data' then
      check_event_socket ('connection', evt.connection, true)
      check.event.string ('value', evt.value)
      check.event.number ('timeout', evt.timeout, 0)

   elseif evt.type == 'disconnect' then
      check_event_socket ('connection', evt.connection, true)
   end
   return evt
end

---
-- Builds a TCP event filter according to the given parameters.
-- Returns a new filter if successful, otherwise throws an error.
--
function tcp:filter (class, connection)
   assert (class == tcp.class)
   if connection ~= nil then
      check_arg_socket ('connection', connection)
   end
   return {class=class, connection=connection}
end

---
-- Cycles the TCP engine once.
--

-- Dispatch TCP event EVT.
local function dispatch (evt)
   evt.class = tcp.class
   tcp.OUTQ:enqueue (evt)
end

local function receive_finished (status, sock, data)

   -- FIXME: Avoid throwing a 'Socket closed' error (cf. TODO).
   if not sock:is_connected () then
      return
   end

   if status then
      if #data > 0 then
         dispatch {type='data', connection=sock, value=data}
         sock:receive (RECEIVE_BUFSIZE, receive_finished)
      end
   else
      dispatch {type='data', error=data}
   end
end

local function connect_finished (status, sock, host, port, errmsg)
   if status then
      dispatch {type='connect', host=host, port=port, connection=sock}
      sock:receive (RECEIVE_BUFSIZE, receive_finished)
   else
      dispatch {type='connect', host=host, port=port, error=errmsg}
   end
end

local function disconnect_finished (status, sock, errmsg)
   if status then
      dispatch {type='disconnect'}
   else
      dispatch {type='disconnect', error=errmsg}
   end
end

local function send_finished (status, sock, data_left)
   if status then
      if #data_left > 0 then
         sock:send (data_left, send_finished)
      end
   else
      dispatch {type='data', error=data_left}
   end
end

function tcp:cycle ()
   while not tcp.INQ:is_empty () do
      local evt = tcp.INQ:dequeue ()
      assert (evt.class == tcp.class)
      if evt.type == 'connect' then
         local host = assert (evt.host)
         local port = assert (evt.port)
         local sock = assert (socket.new (evt.timeout or 0))
         sock:connect (host, port, connect_finished)

      elseif evt.type == 'data' then
         local sock = assert (evt.connection)
         local data = assert (evt.value)
         assert (sock:is_connected ())
         sock:send (data, send_finished)

      elseif evt.type == 'disconnect' then
         local sock = assert (evt.connection)
         assert (sock:is_connected ())
         sock:disconnect (disconnect_finished)
      end
   end
   socket.cycle ()
end

return tcp
