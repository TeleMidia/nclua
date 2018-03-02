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

-- https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8

local streambuf_uri = 'streambuf://b0'
local video = {
  next_seg = 0,
  cur_seg_data = "",
  root_uri = 'http://www.telemidia.puc-rio.br/~roberto/misc/sintel_hls/1100kbit/' ,
  downloading = false
}

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

local function request_finished (e)
  video.cur_seg_data = video.cur_seg_data .. e.body

  if (e.finished) then
    print (e.uri)
    event.post ({ class  = 'streambuf',
                  action = 'write',
                  uri    = streambuf_uri,
                  data   =  video.cur_seg_data })
    video.cur_seg_data = ''

    video.downloading = false
  end
end

local function handler (e)
  if (e.class == 'streambuf' and e.action == 'status') then
    draw_streambuf_info (e)
    
    if (e.size < 30000000 and not video.downloading) then
      event.post ({ class  ='http',
                    type   ='request',
                    method ='get',
                    uri    = video.root_uri .. "seq-" .. video.next_seg .. ".ts"})

      video.next_seg = video.next_seg + 1
      video.downloading = true
    end
    
    -- schedule a new buffer status evt
    event.timer (200, function ()
                        event.post ( { class  = 'streambuf',
                                       uri    = streambuf_uri,
                                       action = 'status' })
                       end )
  end
end

event.register (handler)
event.post ({class="streambuf", uri = streambuf_uri, action='status'})
event.register (request_finished, {class='http', type='response'})
