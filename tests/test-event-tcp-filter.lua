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

local socket = require ('nclua.event.tcp_socket')
local tcp = require ('nclua.event.tcp')
_ENV = nil

local function ASSERT_ERROR_FILTER (...)
   local status, errmsg = pcall (tcp.filter, tcp, ...)
   ASSERT (not status)
   TRACE (errmsg)
end

-- Check bad class.
ASSERT_ERROR_FILTER (nil)
ASSERT_ERROR_FILTER ('unknown')

-- Check bad connection.
ASSERT_ERROR_FILTER ('tcp', 0)

-- Check class-only.
local t = tcp:filter ('tcp')
ASSERT (tests.objeq (t, {class='tcp'}))

-- Check class and connection.
local sock = socket.new ()
local t = tcp:filter ('tcp', sock)
ASSERT (tests.objeq (t, {class='tcp', connection=sock}))
