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

local epsilon = nil             -- default (0%)

-- Sanity checks.
local c = tests.canvas.new ()
ASSERT_ERROR (canvas.drawPolygon, c)
ASSERT_ERROR (canvas.drawPolygon, c, nil, nil)
ASSERT_ERROR (canvas.drawPolygon, c, {})
ASSERT_ERROR (canvas.drawPolygon, c, 'x', nil)
ASSERT_ERROR (canvas.drawPolygon (c, 'open', false), {})

-- Check if drawPolygon() honors anti-alias.
local c, w, h = tests.canvas.new ()
c:attrAntiAlias ('none')
c:drawPolygon ('fill')(0,0)(w/2,h/2)(w,0)()
ASSERT (tests.canvas.check_ref (c, 1, epsilon))

tests.canvas.clear (c)
c:attrAntiAlias ('default')
c:drawPolygon ('fill')(0,0)(w/2,h/2)(w,0)()
ASSERT (tests.canvas.check_ref (c, 2))

-- Check if drawPolygon() honors clip.
local c, w, h = tests.canvas.new ()
c:attrClip (0, 0, w/2, h)
c:drawPolygon ('open')(0,0)(w/2,h/2)(w,0)()
ASSERT (tests.canvas.check_ref (c, 3, epsilon))

-- Check if drawLine() honors color.
local c, w, h = tests.canvas.new ()
c:attrColor (255, 0, 0)
c:drawPolygon ('fill')(0,0)(w/2,h/2)(w,0)()
ASSERT (tests.canvas.check_ref (c, 4, epsilon))

-- Check if drawLine() honors line-width.
local c, w, h = tests.canvas.new ()
c:attrAntiAlias ('none')
c:attrLineWidth (5)
c:drawPolygon ('open')(0,0)(w/2,h/2)(w,0)()
ASSERT (tests.canvas.check_ref (c, 5, epsilon))

-- Make some pseudo-random calls and check the result.
local c, cw, ch = tests.canvas.new ()
c:attrAntiAlias ('none')
tests.iter (
   function ()
      local r, g, b, a = tests.xrand_color (4)
      local n = tests.xrand_integer (0, 100)
      local mode = tests.xrand_option {'fill', 'open', 'close'}
      TRACE_SEP ()
      TRACE ('color:', r, g, b, a)
      TRACE ('mode:', mode)
      c:attrColor (r, g, b, a)
      local f = c:drawPolygon (mode)
      for i=1,n do
         local x, y = tests.xrand_integer (-cw, 2 * ch, 2)
         TRACE ('point:', x, y)
         f = f (x, y)
      end
      f ()
   end
)

ASSERT (tests.canvas.check_ref (c, 6, epsilon))
