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

local soup = require ('nclua.event.http_soup')
_ENV = nil

-- Check the returned soup object type.
local session = soup.new ()
ASSERT_CHECK_OBJECT (session, 'nclua.event.http_soup')

-- Check variations to the 'new' call.
ASSERT (soup.new ())
ASSERT (soup.new (0))
ASSERT (soup:new ())
ASSERT (soup:new (0))
ASSERT (session.new ())
ASSERT (session.new (0))
ASSERT (session:new ())
ASSERT (session:new (0))
