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

local stopwatch = require ('nclua.event.stopwatch')
_ENV = nil

-- Sanity checks.
local clock = stopwatch.new ()
ASSERT_ERROR (stopwatch.get_time)
ASSERT_ERROR (stopwatch.get_time, clock, 'unknown')

-- Sleep for 1s and check if get_time() gives the expected results.
clock:start ()
tests.sleep (1)
ASSERT (tests.numeq (clock:get_time ('us'), 10^6, .5 * 10^6))
ASSERT (tests.numeq (clock:get_time ('ms'), 10^3, .5 * 10^3))
ASSERT (tests.numeq (clock:get_time ('s'), 1, .5))

-- Check if start() and stop() change state.
ASSERT (clock:get_state () == 'started')
clock:stop ()
ASSERT (clock:get_state () == 'stopped')
