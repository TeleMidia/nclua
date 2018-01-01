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

local event = require ('nclua.event')
local engine = event._engine
_ENV = nil

local epsilon
if tests.is_linux () then
   epsilon = 1                  -- 1ms
else
   epsilon = 100                -- 100ms
end

if tests.mk._VALGRIND then
   epsilon = epsilon * 10
end

-- Sanity checks.
ASSERT (event.uptime () == 0)

-- Sleep for 1s and check the resulting uptime.
engine:cycle ()
tests.sleep (1)
local uptime = event.uptime ()
TRACE ('uptime:', uptime)
ASSERT (tests.numeq (uptime, 1000, epsilon)) -- 1ms precision
