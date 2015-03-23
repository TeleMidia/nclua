--[[ Copyright (C) 2013-2015 PUC-Rio/Laboratorio TeleMidia

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
along with NCLua.  If not, see <http://www.gnu.org/licenses/>.  ]]--

local tests = require ('tests')
local ASSERT_CHECK_API = tests.ASSERT_CHECK_API

local canvas = require ('nclua.canvas')
_ENV = nil

ASSERT_CHECK_API {
   canvas,
   __gc = 'function',
   __index = 'table',
   __metatable = 'string',
   _dump_to_file = 'function',
   _dump_to_memory = 'function',
   _resize = 'function',
   _surface = 'function',
   attrAntiAlias = 'function',
   attrClip = 'function',
   attrColor = 'function',
   attrCrop = 'function',
   attrFilter = 'function',
   attrFlip = 'function',
   attrFont = 'function',
   attrLineWidth = 'function',
   attrOpacity = 'function',
   attrRotation = 'function',
   attrScale = 'function',
   attrSize = 'function',
   clear = 'function',
   compose = 'function',
   drawEllipse = 'function',
   drawLine = 'function',
   drawPolygon = 'function',
   drawRect = 'function',
   drawRoundRect = 'function',
   drawText = 'function',
   flush = 'function',
   measureText = 'function',
   new = 'function',
   pixel = 'function',
}
