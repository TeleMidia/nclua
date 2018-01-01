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
local math = math
local os = os
local table = table
local tonumber = tonumber
_ENV = nil

math.randomseed (os.time ())

local WIDTH, HEIGHT = canvas:attrSize ()

local function rand_color_comp ()
   return math.random (0, 255)
end

local function rand_color ()
   return {
      rand_color_comp (),
      rand_color_comp (),
      rand_color_comp (),
      rand_color_comp (),
   }
end

local polygon_mode = {'fill', 'close', 'open'}
local function get_polygon ()
   local p = {}
   p.n = math.random (3,30)                 -- number of points
   p.line = math.random (1,10)              -- line width
   p.mode = polygon_mode[math.random (1,3)] -- fill mode
   p.points = {}                            -- point list
   for i=1,p.n do
      local x = math.random (-100, 100) -- x offset
      local y = math.random (-100, 100) -- y offset
      p.points[i] = {x,y}
   end
   p.color = rand_color ()      -- color
   return p
end

local TARGET = get_polygon ()
local BACK = canvas:new (WIDTH, HEIGHT)
BACK:attrColor ('black')
BACK:clear ()
canvas:compose (0, 0, BACK)
canvas:flush ()

local function draw_target (c, x, y)
   c:attrColor (table.unpack (TARGET.color))
   c:attrLineWidth (TARGET.line)
   local f = assert (c:drawPolygon (TARGET.mode))
   for i=1,TARGET.n do
      local x_off, y_off = table.unpack (TARGET.points[i])
      f = f (x - x_off, y - y_off)
      assert (f)
   end
   f (nil)
   c:flush ()
end

local function move (evt)
   canvas:compose (0, 0, BACK)
   draw_target (canvas, evt.x, evt.y)
   canvas:flush ()
end
assert (event.register (move, {class='pointer', type='move'}))

local function press (evt)
   draw_target (BACK, evt.x, evt.y)
   canvas:compose (0, 0, BACK)
   canvas:flush ()
   TARGET = get_polygon ()
end
assert (event.register (press, {class='pointer', type='press'}))

local function resize ()
   local w, h = BACK:attrSize ()
   if w < WIDTH then w = WIDTH end
   if h < HEIGHT then h = HEIGHT end
   local new_BACK = canvas:new (w, h)
   new_BACK:attrColor ('black')
   new_BACK:clear ()
   new_BACK:compose (0, 0, BACK)
   new_BACK:flush ()
   BACK = new_BACK
   canvas:compose (0, 0, BACK)
   canvas:flush ()
end
assert (
   event.register (
      function (e)
         if e.name == 'width' then
            WIDTH = tonumber (e.value)
            resize ()
         elseif e.name == 'height' then
            HEIGHT = tonumber (e.value)
            resize ()
         end
      end,
      {class='ncl', type='attribution', action='start'}
   )
)
