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

local streambuf_uri = 'streambuf://b0'

local root = "../../ginga/tests-ncl/samples/"
local files = {
  names = {'main1_5s.ts',
           'main2_5s.ts',
           'main3_5s.ts',
           'main4_5s.ts',
           'main5_5s.ts'},
  fds  = {},
  chunk = nil,
  chunk_size = 2^16,

  cur_index = 1,
  waiting = false
}

for i, fname in pairs (files.names) do
  print (i, fname)
  files.fds[i] = io.open (root .. fname, 'rb')
end

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
  print (e.class, cur_time, files.waiting)
  if (e.class ~= 'user' and e.class ~= 'streambuf') then
    return
  end
  if (e.class == 'user' and e.type == 'first') then
    files.chunk = files.fds[files.cur_index]:read (files.chunk_size)
  elseif (e.class == 'streambuf') then
    if (e.action == 'status') then
      draw_streambuf_info (e)
      event.timer (200, function ()
                          event.post ( { class  = 'streambuf',
                                         uri    = streambuf_uri,
                                         action = 'status' })
                       end)
    elseif (e.error ~= nil) then
      print ('Error: ', e.error)
      if (files.waiting) then
        return
      else
        files.waiting = true
        event.timer (500,
          function ()
            files.waiting = false
            event.post ({ class='user' })
          end)
        return
      end
    else
      files.chunk = files.fds[files.cur_index]:read (files.chunk_size)

      if (files.chunk == nil and files.cur_index ~= #files.names) then
        files.cur_index = files.cur_index + 1
        files.chunk = files.fds[files.cur_index]:read (files.chunk_size)
      end
    end
  end

  if (files.chunk) then
    event.post ({ class  = 'streambuf',
                  action = 'write',
                  uri    = streambuf_uri,
                  data   = files.chunk })
  end
end

event.register (handler)
event.post ({class="user", type='first'})
event.post ({class="streambuf", uri = streambuf_uri, action='status'})
