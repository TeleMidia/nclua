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

-- Sanity checks.
local sock = socket.new ()
ASSERT_ERROR (socket.receive)
ASSERT_ERROR (socket.receive, sock)
ASSERT_ERROR (socket.receive, sock, 1)
ASSERT_ERROR (socket.receive, sock, 1, {})
ASSERT_ERROR (socket.receive, sock, 0, function () end) -- zero bytes

-- Receive N bytes form local source server and check the result.
-- FIXME: This check is not working on Windows.
if tests.is_windows () then return end

local n = 128 * 2^10            -- 128K
local tmpfile = tests.rand_file (128 * 2^10)
local server, host, port = tests.server.new_source (nil, tmpfile)
server:start ()
TRACE ('reading data from '..tmpfile)

local sock = socket.new ()
sock:connect (host, port, function (status) ASSERT (status) end)
CYCLE_UNTIL (function () return sock:is_connected () end)

local count = 0
local str = ''
local DONE = false
local function receive_cb (status, _sock, data)
   TRACE ('receive:', _sock, #data..' bytes received')
   ASSERT (status, _sock == sock)
   count = count + #data
   str = str..data
   if #data > 0 then
      sock:receive (tests.rand_integer (4096, 4 * 4096), receive_cb)
   else
      DONE = true               -- eof
   end
end

sock:receive (tests.rand_integer (4096, 4 * 4096), receive_cb)
CYCLE_UNTIL (function () return DONE end)

local src = tests.read_file (tmpfile)
ASSERT (str == src, count == n)
os.remove (tmpfile)
server:stop ()
