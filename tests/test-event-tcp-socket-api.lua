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
local ASSERT_CHECK_API = tests.ASSERT_CHECK_API

local socket = require ('nclua.event.tcp_socket')
_ENV = nil

ASSERT_CHECK_API {
   socket,
   __gc = 'function',
   __index = 'table',
   __metatable = 'string',
   connect = 'function',
   cycle = 'function',
   disconnect = 'function',
   is_connected = 'function',
   is_socket = 'function',
   new = 'function',
   receive = 'function',
   send = 'function',
}
