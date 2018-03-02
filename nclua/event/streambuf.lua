--[[ nclua.event.user -- The STREAMBUF event class.
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

local streambuf

local print = print
local assert = assert
local engine = require ('nclua.event.engine')
local streambuf_pipe = require ('nclua.event.streambuf_pipe')
local io = io
local os = os
local string = string
_ENV = nil

do
   streambuf = engine:new ()
   streambuf.class = 'streambuf'
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
function streambuf:check (evt)
   assert (evt.class == streambuf.class)
   return evt
end

---
-- Builds a STREAM event filter according to the given parameters.
-- Returns a new filter if successful, otherwise throws an error.
--
function streambuf:filter (class)
   assert (class == streambuf.class)
   return {class=class}
end

local buffs = {}

---
-- Cycles the STREAM engine once.
--
function streambuf:cycle ()
   while not streambuf.INQ:is_empty () do
      local evt = streambuf.INQ:dequeue ()
      local buff_id = string.sub (evt.uri, 13)

      if (evt.action == 'write') then
        if (buffs[evt.uri] == nil) then
          os.execute ("mkfifo /tmp/" .. buff_id .. ".mp4")
          buffs[evt.uri] = 1;
        end

        if (evt.data) then
          local ret, size = streambuf_pipe.write (buff_id, #evt.data,
                                                  evt.data)
          if (ret == 0) then
            evt.error = 'Could not write in stream buffer. Buffer is full!'
            evt.state = 'FULL'
          else
            evt.state = 'READY'
          end

          evt.size = size
          streambuf.OUTQ:enqueue (evt)
        else
          if (buffs[evt.uri]) then
            os.execute ("rm /tmp/" .. buf_id)
            buffs[evt.uri] = nil
          end
        end
      elseif evt.action == 'read' then
        -- print ("Received a read streambuf evt.", evt.buff)
      end
   end
end

return streambuf
