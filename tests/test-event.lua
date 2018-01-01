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
local error = error
local ipairs = ipairs
local pcall = pcall

local tests = require ('tests')
local event = require ('nclua.event')
local engine = assert (event._engine)
_ENV = nil

-- Check Engine's API.
assert (engine.init ())
assert (pcall (engine.send, nil) == false)
assert (engine.receive () == nil)
assert (engine.cycle () == 0)
assert (engine.receive () == nil)

local list = {{a='b'}, {c='d'}, {e='f'}}
for _,evt in ipairs (list) do
   engine.send (evt)
end
event.register (function (evt); event.post (evt) end)
assert (engine.cycle () == #list)
for _,evt in ipairs (list) do
   local t = assert (engine.receive ())
   assert (tests.table.equals (evt, t))
end
assert (engine.receive () == nil)

-- Check User's API.

-- event.register
engine.reset ()
local n = 0
for i=1,100 do
   event.register (function (evt) n = n + 1 end)
end
for i=1,100 do
   engine.send {i}
end
assert (engine.cycle () == 100)
assert (n == 100^2)

engine.reset ()
local n = 0
for i=1,100 do
   event.register (function (evt) n = n + 1 end)
end
event.register (1, function (evt) return true end) -- stop processing
for i=1,100 do
   engine.send {i}
end
assert (engine.cycle () == 100)
assert (n == 0)

engine.reset ()
local i, j, k = 0, 0, 0
event.register (function (evt) k = k + 1 end, {class='k'})
event.register (1, function (evt) i = i + 1 end, {class='i'})
event.register (2, function (evt) j = j + 1 end, {class='j'})
for i=1,100 do
   if i <= 50 then
      engine.send {class='i'}
   elseif i <= 75 then
      engine.send {class='j'}
   elseif i <= 80 then
      engine.send {class='k'}
   else
      engine.send {class='unknown'}
   end
end
assert (engine.cycle () == 100)
assert (i == 50 and j == 25 and k == 5)

-- event.unregister
engine.reset ()
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
assert (event.unregister (f1, f2) == 3)
for i=1,100 do
   engine.send {}
end
assert (engine.cycle () == 100)
assert (n == 100^2)

-- event.post
engine.reset ()
event.register (function (evt) event.post ('in', evt) end)
for i=1,100 do
   engine.send {}
end
assert (engine.cycle () == 100)
assert (event.unregister () == 1)
assert (engine.cycle () == 100)
assert (engine.cycle () == 0)

engine.reset ()
engine.load_plugins ()          -- user and tcp
local n = 0
event.register (function (evt) n = n + 1 end, 'user')
for i=1,100 do
   if i <= 50 then
      engine.send {class='user'}
   else
      engine.send {}
   end
end
assert (engine.cycle () == 100)
assert (engine.cycle () == 0)
assert (n == 50)

-- event.uptime
engine.reset ()
assert (event.uptime () == 0)
engine.cycle ()
tests.sleep (1)
local now = event.uptime ()
local epsilon = 10
if not tests.is_linux () then
   epsilon = epsilon * 4
end
assert (now >= 1000 and now < 1000 * epsilon,
        ("now=%d (expected %d)"):format (now, now + epsilon))

-- event.timer
engine.reset ()
local function cmp (x, y) return tests.numeq (x, y, 1) end -- 1ms precision
local function docycle (ms)
   local t0 = event.uptime ()
   while event.uptime () - t0 < ms do
      engine.cycle ()
   end
end
local call = {}
local function f1 () call[#call+1] = {f1, event.uptime ()} end
local function f2 () call[#call+1] = {f2, event.uptime ()} end
local function f3 () call[#call+1] = {f3, event.uptime ()} end
local c1 = event.timer (10, f1)
local c2 = event.timer (20, f1)
local c3 = event.timer (1, f2)
local c4 = event.timer (30, f3)
do
   engine.cycle ()
   docycle (15)
   assert (call[1][1] == f2 and cmp (call[1][2], 1))
   assert (call[2][1] == f1 and cmp (call[2][2], 10))
   call = {}
   c2 ()
   docycle (16)
   assert (#call == 1)
   assert (call[1][1] == f3 and cmp (call[1][2], 30))

   call = {}
   c1 = event.timer (0, f1)
   c2 = event.timer (0, f2)
   c1 (); c2()
   engine.cycle ()
   assert (#call == 0)
   engine.fini ()
end
