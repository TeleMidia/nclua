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

static ncluaw_event_t *
alloc_key_event (const char *type, const char *key)
{
  ncluaw_event_t evt;
  evt.cls = NCLUAW_EVENT_KEY;
  evt.u.key.type = type;
  evt.u.key.key = key;
  return ncluaw_event_clone (&evt);
}

static ncluaw_event_t *
alloc_ncl_event (const char *type, const char *action, const char *name,
                 const char *value)
{
  ncluaw_event_t evt;
  evt.cls = NCLUAW_EVENT_NCL;
  evt.u.ncl.type = type;
  evt.u.ncl.action = action;
  evt.u.ncl.name = name;
  evt.u.ncl.value = value;
  return ncluaw_event_clone (&evt);
}

static ncluaw_event_t *
alloc_pointer_event (const char *type, int x, int y)
{
  ncluaw_event_t evt;
  evt.cls = NCLUAW_EVENT_POINTER;
  evt.u.pointer.type = type;
  evt.u.pointer.x = x;
  evt.u.pointer.y = y;
  return ncluaw_event_clone (&evt);
}

static ncluaw_event_t *event_list[9];

static void
event_list_init (void)
{
  int i = 0;
  event_list[i++] = alloc_key_event ("press", "0");
  event_list[i++] = alloc_ncl_event ("attribution", "start", "x", "y");
  event_list[i++] = alloc_pointer_event ("move", 0, 0);

  event_list[i++] = alloc_key_event ("release", "13");
  event_list[i++] = alloc_ncl_event ("selection", "start", "abc", NULL);
  event_list[i++] = alloc_pointer_event ("press", -13, 23);

  event_list[i++] = alloc_key_event ("press", "abc");
  event_list[i++] = alloc_ncl_event ("presentation", "abort", "y", NULL);
  event_list[i++] = alloc_pointer_event ("release", 1024, -1024);
}

static void
event_list_fini (void)
{
  size_t i;
  for (i = 1; i < nelementsof (event_list); i++)
    ncluaw_event_free (event_list[i]);
}

int
main (void)
{
  /* Push events in event_list array, cycle the engine,
     and check if they are echoed back.  */
  TEST_BEGIN
  {
    ncluaw_t *nw;
    char *errmsg = NULL;
    size_t i;

    nw = ncluaw_open (TOP_SRCDIR "/tests/test-libncluaw-cycle.lua",
                      800, 600, &errmsg);
    ASSERT (nw != NULL && errmsg == NULL);

    event_list_init ();
    for (i = 0; i < nelementsof (event_list); i++)
      {
        const ncluaw_event_t *sent;
        ncluaw_event_t *recv;

        sent = event_list[i];
        ncluaw_send (nw, sent);
        ncluaw_cycle (nw);
        recv = ncluaw_receive (nw);
        ASSERT (recv != NULL);
        ASSERT (sent != recv && ncluaw_event_equals (sent, recv));
        ncluaw_event_free (recv);
        ASSERT (ncluaw_receive (nw) == NULL);
      }
    event_list_fini ();

    ncluaw_close (nw);
  }
  TEST_END;

  exit (EXIT_SUCCESS);
}
