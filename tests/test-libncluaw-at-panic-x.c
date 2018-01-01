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
  /* Open NCLua library and throw an error; the default panic should
     function be called; the program should abort.  */
  TEST_BEGIN
  {
    ncluaw_t *nw;
    lua_State *L;

    nw = ncluaw_open ("libnclua-echo.lua", 800, 600, NULL);
    ASSERT (nw != NULL);

    L = (lua_State *) ncluaw_debug_get_lua_state (nw);
    luaL_loadstring (L, "error ('catch error')");
    lua_call (L, 0, LUA_MULTRET);

    ncluaw_close (nw);
  }
  TEST_END;

  exit (EXIT_SUCCESS);
}
