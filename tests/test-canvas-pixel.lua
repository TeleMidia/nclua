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

local table = table
local canvas = require ('nclua.canvas')
_ENV = nil

canvas._pixel = canvas.pixel
canvas.pixel = function (c, x, y, r, g, b, a)
   if r == nil and g == nil and b == nil and a == nil then
      return canvas._pixel (c, x, y)
   else
      a = a or 255
      canvas._pixel (c, x, y, r, g, b, a)
      local t = {canvas._pixel (c, x, y)}
      local cw, ch = c:attrSize ()
      if x < 0 or y < 0 or x >= cw or y >= ch then
         r, g, b, a = 0, 0, 0, 0
      end
      TRACE_SEP ()
      TRACE ('in:', x, y, r, g, b, a)
      TRACE ('out:', x, y, table.unpack (t))
      return tests.numeq (t[1], r)
         and tests.numeq (t[2], g)
         and tests.numeq (t[3], b)
         and tests.numeq (t[4], a)
   end
end

-- Check invalid calls.
local c = tests.canvas.new ()
ASSERT_ERROR (canvas.pixel)
ASSERT_ERROR (canvas.pixel, c, nil)
ASSERT_ERROR (canvas.pixel, c, 0, nil)
ASSERT_ERROR (canvas.pixel, c, 0, 0, 0, nil)
ASSERT_ERROR (canvas.pixel, c, 0, 0, 0, 0, nil)
ASSERT_ERROR (canvas.pixel, c, 0, 0, 0, 0, {})

-- Check alpha.
local c, cw, ch = tests.canvas.new ()
for a=0,255 do
   c:_pixel (0, 0, 0, 0, 0, a)
   local t = {c:pixel (0, 0)}
   ASSERT (t[1] == 0, t[2] == 0, t[3] == 0, t[4] == a)
end

-- Check pre-multiplied alpha.
local c = tests.canvas.new (1, 1)
c:attrColor (24, 10, 10, 127)
c:clear ()
local t = {c:pixel (0, 0)}
if tests.cairo_check_version (1, 14, 0) then
   ASSERT (t[1] == 24, t[2] == 10, t[3] == 10, t[4] == 127)
else
   ASSERT (t[1] == 22, t[2] == 8, t[3] == 8, t[4] == 127)
end

-- Make some pseudo-random calls and check the result.
local c, cw, ch = tests.canvas.new ()
tests.iter (
   function ()
      local r, g, b = tests.xrand_color (3)
      local x = tests.xrand_integer (-cw/8, cw + cw/8)
      local y = tests.xrand_integer (-ch/8, ch + ch/8)

      -- Don't use alpha; otherwise we can't check the results, since we
      -- lose precision due to pre-multiplication.

      ASSERT (c:pixel (x, y, r, g, b)) -- optional alpha=255
   end
)
ASSERT (tests.canvas.check_ref (c, 1))
