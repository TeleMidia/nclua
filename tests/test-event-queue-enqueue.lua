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

local table = table
local queue = require ('nclua.event.queue')
_ENV = nil

-- Sanity checks.
ASSERT_ERROR (queue.enqueue, nil, 0)

-- Insert 0 objects and check the result.
local q = queue:new ()
ASSERT (q:enqueue () == 0)
ASSERT (q:is_empty ())

-- Insert 1K objects and check the result.
local q = queue:new ()
local n = 2^10
local t = {tests.rand_number (nil, nil, n)}
ASSERT (q:enqueue (table.unpack (t)) == n)
ASSERT (tests.objeq (q, t), #q == n)
