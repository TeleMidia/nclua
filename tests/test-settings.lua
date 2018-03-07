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
for i,v in ipairs(settings.inet) do
  ASSERT (settings.inet[i].name ~= nil)
  ASSERT (settings.inet[i].displayName ~= nil)
  ASSERT (settings.inet[i].inetAddress ~= nil)
  ASSERT (settings.inet[i].hwAddress ~= nil)
  ASSERT (settings.inet[i].mtu ~= nil)
  ASSERT (settings.inet[i].bcastAddress ~= nil)
  ASSERT (settings.inet[i].active ~= nil)
  ASSERT (settings.inet[i].loopback ~= nil)
  ASSERT (settings.inet[i].pointToPoint ~= nil)
  ASSERT (settings.inet[i].supportsMulticast ~= nil)
  ASSERT (settings.inet[i].XYZ == nil)
  for index,value in pairs(v) do
      print ("settings.inet["..i.."]."..index.."="..tostring(value))
  end
  print("");
end