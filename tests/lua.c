/* lua -- A simple Lua interpreter to run the tests.
   Copyright (C) 2013-2018 Free Software Foundation, Inc.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.  */

#ifdef HAVE_CONFIG_H
# include <config.h>
#endif
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

int
main (int argc, const char **argv)
{
  lua_State *L;
  int i;
  int status;

  if (argc != 2)
    {
      fprintf (stderr, "usage: lua FILE\n");
      exit (1);
    }

  L = luaL_newstate ();
  assert (L != NULL);           /* out of memory */
  luaL_openlibs (L);
  lua_newtable (L);
  for (i = 0; i < argc; i++)
    {
      lua_pushstring (L, argv[i]);
      lua_rawseti (L, -2, i);
    }
  lua_setglobal (L, "arg");

  status = luaL_loadfile (L, argv[1]) || lua_pcall (L, 0, 0, 0);
  if (status != 0)
    {
      fprintf (stderr, "error: %s\n", lua_tostring (L, -1));
    }

  lua_close (L);
  exit (status);
}
