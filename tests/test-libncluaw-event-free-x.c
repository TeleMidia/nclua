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
  /* Check if call aborts when we pass it an invalid event.  */
  TEST_BEGIN
  {
    ncluaw_event_t evt, *dup;
    evt.cls = NCLUAW_EVENT_KEY;
    evt.u.key.type = "press";
    evt.u.key.key = "x";
    dup = ncluaw_event_clone (&evt);
    dup->cls = NCLUAW_EVENT_UNKNOWN;
    ncluaw_event_free (dup);
  }
  TEST_END;

  exit (EXIT_SUCCESS);
}
