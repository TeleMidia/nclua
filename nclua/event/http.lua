--[[ nclua.event.http -- The HTTP event class.
     Copyright (C) 2013-2016 PUC-Rio/Laboratorio TeleMidia

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
local pcall = pcall
local type = type

local check = require ('nclua.event.check')
local engine = require ('nclua.event.engine')
local http_soup = require ('nclua.event.http_soup')
_ENV = nil

do
   http = engine:new ()
   http.class = 'http'
end

-- List of supported types.
local type_list = {
   'request',
   'response',
   'cancel',
}

-- List of supported methods.
local method_list = {
   'connection',
   'delete',
   'get',
   'head',
   'options',
   'post',
   'put',
   'trace',
}

---
-- Checks if event EVT is a valid HTTP event.
-- Returns EVT if successful, otherwise throws an error.
--
function http:check (evt)
   assert (evt.class == http.class)
   check.event.option ('type', evt.type, type_list)
   if evt.type == 'request' or evt.type == 'response' then
      check.event.option ('method', evt.method, method_list)
      check.event.string ('uri', evt.uri)
      check.event.table ('headers', evt.headers, {})
      check.event.string ('body', evt.body, '')
      if evt.type == 'request' then
         check.event.number ('timeout', evt.timeout, 0)
      else
         check.event.boolean ('finished', evt.finished, false)
         check.event.string ('error', evt.error, '')
      end
   end
   -- The session can be anything, so there is no need to check it.
   return evt
end

---
-- Builds an HTTP event filter according to the given parameters.
-- Returns a new filter if successful, otherwise throws an error.
--
function http:filter (class, type, session)
   assert (class == http.class)
   if type ~= nil then
      check.arg.option ('type', type, type_list)
   end
   return {class=http.class, type=type, session=session}
end

---
-- Cycles the HTTP engine once.
--

-- Dispatch the HTTP response event EVT.
local function dispatch (evt)
   evt.class = http.class
   evt.type = 'response'
   http.OUTQ:enqueue (evt)
end

-- Maps user sessions to soup objects and vice versa.
local MAP = {
   _session_to_soup = {},
   _soup_to_session = {},
   bind = function (m, session, soup)
      if session == nil or soup == nil then return end
      m._session_to_soup[session] = soup
      m._soup_to_session[soup] = session
   end,
   peer = function (m, session, soup)
      assert (not (session and soup))
      if session then return m._session_to_soup[session] end
      if soup then return m._soup_to_session[soup] end
      return nil
   end,
   unbind = function (m, session, soup)
      if session == nil or soup == nil then return end
      assert (m:peer (session) == soup)
      assert (m:peer (nil, soup) == session)
      m._session_to_soup[session] = nil
      m._soup_to_session[soup] = nil
   end,
}

local function request_finished (status, soup, method, uri,
                                 code, headers, body, error)
   local method = method:lower ()
   local session = MAP:peer (nil, soup)
   local finished = nil
   if status then
      if body and #body == 0 then
         finished = true
         MAP:unbind (session, soup)
      end
   else
      MAP:unbind (session, soup)
   end
   dispatch {
      method=method,
      uri=uri,
      code=code,
      session=session,
      headers=headers,
      body=body,
      finished=finished,
      error=error,
   }
end

function http:cycle ()
   while not http.INQ:is_empty () do
      local evt = http.INQ:dequeue ()
      assert (evt.class == http.class)
      local session = evt.session
      local soup = MAP:peer (session)
      if evt.type == 'request' then
         if soup ~= nil then
            soup:cancel ()
         else
            soup = http_soup.new ()
            MAP:bind (session, soup)
         end
         local status, errmsg = pcall (http_soup.request,
                                       soup,
                                       evt.method:upper (),
                                       evt.uri,
                                       evt.headers or {},
                                       evt.body or '',
                                       request_finished,
                                       evt.timeout)
         if status == false then
            dispatch {
               method=evt.method:lower (),
               uri=evt.uri,
               code=nil,
               session=evt.session,
               headers=nil,
               body=nil,
               finished=true,
               error=errmsg
            }
            MAP:unbind (session, soup)
         end

      elseif evt.type == 'cancel' then
         if soup ~= nil then
            soup:cancel ()
            MAP:unbind (session, soup)
         end
      end
   end
   http_soup.cycle ()
end

return http
