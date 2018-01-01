/* luax-callback.h -- Functions for passing Lua objects to C callbacks.
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

#ifndef CALLBACK_H
#define CALLBACK_H

#include "aux-glib.h"
#include "aux-lua.h"

/* Callback-data object.  */
typedef struct _luax_callback_data_t
{
  lua_State *L;
  int ref;
  void *data;
} luax_callback_data_t;

/* Registry key for the callback-data table.  */
static const int _luax_callback_data_magic = 0;

/* Expands to the address of the above variable.  */
#define LUAX_CALLBACK_REGISTRY_INDEX\
  (deconst (void *, &_luax_callback_data_magic))

/* Allocates a new callback-data object and associates it with object at the
   top of stack (and pops the latter).  Returns the allocated callback-data
   object.  */

static luax_callback_data_t *
luax_callback_data_ref (lua_State *L, void *data)
{
  luax_callback_data_t *cb_data;

  luax_mregistry_get (L, LUAX_CALLBACK_REGISTRY_INDEX);
  if (lua_isnil (L, -1))
    {
      lua_pop (L, 1);
      lua_newtable (L);
      luax_mregistry_create (L, LUAX_CALLBACK_REGISTRY_INDEX);
      luax_mregistry_get (L, LUAX_CALLBACK_REGISTRY_INDEX);
    }
  lua_insert (L, -2);

  cb_data = (luax_callback_data_t *) g_malloc (sizeof (*cb_data));
  g_assert_nonnull (cb_data);
  cb_data->L = L;
  cb_data->data = data;
  cb_data->ref = luaL_ref (L, -2);
  lua_pop (L, 1);

  return cb_data;
}

/* Internal function used by data_push, data_unref, and
   data_push_and_unref.  */

static G_GNUC_UNUSED lua_State *
_luax_callback_data_get_registry (luax_callback_data_t *cb_data)
{
  lua_State *L;
  L = cb_data->L;
  g_assert_nonnull (L);
  luax_mregistry_get (L, LUAX_CALLBACK_REGISTRY_INDEX);
  g_assert (!lua_isnil (L, -1));
  return L;
}

/* Gets the data associated with callback-data object CB_DATA.  */

static G_GNUC_UNUSED void
luax_callback_data_get_data (luax_callback_data_t *cb_data,
                             lua_State **L, void **data)
{
  tryset (L, cb_data->L);
  tryset (data, cb_data->data);
}

/* Pushes onto stack the object associated with callback-data object
   CB_DATA.  */

static G_GNUC_UNUSED void
luax_callback_data_push (luax_callback_data_t *cb_data)
{
  lua_State *L;
  L = _luax_callback_data_get_registry (cb_data);
  lua_rawgeti (L, -1, cb_data->ref);
  lua_remove (L, -2);
}

/* Frees CB_DATA.  */

static G_GNUC_UNUSED void
luax_callback_data_unref (luax_callback_data_t *cb_data)
{
  lua_State *L;
  L = _luax_callback_data_get_registry (cb_data);
  luaL_unref (L, -1, cb_data->ref);
  lua_pop (L, 1);
  g_free (cb_data);
}

/* Pushes onto stack the object associated with callback-data object CB_DATA
   and frees CB_DATA. */

static G_GNUC_UNUSED void
luax_callback_data_push_and_unref (luax_callback_data_t *cb_data)
{
  lua_State *L;
  L = _luax_callback_data_get_registry (cb_data);
  lua_rawgeti (L, -1, cb_data->ref);
  luaL_unref (L, -2, cb_data->ref);
  lua_remove (L, -2);
  g_free (cb_data);
}

#endif /* CALLBACK_H */
