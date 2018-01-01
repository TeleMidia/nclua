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

#define DRAW_SAMPLE                                             \
  "tests = require ('tests');"                                  \
  "canvas:attrColor ('red');"                                   \
  "canvas:clear ();"                                            \
  "aux = canvas:new (tests.canvas.get_sample ('apple-red'));"   \
  "canvas:compose (0, 0, aux);"                                 \
  "canvas:flush ();"

int
main (void)
{
  /* Call nclua_paint and check the result.  */
  TEST_BEGIN
  {
    lua_State *L;
    cairo_surface_t *src;
    cairo_surface_t *dest;
    cairo_content_t content;
    unsigned char *data;
    int w, h, s;

    L = LUA_NEWSTATE ();
    ASSERT (nclua_open (L, 50, 50, NULL) == LUA_OK);
    ASSERT_LUA_DOSTRING (L, DRAW_SAMPLE);

    src = (cairo_surface_t *) nclua_debug_get_surface (L);
    content = cairo_surface_get_content (src);
    w = cairo_image_surface_get_width (src);
    h = cairo_image_surface_get_height (src);
    s = cairo_image_surface_get_stride (src);

    dest = cairo_surface_create_similar (src, content, w, h);
    g_assert_nonnull (dest);
    data = cairo_image_surface_get_data (dest);
    nclua_paint (L, data, "ARGB32", w, h, s);

    ASSERT_LUA_DOSTRING (L, "f = tests.canvas.surface_equals");
    lua_getglobal (L, "f");
    lua_pushlightuserdata (L, src);
    lua_pushlightuserdata (L, dest);
    lua_call (L, 2, 1);
    ASSERT (lua_toboolean (L, -1));

    cairo_surface_destroy (dest);
    nclua_close (L);
    lua_close (L);
  }
  TEST_END;

  exit (EXIT_SUCCESS);
}
