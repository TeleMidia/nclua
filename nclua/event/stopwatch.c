/* nclua.event.stopwatch -- Monotonic stopwatch.
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

#include <config.h>
#include <math.h>
#include "aux-glib.h"
#include "aux-lua.h"

/* Registry key for the stopwatch metatable.  */
#define STOPWATCH "nclua.event.stopwatch"

/* Stopwatch states.  */
typedef enum _stopwatch_state_t
{
  STARTED = 0,
  STOPPED
} stopwatch_state_t;

/* Stopwatch object data.  */
typedef struct _stopwatch_t
{
  lua_Number t0;                /* time-stamp of the last start */
  stopwatch_state_t state;      /* stopwatch state */
} stopwatch_t;

/* Checks if the object at the given index is a stopwatch.  */
#define stopwatch_check(L, index)\
  (stopwatch_t *) luaL_checkudata (L, index, STOPWATCH)

/* Returns a monotonic time-stamp in microseconds.  */

static inline lua_Number
get_monotonic_time (void)
{
  gint64 us;
  us = g_get_monotonic_time ();
  return (lua_Number) us;
}

/*-
 * stopwatch.new ()
 * stopwatch:new ()
 *          -> stopwatch:userdata
 *
 * Creates and returns a new stopwatch object.
 */
static int
l_stopwatch_new (lua_State *L)
{
  stopwatch_t *clock;

  luax_optudata (L, 1, STOPWATCH);
  clock = (stopwatch_t *) lua_newuserdata (L, sizeof (*clock));
  g_assert_nonnull (clock);
  clock->t0 = 0;
  clock->state = STOPPED;
  luaL_setmetatable (L, STOPWATCH);

  return 1;
}

/*-
 * stopwatch:get_state () -> state:string
 *
 * Returns the state of the given stopwatch: 'started' or 'stopped'.
 */
static int
l_stopwatch_get_state (lua_State *L)
{
  stopwatch_t *clock;

  clock = stopwatch_check (L, 1);
  switch (clock->state)
    {
    case STARTED:
      lua_pushliteral (L, "started");
      break;
    case STOPPED:
      lua_pushliteral (L, "stopped");
      break;
    default:
      g_assert_not_reached ();
    }

  return 1;
}

/*-
 * stopwatch:get_time ([unit:string]) -> time:number
 *
 * Gets the time elapsed since last start, for the given stopwatch.
 * The UNIT parameter controls the time unit of the returned value.
 *
 * The following UNIT strings are supported:
 *   s  - seconds;
 *   ms - milliseconds;
 *   us - microseconds.
 */
static int
l_stopwatch_get_time (lua_State *L)
{
  static const char *const unit_list[] = {"us", "ms", "s", NULL};
  stopwatch_t *clock;
  int unit;

  clock = stopwatch_check (L, 1);
  unit = luaL_checkoption (L, 2, "us", unit_list);

  if (clock->state == STOPPED)
    {
      lua_pushnumber (L, 0);
      return 1;
    }
  else
    {
      lua_Number dt;
      dt = get_monotonic_time () - clock->t0;
      lua_pushnumber (L, dt / pow (1000, unit));
      return 1;
    }
}

/*-
 * stopwatch:start ()
 *
 * Starts the given stopwatch.
 */
static int
l_stopwatch_start (lua_State *L)
{
  stopwatch_t *clock;

  clock = stopwatch_check (L, 1);
  clock->state = STARTED;
  clock->t0 = get_monotonic_time ();

  return 1;
}

/*-
 * stopwatch:stop ()
 *
 * Stops the given stopwatch.
 */
static int
l_stopwatch_stop (lua_State *L)
{
  stopwatch_t *clock;

  clock = stopwatch_check (L, 1);
  clock->state = STOPPED;
  clock->t0 = 0;

  return 1;
}

static const struct luaL_Reg funcs[] = {
  {"new", l_stopwatch_new},
  {"get_state", l_stopwatch_get_state},
  {"get_time", l_stopwatch_get_time},
  {"start", l_stopwatch_start},
  {"stop", l_stopwatch_stop},
  {NULL, NULL}
};

int luaopen_nclua_event_stopwatch (lua_State *L);

int
luaopen_nclua_event_stopwatch (lua_State *L)
{
  G_TYPE_INIT_WRAPPER ();
  luax_newmetatable (L, STOPWATCH);
  luaL_setfuncs (L, funcs, 0);
  return 1;
}
