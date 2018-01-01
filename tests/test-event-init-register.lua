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
local TRACE_SEP = tests.trace_sep
local TRACE = tests.trace

local pcall = pcall

local socket = require ('nclua.event.tcp_socket')
local event = require ('nclua.event')
local engine = event._engine
_ENV = nil

local function ASSERT_ERROR_REGISTER (...)
   local status, errmsg = pcall (event.register, ...)
   ASSERT (not status)
   TRACE (errmsg)
end

local function ASSERT_FAIL_REGISTER (...)
   local status, errmsg = event.register (...)
   ASSERT (not status)
   TRACE (errmsg)
end

-- Checks if the i-th entry on engine's handler list is a
-- table of the form {func, filter}.
local function check_handler (i, f, filter)
   return tests.objeq (engine.handler_list[i], {f, filter})
end

-- Sanity checks.
ASSERT_ERROR_REGISTER (nil)
ASSERT_ERROR_REGISTER ({})
ASSERT_ERROR_REGISTER (0, 0)
ASSERT_ERROR_REGISTER (0, {})
ASSERT_ERROR_REGISTER (function () end, function () end)

-- Registers handlers without filters and check the result.
local f1 = function () end
local f2 = function () end
local f3 = function () end
local x = {x='x'}
local y = {y='y'}
local z = {z='z'}

ASSERT (event.register (f1, nil))
ASSERT (check_handler (1, f1, nil))

ASSERT (event.register (1, f2, y))
ASSERT (check_handler (1, f2, y))
ASSERT (check_handler (2, f1, nil))

ASSERT (event.register (3, f3, z))
ASSERT (check_handler (1, f2, y))
ASSERT (check_handler (2, f1, nil))
ASSERT (check_handler (3, f3, z))

-- Register handlers with filters from unknown classes, which should be
-- ignored, and check the resulst.
engine:reset ()
local f1 = function () end
local f2 = function () end
local f3 = function () end

ASSERT (event.register (f1, 'x'))
ASSERT (check_handler (1, f1, nil))

ASSERT (event.register (1, f2, 'x', 'y', 'z', {}))
ASSERT (check_handler (1, f2, nil))
ASSERT (check_handler (2, f1, nil))

ASSERT (event.register (3, f3, 'z'))
ASSERT (check_handler (1, f2, nil))
ASSERT (check_handler (2, f1, nil))
ASSERT (check_handler (3, f3, nil))

-- Register handlers with filters from known classes and check the result.
engine:reset ()
engine:load ('key', 'ncl', 'pointer', 'tcp', 'user')
local f1 = function () end
local f2 = function () end
local f3 = function () end
local sock = socket.new ()

ASSERT_FAIL_REGISTER (f1, 'key', {})
ASSERT_FAIL_REGISTER (f1, 'key', 'press', {})
ASSERT_FAIL_REGISTER (f2, 'ncl', {})
ASSERT_FAIL_REGISTER (f2, 'ncl', 'presentation', {})
ASSERT_FAIL_REGISTER (f2, 'ncl', 'presentation', 'start', {})
ASSERT_FAIL_REGISTER (f3, 'pointer', {})
ASSERT_FAIL_REGISTER (f3, 'pointer', 'move', {})
ASSERT_FAIL_REGISTER (f3, 'pointer', 'move', 40, {})
ASSERT_FAIL_REGISTER (f1, 'tcp', {})

ASSERT (event.register (f1, 'key'))
ASSERT (check_handler (1, f1, {class='key'}))

ASSERT (event.register (f2, 'key', 'press'))
ASSERT (check_handler (2, f2, {class='key', type='press'}))

ASSERT (event.register (1, f3, 'key', 'press', 0))
ASSERT (check_handler (1, f3, {class='key', type='press', key=0}))

ASSERT (event.register (f3, 'key', nil, 0))
ASSERT (check_handler (4, f3, {class='key', key=0}))

ASSERT (event.register (2, f1, 'tcp'))
ASSERT (check_handler (2, f1, {class='tcp'}))

ASSERT (event.register (4, f3, 'tcp', sock))
ASSERT (check_handler (4, f3, {class='tcp', connection=sock}))

ASSERT (event.register (2, f2, 'user'))
ASSERT (check_handler (2, f2, {class='user'}))
