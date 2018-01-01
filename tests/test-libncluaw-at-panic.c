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

static jmp_buf env;

static void
panic (ncluaw_t *nw, const char *errmsg)
{
  TRACE ("%p: %s", (void *) nw, errmsg);
  longjmp (env, 1);
}

int
main (void)
{
  /* Open NCLua library, register a custom panic function, throw an error,
     and check if the correct panic function is called.  */
  TEST_BEGIN
  {
    ncluaw_t *nw;
    lua_State *L;

    nw = ncluaw_open (TOP_SRCDIR "/tests/libnclua-echo.lua", 800, 600,
                      NULL);
    ASSERT (nw != NULL);

    ASSERT (ncluaw_at_panic (nw, NULL) == NULL);
    ASSERT (ncluaw_at_panic (nw, panic) == NULL);
    ASSERT (ncluaw_at_panic (nw, NULL) == panic);
    ASSERT (ncluaw_at_panic (nw, panic) == NULL);

    L = (lua_State *) ncluaw_debug_get_lua_state (nw);
    ASSERT (ncluaw_at_panic (nw, panic) == panic);

    if (!setjmp (env))
      {
        luaL_loadstring (L, "error ('catch error')");
        lua_call (L, 0, LUA_MULTRET);
      }

    ncluaw_close (nw);
  }
  TEST_END;

  exit (EXIT_SUCCESS);
}
