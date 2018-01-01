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
local engine = require ('nclua.event.engine')
_ENV = nil

-- Sanity checks.
local eng = engine.new ()
ASSERT_ERROR (engine.send)

-- Send 0 events and check the result.
local eng = engine:new ()
ASSERT (eng:send () == 0, eng.INQ:is_empty ())

-- Send 1K events and check the result.
local eng = engine:new ()
local n = 2^10
local t = {tests.rand_number (nil, nil, n)}
ASSERT (eng:send (table.unpack (t)) == n)
ASSERT (tests.objeq (eng.INQ, t), #eng.INQ == n)
