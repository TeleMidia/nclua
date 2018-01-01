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
local ncl = require ('nclua.event.ncl')
_ENV = nil

local function ASSERT_ERROR_FILTER (...)
   local status, errmsg = pcall (ncl.filter, ncl, ...)
   ASSERT (not status)
   TRACE (errmsg)
end

-- Check bad class.
ASSERT_ERROR_FILTER (nil)
ASSERT_ERROR_FILTER ('unknown')

-- Check bad type.
ASSERT_ERROR_FILTER ('ncl', {})
ASSERT_ERROR_FILTER ('ncl', 'unknown')

-- Check bad action.
ASSERT_ERROR_FILTER ('ncl', 'selection', nil, {})
ASSERT_ERROR_FILTER ('ncl', 'selection', nil, 'unknown')

-- Check bad name when type='attribution'.
ASSERT_ERROR_FILTER ('ncl', 'attribution', {}, nil)

-- Check bad label when type='presentation' or type='selection'.
ASSERT_ERROR_FILTER ('ncl', 'presentation', {}, nil)
ASSERT_ERROR_FILTER ('ncl', 'selection', {}, nil)

-- Check class-only.
local t = ncl:filter ('ncl')
ASSERT (tests.objeq (t, {class='ncl'}))

-- Check class and type.
local t = ncl:filter ('ncl', 'attribution')
ASSERT (tests.objeq (t, {class='ncl', type='attribution'}))

local t = ncl:filter ('ncl', 'presentation')
ASSERT (tests.objeq (t, {class='ncl', type='presentation'}))

local t = ncl:filter ('ncl', 'selection')
ASSERT (tests.objeq (t, {class='ncl', type='selection'}))

-- Check class and action.
local t = ncl:filter ('ncl', nil, nil, 'abort')
ASSERT (tests.objeq (t, {class='ncl', action='abort'}))

local t = ncl:filter ('ncl', nil, nil, 'pause')
ASSERT (tests.objeq (t, {class='ncl', action='pause'}))

local t = ncl:filter ('ncl', nil, nil, 'resume')
ASSERT (tests.objeq (t, {class='ncl', action='resume'}))

local t = ncl:filter ('ncl', nil, nil, 'start')
ASSERT (tests.objeq (t, {class='ncl', action='start'}))

local t = ncl:filter ('ncl', nil, nil, 'stop')
ASSERT (tests.objeq (t, {class='ncl', action='stop'}))

-- Check, class, type, and action.
local t = ncl:filter ('ncl', 'presentation', nil, 'abort')
ASSERT (tests.objeq (t, {class='ncl', type='presentation', action='abort'}))

local t = ncl:filter ('ncl', 'attribution', nil, 'pause')
ASSERT (tests.objeq (t, {class='ncl', type='attribution', action='pause'}))

local t = ncl:filter ('ncl', 'selection', nil, 'resume')
ASSERT (tests.objeq (t, {class='ncl', type='selection', action='resume'}))

-- Class, type and name when type='attribution'.
local t = ncl:filter ('ncl', 'attribution', 'x', nil)
ASSERT (tests.objeq (t, {class='ncl', type='attribution', name='x'}))

-- Check class and label when type='presentation' or type='selection'.
local t = ncl:filter ('ncl', nil, 'x', nil)
ASSERT (tests.objeq (t, {class='ncl', label='x'}))

-- Check class, type, and label when type='presentation'
-- or type='selection'.
local t = ncl:filter ('ncl', 'presentation', 'x', nil)
ASSERT (tests.objeq (t, {class='ncl', type='presentation', label='x'}))

local t = ncl:filter ('ncl', 'selection', 'x', nil)
ASSERT (tests.objeq (t, {class='ncl', type='selection', label='x'}))

-- Check class, action, and label when type='presentation'
-- or type='selection'.
local t = ncl:filter ('ncl', nil, 'x', 'start')
ASSERT (tests.objeq (t, {class='ncl', action='start', label='x'}))
