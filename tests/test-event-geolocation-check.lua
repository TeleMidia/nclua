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

local pcall = pcall

local check = require ('nclua.event.check')
local geoloc = require ('nclua.event.geolocation')
_ENV = nil

local function ASSERT_ERROR_CHECK (t)
   local status, errmsg = pcall (geoloc.check, geoloc, t)
   ASSERT (not status)
   TRACE (errmsg)
end

-- Check bad class.
ASSERT_ERROR_CHECK {}
ASSERT_ERROR_CHECK {class='unknown'}

-- Check bad timeout.
ASSERT_ERROR_CHECK {class='geolocation', timeout={}}

-- Check bad latitude.
ASSERT_ERROR_CHECK {class='geolocation', latitude={}}

-- Check bad longitude.
ASSERT_ERROR_CHECK {class='geolocation', longitude={}}

-- Check bad altitude.
ASSERT_ERROR_CHECK {class='geolocation', altitude={}}

-- Check bad accuracy.
ASSERT_ERROR_CHECK {class='geolocation', accuracy={}}

-- Check bad speed.
ASSERT_ERROR_CHECK {class='geolocation', speed={}}

-- Check bad heading.
ASSERT_ERROR_CHECK {class='geolocation', heading={}}

-- Check valid request event.
local evt = {class='geolocation'}
ASSERT (geoloc:check (evt))

evt.timeout=33
ASSERT (geoloc:check (evt))

-- Check valid response event.
local evt = {
   class='geolocation',
   latitude=1,
   longitude=2,
   altitude=3,
   accuracy=4,
   speed=5,
   heading=6,
}
ASSERT (geoloc:check (evt))

evt.latitude=nil
ASSERT (geoloc:check (evt))

evt.longitude=nil
ASSERT (geoloc:check (evt))

evt.altitude=nil
ASSERT (geoloc:check (evt))

evt.accuracy=nil
ASSERT (geoloc:check (evt))

evt.speed=nil
ASSERT (geoloc:check (evt))

evt.heading=nil
ASSERT (geoloc:check (evt))

evt.error='unknown'
ASSERT (geoloc:check (evt))
