--[[ nclua.event.pointer -- The POINTER event class.
     Copyright (C) 2013-2018 PUC-Rio/Laboratorio TeleMidia

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

local pointer = {}

local assert = assert
local check = require ('nclua.event.check')
_ENV = nil

do
   pointer.class = 'pointer'
end

-- List of supported POINTER event types.
local type_list = {'press', 'release', 'move'}

---
-- Checks if event EVT is a valid POINTER event.
-- Returns EVT is successful, otherwise throws an error.
--
function pointer:check (evt)
   assert (evt.class == pointer.class)
   check.event.option ('type', evt.type, type_list)
   check.event.number ('x', evt.x)
   check.event.number ('y', evt.y)
   return evt
end

---
-- Builds a POINTER event filter according to the given parameters.
-- Returns a new filter if successful, otherwise throws an error.
--
function pointer:filter (class, type, x, y)
   assert (class == pointer.class)
   if type ~= nil then
      check.arg.option ('type', type, type_list)
   end
   if x ~= nil then
      check.arg.number ('x', x)
   end
   if y ~= nil then
      check.arg.number ('y', y)
   end
   return {class=pointer.class, type=type, x=x, y=y}
end

return pointer
