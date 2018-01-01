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

local ipairs = ipairs
local table = table

local event = require ('nclua.event')
local engine = event._engine
_ENV = nil

-- Sanity checks.
ASSERT_ERROR (engine.unload, nil, {})

-- Loads the KEY, NCL, POINTER, TCP, and USER plugins, unloads them and
-- check the result.
local plugins = {'key', 'ncl', 'pointer', 'tcp', 'user'}
engine:load (table.unpack (plugins))
for _,name in ipairs (plugins) do
   ASSERT (engine.plugin_table[name],
           engine.plugin_table[name].class == name)
end

engine:unload ('ncl')
ASSERT (engine.plugin_table.ncl == nil)

engine:unload ('user')
ASSERT (engine.plugin_table.user == nil)

engine:unload (table.unpack (plugins))
for _,name in ipairs (table) do
   ASSERT (engine.plugin_table[name] == nil)
end
