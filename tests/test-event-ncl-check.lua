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
local ncl = require ('nclua.event.ncl')
_ENV = nil

local function ASSERT_ERROR_CHECK (t)
   local status, errmsg = pcall (ncl.check, ncl, t)
   ASSERT (not status)
   TRACE (errmsg)
end

-- Check bad class.
ASSERT_ERROR_CHECK {}
ASSERT_ERROR_CHECK {class='unknown'}

-- Check missing type.
ASSERT_ERROR_CHECK {class='ncl'}

-- Check bad type.
ASSERT_ERROR_CHECK {class='ncl', type='unknown'}

-- Check missing action.
ASSERT_ERROR_CHECK {class='ncl', type='attribution'}
ASSERT_ERROR_CHECK {class='ncl', type='presentation'}
ASSERT_ERROR_CHECK {class='ncl', type='selection'}

-- Check bad action.
ASSERT_ERROR_CHECK {class='ncl', type='attribution', action='unknown'}
ASSERT_ERROR_CHECK {class='ncl', type='presentation', action='unknown'}
ASSERT_ERROR_CHECK {class='ncl', type='selection', action='unknown'}

-- Check missing name or value when type='attribution'.
ASSERT_ERROR_CHECK {class='ncl', type='attribution', action='start'}
ASSERT_ERROR_CHECK {class='ncl', type='attribution', action='abort'}
ASSERT_ERROR_CHECK {class='ncl', type='attribution', action='pause', name=0}
ASSERT_ERROR_CHECK {class='ncl', type='attribution', action='abort',
                    value=0}

-- Check name or value when type='attribution'.
ASSERT_ERROR_CHECK {class='ncl', type='attribution', action='pause',
                    name={}, value='y'}
ASSERT_ERROR_CHECK {class='ncl', type='attribution', action='abort',
                    name='x', value={}}

-- Check missing label when type='presentation' or type='selection'.
ASSERT_ERROR_CHECK {class='ncl', type='presentation', action='resume'}
ASSERT_ERROR_CHECK {class='ncl', type='selection', action='stop'}

-- Check bad label when type='presentation' or type='selection'.
ASSERT_ERROR_CHECK {class='ncl', type='presentation', action='resume',
                    label={}}
ASSERT_ERROR_CHECK {class='ncl', type='selection', action='stop',
                    label=function () end}

-- Check valid NCL events.
ASSERT (ncl:check {class='ncl', type='attribution',
                   action='start', name='x', value=10})

ASSERT (ncl:check {class='ncl', type='presentation',
                   action='stop', label='y'})

ASSERT (ncl:check {class='ncl', type='selection',
                   action='stop', label=''})
