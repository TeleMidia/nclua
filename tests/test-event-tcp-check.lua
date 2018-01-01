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

local pcall = pcall

local check = require ('nclua.event.check')
local socket = require ('nclua.event.tcp_socket')
local tcp = require ('nclua.event.tcp')
_ENV = nil

local function ASSERT_ERROR_CHECK (t)
   local status, errmsg = pcall (tcp.check, tcp, t)
   ASSERT (not status)
   TRACE (errmsg)
end

local server, host, port = tests.server.new_echo ()
server:start ()
local sock = socket.new ()
sock:connect (host, port, function (status) ASSERT (status) end)
tests.socket.cycle_until (function () return sock:is_connected () end)

-- Check bad class.
ASSERT_ERROR_CHECK {}
ASSERT_ERROR_CHECK {class='unknown'}

-- Check missing type.
ASSERT_ERROR_CHECK {class='tcp'}

-- Check bad type.
ASSERT_ERROR_CHECK {class='tcp', type='unknown'}

-- Check missing host when type='connect'.
ASSERT_ERROR_CHECK {class='tcp', type='connect'}

-- Check missing port when type='connect'.
ASSERT_ERROR_CHECK {class='tcp', type='connect', host='localhost'}

-- Check bad port when type='connect'.
ASSERT_ERROR_CHECK {class='tcp', type='connect', host='localhost', port='a'}

-- Check bad timeout when type='connect'.
ASSERT_ERROR_CHECK {class='tcp', type='connect', host='x',
                    port='10', timeout={}}

-- Check missing connection when type='data'.
ASSERT_ERROR_CHECK {class='tcp', type='data'}

-- Check bad connection when type='data'.
ASSERT_ERROR_CHECK {class='tcp', type='data', connection=50}

-- Check not-connected socket when type='data'.
ASSERT_ERROR_CHECK {class='tcp', type='data', connection=sock:new ()}

-- Check bad connection when type='disconnect'.
ASSERT_ERROR_CHECK {class='tcp', type='disconnect', connection=50}

-- Check not-connected socket when type='disconnect'.
ASSERT_ERROR_CHECK {class='tcp', type='disconnect', connection=sock:new ()}

-- Check missing value when type='data'.
ASSERT_ERROR_CHECK {class='tcp', type='data', connection=sock}

-- Check bad value when type='data'.
ASSERT_ERROR_CHECK {class='tcp', type='data', connection=sock, value={}}

-- Check valid connect events.
ASSERT (tcp:check {class='tcp', type='connect', host='localhost', port=80})
ASSERT (tcp:check {class='tcp', type='connect', host='localhost', port=40,
                   timeout=120})

-- Check valid send events.
ASSERT (tcp:check {class='tcp', type='data', connection=sock, value=''})
ASSERT (tcp:check {class='tcp', type='data', connection=sock, value=1234})

-- Check valid disconnect events.
ASSERT (tcp:check {class='tcp', type='disconnect', connection=sock})
ASSERT (tcp:check {class='tcp', type='disconnect', connection=sock})

server:stop ()
