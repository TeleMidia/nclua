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
  /* Check if call fails when we pass an invalid path.  */
  TEST_BEGIN
  {
    char *errmsg = NULL;
    ASSERT (ncluaw_open (INVALID_PATH, 800, 600, NULL) == NULL);
    ASSERT (ncluaw_open (INVALID_PATH, 800, 600, &errmsg) == NULL);
    TRACE ("%s", errmsg);
    g_free (errmsg);
  }
  TEST_END;

  /* Check if call fails when we pass invalid canvas dimensions.  */
  TEST_BEGIN
  {
    char *errmsg = NULL;
    ASSERT (ncluaw_open (TOP_SRCDIR "/tests/libnclua-echo.lua", -1, 0,
                         &errmsg) == NULL);
    TRACE ("%s", errmsg);
    g_free (errmsg);
  }
  TEST_END;

  /* Check valid call.  */
  TEST_BEGIN
  {
    ncluaw_t *nw;
    char *errmsg = NULL;

    nw = ncluaw_open (TOP_SRCDIR "/tests/libnclua-echo.lua", 800, 600,
                      &errmsg);
    ASSERT (nw != NULL && errmsg == NULL);
    ncluaw_close (nw);
  }
  TEST_END;

  exit (EXIT_SUCCESS);
}
