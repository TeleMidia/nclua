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
main (int argc, char *const *argv)
{
  lua_State *L;

  if (argc != 2)
    {
      fprintf (stderr, "usage: libnclua-echo EVENT\n");
      exit (EXIT_FAILURE);
    }

  L = LUA_NEWSTATE ();
  ASSERT (nclua_open (L, 0, 0, NULL) == LUA_OK);
  if (unlikely (luaL_dofile (L, TOP_SRCDIR "/tests/libnclua-echo.lua")))
    goto fail;

  lua_pushfstring (L, "evt = %s", argv[1]);
  if (unlikely (luaL_dostring (L, lua_tostring (L, -1)) != 0))
    goto fail;

  lua_getglobal (L, "evt");
  nclua_send (L);
  nclua_cycle (L);
  nclua_receive (L);
  lua_setglobal (L, "evt");
  if (unlikely (luaL_dostring (L, "dump (evt)") != 0))
    goto fail;

  fputc ('\n', stdout);

  nclua_close (L);
  lua_close (L);
  exit (EXIT_SUCCESS);

 fail:
  fprintf (stderr, "error: %s\n", lua_tostring (L, -1));
  nclua_close (L);
  lua_close (L);
  exit (EXIT_FAILURE);
}
