/* nclua.dir -- Directory functions.
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

/* Registry key for the dir metatable.  */
#define DIR "nclua.event.dir"

/* Dir object data.  */
typedef struct _dir_t
{
  GDir *gdir;
} dir_t;

/* Checks if the object at the given index is dir.  */
#define dir_check(L, index)\
  (dir_t *) luaL_checkudata (L, index, DIR)

/*-
 * dir.__gc (dir:userdata)
 *
 * Destroys the given dir object.
 */
static int
__l_dir_gc (lua_State *L)
{
  dir_t *dir;

  dir = dir_check (L, 1);
  if (dir->gdir != NULL)
    {
      g_dir_close (dir->gdir);
      dir->gdir = NULL;
    }

  return 0;
}

/*-
 * dir.dir (path:string) -> iter:function
 *
 * Returns an iterator function that each time it is called returns a
 * directory entry's name as a string.  If PATH is not a directory or if it
 * cannot be read, raises an error.
 */
static int
l_dir_dir_it_closure (lua_State *L)
{
  dir_t *dir;
  const char *entry;

  luax_pushupvalue (L, 1);
  dir = (dir_t *) lua_touserdata (L, -1);
  if (unlikely (dir->gdir == NULL))
    {
      lua_pushnil (L);
      return 1;
    }

  entry = g_dir_read_name (dir->gdir);
  if (entry == NULL)
    {
      g_dir_close (dir->gdir);
      dir->gdir = NULL;
      lua_pushnil (L);
      return 1;
    }

  lua_pushstring (L, entry);
  return 1;
}

static int
l_dir_dir (lua_State *L)
{
  const char *path;
  GDir *gdir;
  GError *error;
  dir_t *dir;

  path = luaL_checkstring (L, 1);
  error = NULL;
  gdir = g_dir_open (path, 0, &error);
  if (unlikely (gdir == NULL))
    {
      g_assert_nonnull (error);
      lua_pushfstring (L, "%s", error->message);
      g_error_free (error);
      return lua_error (L);
    }

  dir = (dir_t *) lua_newuserdata (L, sizeof (*dir));
  g_assert_nonnull (dir);
  dir->gdir = gdir;

  lua_pushcclosure (L, l_dir_dir_it_closure, 1);
  return 1;
}

/*-
 * dir.test (path, [query:string]) -> status:boolean
 *
 * Returns true if path satisfies the given query.
 *
 * The following query strings are supported:
 *   directory  - path is a directory;
 *   executable - path is an executable file;
 *   exists     - path can be read;
 *   regular    - path is a regular file.
 *   symlink    - path is a symbolic link;
 *
 * The default query is 'exists'.
 */
static int
l_dir_test (lua_State *L)
{
  static const char *query_list[] = {
    "directory",
    "executable",
    "exists",
    "regular",
    "symlink",
    NULL
  };
  const char *path;
  GFileTest test = G_FILE_TEST_EXISTS;

  path = luaL_checkstring (L, 1);
  switch (luaL_checkoption (L, 2, "exists", query_list))
    {
    case 0:
      test = G_FILE_TEST_IS_DIR;
      break;
    case 1:
      test = G_FILE_TEST_IS_EXECUTABLE;
      break;
    case 2:
      test = G_FILE_TEST_EXISTS;
      break;
    case 3:
      test = G_FILE_TEST_IS_REGULAR;
      break;
    case 4:
      test = G_FILE_TEST_IS_SYMLINK;
      break;
    default:
      g_assert_not_reached ();
    }

  lua_pushboolean (L, g_file_test (path, test));
  return 1;
}

static const struct luaL_Reg funcs[] = {
  {"__gc", __l_dir_gc},
  {"dir", l_dir_dir},
  {"test", l_dir_test},
  {NULL, NULL}
};

int luaopen_nclua_dir (lua_State *L);

int
luaopen_nclua_dir (lua_State *L)
{
  G_TYPE_INIT_WRAPPER ();
  luax_newmetatable (L, DIR);
  luaL_setfuncs (L, funcs, 0);
  return 1;
}
