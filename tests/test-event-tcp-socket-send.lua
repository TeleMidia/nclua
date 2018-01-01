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

local os = os
local socket = require ('nclua.event.tcp_socket')
_ENV = nil

local function CYCLE_UNTIL (func)
   TRACE ('cycling')
   tests.socket.cycle_until (func)
end

--  Sanity checks.
local sock = socket.new ()
ASSERT_ERROR (socket.send)
ASSERT_ERROR (socket.send, sock)
ASSERT_ERROR (socket.send, sock, 'abc') -- not connected

-- Send N bytes to local sink server and check the result.
local n = 128 * 2^10            -- 128K
local tmpfile = tests.tmpname ()
local server, host, port = tests.server.new_sink (nil, tmpfile)
server:start ()
TRACE ('writing data to '..tmpfile)

local sock = socket.new ()
sock:connect (host, port, function (status) ASSERT (status) end)
CYCLE_UNTIL (function () return sock:is_connected () end)

local DONE = false
local function send_cb (status, _sock, data_left)
   TRACE ('send:', _sock, #data_left..' bytes left')
   ASSERT (status, _sock == sock)
   if #data_left > 0 then
      sock:send (data_left, send_cb)
   else
      DONE = true               -- no more data to send
   end
end

local str = tests.rand_string (n)
sock:send (str, send_cb)
CYCLE_UNTIL (function () return DONE end)

local sink = tests.read_file (tmpfile)
ASSERT (str == sink)
os.remove (tmpfile)
server:stop ()
