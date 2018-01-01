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

canvas._attrOpacity = canvas.attrOpacity
canvas.attrOpacity = function (c, a)
   if a == nil then
      return canvas._attrOpacity (c)
   else
      canvas._attrOpacity (c, a)
      local ra = tests.range (0, a, 255)
      local _a = canvas._attrOpacity (c)
      TRACE_SEP ()
      TRACE ('in:', ra..'/'..a)
      TRACE ('out:', _a)
      return tests.numeq (_a, ra)
   end
end

-- Sanity checks.
local c = tests.canvas.new ()
ASSERT_ERROR (canvas._attrOpacity)
ASSERT_ERROR (canvas._attrOpacity, c, nil)
ASSERT_ERROR (canvas._attrOpacity, c, {})

-- Check the default opacity.
local c = tests.canvas.new ()
ASSERT (tests.numeq (c:_attrOpacity (), 255))

-- Make some pseudo-random calls and check the result.
local c = tests.canvas.new ()
tests.iter (
   function ()
      ASSERT (c:attrOpacity (tests.rand_integer (-255, 255)))
   end
)
