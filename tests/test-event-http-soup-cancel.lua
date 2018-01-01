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
local FAIL = tests.FAIL
local TRACE_SEP = tests.trace_sep
local TRACE = tests.trace

local soup = require ('nclua.event.http_soup')
_ENV = nil

local function CYCLE_UNTIL (func)
   TRACE ('cycling')
   tests.soup.cycle_until (func)
end

local function CYCLE_N (n)
   CYCLE_UNTIL (function () n = n - 1; return n <= 0 end)
end

local session = soup.new ()
ASSERT_ERROR (soup.cancel)

-- Make a vacuous cancel.
ASSERT (session:cancel () == false)

-- Cancel a single request before cycling.
TRACE_SEP ()
local function request_cb (...)
   TRACE (...)
   local t = {...}
   ASSERT (t[#t] == 'Operation was cancelled')
end
session:request ('GET', 'http://github.com/', {}, '', request_cb)
ASSERT (session:cancel () == true)
CYCLE_N (10)

-- Override multiple requests before cycling.
TRACE_SEP ()
session:request ('GET', 'http://github.com/', {}, '', request_cb)
session:request ('GET', 'http://www.puc-rio.br/', {}, '', request_cb)
session:request ('GET', 'http://www.inf.puc-rio.br/', {}, '', request_cb)
session:request ('GET', 'http://telemidia.puc-rio.br/', {}, '', request_cb)
ASSERT (session:cancel () == true)
CYCLE_N (10)

-- Cancel a single request after cycling.
TRACE_SEP ()
local SERIAL = 0
local function request_cb (status, soup, method, uri, code, headers, body,
                           error)
   SERIAL = SERIAL + 1
   if SERIAL < 2 then
      ASSERT (status == true)
      TRACE (SERIAL, body)
   else
      ASSERT (status == false, error ~= nil)
      TRACE (SERIAL, error)
   end
end
session:request ('GET', 'https://github.com/', {}, '', request_cb, nil, 1)
CYCLE_UNTIL (function () return SERIAL >= 1 end)
session:cancel ()
CYCLE_N (10)

-- Override a multiple requests after cycling.
TRACE_SEP ()
local STATUS = nil
local SERIAL = 0
local function request_cb (status, ...)
   SERIAL = SERIAL + 1
   STATUS = status
   TRACE (status, ...)
end
session:request ('GET', 'https://github.com/', {}, '', request_cb, nil, 1)
CYCLE_UNTIL (function () return SERIAL == 1 end)
ASSERT (STATUS == true)
session:request ('GET', 'http://www.puc-rio.br/', {}, '', request_cb, nil, 1)
CYCLE_UNTIL (function () return SERIAL == 2 end)
ASSERT (STATUS == false)
CYCLE_UNTIL (function () return SERIAL == 3 end)
ASSERT (STATUS == true)
session:request ('GET', 'http://www.telemidia.puc-rio.br/', {}, '',
                 request_cb, nil, 1)
CYCLE_UNTIL (function () return SERIAL == 4 end)
ASSERT (STATUS == false)
CYCLE_UNTIL (function () return SERIAL == 5 end)
ASSERT (STATUS == true)
