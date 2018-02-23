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

local bufsize = 2^13 -- 8KB buffer

local inp = io.open('/tmp/1080i_4ChAud.ts', "rb")
local chunk = nil

local function handler (e)
  if (e.class == 'user' and e.type == 'first') then
    chunk = inp:read (bufsize)
  elseif (e.class == 'srcbuffer') then
    -- last attempt
    if (e.error) then
      print (e.error)
    else
      chunk = inp:read (bufsize)
    end
  end

  if (chunk) then
    event.post ({class='srcbuffer', action='write', buff='b0.mp4', data=chunk})
  end

end

event.register (handler)
event.post ({class="user", type='first'})

