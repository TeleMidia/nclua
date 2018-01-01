/* Copyright (C) 2013-2018 PUC-Rio/Laboratorio TeleMidia

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
along with NCLua.  If not, see <https://www.gnu.org/licenses/>.  */

#include "tests.h"

#define PNGFILE "test-libnclua-debug-dump.png"

int
main (void)
{
  /* Check bad path.  */
  TEST_BEGIN
  {
    lua_State *L;
    int err;

    L = LUA_NEWSTATE ();
    ASSERT (nclua_open (L, 50, 50, NULL) == LUA_OK);
    err = nclua_debug_dump_surface (L, INVALID_PATH);
    ASSERT (err != LUA_OK);
    TRACE ("%s", luaL_checkstring (L, -1));
    ASSERT_LUA_GETTOP (L, 1);
    lua_pop (L, 1);
    nclua_close (L);
    lua_close (L);
  }
  TEST_END;

  /* Open NCLua library and dump the resulting surface.  */
  TEST_BEGIN
  {
    lua_State *L;
    int err;

    L = LUA_NEWSTATE ();
    ASSERT (nclua_open (L, 50, 50, NULL) == LUA_OK);
    err = nclua_debug_dump_surface (L, PNGFILE);
    ASSERT (err == LUA_OK);
    ASSERT_LUA_GETTOP (L, 0);
    nclua_close (L);
    lua_close (L);
  }
  TEST_END;

  exit (EXIT_SUCCESS);
}
