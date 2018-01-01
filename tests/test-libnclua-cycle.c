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

#define ECHO_HANDLER \
  "event.register (function (evt) assert (event.post (evt)) end)"

int
main (void)
{
  /* Push N events, cycle the engine, and check if they are echoed back.  */
  TEST_BEGIN
  {
    lua_State *L;
    int n = 1024;
    int i;

    L = LUA_NEWSTATE ();
    ASSERT (nclua_open (L, 800, 600, NULL) == LUA_OK);
    ASSERT_LUA_DOSTRING (L, ECHO_HANDLER);

    for (i = 0; i < n; i++)
      {
        lua_pushinteger (L, i);
        nclua_send (L);
        ASSERT_LUA_GETTOP (L, 0);

        nclua_cycle (L);

        nclua_receive (L);
        ASSERT_LUA_GETTOP (L, 1);
        ASSERT (luaL_checkint (L, -1) == i);
        lua_pop (L, 1);
      }
    nclua_close (L);
    lua_close (L);
  }
  TEST_END;

  exit (EXIT_SUCCESS);
}
