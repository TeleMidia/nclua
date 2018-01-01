--[[ nclua.event.init -- The NCLua Event module.
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

local event = {}

local assert = assert
local error = error
local ipairs = ipairs
local pairs = pairs
local pcall = pcall
local require = require
local table = table
local type = type

local check = require ('nclua.event.check')
local engine_proto = require ('nclua.event.engine')
local queue = require ('nclua.event.queue')
local stopwatch = require ('nclua.event.stopwatch')
_ENV = nil


-------------------------------- Engine API --------------------------------

do
   event._engine = engine_proto:new ()
   event._engine.clock = stopwatch:new ()
   event._engine.reset = function (self)
      engine_proto.reset (self)
      self.EVT_MAX = 128        -- max. number of events handled per cycle
      self.TMPQ = queue:new ()  -- temporary event queue
      self.clock:stop ()        -- engine clock
      self.handler_list = {}    -- list of event handlers
      self.plugin_table = {}    -- table of loaded plugins
      self.timer_list = {}      -- list of active timers
   end
   event._engine:reset ()
end

-- Returns a shallow copy of event EVT.
local function clone (evt)
   if type (evt) ~= 'table' then
      return evt
   end
   local copy = {}
   for k,v in pairs (evt) do
      copy[k] = v
   end
   return copy
end

-- Returns true if event EVT matches event filter FILTER.
local function match (evt, filter)
   for k,v in pairs (filter) do
      if evt[k] == nil or evt[k] ~= filter[k] then
         return false
      end
   end
   return true
end

---
-- Loads the given plugins.
--
function event._engine:load (...)
   for _, name in ipairs {...} do
      local plugin = require ('nclua.event.'..name)
      assert (plugin.class == name,
              ("module '%s' is not a plugin"):format (name))
      self.plugin_table[name] = plugin
   end
end

---
-- Unloads the given plugins.
--
function event._engine:unload (...)
   for _, name in ipairs {...} do
      self.plugin_table[name] = nil
   end
end

---
-- Cycles the Event engine once.
--
function event._engine:cycle ()

   -- First cycle?
   if self.clock:get_state () == 'stopped' then
      self.clock:start ()
   end

   -- Trigger expired timers.
   local expired = {}
   while #self.timer_list > 0 do
      if self.timer_list[1].end_time > self.clock:get_time ('ms') then
         break
      end
      table.insert (expired, table.remove (self.timer_list, 1))
   end
   for _,entry in ipairs (expired) do
      entry.func ()
   end

   -- Get input from plugins.
   for _,plugin in pairs (self.plugin_table) do
      if plugin.cycle then
         plugin:cycle ()
         self:send (plugin:receive (self.EVT_MAX))
      end
   end

   -- Process input events.
   for _,evt in ipairs {self.INQ:dequeue (self.EVT_MAX)} do
      for _,entry in ipairs (self.handler_list) do
         local handler = assert (entry[1])
         local filter = entry[2]
         if match (evt, filter or {}) then
            if handler (clone (evt)) then -- call handler
               break                      -- consume event
            end
         end
      end
   end

   -- Send output to plugins or OUTQ.
   for _,evt in ipairs {self.TMPQ:dequeue (self.EVT_MAX)} do
      if type (evt) == 'table'
         and evt.class
         and self.plugin_table[evt.class]
         and self.plugin_table[evt.class].cycle then
         self.plugin_table[evt.class]:send (evt)
      else
         self.OUTQ:enqueue (evt)
      end
   end
end


--------------------------------  User API  --------------------------------

local engine = event._engine    -- alias to the engine object

-- Wrapper to check.arg[FNAME].
local function check_arg (fname, ...)
   local t = {pcall (check.arg[fname], ...)}
   if not t[1] then
      error (t[2], 3)
   end
   return table.unpack (t, 2)
end

-- Finds and returns the largest integer key in table T.
-- This function assumes that T contains no float-point number keys.
local function find_maxi (t)
   local max = #t
   for k,_ in pairs (t) do
      if type (k) == 'number' and k > max then
         max = k
      end
   end
   return max
end

---
-- event.post ([dest:string], evt:table) -> status:boolean, errmsg:string
--
-- Posts event EVT into event queue denoted by DEST: 'in' for input queue or
-- 'out' for output queue (default).
--
-- Returns true if successful, or false plus error message otherwise.
--
function event.post (dest, evt)
   if type (dest) ~= 'string' then
      evt, dest = dest, nil
   end
   dest = check_arg ('option', 'dest', dest, {'in', 'out'}, 'out')
   if evt == nil then
      return true               -- nothing to do
   end
   if type (evt) == 'table' then
      local plugin = engine.plugin_table[evt.class]
      if plugin ~= nil then
         assert (plugin.check)
         local status, errmsg = pcall (plugin.check, plugin, evt)
         if not status then
            return false, errmsg
         end
      end
   end
   local queue
   if dest == 'out' then
      queue = engine.TMPQ
   else
      queue = engine.INQ
   end
   queue:enqueue (clone (evt))
   return true
end

---
-- event.register ([pos:number], func:function, [filter:table])
-- event.register ([pos:number], func:function, [class:string, ...])
--      -> status:boolean, errmsg:string
--
-- Appends function FUNC into the list of registered event handlers.
-- If POS is given, registers FUNC at position POS in the list.
-- If FILTER is given, uses FILTER as event filter for function.
--
-- In the second form, if CLASS is the name of a known event class, uses the
-- extra parameters (...) to build a corresponding filter.
--
-- Returns true if successful, or false plus error message otherwise.
--
function event.register (...)
   local args = {...}
   if type (args[1]) == 'function' then
      table.insert (args, 1, nil)
   end
   local list = engine.handler_list
   local pos = check_arg ('number', 'pos', args[1], #list + 1)
   local func = check_arg ('func', 'func', args[2])
   local filter = nil
   if args[3] == nil then
      filter = nil
   elseif type (args[3]) == 'table' then
      filter = clone (args[3])
   else
      local class = check_arg ('string', 'class', args[3])
      local plugin = engine.plugin_table[class]
      if plugin ~= nil then
         assert (plugin.filter)
         local max = find_maxi (args)
         local status, x = pcall (plugin.filter, plugin, class,
                                  table.unpack (args, 4, max))
         if not status then
            return false, x
         end
         filter = x
      end
   end
   table.insert (list, pos, {func, filter})
   return true
end

---
-- event.timer (delay:number, func:function) -> cancel:function
--
-- Creates a timer that calls function FUNC after DELAY milliseconds.
-- Returns a function that can be used to cancel the timer.
--
function event.timer (delay, func)
   local delay = check_arg ('number', 'delay', delay)
   local func = check_arg ('func', 'func', func)
   local list = engine.timer_list
   local entry = {}
   local cancel = function ()
      for i=1,#list do
         if list[i] == entry then
            table.remove (list, i)
            break
         end
      end
   end
   entry.func = func
   entry.cancel = cancel
   entry.end_time = engine.clock:get_time ('ms') + delay
   local i = 1
   while i <= #list do
      if entry.end_time < list[i].end_time then
         break
      end
      i = i + 1
   end
   table.insert (list, i, entry)
   return cancel
end

---
-- event.unregister (func:function) -> n:number
--
-- Removes all entries that contain function FUNC from the list of
-- registered event handlers.
--
-- Returns the number of entries removed from handler list.
--
function event.unregister (func)
   local func = check_arg ('func', 'func', func)
   local list = engine.handler_list
   local n, i = 0, 1
   while i <= #list do
      if list[i][1] == func then
         table.remove (list, i)
         n = n + 1
      else
         i = i + 1
      end
   end
   return n
end

---
-- event.uptime () -> ms:number
--
-- Returns the number of milliseconds elapsed since the beginning of the
-- application.
--
function event.uptime ()
   return engine.clock:get_time ('ms')
end

return event
