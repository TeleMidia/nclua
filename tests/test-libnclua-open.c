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

int
main (void)
{
  /* Check if call fails when require fails.   */
  TEST_BEGIN
  {
    lua_State *L;
    const char *saved_path;
    const char *saved_cpath;

    saved_path = g_getenv ("LUA_PATH");
    saved_cpath = g_getenv ("LUA_CPATH");
    ASSERT (g_setenv ("LUA_PATH", INVALID_PATH, TRUE));
    ASSERT (g_setenv ("LUA_CPATH", INVALID_PATH, TRUE));

    L = LUA_NEWSTATE ();
    ASSERT (nclua_open (L, 800, 600, NULL) != LUA_OK);
    TRACE ("%s", luaL_checkstring (L, -1));
    ASSERT_LUA_GETTOP (L, 1);
    lua_close (L);

    ASSERT (g_setenv ("LUA_PATH", saved_path, TRUE));
    ASSERT (g_setenv ("LUA_CPATH", saved_cpath, TRUE));
  }
  TEST_END;

  /* Check if call fails when we pass invalid canvas dimensions.  */
  TEST_BEGIN
  {
    lua_State *L;

    L = LUA_NEWSTATE ();

    ASSERT (nclua_open (L, -1, 0, NULL) != LUA_OK);
    TRACE ("%s", luaL_checkstring (L, -1));
    ASSERT_LUA_GETTOP (L, 1);
    lua_pop (L, 1);

    ASSERT (nclua_open (L, 0, -1, NULL) != LUA_OK);
    TRACE ("%s", luaL_checkstring (L, -1));
    ASSERT_LUA_GETTOP (L, 1);
    lua_pop (L, 1);

    ASSERT (nclua_open (L, -1, -1, NULL) != LUA_OK);
    TRACE ("%s", luaL_checkstring (L, -1));
    ASSERT_LUA_GETTOP (L, 1);
    lua_pop (L, 1);

    lua_close (L);
  }
  TEST_END;

  /* Check if call fails when we try to load an invalid plugin.  */
  TEST_BEGIN
  {
    lua_State *L;
    const char *unknown[] = {"unknown", NULL};
    const char *invalid[] = {"stopwatch", NULL};

    L = LUA_NEWSTATE ();

    ASSERT (nclua_open (L, 800, 600, unknown) != LUA_OK);
    TRACE ("%s", luaL_checkstring (L, -1));
    ASSERT_LUA_GETTOP (L, 1);
    lua_pop (L, 1);

    ASSERT (nclua_open (L, 800, 600, invalid) != LUA_OK);
    TRACE ("%s", luaL_checkstring (L, -1));
    ASSERT_LUA_GETTOP (L, 1);
    lua_pop (L, 1);

    lua_close (L);
  }
  TEST_END;

  /* Check valid call.  */
  TEST_BEGIN
  {
    const char *list[] = {
#if defined WITH_SOUP && WITH_SOUP
      "http",
#endif
      "key",
      "ncl",
      "pointer",
#if defined WITH_GIO && WITH_GIO
      "tcp",
#endif
      "user",
      NULL
    };
    lua_State *L;

    L = LUA_NEWSTATE ();
    ASSERT (nclua_open (L, 800, 600, list) == LUA_OK);
    ASSERT_LUA_GETTOP (L, 0);

    lua_pushvalue (L, LUA_REGISTRYINDEX);
    lua_rawgetp (L, -1, nclua_debug_get_registry_index ());
    ASSERT (lua_type (L, -1) == LUA_TTABLE);
    lua_pop (L, 2);

    ASSERT_LUA_DOSTRING (L, "assert (type (canvas) == 'userdata')");
    ASSERT_LUA_DOSTRING (L, "assert (type (event) == 'table')");
    lua_close (L);
  }
  TEST_END;

  exit (EXIT_SUCCESS);
}
