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

local tests = require ('tests')
local ASSERT = tests.ASSERT
local ASSERT_ERROR = tests.ASSERT_ERROR
local TRACE = tests.trace
local TRACE_SEP = tests.trace_sep

local io = io
local pairs = pairs
local tonumber = tonumber
local type = type

local canvas = require ('nclua.canvas')
_ENV = nil

canvas._attrColor = canvas.attrColor
canvas.attrColor = function (c, r, g, b, a, x)
   if r == nil and g == nil and b == nil and a == nil then
      return canvas._attrColor (c)
   elseif type (r) == 'string' then
      if not canvas._attrColor (c, r) then
         return false
      end
      ASSERT (x ~= nil)
      r = tonumber (g)
      g = tonumber (b)
      b = tonumber (a)
      a = tonumber (x)
   else
      canvas._attrColor (c, r, g, b, a)
   end
   local _r, _g, _b, _a = canvas._attrColor (c)
   local rr = tests.range (0, r, 255)
   local rg = tests.range (0, g, 255)
   local rb = tests.range (0, b, 255)
   local ra = tests.range (0, a, 255)
   TRACE_SEP ()
   TRACE ('in:', rr..'/'..r, rg..'/'..g, rb..'/'..b, ra..'/'..a)
   TRACE ('out:', _r, _g, _b, _a)
   return tests.numeq (_r, rr)
      and tests.numeq (_g, rg)
      and tests.numeq (_b, rb)
      and tests.numeq (_a, ra)
end

-- Sanity checks.
local c = tests.canvas.new ()
ASSERT_ERROR (canvas._attrColor)
ASSERT_ERROR (canvas._attrColor, c, nil)
ASSERT_ERROR (canvas._attrColor, c, {})
ASSERT_ERROR (canvas._attrColor, c, 0, nil)
ASSERT_ERROR (canvas._attrColor, c, 0, 0, nil)
ASSERT_ERROR (canvas._attrColor, c, 0, 0, 0, {})

-- Check the default color.
local c = tests.canvas.new ()
local t = {c:attrColor ()}
ASSERT (t[1] == 0, t[2] == 0, t[3] == 0, t[4] == 255)

-- Check optional argument.
c:_attrColor (255, 0, 0)
local r, g, b, a = c:_attrColor ()
ASSERT (r == 255, g == 0, b == 0, a == 255)

-- Make some pseudo-random calls and check the result.
local c = tests.canvas.new ()
tests.iter (
   function ()
      ASSERT (c:attrColor (tests.rand_integer (-255, 255, 4)))
   end
)

-- Check color-table.
local status, errmsg = c:_attrColor ('invalid')
ASSERT (status == false)
ASSERT (errmsg == "unknown color 'invalid'")
local color_table = {}
local file = io.open (tests.mk.top_srcdir..'/nclua/canvas-color-table.h')
for line in ASSERT (file):lines () do
   local name, r, g, b =
      line:match ('%s*{%s*"(%w-)",%s*(%d-)%s*,%s*(%d-)%s*,%s*(%d-)%s*},?')
   if name ~= nil then
      color_table[name] = {r=r, g=g, b=b}
   end
end
for k,v in pairs (color_table) do
   ASSERT (c:attrColor (k, v.r, v.g, v.b, 255))
   ASSERT (c:attrColor (k:lower (), v.r, v.g, v.b, 255))
   ASSERT (c:attrColor (k:upper (), v.r, v.g, v.b, 255))
end
