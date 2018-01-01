--[[ nclua.event.engine -- Prototype for event engines.
     Copyright (C) 2013-2018 PUC-Rio/Laboratorio TeleMidia

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

local engine = {}

local error = error
local setmetatable = setmetatable

local queue = require ('nclua.event.queue')
_ENV =nil

do
   engine.__index = engine
   engine.__metatable = 'not your business'
end

---
-- Creates a new event engine.
--
function engine:new ()
   local obj = setmetatable ({}, engine)
   obj:reset ()
   return obj
end

---
-- Cycles the engine once -- i.e., process the pending events on INQ and
-- store the resulting events in OUTQ.
--
-- This function must be implemented by users.
--
function engine:cycle ()
   error ('not implemented')
end

---
-- Removes and returns N events from OUTQ.
-- If N < 0 then, removes and returns all events from OUTQ.
--
function engine:receive (n)
   return self.OUTQ:dequeue (n)
end

---
-- Resets event queues.
--
function engine:reset ()
   self.INQ = queue:new ()
   self.OUTQ = queue:new ()
end

---
-- Inserts the given events into INQ.
-- Returns the number of events inserted into INQ.
--
function engine:send (...)
   return self.INQ:enqueue (...)
end

return engine
