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

local event = event
local canvas = canvas
local print = print
local io = io
_ENV = nil

canvas:attrFont ('tiresias', 20, 'bold')

local buffer_id = 'b0'
local inp = io.open ('/tmp/fs0.ts', "rb")
local chunk = nil
local chunk_size = 2^16
local waiting = false

local function handler (e)
  print (e.class, event.uptime (), waiting)
  if (e.class ~= 'user' and e.class ~= 'streambuf') then
    return
  end
  if (e.class == 'user' and e.type == 'first') then
    chunk = inp:read (chunk_size)
  elseif (e.class == 'streambuf') then
    if (e.available ~= nil) then
      canvas:attrColor (0, 0, 0, 0)
      canvas:clear ()
      local text =
        ('StreamBuffer ' .. buffer_id .. ' available size: %d bytes.')
              :format (e.available)
      canvas:attrColor ('red')
      canvas:drawText (0, 0, text)
      canvas:flush ()
    end
    if (e.error ~= nil) then
      print ('Error: ', e.error)
      if (waiting) then
        return
      else
        waiting = true
        event.timer (500,
          function ()
            waiting = false
            event.post({ class='user' })
          end)
        return
      end
    else
      chunk = inp:read (chunk_size)
    end
  end

  if (chunk) then
    event.post ({ class='streambuf', 
                  action='write', 
                  buff=buffer_id, 
                  data=chunk })
  end
end

event.register (handler)
event.post ({class="user", type='first'})

