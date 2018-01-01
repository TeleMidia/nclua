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

canvas._attrLineWidth = canvas.attrLineWidth
canvas.attrLineWidth = function (c, w)
   if w == nil then
      return canvas._attrLineWidth (c)
   else
      canvas._attrLineWidth (c, w)
      local rw = tests.range (0, w)
      local _w = canvas._attrLineWidth (c)
      TRACE_SEP ()
      TRACE ('in:', rw..'/'..w)
      TRACE ('out:', _w)
      return tests.numeq (_w, rw)
   end
end

-- Sanity checks.
local c = tests.canvas.new ()
ASSERT_ERROR (canvas._attrLineWidth)
ASSERT_ERROR (canvas._attrLineWidth, c, nil)
ASSERT_ERROR (canvas._attrLineWidth, c, {})

-- Check the default line-width.
local c = tests.canvas.new ()
ASSERT (tests.numeq (c:attrLineWidth (), 2.0))

-- Make some pseudo-random calls and check the result.
local c = tests.canvas.new ()
tests.iter (
   function ()
      ASSERT (c:attrLineWidth (tests.rand_number (-10000, 10000)))
   end
)
