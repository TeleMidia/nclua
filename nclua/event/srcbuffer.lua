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

local srcbuffer

local print = print
local assert = assert
local engine = require ('nclua.event.engine')
local srcbuffer_pipe = require ('nclua.event.srcbuffer_pipe')
local io = io
local os = os
_ENV = nil

do
   srcbuffer = engine:new ()
   srcbuffer.class = 'srcbuffer'
end

-- List of supported types.
local action_list = {
    'read',
    'write'
}

---
-- Checks if event EVT is a valid STREAM event.
-- Returns EVT if successful, otherwise throws an error.
--
function srcbuffer:check (evt)
   assert (evt.class == srcbuffer.class)
   return evt
end

---
-- Builds a STREAM event filter according to the given parameters.
-- Returns a new filter if successful, otherwise throws an error.
--
function srcbuffer:filter (class)
   assert (class == srcbuffer.class)
   return {class=class}
end

local buffs = {}

---
-- Cycles the STREAM engine once.
--
function srcbuffer:cycle ()
   while not srcbuffer.INQ:is_empty () do
      local evt = srcbuffer.INQ:dequeue ()
      print (evt)

      if (evt.action == 'write') then
        print ("Received a write srcbuffer evt on '" .. evt.buff .. "'.")

        if (buffs[evt.buff] == nil) then
          os.execute ("mkfifo /tmp/" .. evt.buff)
          buffs[evt.buff] = 1;
        end

        if (evt.data) then
          local ret = srcbuffer_pipe.write (evt.buff, #evt.data, evt.data)
          if (ret == 0) then
            evt.error = 'Could not write.  Buffer is full!'
          end
          srcbuffer.OUTQ:enqueue (evt)
        else
          print ("empty")

          if (buffs[evt.buff]) then
            os.execute ("rm /tmp/" .. evt.buff)
            buffs[evt.buff] = nil
          end
        end
      elseif evt.action == 'read' then
        print ("Received a read srcbuffer evt.", evt.buff)
      end
   end
end

return srcbuffer
