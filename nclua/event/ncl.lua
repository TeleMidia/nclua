--[[ nclua.event.ncl -- The NCL event class.
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

local ncl = {}

local assert = assert
local check = require ('nclua.event.check')
_ENV = nil

do
   ncl.class = 'ncl'
end

-- List of supported NCL event types.
local type_list = {'attribution', 'presentation', 'selection'}

-- List of supported NCL event actions.
local action_list = {'abort', 'pause', 'resume', 'start', 'stop'}

---
-- Checks if event EVT is a valid NCL event.
-- Returns EVT is successful, otherwise throws an error.
--
function ncl:check (evt)
   assert (evt.class == ncl.class)
   check.event.option ('type', evt.type, type_list)
   check.event.option ('action', evt.action, action_list)
   if evt.type == 'attribution' then
      check.event.string ('name', evt.name)
      check.event.string ('value', evt.value)
   else
      check.event.string ('label', evt.label)
   end
   return evt
end

---
-- Builds a NCL event filter according to the given parameters.
-- Returns a new filter if successful, otherwise throws an error.
--
function ncl:filter (class, type, label, action)
   assert (class == ncl.class)
   if type ~= nil then
      check.arg.option ('type', type, type_list)
   end
   if action ~= nil then
      check.arg.option ('action', action, action_list)
   end
   local name = nil
   if label ~= nil then
      if type ~= nil and type == 'attribution' then
         name = 'name'
      else
         name = 'label'
      end
      check.arg.string (name, label)
   end
   local filter = {class=ncl.class, type=type, action=action}
   if name ~= nil then
      filter[name] = label
   end
   return filter
end

return ncl
