--[[ nclua.event.key -- The KEY event class.
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

local key = {}

local assert = assert
local check = require ('nclua.event.check')
_ENV = nil

do
   key.class = 'key'
end

-- List of supported KEY event types.
local type_list = {'press', 'release'}

---
-- Checks if event EVT is a valid KEY event.
-- Returns EVT is successful, otherwise throws an error.
--
function key:check (evt)
   assert (evt.class == key.class)
   check.event.option ('type', evt.type, type_list)
   check.event.string ('key', evt.key)
   return evt
end

---
-- Builds a KEY event filter according to the given parameters.
-- Returns a new filter if successful, otherwise throws an error.
--
function key:filter (class, type, keycode)
   assert (class == key.class)
   if type ~= nil then
      check.arg.option ('type', type, type_list)
   end
   if keycode ~= nil then
      check.arg.string ('key', keycode)
   end
   return {class=key.class, type=type, key=keycode}
end

return key
