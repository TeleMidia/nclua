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

canvas._attrScale = canvas.attrScale
canvas.attrScale = function (c, sx, sy)
   if sx == nil and sy == nil then
      return canvas._attrScale (c)
   else
      canvas._attrScale (c, sx, sy)
      local t = {canvas._attrScale (c)}
      local rx = tests.range (0, sx)
      local ry = tests.range (0, sy)
      TRACE_SEP ()
      TRACE ('in:', rx..'/'..sx, ry..'/'..sy)
      TRACE ('out:', table.unpack (t))
      return tests.numeq (t[1], rx) and tests.numeq (t[2], ry)
   end
end

-- Sanity checks.
local c = tests.canvas.new ()
ASSERT_ERROR (canvas._attrScale)
ASSERT_ERROR (canvas._attrScale, c, nil)
ASSERT_ERROR (canvas._attrScale, c, {})

-- Check the default scale.
local c = tests.canvas.new ()
local sx, sy = c:_attrScale ()
ASSERT (tests.numeq (sx, 1), tests.numeq (sy, 1))

-- Make some pseudo-random calls and check the result.
local c = tests.canvas.new ()
tests.iter (
   function ()
      ASSERT (c:attrScale (tests.rand_number (-10000, 10000, 2)))
   end
)
