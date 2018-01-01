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
local GET_SAMPLE = tests.canvas.get_sample
local TRACE = tests.trace
local TRACE_SEP = tests.trace_sep

local epsilon = nil             -- default (0%)

local canvas = require ('nclua.canvas')
_ENV = nil

local function apple ()
   local c, w, h = canvas.new (GET_SAMPLE ('apple-red'))
   c:attrColor ('yellow')
   c:drawRect ('frame', 0, 0, w, h)
   return c, w, h
end

local function keys ()
   local c, w, h = canvas.new (GET_SAMPLE ('gnu-keys'))
   c:attrColor ('red')
   c:drawRect ('frame', 0, 0, w, h)
   return c, w, h
end

local function background ()
   local c, w, h = canvas.new (48 * 2, 48 * 2)
   c:attrColor ('blue')
   c:clear ()
   return c, w, h
end

-- Sanity checks.
local a, c = apple (), background ()
ASSERT_ERROR (canvas.compose)
ASSERT_ERROR (canvas.compose, c)
ASSERT_ERROR (canvas.compose, c, 0, nil)
ASSERT_ERROR (canvas.compose, c, 0, 0, nil)
ASSERT_ERROR (canvas.compose, c, 0, 0, a, {})
ASSERT_ERROR (canvas.compose, c, 0, 0, a, 0, {})
ASSERT_ERROR (canvas.compose, c, 0, 0, a, 0, 0, {})
ASSERT_ERROR (canvas.compose, c, 0, 0, a, 0, 0, 0, {})

-- Check if compose() honors crop.
local a, aw, ah = apple ()
local c, cw, ch = background ()
a:attrCrop (aw / 2, ah / 2, aw, ah)
c:compose (10, 10, a)
ASSERT (tests.canvas.check_ref (c, 1, epsilon))

-- Check if compose() ignores crop when it receives custom crop parameters.
local a, aw, ah = apple ()
local c, cw, ch = background ()
a:attrCrop (aw / 2, ah / 2, aw, ah)
c:compose (10, 10, a, 0, 0, aw / 2, ah / 2)
ASSERT (tests.canvas.check_ref (c, 2, epsilon))

-- Check if compose() honors flip.
local a, aw, ah = apple ()
local c, cw, ch = background ()
c:compose (0, 0, a)
a:attrFlip (true, false)
c:compose (15, 15, a)
a:attrFlip (false, true)
c:compose (30, 30, a)
a:attrFlip (true, true)
c:compose (45, 45, a)
ASSERT (tests.canvas.check_ref (c, 3, epsilon))

-- Check if compose() honors opacity.
local a, aw, ah = apple ()
local c, cw, ch = background ()
c:compose (0, 0, a)
a:attrOpacity (127)
c:compose (cw - aw, ch - ah, a)
ASSERT (tests.canvas.check_ref (c, 4, epsilon))

-- Check if compose() honors rotation.
-- FIXME: This check is not working on Windows.
if not tests.is_windows () then
   local a, aw, ah = apple ()
   local c, cw, ch = background ()
   a:attrRotation (-45)
   c:compose (0, 0, a)
   a:attrRotation (45)
   local _, _, aw, ah = a:attrSize ()
   c:compose (cw - aw, ch - ah, a)
   for i=1,360/10 do
      a:attrRotation (i*10)
      local _, _, aw, ah = a:attrSize ()
      c:compose ((cw - aw)/2, (ch - ah)/2, a)
   end
   ASSERT (tests.canvas.check_ref (c, 5, epsilon))
end

-- Check if compose() honors scale and filter.
local a, aw, ah = apple ()
local c, cw, ch = background ()
a:attrScale (2, 1)
c:compose (0, 0, a)
a:attrFilter ('fast')
a:attrScale (1, 2)
c:compose (0, 0, a)
a:attrFilter ('good')
a:attrScale (.5, .5)
a:attrRotation (25)
local _, _, aw, ah = a:attrSize ()
c:attrColor ('green')
c:drawRect ('fill', cw-aw, ch-ah, cw, ch)
c:flush ()
c:compose (cw-aw, ch-ah, a)
ASSERT (tests.canvas.check_ref (c, 6, epsilon))

-- Make some pseudo-random calls and check the result.
-- FIXME: This check is not working on Windows.
if not tests.is_windows () then
   local c, cw, ch = background ()
   tests.iter (
      function ()
         local a, aw, ah = tests.xrand_option {apple, keys} ()
         local _x = tests.xrand_integer (-10, cw + 10)
         local _y = tests.xrand_integer (-10, ch + 10)
         local x, w = tests.xrand_integer (0, aw, 2)
         local y, h = tests.xrand_integer (0, ah, 2)
         local fx, fy = tests.xrand_boolean (2)
         local op = tests.xrand_integer (127, 255)
         local r = tests.xrand_number (-720, 720)
         local sx, sy = tests.xrand_number (1, 3, 2)
         TRACE_SEP ()
         TRACE ('flip:', fx, fy)
         TRACE ('opac:', op)
         TRACE ('rotat:', r)
         TRACE ('scal:', sx, sy)
         TRACE ('comp:', x, y, a)
         a:attrFlip (fx, fy)
         a:attrOpacity (op)
         a:attrRotation (r)
         a:attrScale (sx, sy)
         c:compose (_x, _y, a)
      end
   )
ASSERT (tests.canvas.check_ref (c, 7, epsilon))
end
