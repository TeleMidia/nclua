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
  /* Check valid call.  */
  TEST_BEGIN
  {
    ncluaw_event_t evt;
    ncluaw_event_t *dup;

    evt.cls = NCLUAW_EVENT_KEY;
    evt.u.key.type = "press";
    evt.u.key.key = "5";
    dup = ncluaw_event_clone (&evt);
    ASSERT (dup != NULL);
    ASSERT (dup->cls == evt.cls);
    ASSERT (dup->u.key.type != evt.u.key.type);
    ASSERT (g_str_equal (dup->u.key.type, evt.u.key.type));
    ASSERT (dup->u.key.key != evt.u.key.key);
    ASSERT (g_str_equal (dup->u.key.key, evt.u.key.key));
    ncluaw_event_free (dup);

    evt.cls = NCLUAW_EVENT_NCL;
    evt.u.ncl.type = "attribution";
    evt.u.ncl.action = "start";
    evt.u.ncl.name = "x";
    evt.u.ncl.value = "y";
    dup = ncluaw_event_clone (&evt);
    ASSERT (dup != NULL);
    ASSERT (dup->cls == evt.cls);
    ASSERT (dup->u.ncl.type != evt.u.ncl.type);
    ASSERT (g_str_equal (dup->u.ncl.type, evt.u.ncl.type));
    ASSERT (dup->u.ncl.action != evt.u.ncl.action);
    ASSERT (g_str_equal (dup->u.ncl.action, evt.u.ncl.action));
    ASSERT (dup->u.ncl.name != evt.u.ncl.name);
    ASSERT (g_str_equal (dup->u.ncl.name, evt.u.ncl.name));
    ASSERT (dup->u.ncl.value != evt.u.ncl.value);
    ASSERT (g_str_equal (dup->u.ncl.value, evt.u.ncl.value));
    ncluaw_event_free (dup);

    evt.cls = NCLUAW_EVENT_POINTER;
    evt.u.pointer.type = "move";
    evt.u.pointer.x = 50;
    evt.u.pointer.y = 44;
    dup = ncluaw_event_clone (&evt);
    ASSERT (dup != NULL);
    ASSERT (dup->cls == evt.cls);
    ASSERT (dup->u.pointer.type != evt.u.pointer.type);
    ASSERT (g_str_equal (dup->u.pointer.type, evt.u.pointer.type));
    ASSERT (dup->u.pointer.x == evt.u.pointer.x);
    ASSERT (dup->u.pointer.y == evt.u.pointer.y);
    ncluaw_event_free (dup);
  }
  TEST_END;

  exit (EXIT_SUCCESS);
}
