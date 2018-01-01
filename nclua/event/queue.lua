--[[ nclua.event.queue -- Queue data structure.
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

local queue = {}

local ipairs = ipairs
local setmetatable = setmetatable
local table = table
_ENV = nil

do
   queue.__index = queue
   queue.__metatable = 'not your business'
end

---
-- Creates a new object queue.
--
function queue:new ()
   return setmetatable ({}, queue)
end

---
-- Dequeues and returns N objects from the given queue.
-- If N < 0 then dequeues and returns all objects from the given queue.
--
function queue:dequeue (n)
   local n = n or 1
   if n < 0 or n > #self then
      n = #self
   end
   local result = {}
   for i=1,n do
      table.insert (result, table.remove (self, 1))
   end
   return table.unpack (result)
end

---
-- Enqueues objects into the given queue.
-- Returns the number of objects inserted into queue.
--
function queue:enqueue (...)
   local n = 0
   for _, obj in ipairs {...} do
      n = n + 1
      table.insert (self, obj)
   end
   return n
end

---
-- Returns true if the given queue is empty.
--
function queue:is_empty ()
   return #self == 0
end

return queue
