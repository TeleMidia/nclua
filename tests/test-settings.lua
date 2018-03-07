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
-- local inspect = require ('inspect')
local ASSERT = tests.ASSERT

local settings = require ('nclua.settings')

ASSERT (settings.luaVersion == tests.NCLUA_VERSION)
ASSERT (settings.luaVersionMajor == tests.NCLUA_VERSION_MAJOR)
ASSERT (settings.luaVersionMinor == tests.NCLUA_VERSION_MINOR)
ASSERT (settings.luaVersionMicro == tests.NCLUA_VERSION_MICRO)

ASSERT (settings.inet)
ASSERT (settings.inet6)
-- print (inspect (settings.inet))

local text = ''
local INFO = nil

for i,v in ipairs(settings.inet) do
  for index,value in pairs(v) do
    text = text..'settings.inet['..i..'].'..index..'='..tostring(value)..'\n'
  end
  text = text..'\n'
end
print(text);

local canvas = canvas
local WIDTH, HEIGHT = canvas:attrSize ()

-- Colors.
local BG_COLOR = 'black'        -- background
local FG_COLOR = 'lime'         -- foreground
local FT_COLOR = 'yellow'       -- footer
local function clear ()
   canvas:attrColor (BG_COLOR)
   canvas:clear ()
   canvas:attrColor (FG_COLOR)
end
clear ()
canvas:attrFont ('monospace', 12)
local w,h = canvas:measureText (text)
local family, size, style = canvas:attrFont ()
canvas:attrColor (FT_COLOR)
canvas:attrFont (family, size, 'bold')
canvas:attrColor (FT_COLOR)
canvas:drawText ((WIDTH - w)/2, (HEIGHT - h)/2, text)
canvas:attrFont (family, size, style)
canvas:flush ()