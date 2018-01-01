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
  /* Open NCLua library and check the resulting surface.  */
  TEST_BEGIN
  {
    lua_State *L;
    cairo_surface_t *sfc, *wsfc;

    L = LUA_NEWSTATE ();
    ASSERT (nclua_open (L, 800, 600, NULL) == LUA_OK);

    sfc = (cairo_surface_t *) nclua_debug_get_surface (L);
    TRACE ("%p", (void *) sfc);

    wsfc = (cairo_surface_t *) ncluaw_debug_get_surface ((ncluaw_t *) L);
    TRACE ("%p", (void *) wsfc);

    ASSERT (sfc == wsfc);

    nclua_close (L);
    lua_close (L);
  }
  TEST_END;

  exit (EXIT_SUCCESS);
}
