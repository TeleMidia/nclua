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
local pointer = require ('nclua.event.pointer')
_ENV = nil

local function ASSERT_ERROR_CHECK (t)
   local status, errmsg = pcall (pointer.check, pointer, t)
   ASSERT (not status)
   TRACE (errmsg)
end

-- Check bad class.
ASSERT_ERROR_CHECK {}
ASSERT_ERROR_CHECK {class='unknown'}

-- Check missing type.
ASSERT_ERROR_CHECK {class='pointer'}

-- Check bad type.
ASSERT_ERROR_CHECK {class='pointer', type='unknown'}

-- Check missing x or y.
ASSERT_ERROR_CHECK {class='pointer', type='press'}
ASSERT_ERROR_CHECK {class='pointer', type='release', x=25}
ASSERT_ERROR_CHECK {class='pointer', type='move', y=50}

-- Check bad x or y.
ASSERT_ERROR_CHECK {class='pointer', type='release', x={}, y=50}
ASSERT_ERROR_CHECK {class='pointer', type='release', x=50, y={}}

-- Check valid POINTER events.
ASSERT (pointer:check {class='pointer', type='move', x=-50, y=23})
ASSERT (pointer:check {class='pointer', type='press', x='33', y=0})
ASSERT (pointer:check {class='pointer', type='release', x=33, y='0'})
