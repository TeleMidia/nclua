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

local tests = require ('tests')
local canvas = require ('nclua.canvas')
_ENV = nil

-- Sanity checks.
local c = tests.canvas.new ()
ASSERT_ERROR (canvas.drawLine)
ASSERT_ERROR (canvas.drawLine, c, 0)
ASSERT_ERROR (canvas.drawLine, c, 0, 0)
ASSERT_ERROR (canvas.drawLine, c, 0, 0, 0)
ASSERT_ERROR (canvas.drawLine, c, 0, 0, 0, {})

-- Check if drawLine() honors anti-alias.
local c, w, h = tests.canvas.new ()
c:attrAntiAlias ('none')
c:drawLine (0, 0, w, h)
ASSERT (tests.canvas.check_ref (c, 1))

tests.canvas.clear (c)
c:attrAntiAlias ('default')
c:drawLine (0, 0, w, h)
ASSERT (tests.canvas.check_ref (c, 2))

-- Check if drawLine() honors clip.
local c, w, h = tests.canvas.new ()
c:attrClip (0, 0, w/2, h)
c:drawLine (0, 0, w, h)
c:drawLine (w, 0, 0, h)
ASSERT (tests.canvas.check_ref (c, 3))

-- Check if drawLine() honors color.
local c, w, h = tests.canvas.new ()
c:attrColor (255, 0, 0)
c:drawLine (0, 0, w, h)
ASSERT (tests.canvas.check_ref (c, 4))

-- Check if drawLine() honors line-width.
local c, w, h = tests.canvas.new ()
c:attrAntiAlias ('none')
c:attrLineWidth (5)
c:drawLine (0, 0, w, h)
ASSERT (tests.canvas.check_ref (c, 5))

-- Make some pseudo-random calls and check the result.
local c, cw, ch = tests.canvas.new ()
c:attrAntiAlias ('none')
tests.iter (
   function ()
      local r, g, b, a = tests.xrand_color (4)
      local x, w = tests.xrand_integer (-cw, 2 * cw, 2)
      local y, h = tests.xrand_integer (-ch, 2 * ch, 2)
      TRACE_SEP ()
      TRACE ('color:', r, g, b, a)
      TRACE ('draw:', x, y, w, h)
      c:attrColor (r, g, b, a)
      c:drawLine (x, y, w, h)
   end
)
ASSERT (tests.canvas.check_ref (c, 6, .05))
