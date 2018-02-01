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
local FAIL = tests.FAIL
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

-- Fetch project's NEWS from remote site and compare it to local NEWS.
local URI = 'https://github.com/telemidia/nclua/raw/master/NEWS'
http:send {
   class='http',
   type='request',
   method='GET',
   uri=URI,
   session=1,
}

local body = ''
while true do
   local evt = AWAIT ()
   local headers = ''
   for k,v in pairs (evt.headers or {}) do
      headers = headers .. ('%s: %s\n'):format (k,v)
   end
   TRACE('get:', evt.class, evt.type, evt.method, evt.uri, evt.session,
         headers, evt.body, evt.finished, evt.error)
   ASSERT (evt.type == 'response',
           evt.method == 'get',
           evt.uri == URI,
           evt.session == 1,
           evt.error == nil)
   body = body .. evt.body
   if evt.finished then
      break
   end
end
local readme = tests.read_file (tests.mk.top_srcdir..'/NEWS')
ASSERT (body == readme)

-- Try to cancel the previous request.
http:send {
   class='http',
   type='cancel',
   session=1,
}
http.cycle ()

-- Force some errors.
http:send {
   class='http',
   type='request',
   method='get',
   uri='invalid-uri',
}

local evt = AWAIT ()
ASSERT (evt.error and #evt.error > 0)
TRACE ('error:', evt.error)

http:send {
   class='http',
   type='request',
   method='get',
   uri='http://www.this-uri-should-not-exist.com/',
}

local evt = AWAIT ()
ASSERT (evt.error and #evt.error > 0)
TRACE ('error:', evt.error)

http:send {
   class='http',
   type='request',
   method='get',
   uri='http://www.puc-rio.br/',
   headers={x='\n\n'},
}

local evt = AWAIT ()
ASSERT (evt.error and #evt.error > 0)
TRACE ('error:', evt.error)

http:send {
   class='http',
   type='request',
   method='get',
   uri='http://www.puc-rio.br/',
   headers={['\n\n']='x'},
}

local evt = AWAIT ()
ASSERT (evt.error and #evt.error > 0)
TRACE ('error:', evt.error)

-- Force a timeout.
local tmpfile = tests.tmpname ()
local server, host, port = tests.server.new_sink (nil, tmpfile)
server:start ()
TRACE ('writing data to '..tmpfile)

http:send {
   class='http',
   type='request',
   method='GET',
   uri=('http://%s:%s'):format (host, port),
   timeout=1,
}

local evt = AWAIT ()
ASSERT (evt.error and #evt.error)
TRACE ('error:', evt.error)

os.remove (tmpfile)
server:stop ()
