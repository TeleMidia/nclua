/* ncluaw.c -- The NCLua wrapper (Lua-free) interface.
   Copyright (C) 2013-2015 PUC-Rio/Laboratorio TeleMidia

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
along with NCLua.  If not, see <http://www.gnu.org/licenses/>.  */

#include <config.h>
#include <string.h>

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

#include "macros.h"
#include "luax-macros.h"

#include "nclua.h"
#include "ncluaw.h"

/* NCLua wrapper local registry.  */
static const int _ncluaw_magic = 0;
#define NCLUAW_REGISTRY_INDEX (deconst (void *, &_ncluaw_magic))

#define ncluaw_registry_create(L)\
  luax_mregistry_create (L, NCLUAW_REGISTRY_INDEX)

#define ncluaw_registry_destroy(L)\
  luax_mregistry_destroy (L, NCLUAW_REGISTRY_INDEX)

#define ncluaw_registry_get_field(L, field)\
  luax_mregistry_getfield (L, NCLUAW_REGISTRY_INDEX, field)

#define ncluaw_registry_set_field(L, field)\
  luax_mregistry_setfield (L, NCLUAW_REGISTRY_INDEX, field)

/* List of NCLua Event plugins to be loaded by ncluaw_open().  */
static const char *plugin_list[] = {
  "key", "ncl", "pointer", "tcp", "user", NULL
};

/* Fail-safe malloc.  */
static void *
xmalloc (size_t n)
{
  void *p;
  p = malloc (n);
  assert (p != NULL);
  return p;
}

/* Fail-safe xstrdup.  */
static char *
xstrdup (const char *s)
{
  size_t n;
  char *dup;
  assert (s != NULL);
  n = strlen (s) + 1;
  dup = (char *) xmalloc (sizeof (*dup) * n);
  return (char *) memcpy (dup, s, n);
}

/* Returns the class of event at index INDEX.  If the object at the given
   index is not a known event, returns NCLUAW_EVENT_UNKNOWN.  */

static ncluaw_event_class_t
get_event_class (lua_State *L, int index)
{
  static const char *known_class_list[] = {"key", "ncl", "pointer"};
  ncluaw_event_class_t result;
  const char *name;
  size_t i;

  if (lua_type (L, index) != LUA_TTABLE)
    return NCLUAW_EVENT_UNKNOWN;

  lua_getfield (L, index, "class");
  name = lua_tostring (L, -1);
  if (name == NULL)
    {
      lua_pop (L, 1);
      return NCLUAW_EVENT_UNKNOWN;
    }

  result = NCLUAW_EVENT_UNKNOWN;
  for (i = 0; i < nelementsof (known_class_list); i++)
    {
      if (streq (name, known_class_list[i]))
        {
          result = (ncluaw_event_class_t) i;
          break;
        }
    }

  lua_pop (L, 1);
  return result;
}

/* Returns the Lua state associate with NW.  */
#define ncluaw_get_lua_state(nw) ((lua_State *) (nw))

/* Returns the wrapper associated with Lua state L.  */
#define ncluaw_get_nw_from_lua_state(L) ((ncluaw_t *) (L))

/* Calls the panic function stored in field "panic" of module's registry.
   If this field is empty, calls the default panic function (which is stored
   in field "lua_panic").  */
static int
ncluaw_panic_wrapper (lua_State *L)
{
  ncluaw_panic_function_t panic;
  lua_CFunction lua_panic;

  assert (lua_checkstack (L, 1));
  ncluaw_registry_get_field (L, "panic");
  panic = (ncluaw_panic_function_t) integralof (lua_touserdata (L, -1));
  if (panic != NULL)
    {
      panic (ncluaw_get_nw_from_lua_state (L), lua_tostring (L, 1));
    }
  else
    {
      assert (lua_checkstack (L, 1));
      ncluaw_registry_get_field (L, "lua_panic");
      lua_panic = (lua_CFunction) integralof (lua_touserdata (L, -1));
      assert (lua_panic != NULL);
      return lua_panic (L);
    }

  return 0;
}

/********************************* Event **********************************/

/*-
 * Returns a copy of event EVT.
 *
 * The caller owns this copy and must call ncluaw_event_free() when done
 * with it.
 */
ncluaw_event_t *
ncluaw_event_clone (const ncluaw_event_t *evt)
{
  ncluaw_event_t *dup;

  dup = (ncluaw_event_t *) xmalloc (sizeof (*dup));
  memset (dup, 0, sizeof (*dup));

  dup->cls = evt->cls;
  switch (dup->cls)
    {
    case NCLUAW_EVENT_KEY:
      dup->u.key.type = xstrdup (evt->u.key.type);
      dup->u.key.key = xstrdup (evt->u.key.key);
      break;

    case NCLUAW_EVENT_NCL:
      dup->u.ncl.type = xstrdup (evt->u.ncl.type);
      dup->u.ncl.action = xstrdup (evt->u.ncl.action);
      dup->u.ncl.name = xstrdup (evt->u.ncl.name);
      dup->u.ncl.value = (evt->u.ncl.value != NULL)
        ? xstrdup (evt->u.ncl.value) : NULL;
      break;

    case NCLUAW_EVENT_POINTER:
      dup->u.pointer.type = xstrdup (evt->u.pointer.type);
      dup->u.pointer.x = evt->u.pointer.x;
      dup->u.pointer.y = evt->u.pointer.y;
      break;

    case NCLUAW_EVENT_UNKNOWN:
    default:
      ASSERT_NOT_REACHED;
    }
  return dup;
}

/*-
 * Releases the resources associated with event EVT.
 */
void
ncluaw_event_free (ncluaw_event_t *evt)
{
  switch (evt->cls)
    {
    case NCLUAW_EVENT_KEY:
      free (deconst (char *, evt->u.key.type));
      free (deconst (char *, evt->u.key.key));
      break;

    case NCLUAW_EVENT_NCL:
      free (deconst (char *, evt->u.ncl.type));
      free (deconst (char *, evt->u.ncl.action));
      free (deconst (char *, evt->u.ncl.name));
      free (deconst (char *, evt->u.ncl.value));
      break;

    case NCLUAW_EVENT_POINTER:
      free (deconst (char *, evt->u.pointer.type));
      break;

    case NCLUAW_EVENT_UNKNOWN:
    default:
      ASSERT_NOT_REACHED;
    }
  free (evt);
}

/*-
 * Returns true if events E1 and E2 are equal (have the same content),
 * otherwise returns false.
 */
ATTR_PURE int
ncluaw_event_equals (const ncluaw_event_t *e1, const ncluaw_event_t *e2)
{
  int result;

  if (e1->cls != e2->cls)
    return FALSE;

  switch (e1->cls)
    {
    case NCLUAW_EVENT_KEY:
      result = streq (e1->u.key.type, e2->u.key.type)
        && streq (e1->u.key.key, e2->u.key.key);
      break;

    case NCLUAW_EVENT_NCL:
      result = streq (e1->u.ncl.type, e2->u.ncl.type)
        && streq (e1->u.ncl.action, e2->u.ncl.action)
        && streq (e1->u.ncl.name, e2->u.ncl.name)
        && ((e1->u.ncl.value == NULL && e2->u.ncl.value == NULL)
            || (e1->u.ncl.value && e2->u.ncl.value
                && streq (e1->u.ncl.value, e2->u.ncl.value)));
      break;

    case NCLUAW_EVENT_POINTER:
      result = streq (e1->u.pointer.type, e2->u.pointer.type)
        && e1->u.pointer.x == e2->u.pointer.x
        && e1->u.pointer.y == e2->u.pointer.y;
      break;

    case NCLUAW_EVENT_UNKNOWN:
    default:
      ASSERT_NOT_REACHED;
    }

  return result;
}

/******************************** Wrappers ********************************/

/*-
 * Creates new NCLua state from the NCLua script at path PATH.
 *
 * The WIDTH and HEIGHT parameters define the dimensions (in pixels) of the
 * global canvas.
 *
 * Returns a new NCLua state if successful, otherwise returns NULL and, if
 * ERRMSG is non-NULL, stores a copy of the error message into *ERRMSG --
 * the caller owns this copy and should call free() when done with it.
 */
ncluaw_t *
ncluaw_open (const char *path, int width, int height, char **errmsg)
{
  lua_CFunction lua_panic;
  lua_State *L;
  int err;

  L = luaL_newstate ();
  luaL_openlibs (L);
  err = nclua_open (L, width, height, plugin_list);
  if (unlikely (err != LUA_OK))
    goto fail;

  err = luaL_dofile (L, path);
  if (unlikely (err != LUA_OK))
    goto fail;

  lua_newtable (L);
  ncluaw_registry_create (L);

  lua_panic = lua_atpanic (L, ncluaw_panic_wrapper);
  assert (lua_panic != NULL);
  lua_pushlightuserdata (L, pointerof (lua_panic));
  ncluaw_registry_set_field (L, "lua_panic");

  return (ncluaw_t *) L;

 fail:
  test_and_set (errmsg, *errmsg, xstrdup (luaL_checkstring (L, -1)));
  lua_close (L);
  return NULL;
}

/*-
 * Releases the resources associated with NCLua state NW.
 */
void
ncluaw_close (ncluaw_t *nw)
{
  lua_State *L;

  L = ncluaw_get_lua_state (nw);
  ncluaw_registry_destroy (L);
  nclua_close (L);
}

/*-
 * Sets a new panic function and returns the old one or NULL if no custom
 * panic function was set.  If PANIC is NULL, revert to use the default
 * panic function.
 */
ncluaw_panic_function_t
ncluaw_at_panic (ncluaw_t *nw, ncluaw_panic_function_t panic)
{
  lua_State *L;
  ncluaw_panic_function_t old_panic;

  L = ncluaw_get_lua_state (nw);
  ncluaw_registry_get_field (L, "panic");
  old_panic = (ncluaw_panic_function_t) integralof (lua_touserdata (L, -1));
  if (panic == NULL)
    {
      if (old_panic == NULL)
        return NULL;            /* nothing to do */
      lua_pushnil (L);
    }
  else
    {
      lua_pushlightuserdata (L, pointerof (panic));
    }
  ncluaw_registry_set_field (L, "panic");

  return old_panic;
}

/*-
 * Cycles NW's engine once.
 */
void
ncluaw_cycle (ncluaw_t *nw)
{
  nclua_cycle (ncluaw_get_lua_state (nw));
}

/*-
 * Receives an event from NW's engine -- the caller owns this event and
 * should call free() when done with it.
 *
 * If there is no known event to be received returns NULL.
 *
 * WARNING: This function silently discards unknown events.  If you need to
 * deal with such events, use the NCLua core API.
 */
ncluaw_event_t *
ncluaw_receive (ncluaw_t *nw)
{
  lua_State *L;
  ncluaw_event_t evt;
  ncluaw_event_t *dup = NULL;

  L = ncluaw_get_lua_state (nw);
  nclua_receive (L);
  if (lua_isnil (L, -1))
    goto done;

  evt.cls = get_event_class (L, -1);
  switch (evt.cls)
    {
    case NCLUAW_EVENT_KEY:
      lua_getfield (L, -1, "type");
      evt.u.key.type = luaL_checkstring (L, -1);
      lua_getfield (L, -2, "key");
      evt.u.key.key = luaL_checkstring (L, -1);
      dup = ncluaw_event_clone (&evt);
      lua_pop (L, 2);
      break;

    case NCLUAW_EVENT_NCL:
      lua_getfield (L, -1, "type");
      evt.u.ncl.type = luaL_checkstring (L, -1);
      lua_getfield (L, -2, "action");
      evt.u.ncl.action = luaL_checkstring (L, -1);
      lua_getfield (L, -3, "label");
      if (!lua_isnil (L, -1))
        {
          evt.u.ncl.name = luaL_checkstring (L, -1);
          evt.u.ncl.value = NULL;
        }
      else
        {
          lua_pop (L, 1);
          lua_getfield (L, -3, "name");
          evt.u.ncl.name = luaL_checkstring (L, -1);
          lua_getfield (L, -4, "value");
          evt.u.ncl.value = luaL_checkstring (L, -1);
          lua_pop (L, 1);
        }
      dup = ncluaw_event_clone (&evt);
      lua_pop (L, 3);
      break;

    case NCLUAW_EVENT_POINTER:
      lua_getfield (L, -1, "type");
      evt.u.pointer.type = luaL_checkstring (L, -1);
      lua_getfield (L, -2, "x");
      evt.u.pointer.x = luaL_checkint (L, -1);
      lua_getfield (L, -3, "y");
      evt.u.pointer.y = luaL_checkint (L, -1);
      dup = ncluaw_event_clone (&evt);
      lua_pop (L, 3);
      break;

    case NCLUAW_EVENT_UNKNOWN:
      break;

    default:
      ASSERT_NOT_REACHED;
    }

 done:
  lua_pop (L, 1);
  return dup;
}

/*-
 * Sends a copy of event EVT to NW's engine.
 */
void
ncluaw_send (ncluaw_t *nw, const ncluaw_event_t *evt)
{
  lua_State *L;

  L = ncluaw_get_lua_state (nw);
  lua_newtable (L);

  /* TODO: Check if evt is valid using plugin:check().  */
  switch (evt->cls)
    {
    case NCLUAW_EVENT_KEY:
      luax_setstringfield (L, -1, "class", "key");
      luax_setstringfield (L, -1, "type", evt->u.key.type);
      luax_setstringfield (L, -1, "key", evt->u.key.key);
      break;

    case NCLUAW_EVENT_NCL:
      luax_setstringfield (L, -1, "class", "ncl");
      luax_setstringfield (L, -1, "type", evt->u.ncl.type);
      luax_setstringfield (L, -1, "action", evt->u.ncl.action);
      if (evt->u.ncl.value != NULL)
        {
          luax_setstringfield (L, -1, "name", evt->u.ncl.name);
          luax_setstringfield (L, -1, "value", evt->u.ncl.value);
        }
      else
        {
          luax_setstringfield (L, -1, "label", evt->u.ncl.name);
        }
      break;

    case NCLUAW_EVENT_POINTER:
      luax_setstringfield (L, -1, "class", "pointer");
      luax_setstringfield (L, -1, "type", evt->u.pointer.type);
      luax_setintegerfield (L, -1, "x", evt->u.pointer.x);
      luax_setintegerfield (L, -1, "y", evt->u.pointer.y);
      break;

    case NCLUAW_EVENT_UNKNOWN:
    default:
      ASSERT_NOT_REACHED;
    }

  nclua_send (L);
}

/*-
 * Paints the surface of NW's global canvas into buffer BUFFER.
 */
void
ncluaw_paint (ncluaw_t *nw, unsigned char *buffer, const char *format,
              int width, int height, int stride)
{
  nclua_paint (ncluaw_get_lua_state (nw), buffer, format,
               width, height, stride);
}

/********************************* Debug **********************************/

/*-
 * Dumps the surface of NW's global canvas into PNG file at path PATH.
 *
 * Returns true if successful, otherwise returns false and, if ERRMSG is
 * non-NULL, stores a copy of the error message into *ERRMSG -- the caller
 * owns this copy and should call free() when done with it.
 */
int
ncluaw_debug_dump_surface (ncluaw_t *nw, const char *path, char **errmsg)
{
  lua_State *L;
  int err;

  L = ncluaw_get_lua_state (nw);
  err = nclua_debug_dump_surface (L, path);
  if (unlikely (err != LUA_OK))
    {
      test_and_set (errmsg, *errmsg, xstrdup (luaL_checkstring (L, -1)));
      return FALSE;
    }
  return TRUE;
}

/*-
 * Returns a pointer to the Lua state associated with NCLua state NW.
 */
ATTR_CONST void *
ncluaw_debug_get_lua_state (ncluaw_t *nw)
{
  return (void *) ncluaw_get_lua_state (nw);
}

/*-
 * Returns a pointer to the surface of NW's global canvas.
 *
 * WARNING: This pointer may become invalid after ncluaw_cycle() is called.
 */
void *
ncluaw_debug_get_surface (ncluaw_t *nw)
{
  return nclua_debug_get_surface (ncluaw_get_lua_state (nw));
}
