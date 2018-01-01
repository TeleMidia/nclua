/* tests.h -- Common declarations for tests.
   Copyright (C) 2013-2018 PUC-Rio/Laboratorio TeleMidia

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

#ifndef TESTS_H
#define TESTS_H

#include <config.h>
#include <ctype.h>
#include <errno.h>
#include <float.h>
#include <limits.h>
#include <math.h>
#include <setjmp.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include "aux-glib.h"
PRAGMA_DIAG_IGNORE (-Woverlength-strings)
#include "aux-lua.h"
#include <cairo.h>

#include "nclua.h"
#include "ncluaw.h"

#ifdef __MINGW32__
# define INVALID_PATH "invalid:/invalid"
#else
# define INVALID_PATH "/invalid/invalid"
#endif

#define TEST_BEGIN TRACE_SEP (); G_STMT_START
#define TEST_END   G_STMT_END

#define ASSERT(cond)                                            \
  G_STMT_START                                                  \
  {                                                             \
   if (unlikely (!(cond)))                                      \
     {                                                          \
      fprintf (stderr, "%s:%d: ASSERTION FAILED!\n--> %s\n",    \
               __FILE__, __LINE__, G_STRINGIFY (cond));         \
      abort ();                                                 \
     }                                                          \
  }                                                             \
  G_STMT_END

#define ASSERT_LUA_DOSTRING(L, s) ASSERT (luaL_dostring (L, s) == 0)
#define ASSERT_LUA_GETTOP(L, i)   ASSERT (lua_gettop (L) == i)

/*-
 * Creates and returns a new Lua state with standard libraries opened.
 */
static G_GNUC_UNUSED inline lua_State *
LUA_NEWSTATE (void)
{
  lua_State *L;
  L = luaL_newstate ();
  luaL_openlibs (L);
  return L;
}

/*-
 * Outputs arguments to stdout prefixed with a time-stamp.
 */
static G_GNUC_UNUSED
G_GNUC_PRINTF (1, 2)
     void TRACE (const char *format, ...)
{
  static gint64 t0 = -1;
  gint64 dt;
  va_list args;

  if (unlikely (t0 < 0))
    {
      t0 = g_get_monotonic_time ();
    }
  dt = g_get_monotonic_time () - t0;

  va_start (args, format);
  printf ("[%gms]\t", ((double) dt) / 1000);
  vprintf (format, args);
  putc ('\n', stdout);
  fflush (stdout);
  va_end (args);
}

/*-
 * Outputs a numbered entry separator.
 */
static G_GNUC_UNUSED void
TRACE_SEP (void)
{
  static int n = 1;
  printf ("#%d\t", n++);
  printf ("-----------------------------------");
  printf ("-----------------------------------");
  putc ('\n', stdout);
  fflush (stdout);
}

#endif /* TESTS_H */
