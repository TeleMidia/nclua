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

local dir = require ('nclua.dir')
_ENV = nil

-- Sanity checks.
ASSERT_ERROR (dir.test)
ASSERT_ERROR (dir.test, nil)
ASSERT_ERROR (dir.test, {})
ASSERT_ERROR (dir.test, function()end)
ASSERT_ERROR (dir.test, '', {})
ASSERT_ERROR (dir.test, '', function()end)

-- Check bad query.
ASSERT_ERROR (dir.test, '', '*** invalid ***')

-- Check empty path.
ASSERT (dir.test ('') == false)
ASSERT (dir.test ('', 'directory') == false)

-- Check successful queries.
ASSERT (dir.test ('.', 'directory'))
ASSERT (dir.test ('.', 'exists'))
ASSERT (dir.test ('.'))
ASSERT (dir.test (tests.mk.top_srcdir, 'directory'))
ASSERT (dir.test (tests.mk.top_srcdir, 'exists'))
ASSERT (dir.test (tests.mk.top_srcdir))
ASSERT (dir.test (tests.mk.top_srcdir..'/tests/Makefile', 'regular'))
ASSERT (dir.test (tests.mk.top_srcdir..'/tests/Makefile', 'exists'))
ASSERT (dir.test (tests.mk.top_srcdir..'/tests/Makefile'))

-- Check unsuccessful queries.
ASSERT (dir.test ('nonexistent') == false)
ASSERT (dir.test ('nonexistent', 'directory') == false)
ASSERT (dir.test ('nonexistent', 'executable') == false)
ASSERT (dir.test ('nonexistent', 'exists') == false)
ASSERT (dir.test ('nonexistent', 'regular') == false)
ASSERT (dir.test ('nonexistent', 'symlink') == false)

ASSERT (dir.test ('.', 'regular') == false)
ASSERT (dir.test (tests.mk.top_srcdir, 'symlink') == false)
ASSERT (dir.test (tests.mk.top_srcdir, 'regular') == false)
ASSERT (dir.test (tests.mk.top_srcdir..'/tests/Makefile', 'directory')
           == false)
ASSERT (dir.test (tests.mk.top_srcdir..'/tests/Makefile', 'executable')
           == false)
