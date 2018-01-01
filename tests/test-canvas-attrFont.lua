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

local ipairs = ipairs
local canvas = require ('nclua.canvas')
_ENV = nil

canvas._attrFont = canvas.attrFont
canvas.attrFont = function (c, face, size, style)
   if face == nil then
      return canvas._attrFont (c)
   else
      canvas._attrFont (c, face, size, style)
      local _face, _size, _style = canvas._attrFont (c)
      TRACE_SEP ()
      TRACE ('in:', face, size, style)
      TRACE ('out:', face, size, style)
      return _face == face and tests.numeq (_size, size) and _style == style
   end
end

-- Sanity checks.
local c = tests.canvas.new ()
ASSERT_ERROR (canvas._attrFont)
ASSERT_ERROR (canvas._attrFont, c, nil)
ASSERT_ERROR (canvas._attrFont, c, {})
ASSERT_ERROR (canvas._attrFont, c, '')
ASSERT_ERROR (canvas._attrFont, c, '', 0, 'x')
ASSERT_ERROR (canvas._attrFont, c, '', 0, '-x')
ASSERT_ERROR (canvas._attrFont, c, '', 0, 'y-normal')
ASSERT_ERROR (canvas._attrFont, c, '', 0, 'bold-italic ')

-- Check the default font.
local c = tests.canvas.new ()
ASSERT (c:_attrFont () == nil)

-- Check default styles.
local function check_style (c, set, res)
   c:_attrFont ('', 12, set)
   local _, _, style = c:_attrFont ()
   return style == res
end
ASSERT (check_style (c, nil, 'normal-normal'))
ASSERT (check_style (c, '', 'normal-normal'))
ASSERT (check_style (c, '-', 'normal-normal'))
ASSERT (check_style (c, 'bold-', 'bold-normal'))
ASSERT (check_style (c, '-italic', 'normal-italic'))

-- Check all supported styles.
for _, style in ipairs (tests.canvas.text_style_list) do
   ASSERT (c:attrFont ('', 12.5, style))
end

-- Make some pseudo-random calls and check the result.
local c, cw, ch = tests.canvas.new ()
tests.iter (
   function ()
      local size = tests.rand_number (-1000, 1000)
      local style = tests.rand_option (tests.canvas.text_style_list)
      c:attrFont ('', size, style)
   end
)
