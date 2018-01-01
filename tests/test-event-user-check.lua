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
local user = require ('nclua.event.user')
_ENV = nil

local function ASSERT_ERROR_CHECK (t)
   local status, errmsg = pcall (user.check, user, t)
   ASSERT (not status)
   TRACE (errmsg)
end

-- Check bad class.
ASSERT_ERROR_CHECK ({})
ASSERT_ERROR_CHECK ({class='unknown'})

-- Check valid USER events.
ASSERT (user:check {class='user'})
ASSERT (user:check {class='user', x='y'})
do
   local t = tests.rand_table (20, 3)
   t.class = 'user'
   tests.dump (t)
   ASSERT (user:check (t))
end
