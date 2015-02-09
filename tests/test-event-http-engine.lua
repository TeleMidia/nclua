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

local tests = require ('tests')
local ASSERT = tests.ASSERT
local ASSERT_ERROR = tests.ASSERT_ERROR
local FAIL = tests.fail
local TRACE_SEP = tests.trace_sep
local TRACE = tests.trace

local os = os
local pairs = pairs

local http = require ('nclua.event.http')
_ENV = nil

local function AWAIT ()
   TRACE ('cycling')
   local evt = nil
   repeat
      http:cycle ()
      evt = http:receive ()
   until evt ~= nil
   return evt
end

-- Fetch project's README from remote site and compare it to local README.
http:send {
   class='http',
   method='GET',
   uri='https://github.com/gflima/nclua/raw/master/README.md',
}

local evt = AWAIT ()
local headers = ''
for k,v in pairs (evt.headers) do
   headers = headers .. ('%s: %s\n'):format (k,v)
end
TRACE('get:', evt.class, evt.method, evt.uri, evt.session,
      headers, evt.body)
local readme = tests.read_file (tests.mk.top_srcdir..'/README.md')
ASSERT (evt.body == readme)

-- Force an error.
http:send {
   class='http',
   method='GET',
   uri='http://www.this-uri-should-be-invalid.com.br/',
}

local evt = AWAIT ()
ASSERT (evt.error and #evt.error > 0)
TRACE ('error:', evt.error)

-- Force a timeout.
local tmpfile = os.tmpname ()
local server, host, port = tests.server.new_sink (nil, tmpfile)
server:start ()
TRACE ('writing data to '..tmpfile)

http:send {
   class='http',
   method='GET',
   uri=('http://%s:%s'):format (host, port),
   timeout=1,
}

local evt = AWAIT ()
ASSERT (evt.error and #evt.error)
TRACE ('error:', evt.error)

os.remove (tmpfile)
server:stop ()
