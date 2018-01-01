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

local function ASSERT_ERROR_FILTER (...)
   local status, errmsg = pcall (pointer.filter, pointer, ...)
   ASSERT (not status)
   TRACE (errmsg)
end

-- Check bad class.
ASSERT_ERROR_FILTER (nil)
ASSERT_ERROR_FILTER ('unknown')

-- Check bad type.
ASSERT_ERROR_FILTER ('pointer', {})
ASSERT_ERROR_FILTER ('pointer', 'unknown')

-- Check bad x or y.
ASSERT_ERROR_FILTER ('pointer', 'press', {})
ASSERT_ERROR_FILTER ('pointer', 'press', nil, {})

-- Check class-only.
local t = pointer:filter ('pointer')
ASSERT (tests.objeq (t, {class='pointer'}))

-- Check class and type.
local t = pointer:filter ('pointer', 'press')
ASSERT (tests.objeq (t, {class='pointer', type='press'}))

local t = pointer:filter ('pointer', 'release')
ASSERT (tests.objeq (t, {class='pointer', type='release'}))

local t = pointer:filter ('pointer', 'move')
ASSERT (tests.objeq (t, {class='pointer', type='move'}))

-- Check class and x or y.
local t = pointer:filter ('pointer', nil, 50)
ASSERT (tests.objeq (t, {class='pointer', x=50}))

local t = pointer:filter ('pointer', nil, nil, 80)
ASSERT (tests.objeq (t, {class='pointer', y=80}))

local t = pointer:filter ('pointer', nil, -1, -5)
ASSERT (tests.objeq (t, {class='pointer', x=-1, y=-5}))

-- Check class, type, and x or y.
local t = pointer:filter ('pointer', 'move', -1, -5)
ASSERT (tests.objeq (t, {class='pointer', type='move', x=-1, y=-5}))

local t = pointer:filter ('pointer', 'press', nil, -5)
ASSERT (tests.objeq (t, {class='pointer', type='press', nil, y=-5}))

local t = pointer:filter ('pointer', 'release', 12)
ASSERT (tests.objeq (t, {class='pointer', type='release', x=12}))
