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

-- Written by Guilherme F. Lima.

-- TODO: Add support to re-entrant http.execute() calls.

local http = {}

local assert = assert
local coroutine = coroutine

local event = event
_ENV =nil

-- Maps a co-routine to the response headers and body so far collected.
local DATA = {}

-- Resumes co-routine CO with the given arguments.
-- If CO is dead remove it from the DATA table.
local function resume (co, ...)
   assert (coroutine.status (co) == 'suspended')
   assert (coroutine.resume (co, ...))
   if coroutine.status (co) == 'dead' then
      DATA[co] = nil
   end
end

-- Returns the current co-routing.
local function current ()
   return assert (coroutine.running ())
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
   local co = assert (e.session)
   if e.error then
      resume (co, false, e.error)
   else
      if e.headers then
         DATA[co].headers = e.headers
      end
      if e.body then
         DATA[co].body = DATA[co].body .. e.body
      end
      if e.finished then
         resume (co, true, e.code, DATA[co].headers, DATA[co].body)
      end
   end
   return true                  -- consume event
end
event.register (request_finished, {class='http', type='response'})

function http.request (method, uri, headers, body)
   local co = current ()
   DATA[co] = {headers={}, body=''}
   local status, errmsg = event.post {
      class='http',
      type='request',
      method=method,
      uri=uri,
      headers=headers,
      body=body,
      session=co,
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
