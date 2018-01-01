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
  /* Call nclua_resize and check the result.  */
  TEST_BEGIN
  {
    lua_State *L;
    cairo_surface_t *sfc;
    int w, h;

    cairo_surface_t *new_sfc;
    int new_w, new_h;

    L = LUA_NEWSTATE ();
    ASSERT (nclua_open (L, 50, 50, NULL) == LUA_OK);
    sfc = (cairo_surface_t *) nclua_debug_get_surface (L);
    w = cairo_image_surface_get_width (sfc);
    h = cairo_image_surface_get_height (sfc);

    nclua_resize (L, w * 2, h * 2);
    new_sfc = (cairo_surface_t *) nclua_debug_get_surface (L);
    new_w = cairo_image_surface_get_width (new_sfc);
    new_h = cairo_image_surface_get_height (new_sfc);

    ASSERT (new_sfc != sfc);
    ASSERT (new_w == w * 2);
    ASSERT (new_h == h * 2);

    nclua_close (L);
    lua_close (L);
  }
  TEST_END;

  exit (EXIT_SUCCESS);
}
