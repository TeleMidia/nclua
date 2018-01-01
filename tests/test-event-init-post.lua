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
local TRACE_SEP = tests.trace_sep
local TRACE = tests.trace

local pcall = pcall

local event = require ('nclua.event')
local engine = event._engine
_ENV = nil

local function ASSERT_ERROR_POST (...)
   local status, errmsg = pcall (event.post, ...)
   ASSERT (not status)
   TRACE (errmsg)
end

local function ASSERT_FAIL_POST (...)
   local status, errmsg = event.post (...)
   ASSERT (not status)
   TRACE (errmsg)
end

-- Sanity checks.
ASSERT_ERROR_POST ('unknown')
ASSERT_ERROR_POST ('unknown', {})

-- Post events of unknown classes and check the result.
local x = {x='x'}
local y = {y='y'}
local z = {z='z'}

ASSERT (event.post (x))
ASSERT (tests.objeq (engine.TMPQ[1], x))

ASSERT (event.post ('out', y))
ASSERT (tests.objeq (engine.TMPQ[2], y))

ASSERT (event.post ('in', z))
ASSERT (tests.objeq (engine.INQ[1], z))

engine.INQ:dequeue (-1)
engine.TMPQ:dequeue (-1)

for i=1,100 do
   event.post ('in', {i=i})
   event.post ('out', {i=-i})
end

ASSERT (#engine.INQ == 100)
ASSERT (#engine.TMPQ == 100)

for i=1,100 do
   ASSERT (tests.objeq (engine.INQ[i], {i=i}))
   ASSERT (tests.objeq (engine.TMPQ[i], {i=-i}))
end

engine.INQ:dequeue (-1)
engine.TMPQ:dequeue (-1)

-- Post events of known classes and check the result
engine:load ('key', 'ncl', 'pointer', 'tcp', 'user')

ASSERT_FAIL_POST {class='key'}
ASSERT_FAIL_POST {class='key', type='press'}
ASSERT_FAIL_POST {class='key', type='release', key={}}
ASSERT_FAIL_POST {class='ncl'}
ASSERT_FAIL_POST {class='ncl', type='attribution'}
ASSERT_FAIL_POST {class='ncl', type='attribution', action='start'}
ASSERT_FAIL_POST {class='ncl', type='attribution', action='start', name='x'}
ASSERT_FAIL_POST {class='ncl', type='presentation', action='stop'}
ASSERT_FAIL_POST {class='ncl', type='selection', action='abort'}
ASSERT_FAIL_POST {class='pointer'}
ASSERT_FAIL_POST {class='pointer', type='move'}
ASSERT_FAIL_POST {class='pointer', type='move', x=0}
ASSERT_FAIL_POST {class='pointer', type='move', y=0}
ASSERT_FAIL_POST {class='tcp'}
ASSERT_FAIL_POST {class='tcp', type='connect'}
ASSERT_FAIL_POST {class='tcp', type='connect', host='x'}
ASSERT_FAIL_POST {class='tcp', type='data'}

local key = {class='key', type='press', key=0}
local ncl = {class='ncl', type='presentation', action='stop', label='x'}
local pointer = {class='pointer', type='move', x=10, y=23}
local tcp = {class='tcp', type='connect', host='x', port=0}
local user = {class='user', x='x'}

ASSERT (event.post (key))
ASSERT (event.post (ncl))
ASSERT (event.post (pointer))
ASSERT (event.post (tcp))
ASSERT (event.post (user))

ASSERT (tests.objeq (engine.TMPQ[1], key))
ASSERT (tests.objeq (engine.TMPQ[2], ncl))
ASSERT (tests.objeq (engine.TMPQ[3], pointer))
ASSERT (tests.objeq (engine.TMPQ[4], tcp))
ASSERT (tests.objeq (engine.TMPQ[5], user))

ASSERT (event.post ('in', user))
ASSERT (event.post ('in', tcp))
ASSERT (event.post ('in', pointer))
ASSERT (event.post ('in', ncl))
ASSERT (event.post ('in', key))

ASSERT (tests.objeq (engine.INQ[1], user))
ASSERT (tests.objeq (engine.INQ[2], tcp))
ASSERT (tests.objeq (engine.INQ[3], pointer))
ASSERT (tests.objeq (engine.INQ[4], ncl))
ASSERT (tests.objeq (engine.INQ[5], key))
