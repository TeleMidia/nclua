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
local ASSERT_CHECK_OBJECT = tests.ASSERT_CHECK_OBJECT
local TRACE = tests.trace

local soup = require ('nclua.event.http_soup')
_ENV = nil

local function CYCLE_UNTIL (func)
   TRACE ('cycling')
   tests.soup.cycle_until (func)
end

-- A valid URI.
local URI = 'https://github.com/telemidia/nclua/raw/master/AUTHORS'

-- Sanity checks.
local session = soup.new ()
ASSERT_ERROR (soup.request)
ASSERT_ERROR (soup.request, session)
ASSERT_ERROR (soup.request, session, 1)
ASSERT_ERROR (soup.request, session, 'GET')
ASSERT_ERROR (soup.request, session, 'GET', URI, 1)
ASSERT_ERROR (soup.request, session, 'GET', URI, {}, nil)
ASSERT_ERROR (soup.request, session, 'GET', URI, {}, '', nil)
ASSERT_ERROR (soup.request, session, 'GET', URI, {}, '', soup.new, {})
ASSERT_ERROR (soup.request, session, 'GET', URI, {}, '', soup.new, 0, {})

-- Sanity check: request an invalid URI.
ASSERT_ERROR (soup.request, session, 'GET', '<invalid-uri>', {}, '',
              function () end)

-- Sanity check: make a request with an invalid header name.
ASSERT_ERROR (soup.request, session, 'GET', URI, {['in\nvalid']='abc'}, '',
              function () end)

-- Sanity check: make a request with an invalid header value.
ASSERT_ERROR (soup.request, session, 'GET', URI, {['X-test']='\n'}, '',
              function () end)

-- Force a transport error.
local DONE = false
local function request_cb (status, soup, method, uri, code, headers, body,
                           error)
   TRACE (status, method, uri, soup, error)
   ASSERT (error ~= nil)
   DONE = true
end
session:request ('GET', 'http://www.x1x1.br', {}, '', request_cb)
CYCLE_UNTIL (function () return DONE end)

-- Force an HTTP error.
local DONE = false
local full_body = ''
local function request_cb (status, soup, method, uri, code, headers, body,
                           error)
   TRACE (status, method, uri, soup, code)
   tests.dump (headers)
   TRACE (body)
   ASSERT (status == true)
   ASSERT (code ~= 200)
   ASSERT (error == nil)
   if #body == 0 then
      DONE = true
   else
      full_body = full_body .. body
   end
end

session:request ('POST', 'http://www.puc-rio.br/404', {}, '',
                 request_cb)
CYCLE_UNTIL (function () return DONE end)

-- Make a successful request and check the response body.
local DONE = false
local full_body = ''
local function request_cb (status, soup, method, uri, code, headers, body,
                           error)
   TRACE (status, soup, method, uri, code)
   tests.dump (headers)
   ASSERT (status == true)
   ASSERT (code == 200)
   ASSERT (error == nil)
   if #body == 0 then
      DONE = true
   else
      full_body = full_body .. body
   end
end

session:request ('GET', URI, {Accept='text/plain'}, '', request_cb)
CYCLE_UNTIL (function () return DONE end)

local authors = tests.read_file (tests.mk.top_srcdir..'/AUTHORS')
ASSERT (full_body == authors)
