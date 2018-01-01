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
local key = require ('nclua.event.key')
_ENV = nil

local function ASSERT_ERROR_CHECK (t)
   local status, errmsg = pcall (key.check, key, t)
   ASSERT (not status)
   TRACE (errmsg)
end

-- Check bad class.
ASSERT_ERROR_CHECK {}
ASSERT_ERROR_CHECK {class='unknown'}

-- Check missing type.
ASSERT_ERROR_CHECK {class='key'}

-- Check bad type.
ASSERT_ERROR_CHECK {class='key', type='unknown'}

-- Check missing key.
ASSERT_ERROR_CHECK {class='key', type='press'}
ASSERT_ERROR_CHECK {class='key', type='release'}

-- Check bad key.
ASSERT_ERROR_CHECK {class='key', type='press', key={}}

-- Check valid KEY events.
ASSERT (key:check {class='key', type='press', key='0'})
ASSERT (key:check {class='key', type='release', key='ENTER'})
ASSERT (key:check {class='key', type='release', key='enter'})
