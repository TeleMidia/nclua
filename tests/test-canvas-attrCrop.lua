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

canvas._attrCrop = canvas.attrCrop
canvas.attrCrop = function (c, x, y, w, h)
   if x == nil and y == nil and w == nil and h == nil then
      return canvas._attrCrop (c)
   else
      canvas._attrCrop (c, x, y, w, h)
      local t = {canvas._attrCrop (c)}
      local cw, ch = c:attrSize ()

      TRACE_SEP ()
      TRACE ('in:', x, y, w, h)

      -- The function c:attrCrop () returns the intersection between the
      -- original crop parameters and the canvas region.

      x, y, w, h = tests.canvas.intersect (0, 0, cw, ch, x, y, w, h)
      TRACE ('cap:', x, y, w, h)
      TRACE ('out:', table.unpack (t))
      return t[1] == x and t[2] == y and t[3] == w and t[4] == h
   end
end

-- Sanity checks.
local c = tests.canvas.new ()
ASSERT_ERROR (canvas._attrCrop)
ASSERT_ERROR (canvas._attrCrop, c, nil)
ASSERT_ERROR (canvas._attrCrop, c, {})
ASSERT_ERROR (canvas._attrCrop, c, 0)
ASSERT_ERROR (canvas._attrCrop, c, 0, 0)
ASSERT_ERROR (canvas._attrCrop, c, 0, 0, 0)

-- Check the default crop.
local c, cw, ch = tests.canvas.new ()
local t = {c:_attrCrop ()}
ASSERT (t[1] == 0, t[2] == 0, t[3] == cw, t[4] == ch)

-- Make some pseudo-random calls and check the result.
local c, cw, ch = tests.canvas.new ()
tests.iter (
   function ()
      local w = tests.rand_integer (0, 2 * cw)
      local h = tests.rand_integer (0, 2 * ch)
      local x = tests.rand_integer (-cw, 2 * cw)
      local y = tests.rand_integer (-ch, 2 * cw)
      ASSERT (c:attrCrop (x, y, w, h))
   end
)
