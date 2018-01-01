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
    cairo_surface_t *sfc;

    L = LUA_NEWSTATE ();
    ASSERT (nclua_open (L, 800, 600, NULL) == LUA_OK);
    sfc = (cairo_surface_t *) nclua_debug_get_surface (L);
    TRACE ("%p", (void *) sfc);
    ASSERT (sfc != NULL);
    ASSERT (cairo_surface_status (sfc) == CAIRO_STATUS_SUCCESS);
    ASSERT (cairo_image_surface_get_width (sfc) == 800);
    ASSERT (cairo_image_surface_get_height (sfc) == 600);
    ASSERT_LUA_GETTOP (L, 0);
    nclua_close (L);
    lua_close (L);
  }
  TEST_END;

  exit (EXIT_SUCCESS);
}
