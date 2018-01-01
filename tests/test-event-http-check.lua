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
along with NCLua.  If not, see <http://www.gnu.org/licenses/>.  ]]--

local tests = require ('tests')
local ASSERT = tests.ASSERT
local ASSERT_ERROR = tests.ASSERT_ERROR
local FAIL = tests.FAIL
local TRACE_SEP = tests.trace_sep
local TRACE = tests.trace

local pcall = pcall

local check = require ('nclua.event.check')
local soup = require ('nclua.event.http_soup')
local http = require ('nclua.event.http')
_ENV = nil

local function ASSERT_ERROR_CHECK (t)
   local status, errmsg = pcall (http.check, http, t)
   ASSERT (not status)
   TRACE (errmsg)
end

-- Check bad class.
ASSERT_ERROR_CHECK {}
ASSERT_ERROR_CHECK {class='unknown'}

-- Check missing or bad type.
ASSERT_ERROR_CHECK {class='http'}
ASSERT_ERROR_CHECK {class='http', type='unknown'}

-- Check missing or bad method.
ASSERT_ERROR_CHECK {class='http'}
ASSERT_ERROR_CHECK {class='http', type='request', method='unknown'}

-- Check missing or bad URI.
ASSERT_ERROR_CHECK {class='http', type='request', method='get'}
ASSERT_ERROR_CHECK {class='http', type='request', method='get', uri={}}

-- Check bad headers.
ASSERT_ERROR_CHECK {class='http', type='request', method='post',
                    uri='http://github.com/',
                    headers=function () end}

-- Check bad body.
ASSERT_ERROR_CHECK {class='http', type='request', method='post',
                    uri='http://github.com/', headers={},
                    body=function ()end}

-- Check valid request event.
local evt = {class='http', type='request', method='post',
             uri='http://www.telemidia.puc-rio.br/',
             headers={['Content-Type']='text/html'},
             body='moving', timeout=33, session={}}
ASSERT (http:check (evt))

-- Check valid response event.
local evt = {class='http', type='response', method='get',
             uri='http://www.telemidia.puc-rio.br/',
             headers={}, body='moving', session={}}
ASSERT (http:check (evt))

-- Check valid cancel event.
local evt = {class='http', type='cancel', session={}}
ASSERT (http:check (evt))
