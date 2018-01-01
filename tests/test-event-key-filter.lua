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

local function ASSERT_ERROR_FILTER (...)
   local status, errmsg = pcall (key.filter, key, ...)
   ASSERT (not status)
   TRACE (errmsg)
end

-- Check bad class.
ASSERT_ERROR_FILTER (nil)
ASSERT_ERROR_FILTER ('unknown')

-- Check bad type.
ASSERT_ERROR_FILTER ('key', {})
ASSERT_ERROR_FILTER ('key', 'unknown')

-- Check bad key.
ASSERT_ERROR_FILTER ('key', 'press', {})

-- Check class-only.
local t = key:filter ('key')
ASSERT (tests.objeq (t, {class='key'}))

-- Check class and type.
local t = key:filter ('key', 'press')
ASSERT (tests.objeq (t, {class='key', type='press'}))

local t = key:filter ('key', 'release')
ASSERT (tests.objeq (t, {class='key', type='release'}))

-- Check class and key.
local t = key:filter ('key', nil, 'RED')
ASSERT (tests.objeq (t, {class='key', key='RED'}))

-- Check class, type, and key.
local t = key:filter ('key', 'press', 'GREEN')
ASSERT (tests.objeq (t, {class='key', type='press', key='GREEN'}))
