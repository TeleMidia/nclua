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

local streambuf_uri = 'streambuf://b0'
local file = {
  fd          = io.open ('/tmp/main1_5s.ts', "rb"),
  chunk       = nil,
  chunk_size  = 2^16,
  waiting = false
}

local function draw_streambuf_info (e)
  canvas:attrColor (0, 0, 0, 0)
  canvas:clear ()
  local text = ( 'StreamBuffer ' .. e.uri .. ' status: '.. e.state
                 .. ' size: %d bytes.' )
                :format (e.size)
  canvas:attrColor ('red')
  canvas:attrFont ('tiresias', 20, 'bold')
  canvas:drawText (0, 0, text)
  canvas:flush ()
end

local function handler (e)
  if (e.class ~= 'user' and e.class ~= 'streambuf') then
    return
  end

  local ask_next_chunk = false
  if (e.class == 'user' and e.type == 'first') then
    ask_next_chunk = true
  elseif (e.class == 'streambuf') then
    draw_streambuf_info (e)

    if (not e.error) then
      ask_next_chunk = true
    else
      print ('Error: ', e.error)
      if (file.waiting) then return end

      file.waiting = true
      event.timer (500, function ()
                          file.waiting = false
                          event.post({ class='user' })
                        end )
      return
    end
  end

  if (ask_next_chunk) then
    file.chunk = file.fd:read (file.chunk_size)
  end

  if (file.chunk) then
    event.post ({ class  = 'streambuf',
                  action = 'write',
                  uri    = streambuf_uri,
                  data   = file.chunk })
  end
end

event.register (handler)
event.post ({class="user", type='first'})
