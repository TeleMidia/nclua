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
local event = require ('nclua.event')
local engine = event._engine
_ENV = nil

local function ASSERT_ERROR_UNREGISTER (...)
   local status, errmsg = pcall (event.unregister, ...)
   ASSERT (not status)
   TRACE (errmsg)
end

-- Checks if the i-th entry on engine's handler list is a
-- table of the form {func, filter}.
local function check_handler (i, f, filter)
   return tests.objeq (engine.handler_list[i], {f, filter})
end

-- Sanity checks.
ASSERT_ERROR_UNREGISTER (nil)
ASSERT_ERROR_UNREGISTER ({})

-- Registers some functions, unregisters them, and check the result.
local f1 = function () end
local f2 = function () end
local f3 = function () end
local x = {x='x'}
local y = {y='y'}
local z = {z='z'}

ASSERT (event.register (f1, x))
ASSERT (event.register (f2, x))
ASSERT (event.register (f3, x))
ASSERT (event.register (f1, y))
ASSERT (event.register (f2, y))
ASSERT (event.register (f3, y))
ASSERT (event.register (f1, z))
ASSERT (event.register (f2, z))
ASSERT (event.register (f3, z))

ASSERT (event.unregister (f1) == 3)
ASSERT (check_handler (1, f2, x))
ASSERT (check_handler (2, f3, x))
ASSERT (check_handler (3, f2, y))
ASSERT (check_handler (4, f3, y))
ASSERT (check_handler (5, f2, z))
ASSERT (check_handler (6, f3, z))
