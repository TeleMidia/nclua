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

local tcp = require ('nclua.event.tcp')
_ENV = nil

local function AWAIT ()
   TRACE ('cycling')
   local evt = nil
   repeat
      tcp:cycle ()
      evt = tcp:receive ()
   until evt ~= nil
   return evt
end

-- Connect to local echo server, send random data, check if the receive data
-- is equal to the sent data, and disconnect from server.
local server, host, port = tests.server.new_echo ()
server:start ()

tcp:send {class='tcp', type='connect', host=host, port=port}
local evt = AWAIT ()

TRACE_SEP ()
TRACE ('connect:', evt.class, evt.type, evt.host, evt.port)
ASSERT (evt.class == 'tcp',
        evt.type == 'connect',
        evt.host == host,
        evt.port == port)

local sock = evt.connection
ASSERT (sock:is_connected ())

local sent_data = tests.rand_string (128 * 2^10) -- 128K
tcp:send {class='tcp', type='data', connection=sock, value=sent_data}

local received_data = ''
while #received_data < #sent_data do
   local evt = AWAIT ()
   TRACE ('receive:', evt.class, evt.connection,
          evt.type, #evt.value..' bytes')
   ASSERT (evt.class == 'tcp',
           evt.type == 'data',
           evt.connection == sock,
           evt.value)
   received_data = received_data..evt.value
end
ASSERT (sent_data == received_data)

tcp:send {class='tcp', type='disconnect', connection=sock}
local evt = AWAIT ()

TRACE ('disconnect', evt.class, evt.type)
ASSERT (evt.class == 'tcp',
        evt.type == 'disconnect')

-- Force a receive timeout.
tcp:send {class='tcp', type='connect', host=host, port=port, timeout=1}
local evt = AWAIT ()

TRACE_SEP ()
TRACE ('connect:', evt.class, evt.type, evt.host, evt.port)
ASSERT (evt.class == 'tcp',
        evt.type == 'connect',
        evt.host == host,
        evt.port == port)

local sock = evt.connection
ASSERT (sock:is_connected ())

local sent_data = tests.rand_string (128 * 2^10) -- 128K
tcp:send {class='tcp', type='data', connection=sock, value=sent_data}
local evt = AWAIT ()
TRACE ('error:', evt.class, evt.type, evt.error)
ASSERT (evt.class == 'tcp',
        evt.type == 'data',
        #evt.error > 0)

server:stop ()
