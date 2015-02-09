--[[ Copyright (C) 2013-2015 PUC-Rio/Laboratorio TeleMidia

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
along with NCLua.  If not, see <http://www.gnu.org/licenses/>.  ]]--

-- Written by Guilherme F. Lima.

-- TODO: Add support to re-entrant http.execute() calls.

local http = {}

local assert = assert
local coroutine = coroutine
local pairs = pairs

local event = event
_ENV =nil

-- Maps a co-routine object to a table of the form {uri=URI, method=METHOD,
-- session=SESSION}.
local SESSIONS = {}

-- Resumes co-routine CO with the given arguments.
-- If CO is dead remove it from the SESSIONS table.
local function resume (co, ...)
   assert (coroutine.status (co) == 'suspended')
   assert (coroutine.resume (co, ...))
   if coroutine.status (co) == 'dead' then
      SESSIONS[co] = nil
   end
end

-- Returns the current co-routing and its associated connection (if any).
local function current ()
   local co = assert (coroutine.running ())
   return co, SESSIONS[co]
end

---
-- Execute function F under HTTP context.
--
function http.execute (f, ...)
   resume (coroutine.create (f), ...)
end

---
-- Makes an HTTP request with method METHOD, headers HEADERS, and body BODY
-- to the given URI.  If successful, returns true, the response code, and
-- the response headers and body.  Otherwise, returns false plus error
-- message.
--
local function request_finished (e)
   local co = nil
   for _co,t in pairs (SESSIONS) do
      if t.session == e.session
      or (t.uri == e.uri and t.method == e.method) then
         co = _co
         if t.session == nil then -- register session
            t.session = e.session
         end
         break
      end
   end
   if co == nil then
      return false              -- nothing to do
   end
   if e.error == nil then
      resume (co, true, e.code, e.headers, e.body)
   else
      resuem (co, false, e.error)
   end
   return true                  -- consume event
end
event.register (request_finished, {class='http'})

function http.request (method, uri, headers, body)
   local co, t = current ()
   if t == nil then
      t = {method=method, uri=uri}
      SESSIONS[co] = t
   end
   local status, errmsg = event.post {
      class='http',
      method=method,
      uri=uri,
      headers=headers,
      body=body,
      session=t.session
   }
   if status == false then
      return false, errmsg
   end
   return coroutine.yield (co)
end

---
-- Alias to http.request ('get', ...).
--
function http.get (uri, headers, body)
   return http.request ('get', uri, headers, body)
end

---
-- Alias to http.request ('post', ...).
--
function http.post (uri, headers, body)
   return http.request ('post', uri, headers, body)
end

return http
