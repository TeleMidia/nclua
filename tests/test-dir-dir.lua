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

local type = type
local dir = require ('nclua.dir')
_ENV = nil

-- Sanity checks.
ASSERT_ERROR (dir.dir)
ASSERT_ERROR (dir.dir, nil)
ASSERT_ERROR (dir.dir, {})
ASSERT_ERROR (dir.dir, function()end)

-- Check iterator.
local it = dir.dir ('.')
ASSERT (type (it) == 'function')
local found_me = false
local found_sample = false
for f in it do
   ASSERT (dir.test (f))
   if f == 'test-dir-dir.lua' then
      ASSERT (dir.test (f, 'regular'))
      found_me = true
   elseif f == 'sample' then
      ASSERT (dir.test (f, 'directory'))
      found_sample = true
   end
end
ASSERT (found_me, found_sample)
