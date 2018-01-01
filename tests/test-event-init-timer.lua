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

local pcall = pcall
local table = table

local event = require ('nclua.event')
local engine = event._engine
_ENV = nil

local function ASSERT_ERROR_TIMER (...)
   local status, errmsg = pcall (event.timer, ...)
   ASSERT (not status)
   TRACE (errmsg)
end

-- Checks if the i-th entry on engine's timer list is a
-- table of the form {end_time=t, func=func, cancel=cancel}.
local function check_timer (i, t, func, cancel)
   return tests.objeq (engine.timer_list[i],
                       {end_time=t, func=func, cancel=cancel})
end

-- Sanity checks.
ASSERT_ERROR_TIMER (nil)
ASSERT_ERROR_TIMER (0)
ASSERT_ERROR_TIMER (nil, function () end)

-- Register three timers, cancel them and check the result.
local f1 = function () end
local f2 = function () end
local f3 = function () end

local c1 = event.timer (10, f1)
local c2 = event.timer (20, f2)
local c3 = event.timer (20, f3)

ASSERT (check_timer (1, 10, f1, c1))
ASSERT (check_timer (2, 20, f2, c2))
ASSERT (check_timer (3, 20, f3, c3))
c2 ()
ASSERT (check_timer (1, 10, f1, c1))
ASSERT (check_timer (2, 20, f3, c3))
c1 ()
ASSERT (check_timer (1, 20, f3, c3))
c3 ()
ASSERT (#engine.timer_list == 0)

-- Check if timers time is honored.
engine:reset ()

local epsilon
if tests.mk._VALGRIND or tests.is_windows () then
   epsilon = 10                 -- 10ms
else
   epsilon = 1                  -- 1ms
end

local function numeq (x, y)
   return tests.numeq (x, y, epsilon)
end

local t0 = event.uptime ()
local function CYCLE (ms)
   TRACE ('cycling for '..ms..'ms')
   while event.uptime () - t0 < ms do
      engine:cycle ()
   end
end

local CALL_LOG = {}
local function _f (name)
   local time = event.uptime ()
   TRACE (name..' called at '..time..'ms')
   table.insert (CALL_LOG, {func=name, time=time})
end

local f1 = function () return _f ('f1') end
local f2 = function () return _f ('f2') end
local f3 = function () return _f ('f3') end

local c1 = event.timer (10, f1) -- 10ms
local c2 = event.timer (20, f1) -- 20ms
local c3 = event.timer (1, f2)  -- 1ms
local c4 = event.timer (30, f3) -- 30ms

tests.dump (engine.timer_list)
ASSERT (tests.objeq (
           engine.timer_list, {
              {end_time=1, func=f2, cancel=c3},
              {end_time=10, func=f1, cancel=c1},
              {end_time=20, func=f1, cancel=c2},
              {end_time=30, func=f3, cancel=c4}}))
do
   CYCLE (15)

   ASSERT (CALL_LOG[1] ~= nil,
           CALL_LOG[1].func == 'f2',
           numeq (CALL_LOG[1].time, 1))

   ASSERT (CALL_LOG[2] ~= nil,
           CALL_LOG[2].func == 'f1',
           numeq (CALL_LOG[2].time, 10))
   c2 ()

   CYCLE (31)
   ASSERT (CALL_LOG[3] ~= nil,
           CALL_LOG[3].func == 'f3',
           numeq (CALL_LOG[3].time, 30))
   c1 = event.timer (0, f1)
   c2 = event.timer (0, f2)
   c1 ()
   c2 ()

   CYCLE (40)
   ASSERT (CALL_LOG, #CALL_LOG == 3)
end

ASSERT (tests.objeq (engine.timer_list, {}))
