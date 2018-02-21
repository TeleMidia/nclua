--[[ nclua.event.udp -- The TCP event class.
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

local udp

local assert = assert
local print = print
local type = type

local check = require ('nclua.event.check')
local engine = require ('nclua.event.engine')
_ENV = nil

do
   print ("CREATE LUA UDP CLASS EVENT")
   udp = engine:new ()
   udp.class = 'udp'
end

---
-- Checks if event EVT is a valid UDP event.
-- Returns EVT if successful, otherwise throws an error.
--
function udp:check (evt)
    print("UDP CHECK")
    assert (evt.class == udp.class)
    print("UDP CHECK END")
    return evt
end

---
-- Builds a UDP event filter according to the given parameters.
-- Returns a new filter if successful, otherwise throws an error.
--
function udp:filter (class)
    print("UDP FILTER")
    assert (class == udp.class)
    print("UDP FILTER END")
    return {class=class}
end

---
-- Cycles the UDP engine once.
--
function udp:cycle ()
   while not udp.INQ:is_empty () do
      local evt = udp.INQ:dequeue ()
      assert (evt.class == udp.class)
      print ('cycling...', evt)
      udp.OUTQ:enqueue (evt)    -- echo back
   end
end

return udp
