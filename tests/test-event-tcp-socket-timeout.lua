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

-- Force a receive timeout and check the result.
local server, host, port = tests.server.new_echo ()
server:start ()

local sock = socket.new (1)     -- 1s timeout
sock:connect (host, port, function (status) ASSERT (status) end)
CYCLE_UNTIL (function () return sock:is_connected () end)

local sent_data = tests.rand_string (128 * 2^10) -- 128K
local function send_cb (status, _sock, data_left)
   TRACE ('send:', _sock, #data_left..' bytes left')
   ASSERT (status, _sock == sock)
   if #data_left > 0 then
      sock:send (data_left, send_cb)
   end
end
sock:send (sent_data, send_cb)

local received_data
local DONE = false
local function receive_cb (status, _sock, data)
   if status then
      received_data = (received_data or '')..data
      TRACE ('receive:', _sock, #data..' bytes received')
      ASSERT (_sock == sock, #data > 0) -- should reach EOF
      sock:receive (4096, receive_cb)
   else
      TRACE ('receive failure:', _sock, data)
      ASSERT (received_data == sent_data)
      DONE = true
   end
end

sock:receive (4096, receive_cb)
CYCLE_UNTIL (function () return DONE end)
server:stop ()
