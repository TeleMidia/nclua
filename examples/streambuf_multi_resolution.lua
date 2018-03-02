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
local pairs = pairs
local io = io
_ENV = nil

canvas:attrFont ('tiresias', 20, 'bold')

local resolutions = {
  'main1_5s.ts',
  'main2_5s.ts',
  'main3_5s.ts',
  'main4_5s.ts',
  'main5_5s.ts',
}

local fd = {};

local root = "../../ginga/tests-ncl/samples/"
for i, fname in pairs (resolutions) do
  print (i, fname)
  fd[i] = io.open (root .. fname, 'rb')
end

local buffer_id = 'streambuf://b0'
local chunk = nil
local chunk_size = 2^16
local cur_index = 1
local waiting = false
local last_change = 0

local function draw_streambuf_info (e)
  canvas:attrColor (0, 0, 0, 0)
  canvas:clear ()
  local text = ( e.uri .. ' status: '.. e.state .. ' size: %d bytes.' )
                :format (e.size)
  canvas:attrColor ('red')
  canvas:attrFont ('tiresias', 20, 'bold')
  canvas:drawText (0, 0, text)
  canvas:flush ()
end

local function handler (e)
  local cur_time = event.uptime ()
  print (e.class, cur_time, waiting)
  if (e.class ~= 'user' and e.class ~= 'streambuf') then
    return
  end
  if (e.class == 'user' and e.type == 'first') then
    chunk = fd[cur_index]:read (chunk_size)
  elseif (e.class == 'streambuf') then
    if (e.action == 'status') then
      draw_streambuf_info (e)
      event.timer (200, function ()
                          event.post ( { class  = 'streambuf',
                                         uri    = buffer_id,
                                         action = 'status' })
                       end)
    elseif (e.error ~= nil) then
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
      chunk = fd[cur_index]:read (chunk_size)
      if (chunk == nil and cur_index ~= #resolutions) then
        cur_index = cur_index + 1
        chunk = fd[cur_index]:read (chunk_size)
      end
    end
  end

  if (chunk) then
    event.post ({ class='streambuf',
                  action='write',
                  uri=buffer_id,
                  data=chunk })
  end
end

event.register (handler)
event.post ({class="user", type='first'})
event.post ({class="streambuf", uri = buffer_id, action='status'})
