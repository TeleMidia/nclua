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
ASSERT_ERROR (canvas.drawText)
ASSERT_ERROR (canvas.drawText, c)
ASSERT_ERROR (canvas.drawText, c, 'unknown')
ASSERT_ERROR (canvas.drawText, c, 'fill', 0)
ASSERT_ERROR (canvas.drawText, c, 'fill', 0, 0)
ASSERT_ERROR (canvas.drawText, c, 0, 0)
ASSERT_ERROR (canvas.drawText, c, 0, 0, {})
ASSERT_ERROR (canvas.drawText, c, 'frame', 0, 0, {})

-- Check if drawText() honors anti-alias.
local c, w, h = tests.canvas.new ()
c:attrAntiAlias ('none')
c:attrFont ('Bitstream Vera Sans', 30)
c:drawText (0, 0, '000')
ASSERT (tests.canvas.check_ref (c, 1))

tests.canvas.clear (c)
c:attrAntiAlias ('default')
c:drawText (0, 0, '000')
ASSERT (tests.canvas.check_ref (c, 2))

tests.canvas.clear (c)
c:attrAntiAlias ('gray')
c:drawText (0, 0, '000')
ASSERT (tests.canvas.check_ref (c, 3))

-- Check if drawText() honors clip.
local c, w, h = tests.canvas.new ()
c:attrFont ('Bitstream Vera Sans', 30)
c:attrClip (0, 0, w/2, h)
c:drawText (0, 0, '0123456789')
ASSERT (tests.canvas.check_ref (c, 4, epsilon))

-- Check if drawText() honors color.
local c, w, h = tests.canvas.new ()
c:attrFont ('Bitstream Vera Sans', 30)
c:attrColor ('green')
c:drawText (0, 0, '0123456789')
ASSERT (tests.canvas.check_ref (c, 5, epsilon))

-- Check if drawText() honors line-width.
local c, w, h = tests.canvas.new ()
c:attrFont ('Bitstream Vera Sans', 30)
c:attrAntiAlias ('none')
c:attrLineWidth (3)
c:drawText ('frame', 0, 0, '0123456789')
ASSERT (tests.canvas.check_ref (c, 6, epsilon))

-- Make some pseudo-random calls and check the result.
local t = tests.canvas.text_style_list
local c, cw, ch = tests.canvas.new ()
c:attrAntiAlias ('none')
tests.iter (
   function ()
      local r, g, b, a = tests.xrand_color (4)
      local mode = tests.xrand_option {'fill', 'frame'}
      local x = tests.xrand_integer (-cw, 2 * cw)
      local y = tests.xrand_integer (-ch, 2 * ch)
      local text = tests.xrand_integer (0, 1000)
      local size = tests.xrand_number (-10, 100)
      local style = tests.xrand_option (tests.canvas.text_style_list)
      TRACE_SEP ()
      TRACE ('color:', r, g, b, a)
      TRACE ('size:', size)
      TRACE ('style:', style)
      TRACE ('draw:', mode, x, y, text)
      c:attrColor (r, g, b, a)
      c:attrFont ('Bitstream Vera Sans', size, style)
      c:drawText (mode, x, y, text)
   end
)
ASSERT (tests.canvas.check_ref (c, 7))
