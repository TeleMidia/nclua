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
local dir = dir
local event = event
_ENV = nil

local text = '$ ls -1F\n'
for f in dir.dir ('.') do
   text = text..f
   if dir.test (f, 'directory') then
      text = text..'/'
   end
   text = text..'\n'
end

local w, h = canvas:attrSize ()
canvas:attrClip (0, 0, w, h)
canvas:attrColor ('white')
canvas:clear (0, 0, w, h)
canvas:attrFont ('fixed', 14)
local tw, th = canvas:measureText (text)
canvas:attrColor ('green')
canvas:drawText ((w-tw)/2, (h-th)/2, text)
canvas:flush ()
