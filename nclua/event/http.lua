--[[ nclua.event.http -- The HTTP event class.
     Copyright (C) 2013-2015 PUC-Rio/Laboratorio TeleMidia

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

local http

local assert = assert
local type = type

local check = require ('nclua.event.check')
local engine = require ('nclua.event.engine')
local soup = require ('nclua.event.http_soup')
_ENV = nil

do
   http = engine:new ()
   http.class = 'http'
end

-- List of supported methods.
local method_list = {'get', 'post'}

-- Checks if SESSION is is a soup object.
-- Returns SESSION if successful, otherwise throws an error.
local function check_soup (prefix, name, session)
   if not soup:is_soup (session) then
      check.throw_bad_type (prefix, name, 'soup', type (session))
   end
   return session
end

local function check_arg_soup (...)
   check_soup (check.ERR_ARG_PREFIX, ...)
end

local function check_event_soup (...)
   check_soup (check.ERR_EVENT_PREFIX, ...)
end

---
-- Checks if event EVT is a valid HTTP event.
-- Returns EVT if successful, otherwise throws an error.
--
function http:check (evt)
   assert (evt.class == http.class)
   if evt.session then
      check_event_soup ('session', evt.session)
   end
   check.event.option ('method', evt.method, method_list)
   check.event.string ('uri', evt.uri)
   check.event.table ('headers', evt.headers)
   check.event.string ('body', evt.body)
   return evt
end

---
-- Builds an HTTP event filter according to the given parameters.
-- Returns a new filter if successful, otherwise throws an error.
--
function http:filter (class, uri, method, session)
   assert (class == http.class)
   if uri ~= nil then
      check.arg.string ('uri', uri)
   end
   if method ~= nil then
      check.arg.option ('method', method, method_list)
   end
   if session ~= nil then
      check_arg_soup ('session', session)
   end
   return {class=http.class, uri=uri, method=method, session=soup}
end

---
-- Cycles the HTTP engine once.
--

-- Dispatch HTTP event EVT.
local function dispatch (evt)
   evt.class = http.class
   http.OUTQ:enqueue (evt)
end

local function request_finished (status, session, method, uri,
                                 code, headers, body)
   if status then
      dispatch {session=session, method=method, uri=uri, code=code,
                headers=headers, body=body}
   else
      dispatch {session=session, method=method, uri=uri, error=code}
   end
end

function http:cycle ()
   while not http.INQ:is_empty () do
      local evt = http.INQ:dequeue ()
      assert (evt.class == http.class)
      local session = evt.session
      if session == nil then
         session = soup:new ()
      end
      local method = assert (evt.method)
      local uri = assert (evt.uri)
      local headers = assert (evt.headers)
      local body = assert (evt.body)
      session:request (method, uri, headers, body, request_finished)
   end
   soup.cycle ()
end

return http
