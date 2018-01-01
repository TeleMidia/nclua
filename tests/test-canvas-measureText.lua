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

-- Sanity checks.
local c = tests.canvas.new ()
ASSERT_ERROR (canvas.measureText)
ASSERT_ERROR (canvas.measureText, c)
ASSERT_ERROR (canvas.measureText, c, {})

-- Check if the width of an empty text is zero pixels.
local c = tests.canvas.new ()
ASSERT (c:measureText ('') == 0)

-- Check if a 0pt font gives a width of zero pixels.
local c = tests.canvas.new ()
c:attrFont ('', 0)
ASSERT (c:measureText ('abc') == 0)

-- Check if increasing point sizes gives larger dimensions.
local last_w, last_h = 0, 0
for i=1,100 do
   c:attrFont ('', i)
   local w, h = c:measureText ('abc')
   TRACE (w..' > '..last_w, 'or', h..' > '..last_h)
   ASSERT (w > last_w or h > last_h)
   last_w, last_h = w, h
end
