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

local ipairs = ipairs
local table = table

local canvas = require ('nclua.canvas')
_ENV=nil

canvas._attrAntiAlias = canvas.attrAntiAlias
canvas.attrAntiAlias = function (c, mode)
   if mode == nil then
      return canvas._attrAntiAlias (c)
   else
      canvas._attrAntiAlias (c, mode)
      return canvas._attrAntiAlias (c) == mode
   end
end

-- Sanity checks.
local c = tests.canvas.new ()
ASSERT_ERROR (canvas._attrAntiAlias)
ASSERT_ERROR (canvas._attrAntiAlias, c, nil)
ASSERT_ERROR (canvas._attrAntiAlias, c, {})
ASSERT_ERROR (canvas._attrAntiAlias, c, 'invalid')

-- Check the default anti-alias.
local c = tests.canvas.new ()
ASSERT (c:attrAntiAlias () == 'default')

-- Check all supported modes.
local list = {'default', 'none', 'gray', 'subpixel'}
if tests.cairo_check_version (1, 12) then
   table.insert (list, 'fast')
   table.insert (list, 'good')
   table.insert (list, 'best')
end

for _,mode in ipairs (list) do
   ASSERT (c:attrAntiAlias (mode))
end
