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
local TRACE = tests.trace
local TRACE_SEP = tests.trace_sep

local canvas = require ('nclua.canvas')
_ENV = nil

-- Sanity checks.
local c = tests.canvas.new ()
ASSERT_ERROR (canvas.clear)
ASSERT_ERROR (canvas.clear, c, {})
ASSERT_ERROR (canvas.clear, c, 0, {})
ASSERT_ERROR (canvas.clear, c, 0, 0, {})
ASSERT_ERROR (canvas.clear, c, 0, 0, 0, {})

-- Check if clear() ignores clip.
local c, w, h = tests.canvas.new ()
c:attrClip (0, 0, w/2, h/2)
c:attrColor (255, 0, 0)
c:clear ()
ASSERT (tests.canvas.check_ref (c, 1))

-- Check optional arguments.
local c, w, h = tests.canvas.new ()
c:attrColor (255, 0, 0)
c:clear ()
ASSERT (tests.canvas.check_ref (c, 1))

c:attrColor (0, 255, 0)
c:clear (w/2)
ASSERT (tests.canvas.check_ref (c, 2))

c:attrColor (0, 0, 255)
c:clear (w/2, h/2)
ASSERT (tests.canvas.check_ref (c, 3))

c:attrColor (255, 255, 0)
c:clear (0, 0, w/2)
ASSERT (tests.canvas.check_ref (c, 4))

c:attrColor (0, 255, 255)
c:clear (0, 0, w/2, h/2)
ASSERT (tests.canvas.check_ref (c, 5))

-- Make some pseudo-random calls and check the result.
local c, cw, ch = tests.canvas.new ()
tests.iter (
   function ()
      local r, g, b, a = tests.xrand_color (4)
      local x, w = tests.xrand_integer (-cw, 2 * cw, 2)
      local y, h = tests.xrand_integer (-ch, 2 * ch, 2)
      TRACE_SEP ()
      TRACE ('color:', r, g, b, a)
      TRACE ('rect:', x, y, w, h)
      c:attrColor (r, g, b, a)
      c:clear (x, y, w, h)
   end
)
ASSERT (tests.canvas.check_ref (c, 6))
