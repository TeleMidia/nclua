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

local os = os
local canvas = require ('nclua.canvas')
_ENV = nil

-- Sanity checks.
ASSERT_ERROR (canvas.attrSize, nil)

-- Check the size of an empty canvas.
local c, w, h = canvas.new (0, 0)
local _w, _h = c:attrSize ()
ASSERT (w == 0, h == 0, _w == 0, _h == 0)

-- Check size of canvas created with explicit width and height parameters.
local c, w, h = c:new (50, 50)
local _w, _h = c:attrSize ()
ASSERT (w == 50, h == 50, _w == 50, _h == 50)

-- Check the size of a canvas created from file-path.
local tmpfile = tests.tmpname ()
ASSERT (c:_dump_to_file (tmpfile))

local c, w, h = canvas.new (tmpfile)
local _w, _h = c:attrSize ()
ASSERT (w == 50, h == 50, _w == 50, _h == 50)
os.remove (tmpfile)

-- Make some pseudo-random calls and check the result.
tests.iter (
   function ()
      local cw, ch = tests.rand_integer (0, 255, 2)
      local c = canvas.new (cw, ch)
      local t = {c:attrSize ()}
      TRACE_SEP ()
      TRACE ('in:', cw, ch)
      TRACE ('out:', t[1], t[2])
      ASSERT (t[1] == cw, t[2] == ch)
   end
)
