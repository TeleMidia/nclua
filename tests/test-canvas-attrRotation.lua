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

canvas._attrRotation = canvas.attrRotation
canvas.attrRotation = function (c, ang)
   if ang == nil then
      return canvas._attrRotation (c)
   else
      canvas._attrRotation (c, ang)
      local _ang = canvas._attrRotation (c)
      TRACE_SEP ()
      TRACE ('in:', ang)
      TRACE ('out:', _ang)
      return tests.numeq (_ang, ang)
   end
end

-- Sanity checks.
local c = tests.canvas.new ()
ASSERT_ERROR (canvas._attrRotation)
ASSERT_ERROR (canvas._attrRotation, c, nil)
ASSERT_ERROR (canvas._attrRotation, c, {})

-- Check the default rotation.
local c = tests.canvas.new ()
ASSERT (tests.numeq (c:_attrRotation (), 0))

-- Make some pseudo-random calls and check the result.
local c = tests.canvas.new ()
tests.iter (
   function ()
      ASSERT (c:attrRotation (tests.rand_number (-10000, 10000)))
   end
)
