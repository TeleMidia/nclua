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

local math = math
local table = table
local type = type

local event = require ('nclua.event')
local engine = event._engine
_ENV = nil

local LARGE = 2^10              -- 1K

local function CYCLE (engine)
   while not engine.INQ:is_empty () do
      TRACE ('cycling')
      engine:cycle ()
   end
end

-- Check if event.register behaves correctly.
engine:reset ()
local n = 0
for i=1,LARGE do
   event.register (function (evt) n = n + 1 end)
end
for i=1,LARGE do
   engine:send (i)
end
CYCLE (engine)
ASSERT (n == LARGE^2)

engine:reset ()
local n = 0
for i=1,LARGE do
   event.register (function (evt) n = n + 1 end)
end
event.register (1, function (evt) return true end) -- stop processing
for i=1,LARGE do
   engine:send {i}
end
CYCLE (engine)
ASSERT (n == 0)

engine:reset ()
local i, j, k = 0, 0, 0
event.register (function (evt) k = k + 1 end, {class='k'})
event.register (1, function (evt) i = i + 1 end, {class='i'})
event.register (2, function (evt) j = j + 1 end, {class='j'})
for i=1,LARGE do
   if i <= math.floor (LARGE/4) then
      engine:send {class='i'}
   elseif i <= math.floor (LARGE/3) then
      engine:send {class='j'}
   elseif i <= math.floor (LARGE/2) then
      engine:send {class='k'}
   else
      engine:send {class='unknown'}
   end
end
CYCLE (engine)
ASSERT (i == LARGE/4,
        j == math.floor (LARGE/3) - i,
        k == LARGE/2 - (i + j))

-- Check if event.unregister behaves correctly.
engine:reset ()
local n = 0
local f1 = function (evt) error ('f1 called') end
local f2 = function (evt) error ('f2 called') end
local f3 = function (evt) n = n + 1 end
event.register (f1)
event.register (f1, {a='b'})
event.register (f2, {b='c'})
event.register (f3, {c='d'})
event.register (f3)
event.register (f3)
ASSERT (event.unregister (f1) == 2)
ASSERT (event.unregister (f2) == 1)
for i=1,LARGE do
   engine:send {}
end
CYCLE (engine)
ASSERT (n == 2 * LARGE)

-- Send and receive 10 * N events and check the result.
engine:reset ()
local t, n = {}, 10 * engine.EVT_MAX
for i=1,n do
   t[i] = i
end
ASSERT (engine:send (table.unpack (t)))
ASSERT (tests.objeq (engine.INQ, t))
ASSERT (#engine.INQ == n)
ASSERT (#engine.TMPQ == 0)
ASSERT (#engine.OUTQ == 0)
ASSERT (event.register (function (evt) ASSERT (event.post (evt)) end))
for i=1,10 do
   engine:cycle ()
   ASSERT (#engine.INQ == n - i * engine.EVT_MAX)
   ASSERT (#engine.OUTQ == n - #engine.INQ)
   ASSERT (#engine.TMPQ == 0)
end
ASSERT (tests.objeq (engine.OUTQ, t))

-- Send and receive a KEY and a TCP event, and check the result.
engine:reset ()
engine:load ('tcp')

event.post {class='key', type='press', key=0} -- ends up in OUTQ
event.post {class='tcp', type='connect', host='unknown', port=0, timeout=1}

local DONE = nil
event.register (function (evt) tests.dump (evt); DONE = evt end)

TRACE ('INQ:', 'OUTQ:', 'TMPQ:')
TRACE (#engine.INQ, #engine.OUTQ, #engine.TMPQ)
ASSERT (#engine.INQ == 0, #engine.OUTQ == 0, #engine.TMPQ == 2)

while not DONE do
   engine:cycle ()
   TRACE (#engine.INQ, #engine.TMPQ, #engine.OUTQ)
   tests.sleep (.05)
end

local response = {
   class='tcp',
   error='Could not connect to unknown: Socket I/O timed out',
   host='unknown',
   port=0,
   type='connect',
}
ASSERT (DONE.class =='tcp',
        DONE.host == 'unknown',
        DONE.port == 0,
        DONE.type == 'connect',
        type (DONE.error) == 'string')
ASSERT (tests.objeq (engine:receive (), {class='key', type='press', key=0}))
TRACE (#engine.INQ, #engine.TMPQ, #engine.OUTQ)
ASSERT (#engine.INQ == 0, #engine.OUTQ == 0, #engine.TMPQ == 0)

-- Send and receive 'user' events and check the result.
engine:reset ()
engine:load ('user')
local n = 0
event.register (function (evt) n = n + 1 end, 'user')
for i=1,LARGE do
   if i <= LARGE/2 then
      engine:send {class='user'}
   else
      engine:send {}
   end
end
CYCLE (engine)
ASSERT (n == LARGE/2)
