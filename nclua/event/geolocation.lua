--[[ nclua.event.geolocation -- The GEOLOCATION event class.
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

local geoloc

local assert = assert
local print = print

local check = require ('nclua.event.check')
local engine = require ('nclua.event.engine')
_ENV = nil

do
   geoloc = engine:new ()
   geoloc.class = 'geolocation'
end

-- {class='geolocation', [timeout=%d]})
-- -> {class='geolocation',
--     latitude=%g,
--     longitude=%g,
--     altitude=%g,
--     accurracy=%g,
--     speed=%g,
--     heading=%g,
--    }
-- -> {class='geolocation', error=%s}

---
-- Checks if event EVT is a valid GEOLOCATION event.
-- Returns EVT if successful, otherwise throws an error.
--
function geoloc:check (evt)
   assert (evt.class == geoloc.class)
   -- request
   check.event.number ('timeout', evt.timeout, 0)
   -- response
   check.event.number ('latitude', evt.latitude, 0)
   check.event.number ('longitude', evt.longitude, 0)
   check.event.number ('altitude', evt.altitude, 0)
   check.event.number ('accuracy', evt.accuracy, 0)
   check.event.number ('speed', evt.speed, 0)
   check.event.number ('heading', evt.heading, 0)
   return evt
end

---
-- Builds an GEOLOCATION event filter according to the given parameters.
-- Returns a new filter if successful, otherwise throws an error.
--
function geoloc:filter (class)
   assert (class == geoloc.class)
   return {class=geoloc.class}
end

---
-- Cycles the GEOLOCATION engine once.
--
function geoloc:cycle ()
   while not geoloc.INQ:is_empty () do
      local evt = geoloc.INQ:dequeue ()
      print (evt)
      geoloc.OUTQ:enqueue (evt)
   end
end

return geoloc
