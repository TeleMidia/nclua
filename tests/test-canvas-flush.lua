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
local GET_SAMPLE = tests.canvas.get_sample
local PROJ = tests.proj

local canvas = require ('nclua.canvas')
_ENV = nil

-- Sanity checks.
ASSERT_ERROR (canvas.flush)

-- Check if flush() is honored when double buffering is enabled.
local c, w, h = canvas.new (50, 50, true), 50, 50
for i=1,w do
   c:attrColor (i * 255/w, 0, 0)
   c:drawLine (i, 0, i, h)
end
c:compose (0, 0, PROJ (1, canvas.new (GET_SAMPLE ('gnu-keys'))))
ASSERT (tests.canvas.check_ref (c, 1))

c:flush ()
ASSERT (tests.canvas.check_ref (c, 2))

for i=1,h do
   c:attrColor (0, i * 255/h, 0, 100)
   c:drawLine (0, i, w, i)
end
ASSERT (tests.canvas.check_ref (c, 2))

c:flush {}                      -- ignore argument
ASSERT (tests.canvas.check_ref (c, 3))

-- Check if flush() is ignored when double buffering is disabled.
local c = canvas.new (w, h)
for i=1,w do
   c:attrColor (0, 0, i * 255/w)
   c:drawLine (i, 0, i, h)
end
ASSERT (tests.canvas.check_ref (c, 4))
c:flush ()
