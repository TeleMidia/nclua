--[[ Copyright (C) 2013-2018 PUC-Rio/Laboratorio TeleMidia

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

local tests = require ('tests')
local ASSERT = tests.ASSERT
local ASSERT_ERROR = tests.ASSERT_ERROR
local FAIL = tests.FAIL
local TRACE_SEP = tests.trace_sep
local TRACE = tests.trace

local socket = require ('nclua.event.tcp_socket')
_ENV = nil

local function CYCLE_UNTIL (func)
   TRACE ('cycling')
   tests.socket.cycle_until (func)
end

-- Sanity checks.
local sock = socket.new ()
ASSERT_ERROR (socket.connect)
ASSERT_ERROR (socket.connect, sock)
ASSERT_ERROR (socket.connect, sock, 0)
ASSERT_ERROR (socket.connect, sock, 0, 0)
ASSERT_ERROR (socket.connect, sock, 0, 0, {})

-- Connect to test server and check the result.
local sock = socket.new ()
local server, host, port = tests.server.new_echo ()
server:start ()

local function connect_cb (status, _sock, _host, _port, errmsg)
   TRACE ('connect:', _sock, _host, _port, errmsg)
   if status then
      ASSERT (_sock == sock, _host == host, port == _port)
   else
      FAIL ('connected failed')
   end
end

sock:connect (host, port, connect_cb)
CYCLE_UNTIL (function () return sock:is_connected () end)
ASSERT (sock:is_connected ())

-- Sanity check: call connect() on a already connected socket.
ASSERT_ERROR (socket.connect, sock, host, port, connect_cb)

-- Disconnect form test server and check the result.
local function disconnect_cb (status, _sock, errmsg)
   TRACE ('disconnect:', _sock, errmsg)
   if status then
      ASSERT (_sock == sock)
   else
      FAIL ('disconnect failed')
   end
end

sock:disconnect (disconnect_cb)
CYCLE_UNTIL (function () return not sock:is_connected () end)
ASSERT (not sock:is_connected ())

-- Sanity check: call disconnect() on a already disconnected socket.
ASSERT_ERROR (socket.disconnect, sock, disconnect_cb)

-- Connect to server and let socket:__gc() disconnect the socket.
do
   sock:connect (host, port, connect_cb)
   CYCLE_UNTIL (function () return sock:is_connected () end)
   ASSERT (sock:is_connected ())
   sock = nil
end
server:stop ()

-- Check unsuccessful connection.
-- FIXME: This check is not working on Windows.
if tests.is_windows () then return end

local sock = socket.new ()
local DONE = false
local function connect_fail_cb (status, _sock, _host, _port, errmsg)
   TRACE ('connect fail:', _sock, _host, _port, errmsg)
   if status then
      FAIL ('connect succeeded when it should fail')
   else
      DONE = true
   end
end
sock:connect (host, port, connect_fail_cb)
CYCLE_UNTIL (function () return DONE end)
ASSERT (not sock:is_connected ())
