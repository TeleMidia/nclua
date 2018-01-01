--[[ Copyright (C) 2008 PUC-Rio/Laboratorio Telemidia/LabLua
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

-- Originally written by Francisco Sant'Anna.
-- Updated by Guilherme F. Lima.

-- TODO: Add support to re-entrant tcp.execute() calls.

local tcp = {}

local assert = assert
local coroutine = coroutine
local pairs = pairs

local event = event
_ENV = nil

-- Table of pending connection requests.  Maps a co-routine object to a
-- table of the form {host=HOST,port=PORT}.
local PENDING = {}

-- Table of established connections.  ESTABLISH maps a co-routine object to
-- a connection id; ESTABLISH_REV maps a connection id to a co-routine
-- object.
local ESTABLISHED = {}
local ESTABLISHED_REV = {}

-- Resumes co-routine CO with the given arguments.
-- If CO is dead removes it from the table of established connections.
local function resume (co, ...)
   assert (coroutine.status (co) == 'suspended')
   assert (coroutine.resume (co, ...))
   if coroutine.status (co) == 'dead' then
      local conn = ESTABLISHED[co]
      if ESTABLISHED[co] then
         ESTABLISHED[co] = nil
      end
      if ESTABLISHED_REV[conn] then
         ESTABLISHED_REV[conn] = nil
      end
   end
end

-- Returns the current co-routing and its associated connection.
local function current ()
   local co = assert (coroutine.running ())
   return co, assert (ESTABLISHED[co])
end

---
-- Executes function F under blocking TCP context.
--
function tcp.execute (f, ...)
   resume (coroutine.create (f), ...)
end

---
-- Connects to host HOST at port PORT.
-- Returns true if successful, otherwise returns false plus error message.
--
local function connect_finished (e)
   for co, t in pairs (PENDING) do
      if t.host == e.host and t.port == e.port then
         PENDING[co] = nil
         if e.error == nil then
            ESTABLISHED[co] = e.connection
            ESTABLISHED_REV[e.connection] = co
            resume (co, true)   -- success
         else
            resume (co, false, e.error) -- failure
         end
         return true            -- consume event
      end
   end
   return false
end
event.register (connect_finished, {class='tcp', type='connect'})

function tcp.connect (host, port, timeout)
   local co = assert (coroutine.running ())
   PENDING[co] = {
      host = host,
      port = port,
   }
   local status, errmsg = event.post {
      class = 'tcp',
      type = 'connect',
      host = host,
      port = port,
      timeout = timeout,
   }
   if status == false then
      return false, errmsg
   end
   return coroutine.yield ()
end

---
-- Closes the current connection.
-- Returns true if successful, otherwise returns false plus error message.
--
local function disconnect_finished (e)
   local co = ESTABLISHED_REV[e.connection]
   if co == nil then
      return false              -- nothing to do
   end
   resume (co, e.error == nil, e.error)
   return true                  -- consume event
end
event.register (disconnect_finished, {class='tcp', type='disconnect'})

function tcp.disconnect (data)
   local _, conn = current ()
   return event.post {
      class = 'tcp',
      type = 'disconnect',
      connection = conn,
   }
end

---
-- Sends data DATA over the current connection.
-- Returns true if successful, otherwise returns false plus error message.
--
function tcp.send (data)
   local _, conn = current ()
   return event.post {
      class = 'tcp',
      type = 'data',
      connection = conn,
      value = data,
   }
end

---
-- Receives data form the current connection.
-- Returns the received data if successful, otherwise returns false plus
-- error message.
--
local function receive_finished (e)
   local co = ESTABLISHED_REV[e.connection]
   if co == nil then
      return false              -- nothing to do
   end
   if e.error == nil then
      resume (co, e.value)
   else
      resume (co, false, e.error)
   end
   return true                  -- consume event
end
event.register (receive_finished, {class='tcp', type='data'})

function tcp.receive ()
   local co, _ = current ()
   return coroutine.yield (co)
end

return tcp
