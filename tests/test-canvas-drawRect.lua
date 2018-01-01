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
ASSERT_ERROR (canvas.drawRect)
ASSERT_ERROR (canvas.drawRect, c)
ASSERT_ERROR (canvas.drawRect, c, 'unknown')
ASSERT_ERROR (canvas.drawRect, c, 'fill', 0)
ASSERT_ERROR (canvas.drawRect, c, 'fill', 0, 0)
ASSERT_ERROR (canvas.drawRect, c, 'fill', 0, 0, 0)
ASSERT_ERROR (canvas.drawRect, c, 'fill', 0, 0, 0, {})

-- Check if drawRect() honors anti-alias.
local c, w, h = tests.canvas.new ()
c:attrAntiAlias ('none')
c:drawRect ('frame', 10, 10, 20, 20)
ASSERT (tests.canvas.check_ref (c, 1))

tests.canvas.clear (c)
c:attrAntiAlias ('default')
c:drawRect ('frame', 10, 10, 20, 20)
ASSERT (tests.canvas.check_ref (c, 2))

-- Check if drawRect() honors clip.
local c, w, h = tests.canvas.new ()
c:attrClip (0, 0, w/2, h)
c:drawRect ('fill', 0, 0, w, h)
ASSERT (tests.canvas.check_ref (c, 3))

-- Check if drawRect() honors color.
local c, w, h = tests.canvas.new ()
c:attrColor (255, 0, 0)
c:drawRect ('fill', 0, 0, w, h)
ASSERT (tests.canvas.check_ref (c, 4))

-- Check if drawRect() honors line-width.
local c, w, h = tests.canvas.new ()
c:attrLineWidth (5)
c:drawRect ('frame', 10, 10, 20, 20)
ASSERT (tests.canvas.check_ref (c, 5))

-- Make some pseudo-random calls and check the result.
local c, cw, ch = tests.canvas.new ()
tests.iter (
   function ()
      local r, g, b, a = tests.xrand_color (4)
      local mode = tests.xrand_option {'fill', 'frame'}
      local x, w = tests.xrand_integer (-cw, 2 * cw, 2)
      local y, h = tests.xrand_integer (-ch, 2 * ch, 2)
      TRACE_SEP ()
      TRACE ('color:', r, g, b, a)
      TRACE ('draw:', mode, x, y, w, h)
      c:attrColor (r, g, b, a)
      c:drawRect (mode, x, y, w, h)
   end
)
ASSERT (tests.canvas.check_ref (c, 6))
