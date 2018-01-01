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
local GET_SAMPLE = tests.canvas.get_sample
local TRACE = tests.trace
local TRACE_SEP = tests.trace_sep

local canvas = require ('nclua.canvas')
_ENV = nil

-- Sanity checks.
ASSERT_ERROR (canvas._resize)
ASSERT_ERROR (canvas._resize, {})
ASSERT_ERROR (canvas._resize, 0)

-- Check invalid dimensions.
local c = ASSERT (canvas.new (1, 1))
ASSERT_ERROR (canvas._resize, c, -50, 1)
ASSERT_ERROR (canvas._resize, c, 1, -50)

-- Check a vacuous resize; it should do nothing.
local c, w, h = ASSERT (canvas.new (50, 50))
local sfc = c:_surface ()
local new_w, new_h = c:_resize (w, h)
local new_sfc = c:_surface ()
ASSERT (new_w == w, new_h == h, new_sfc == sfc)

-- Check if canvas._resize() actually resizes the surface.
local a, w, h = canvas.new (GET_SAMPLE ('apple-red'))
local c = canvas.new (w, h)
c:attrColor ('yellow')
c:clear ()
c:compose (0, 0, a)
ASSERT (tests.canvas.check_ref (c, 1))

c:attrFilter ('good')
local w, h = c:_resize (w * 2, h * 2)
ASSERT (tests.canvas.check_ref (c, 2))

c:attrFilter ('fast')
local w, h = c:_resize (w / 4, h)
ASSERT (tests.canvas.check_ref (c, 3))

-- Check if canvas._resize() maintains the original attributes.
local c, w, h = ASSERT (canvas.new (50, 50))
local sfc = c:_surface ()
local antialias = c:attrAntiAlias ()
local clip_x, clip_y, clip_w, clip_h = c:attrClip ()
local r, g, b, a = c:attrColor ()
local crop_x, crop_y, crop_w, crop_h = c:attrCrop ()
local filter = c:attrFilter ()
local flip_x, flip_y = c:attrFlip ()
local family, size, style = c:attrFont ()
local line = c:attrLineWidth ()
local opacity = c:attrOpacity ()
local rotation = c:attrRotation ()
local scale_x, scale_y = c:attrScale ()

local new_w, new_h = ASSERT (c:_resize (w * 2, h * 2))
ASSERT (new_w == 2 * w, new_h == 2 * h)
local w, h = c:attrSize ()
ASSERT (w == new_w, h == new_h)

local new_sfc = c:_surface ()
ASSERT (new_sfc ~= sfc)

local new_antialias = c:attrAntiAlias ()
ASSERT (new_antialias == antialias)

local new_clip_x, new_clip_y, new_clip_h, new_clip_w = c:attrClip ()
ASSERT (new_clip_x == clip_x,
        new_clip_y == clip_y,
        new_clip_w == new_w,    -- clip should be updated to whole canvas
        new_clip_h == new_h)

local new_r, new_g, new_b, new_a = c:attrColor ()
ASSERT (new_r == r, new_g == g, new_b == b, new_a == a)

local new_crop_x, new_crop_y, new_crop_w, new_crop_h = c:attrCrop ()
ASSERT (new_crop_x == crop_x,
        new_crop_y == crop_y,
        new_crop_w == new_w,    -- crop should be updated to whole canvas
        new_crop_h == new_h)

local new_filter = c:attrFilter ()
ASSERT (new_filter == filter)

local new_flip_x, new_flip_y = c:attrFlip ()
ASSERT (new_flip_x == flip_x, new_flip_y == flip_y)

local new_family, new_size, new_style = c:attrFont ()
ASSERT (new_family == family,
        new_size == size,
        new_style == style)

local new_line = c:attrLineWidth ()
ASSERT (new_line == line)

local new_opacity = c:attrOpacity ()
ASSERT (new_opacity == opacity)

local new_rotation = c:attrRotation ()
ASSERT (new_rotation == rotation)

local new_scale_x, new_scale_y = c:attrScale ()
ASSERT (new_scale_x == new_scale_x,
        new_scale_y == new_scale_y)

-- Check if canvas._resize() honors clip attribute if it is set.
local c, w, h = canvas.new (GET_SAMPLE ('apple-red'))
c:attrClip (0, 0, w/2, h/2)
local clip_x, clip_y, clip_w, clip_h = c:attrClip ()
local new_w, new_h = c:_resize (w/2, h/2)
ASSERT (new_w == w/2, new_h ==h/2)
local new_clip_x, new_clip_y, new_clip_w, new_clip_h = c:attrClip ()
ASSERT (new_clip_x == clip_x,
        new_clip_y == clip_y,
        new_clip_w == clip_w,
        new_clip_h == clip_h)

-- Check if canvas._resize() honors crop attribute if it is set.
local c, w, h = canvas.new (GET_SAMPLE ('apple-red'))
c:attrCrop (0, 0, w/2, h/2)
local crop_x, crop_y, crop_w, crop_h = c:attrCrop ()
local new_w, new_h = c:_resize (w/2, h/2)
ASSERT (new_w == w/2, new_h == h/2)
local new_crop_x, new_crop_y, new_crop_w, new_crop_h = c:attrCrop ()
ASSERT (new_crop_x == crop_x,
        new_crop_y == crop_y,
        new_crop_w == crop_w,
        new_crop_h == crop_h)
