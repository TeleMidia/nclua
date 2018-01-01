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

local ipairs = ipairs
local pairs = pairs
local table = table

local socket = require ('nclua.event.tcp_socket')
_ENV = nil

local function CYCLE_UNTIL (func)
   TRACE ('cycling')
   tests.socket.cycle_until (func)
end

-- Connect N sockets to local echo server, send random data, and check if
-- the received data is equal to the sent data.
local server, host, port = tests.server.new_echo ()
server:start ()

local n = 9
local sock = {}
for i=1,n do
   sock[i] = socket.new ()
end

local function connect_all (...)
   local connect_cb = function (status, sock, host, port, errmsg)
      TRACE ('connect:', sock, host, port, errmsg)
      ASSERT (status)
   end
   for _,sock in ipairs {...} do
      sock:connect (host, port, connect_cb)
   end
end

connect_all (table.unpack (sock))
CYCLE_UNTIL (                   -- wait until all sockets are connected
   function ()
      for _,sock in ipairs (sock) do
         if not sock:is_connected () then
            return false
         end
      end
      return true
   end
)

local sent_data = {}
local received_data = {}

local function receive_all (...)
   local receive_cb
   receive_cb = function (status, sock, data)
      TRACE ('receive:', sock, #data..' bytes received')
      ASSERT (status)
      received_data[sock] = (received_data[sock] or '')..data
      if #data > 0 and #received_data[sock] < #sent_data[sock] then
         sock:receive (1, receive_cb)
      else
         TRACE ('disconnecting', sock)
         sock:disconnect (function (status) ASSERT (status) end)
      end
   end
   for _,sock in ipairs {...} do
      sock:receive (1, receive_cb)
   end
end

local function send_all (...)
   local send_cb
   send_cb = function (status, sock, data_left)
      TRACE (sock, 'send:', #data_left..' bytes left')
      ASSERT (status)
      if #data_left > 0 then
         sock:send (data_left, send_cb)
      end
   end
   for _,sock in ipairs {...} do
      sent_data[sock] = tests.rand_string (1024) -- 1K
      sock:send (sent_data[sock], send_cb)
   end
end

receive_all (table.unpack (sock))
send_all (table.unpack (sock))

CYCLE_UNTIL (                   -- wait until all sockets are disconnected
   function ()
      for _,sock in ipairs (sock) do
         if sock:is_connected () then
            return false
         end
      end
      return true
   end
)

for sock, str in pairs (received_data) do
   ASSERT (str == sent_data[sock])
end

server:stop ()
