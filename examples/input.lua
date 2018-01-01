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

local canvas = canvas
local event = event
local pairs = pairs
local print = print
local tonumber = tonumber

_ENV = nil

local WIDTH, HEIGHT = canvas:attrSize ()
event.register (
   function (e)
      if e.name == 'width' then
         WIDTH = tonumber (e.value)
      elseif e.name == 'height' then
         HEIGHT = tonumber (e.value)
      end
   end,
   {class='ncl', type='attribution', action='start'}
)

local n = 1
canvas:attrFont ('comic sans', 16)
event.register (
   function (evt)
      local text = '#'..n..' { '
      for k,v in pairs (evt) do
         text = text .. k .. '=' .. v .. ', '
      end
      text = text .. '}'
      print (text)
      canvas:attrColor ('black')
      canvas:clear ()
      local w, h = canvas:measureText (text)
      canvas:attrColor ('red')
      canvas:drawText ((WIDTH - w) / 2, (HEIGHT - h) / 2, text)
      canvas:flush ()
      n = n + 1
   end
)
