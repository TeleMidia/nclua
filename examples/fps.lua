--[[ Copyright (C) 2013-2015 PUC-Rio/Laboratorio TeleMidia

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
along with NCLua.  If not, see <http://www.gnu.org/licenses/>.  ]]--

local event = event
local canvas = canvas
_ENV = nil

canvas:attrFont ('tiresias', 40, 'bold')
local function redraw (e)
   local w, h = canvas:attrSize ()
   canvas:attrClip (0, 0, w, h)
   canvas:attrColor ('white')
   canvas:clear (0, 0, w, h)
   canvas:attrColor ('black')
   local n = 10
   for i=0,w/n do
      canvas:drawLine (i * n, 0, i * n, h)
   end
   for i=0,h/n do
      canvas:drawLine (0, i * n, w, i * n)
   end
   local now = event.uptime ()
   local text = ('%.3g fps'):format (1000/(now - e.last))
   local tw, th = canvas:measureText (text)
   canvas:attrColor ('yellow')
   canvas:drawText ((w-tw)/2, (h-th)/2, text)
   canvas:attrColor ('navy')
   canvas:drawText ((w-tw)/2 - 1, (h-th)/2 - 1, text)
   canvas:flush ()
   e.last = now
   event.post ('in', e)
end
event.register (redraw, {class='user'})
event.post ('in', {class='user', last=event.uptime ()})
