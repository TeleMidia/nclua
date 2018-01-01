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

local assert = assert
local canvas = canvas
local event = event
local ipairs = ipairs
local math = math
local os = os
local table = table
local tonumber = tonumber
local toint = math.modf or function (x) return x end
_ENV = nil

-- Dimensions of the top-level canvas.
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

local function new_circle ()
   local max = toint (1 + WIDTH / 10)
   local t = {}
   t.r = math.random (1, max)   -- radius in pixels
   t.w = t.r * 2                -- width in pixels
   t.h = t.w                    -- height in pixels
   t.xv = math.random (1, max)  -- x speed in pixels/sec
   t.yv = math.random (1, max)  -- y speed in pixels/sec
   t.x = math.random (0, math.max (WIDTH - 2 * t.r, 0))  -- x position
   t.y = math.random (0, math.max (HEIGHT - 2 * t.r, 0)) -- y position
   t.color = {                                           -- circle color
      math.random (0, 255),
      math.random (0, 255),
      math.random (0, 255),
      math.random (0, 255),
   }
   t.cvs = canvas.new (t.w, t.h) -- image canvas
   t.cvs:attrColor (table.unpack (t.color))
   t.cvs:drawEllipse ('fill', t.r, t.r, t.w, t.h)
   t.cvs:flush ()
   return t
end

local function move_circle (t, dt)
   t.x = t.x + t.xv * dt
   t.y = t.y + t.yv * dt
   if t.x < 0 then
      t.x = 0
      t.xv = t.xv * -1
   elseif t.x + t.w > WIDTH then
      t.x = WIDTH - t.w
      t.xv = t.xv * -1
   end
   if t.y < 0 then
      t.y = 0
      t.yv = t.yv * -1
   elseif t.y + t.h > HEIGHT then
      t.y = HEIGHT - t.h
      t.yv = t.yv * -1
   end
end

-- List of circles to be displayed.
local CIRCLE_LIST = {}

-- Info text.
local INFO = nil
do
   canvas:attrFont ('sans', 16)
   local text = 'Press < or > to decrease or increase the number of circles'
   local text_w, text_h = canvas:measureText (text)
   INFO = canvas.new (text_w + 1, text_h + 1)
   INFO:attrFont (canvas:attrFont ())
   INFO:attrColor ('gray')
   INFO:drawText ('fill', 1, 1, text)
   INFO:attrColor ('purple')
   INFO:drawText ('fill', 0, 0, text)
end

local function redraw (e)
   if e.frame == 1 then
      math.randomseed (os.time ())
      for i=1,10 do
         CIRCLE_LIST[i] = new_circle ()
      end
   end
   canvas:attrColor (0, 0, 0, 0)
   canvas:clear ()
   for _,t in ipairs (CIRCLE_LIST) do
      move_circle (t, e.diff / 1000000)
      local xc, yc, w, h = t.x + t.r, t.y + t.r, t.w, t.h
      canvas:compose (t.x, t.y, t.cvs)
      canvas:attrColor (
         (t.color[1] + 127) % 255,
         (t.color[2] + 127) % 255,
         (t.color[3] + 127) % 255,
         255)
      canvas:attrFont ('sans', 7)
      local text = ('(%d,%d)'):format (toint (xc), toint (yc))
      local text_w, text_h = canvas:measureText (text)
      canvas:drawText (t.x + w/2 - text_w/2,
                       t.y + h/2 - text_h/2, text)
   end
   local w, h = INFO:attrSize ()
   canvas:compose ((WIDTH - w) / 2, (HEIGHT - h) / 2, INFO)
   canvas:attrFont ('sans', 12)
   local s = 's'
   if #CIRCLE_LIST == 1 then s = '' end
   local text = ('(%ds, %d circle%s, %dx%d, %d fps)')
      :format (toint (e.relative / 1000000),
               #CIRCLE_LIST,
               s,
               WIDTH,
               HEIGHT,
               toint (1000000 / math.max (e.diff, 1)))
   local text_w, text_h = canvas:measureText (text)
   canvas:attrColor ('gray')
   canvas:drawText (1 + (WIDTH - text_w) / 2, 1 + (HEIGHT + text_h) / 2, text)
   canvas:attrColor ('purple')
   canvas:drawText ((WIDTH - text_w) / 2, (HEIGHT + text_h) / 2, text)
   canvas:flush ()
end
assert (event.register (redraw, {class='tick'}))

local key_increase = {
   ['GREATER'] = true,
   ['PERIOD'] = true,
}

local key_decrease = {
   ['LESS'] = true,
   ['COMMA'] = true,
}

local function key (evt)
   if evt.type ~= 'press' then
      return
   end
   if key_decrease [evt.key] and #CIRCLE_LIST > 0 then
      table.remove (CIRCLE_LIST)
   elseif key_increase[evt.key] then
      table.insert (CIRCLE_LIST, new_circle ())
   elseif evt.key == 'q' then
      event.post {class='ncl', type='presentation', action='stop', label=''}
   end
end
assert (event.register (key, {class='key'}))
