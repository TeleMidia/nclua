--[[ nclua.event.user -- The USER event class.
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

local user

local assert = assert
local engine = require ('nclua.event.engine')
_ENV = nil

do
   user = engine:new ()
   user.class = 'user'
end

---
-- Checks if event EVT is a valid USER event.
-- Returns EVT if successful, otherwise throws an error.
--
function user:check (evt)
   assert (evt.class == user.class)
   return evt
end

---
-- Builds a USER event filter according to the given parameters.
-- Returns a new filter if successful, otherwise throws an error.
--
function user:filter (class)
   assert (class == user.class)
   return {class=class}
end

---
-- Cycles the USER engine once.
--
function user:cycle ()
   if not user.INQ:is_empty () then
      user.OUTQ:enqueue (user.INQ:dequeue (#user.INQ))
   end
end

return user
