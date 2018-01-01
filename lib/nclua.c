/* nclua.c -- The NCLua core interface.
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
#include "aux-glib.h"
#include "aux-lua.h"

#include "nclua.h"

/* NCLua local registry.  */
static const int _nclua_magic = 0;
#define NCLUA_REGISTRY_INDEX (deconst (void *, &_nclua_magic))

#define nclua_registry_create(L)\
  luax_mregistry_create (L, NCLUA_REGISTRY_INDEX)

#define nclua_registry_destroy(L)\
  luax_mregistry_destroy (L, NCLUA_REGISTRY_INDEX)

#define nclua_registry_get_field(L, field)\
  luax_mregistry_getfield (L, NCLUA_REGISTRY_INDEX, field)

/* Calls 'require' on name NAME.  Returns LUA_OK if successful, otherwise
   returns an error code and pushes an error message onto stack.  */
static int
require (lua_State *L, const char *name)
{
  lua_getglobal (L, "require");
  g_assert (!lua_isnil (L, -1));
  lua_pushstring (L, name);
  return lua_pcall (L, 1, 1, 0);
}

/********************************** Core **********************************/

/*-
 * Loads the NCLua library onto Lua state L.
 *
 * The WIDTH and HEIGHT parameters define the dimensions (in pixels) of the
 * global canvas.
 *
 * If PLUGINS is non-NULL, loads each Event plugin listed in PLUGINS
 * (a NULL-terminate array of plugin names).
 *
 * This function assumes that the 'require' global is set in L.
 * This function sets the following globals:
 *   canvas   - the NCLua Canvas API;
 *   event    - the NCLua Event API;
 *   settings - the NCLua Settings API.
 *
 * Returns LUA_OK if successful, otherwise returns an error code and pushes
 * an error message onto stack.
 */
int
nclua_open (lua_State *L, int width, int height,
            const char *const *plugins)
{
  int top;
  int err;

  top = lua_gettop (L);
  lua_newtable (L);

  err = require (L, "nclua.canvas");
  if (unlikely (err != LUA_OK))
    goto fail;

  lua_getfield (L, -1, "new");
  lua_remove (L, -2);
  lua_pushinteger (L, width);
  lua_pushinteger (L, height);
  lua_pushboolean (L, TRUE);
  lua_call (L, 3, 2);
  if (unlikely (lua_isnil (L, -2)))
    {
      err = LUA_ERRRUN;
      goto fail;
    }
  lua_pop (L, 1);
  lua_setfield (L, -2, "canvas");

  err = require (L, "nclua.dir");
  if (unlikely (err != LUA_OK))
    goto fail;
  lua_setfield (L, -2, "dir");

  err = require (L, "nclua.event");
  if (unlikely (err != LUA_OK))
    goto fail;

  if (plugins != NULL)
    {
      int n = 0;
      luax_getfield (L, -1, "_engine.load");
      luax_getfield (L, -2, "_engine");
      while (*plugins)
        {
          n++;
          lua_pushstring (L, *plugins++);
        }
      err = lua_pcall (L, n + 1, 0, 0);
      if (unlikely (err != LUA_OK))
        goto fail;
    }
  lua_setfield (L, -2, "event");
  luax_getfield (L, -1, "event._engine");
  lua_setfield (L, -2, "engine");

  nclua_registry_create (L);
  nclua_registry_get_field (L, "canvas");
  lua_setglobal (L, "canvas");
  nclua_registry_get_field (L, "dir");
  lua_setglobal (L, "dir");
  nclua_registry_get_field (L, "event");
  lua_setglobal (L, "event");

  return LUA_OK;

 fail:
  lua_insert (L, top + 1);
  lua_settop (L, top + 1);
  return err;
}

/*-
 * Unloads the NCLua library from Lua state L.
 */
void
nclua_close (lua_State *L)
{
  if (unlikely (L == NULL))
    return;                     /* nothing to do */

  nclua_registry_destroy (L);
}

/*-
 * Cycles the NCLua engine once.
 */
void
nclua_cycle (lua_State *L)
{
  nclua_registry_get_field (L, "engine.cycle");
  nclua_registry_get_field (L, "engine");
  lua_call (L, 1, 0);
}

/*-
 * Receives an event from the NCLua engine.
 * If there is no event to be received, pushes nil onto stack.
 */
void
nclua_receive (lua_State *L)
{
  nclua_registry_get_field (L, "engine.receive");
  nclua_registry_get_field (L, "engine");
  lua_call (L, 1, 1);
}

/*-
 * Pops the event on top of stack and sends it to the NCLua engine.
 */
void
nclua_send (lua_State *L)
{
  nclua_registry_get_field (L, "engine.send");
  nclua_registry_get_field (L, "engine");
  lua_pushvalue (L, -3);
  lua_call (L, 2, 0);
  lua_pop (L, 1);
}

/*-
 * Paints the surface of the global canvas into buffer BUFFER.
 *
 * The parameters WIDTH and HEIGHT define the width and height of the image
 * to be stored in BUFFER; the parameter STRIDE defines its stride -- i.e.,
 * the number of bytes between the start of the rows in the buffer as
 * allocated.
 *
 * The following FORMAT strings are supported:
 *
 *   ARGB32 - each pixel is a 32-bit quantity, with alpha in the upper 8
 *            bits, then red, then green, then blue; the 32-bit quantities
 *            are stored native-endian; pre-multiplied alpha is used;
 *
 *   RGB24  - each pixel is a 32-bit quantity, with the upper 8 bits unused;
 *            red, green, and blue are stored in the remaining 24 bits in
 *            that order.
 *
 * If FORMAT is NULL, the function assumes 'ARGB32'.
 */
void
nclua_paint (lua_State *L, unsigned char *buffer, const char *format,
             int width, int height, int stride)
{
  nclua_registry_get_field (L, "canvas._dump_to_memory");
  nclua_registry_get_field (L, "canvas");
  lua_pushlightuserdata (L, buffer);
  if (format != NULL)
    {
      lua_pushstring (L, format);
    }
  else
    {
      lua_pushnil (L);
    }
  lua_pushinteger (L, width);
  lua_pushinteger (L, height);
  lua_pushinteger (L, stride);
  lua_call (L, 6, 0);
}

/*-
 * Resizes the surface of the global canvas to WIDTH and HEIGHT pixels.
 */
void
nclua_resize (lua_State *L, int width, int height)
{
  nclua_registry_get_field (L, "canvas._resize");
  nclua_registry_get_field (L, "canvas");
  lua_pushinteger (L, width);
  lua_pushinteger (L, height);
  lua_call (L, 3, 0);
}

/********************************* Debug **********************************/

/*-
 * Dumps the surface of the global canvas into PNG file at path PATH.
 *
 * Returns LUA_OK if successful, otherwise returns an error code and pushes
 * an error message onto stack.
 */
int
nclua_debug_dump_surface (lua_State *L, const char *path)
{
  nclua_registry_get_field (L, "canvas._dump_to_file");
  nclua_registry_get_field (L, "canvas");
  lua_pushstring (L, path);
  lua_call (L, 2, 2);
  if (unlikely (!lua_toboolean (L, -2)))
    {
      lua_remove (L, -2);
      return LUA_ERRRUN;
    }
  lua_pop (L, 2);
  return LUA_OK;
}

/*-
 * Returns the registry index of the NCLua table.
 */
G_GNUC_CONST void *
nclua_debug_get_registry_index (void)
{
  return NCLUA_REGISTRY_INDEX;
}

/*-
 * Returns a pointer to the surface of the global canvas.
 *
 * WARNING: This pointer may become invalid after nclua_cycle() is called.
 */
void *
nclua_debug_get_surface (lua_State *L)
{
  void *sfc;

  nclua_registry_get_field (L, "canvas._surface");
  nclua_registry_get_field (L, "canvas");
  lua_call (L, 1, 1);
  g_assert (lua_type (L, -1) == LUA_TLIGHTUSERDATA);
  sfc = lua_touserdata (L, -1);
  lua_pop (L, 1);

  return sfc;
}
