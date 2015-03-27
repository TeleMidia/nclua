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

local assert = assert
local canvas = canvas
local event = event
local ipairs = ipairs
local math = math
local os = os
local table = table
local tonumber = tonumber
_ENV = nil

math.randomseed (os.time ())

local WIDTH, HEIGHT
do
   WIDTH, HEIGHT = canvas:attrSize ()
   local resize = function (w,h)
      WIDTH = w or WIDTH
      HEIGHT = h or HEIGHT
   end
   local resize_w = function (e) resize (tonumber (e.value)) end
   local resize_h = function (e) resize (nil, tonumber (e.value)) end
   local t = {class='ncl', type='attribution', action='start'}
   t.name = 'width'
   assert (event.register (resize_w, t))
   t.name = 'height'
   assert (event.register (resize_h, t))
end

local function rand_color ()
   local t = {}
   for i=1,4 do
      t[i] = math.random (0, 255)
   end
   return t
end

local function comp_color (r, g, b)
   return (r + 127) % 255, (g + 127) % 255, (b + 127) % 255
end

local function _move (coord, radius, speed, limit, dt)
   coord = coord + speed * dt
   if speed > 0 and coord + 2 * radius >= limit then
      return limit - 2 * radius, speed * -1
   end
   if speed < 0 and coord < 0 then
      return 0, speed * -1
   end
   return coord, speed
end

local function get_circle ()
   local c = {}
   c.color = rand_color ()                 -- RGBA
   c.r = math.random (0, 100)              -- radius in pixels
   c.xv = math.random (0, 200)             -- x speed in pixels/sec
   c.yv = math.random (0, 200)             -- y speed in pixels/sec
   c.x = math.random (0, WIDTH - 2 * c.r)  -- x position
   c.y = math.random (0, HEIGHT - 2 * c.r) -- y position
   c.move = function (self, dt)
      self.x, self.xv = _move (self.x, self.r, self.xv, WIDTH, dt)
      self.y, self.yv = _move (self.y, self.r, self.yv, HEIGHT, dt)
   end
   return c
end

local CIRCLE_LIST = {}
for i=1,10 do
   CIRCLE_LIST[i] = get_circle ()
end

local last = event.uptime ()
local function update ()
   local now = event.uptime ()
   local dt = (now - last) / 1000
   last = now

   canvas:attrColor (0, 0, 0, 0)
   canvas:clear ()
   for _,c in ipairs (CIRCLE_LIST) do
      c:move (dt)
      local xc = c.x + c.r
      local yc = c.y + c.r
      local len = 2 * c.r
      canvas:attrColor (table.unpack (c.color))
      canvas:drawEllipse ('fill', xc, yc, len, len)
      canvas:attrColor (comp_color (table.unpack (c.color)))
      canvas:attrFont ('sans', 7)
      local text = ('(%d,%d)'):format (xc, yc)
      local w, h = canvas:measureText (text)
      canvas:drawText (c.x + len/2 - w/2, c.y + len/2 - h/2, text)
   end

   canvas:attrFont ('sans', 16)
   local text = 'Press < or > to decrease or increase the number of circles'
   local w, h = canvas:measureText (text)
   canvas:attrColor ('gray')
   canvas:drawText ('fill', (1 + WIDTH - w)/2, (1 + HEIGHT - h)/2, text)
   canvas:attrColor ('purple')
   canvas:drawText ('fill', (WIDTH - w)/2, (HEIGHT - h)/2, text)
   canvas:flush ()
   assert (event.post ('in', {class='user'}))
end

local key_increase = {
   ['LESS'] = true,
   ['PERIOD'] = true,
}

local key_decrease = {
   ['GREATER'] = true,
   ['COMMA'] = true,
}

local function key (evt)
   if evt.type ~= 'press' then
      return
   end
   if key_decrease [evt.key] and #CIRCLE_LIST > 0 then
      table.remove (CIRCLE_LIST)

   elseif key_increase[evt.key] then
      table.insert (CIRCLE_LIST, get_circle ())

   elseif evt.key == 'q' then
      event.post {class='ncl', type='presentation', action='stop', label=''}
   end
end

assert (event.register (key, {class='key'}))
assert (event.register (update, {class='user'}))
assert (event.post ('in', {class='user'}))
