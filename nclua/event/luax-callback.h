/* luax-callback.h -- Functions for passing Lua objects to C callbacks.
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

#ifndef LUAX_CALLBACK_H
#define LUAX_CALLBACK_H

#include <config.h>
#include <assert.h>
#include <stdlib.h>

#include "macros.h"
#include "luax-macros.h"

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

  cb_data = (luax_callback_data_t *) malloc (sizeof (*cb_data));
  assert (cb_data != NULL);
  cb_data->L = L;
  cb_data->data = data;
  cb_data->ref = luaL_ref (L, -2);
  lua_pop (L, 1);

  return cb_data;
}

/* Gets the data associated with callback-data object CB_DATA.  */

static void
luax_callback_data_get_data (luax_callback_data_t *cb_data,
                             lua_State **L, void **data)
{
  set_if_nonnull (L, cb_data->L);
  set_if_nonnull (data, cb_data->data);
}

/* Pushes onto stack the object associated with callback-data object CB_DATA
   and frees CB_DATA.  */

static void
luax_callback_data_unref (luax_callback_data_t *cb_data)
{
  lua_State *L;

  assert (cb_data->L != NULL);
  L = cb_data->L;
  luax_mregistry_get (L, LUAX_CALLBACK_REGISTRY_INDEX);
  assert (!lua_isnil (L, -1));

  lua_rawgeti (L, -1, cb_data->ref);
  luaL_unref (L, -2, cb_data->ref);
  lua_remove (L, -2);
  free (cb_data);
}

#endif /* LUAX_CALLBACK_H */
