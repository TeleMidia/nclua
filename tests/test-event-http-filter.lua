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

local soup = require ('nclua.event.http_soup')
local http = require ('nclua.event.http')
_ENV = nil

local function ASSERT_ERROR_FILTER (...)
   local status, errmsg = pcall (http.filter, http, ...)
   ASSERT (not status)
   TRACE (errmsg)
end

-- Check bad class.
ASSERT_ERROR_FILTER (nil)
ASSERT_ERROR_FILTER ('unknown')

-- Check bad type.
ASSERT_ERROR_FILTER ('http', {})

-- Check class-only.
local t = http:filter ('http')
ASSERT (tests.objeq (t, {class='http'}))

-- Check class and type.
local t = http:filter ('http', 'request')
ASSERT (tests.objeq (t, {class='http', type='request'}))

-- Check class, type, and session.
local session = {}
local t = http:filter ('http', 'cancel', session)
ASSERT (tests.objeq (t, {class='http', type='cancel', session=session}))
