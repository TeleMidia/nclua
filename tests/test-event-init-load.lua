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
local TRACE_SEP = tests.trace_sep
local TRACE = tests.trace

local event = require ('nclua.event')
local engine = event._engine
_ENV = nil

-- Sanity checks.
ASSERT_ERROR (engine.load, nil, {})
ASSERT_ERROR (engine.load, nil, 'unknown') -- no such plugin
ASSERT_ERROR (engine.load, nil, 'socket')  -- not an event plugin

-- Check if, initially, the engine.plugin_table is empty.
ASSERT (tests.objeq (engine.plugin_table, {}))

-- Load TCP plugin and check the result.
engine:load ('tcp')
ASSERT (engine.plugin_table.tcp, engine.plugin_table.tcp.class == 'tcp')

-- Load KEY and USER plugins and check the result.
engine:load ('key', 'user')
ASSERT (engine.plugin_table.key, engine.plugin_table.key.class == 'key')
ASSERT (engine.plugin_table.user, engine.plugin_table.user.class == 'user')
