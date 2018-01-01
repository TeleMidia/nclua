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
  /* Check valid call.  */
  TEST_BEGIN
  {
    lua_State *L;
    void *p;

    L = LUA_NEWSTATE ();
    ASSERT (nclua_open (L, 800, 600, NULL) == LUA_OK);
    nclua_close (L);
    ASSERT_LUA_GETTOP (L, 0);

    p = nclua_debug_get_registry_index ();
    lua_pushvalue (L, LUA_REGISTRYINDEX);
    lua_rawgetp (L, -1, p);
    ASSERT (lua_isnil (L, -1));

    lua_close (L);
    exit (EXIT_SUCCESS);
  }
  TEST_END;

  exit (EXIT_SUCCESS);
}
