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

canvas._attrFlip = canvas.attrFlip
canvas.attrFlip = function (c, fx, fy)
   if fx == nil and fy == nil then
      return canvas._attrFlip (c)
   else
      canvas._attrFlip (c, fx, fy)
      local t = {canvas._attrFlip (c)}
      TRACE_SEP ()
      TRACE ('in:', fx, fy)
      TRACE ('out:', table.unpack (t))
      return t[1] == fx and t[2] == fy
   end
end

-- Sanity checks.
ASSERT_ERROR (canvas.attrFlip)

-- Check the default flip.
local c = tests.canvas.new ()
local fx, fy = c:_attrFlip ()
ASSERT (fx == false, fy == false)

-- Make some pseudo-return calls and check the result.
local c = tests.canvas.new ()
tests.iter (
   function ()
      ASSERT (c:attrFlip (tests.rand_boolean (2)))
   end
)
