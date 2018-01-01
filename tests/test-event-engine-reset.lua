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

local engine = require ('nclua.event.engine')
_ENV = nil

-- Sanity checks.
ASSERT_ERROR (engine.reset)

-- Check if reset clears the INQ and OUTQ.
local eng = engine.new ()
local n = 2^10
ASSERT (eng.INQ:enqueue (tests.rand_number (nil, nil, n)) == n)
ASSERT (eng.OUTQ:enqueue (tests.rand_number (nil, nil, n)) == n)
ASSERT (not eng.INQ:is_empty (), not eng.OUTQ:is_empty ())
eng:reset ()
ASSERT (eng.INQ:is_empty ())
ASSERT (eng.OUTQ:is_empty ())
