/* nclua.event.http_soup -- Non-blocking HTTP requests.
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
#include <string.h>
#include <stdlib.h>
#include "aux-glib.h"
#include "aux-lua.h"

#include <gio/gio.h>
#include <fcntl.h>

/* Registry key for the srcbuffer metatable.  */
#define SRCBUFFER_PIPE "nclua.event.srcbuffer_pipe"
int fd = -1;
GByteArray *byte_array;
GThread *thread;
G_LOCK_DEFINE (buffer_lock);

#define MAX_BYTE_ARRAY_SIZE 2^16

static int
thread_update_pipe (gpointer data)
{
  // try to write pedding data to pipe.
  while ( 1 )
    {
      G_LOCK (buffer_lock);
      if (byte_array->len)
        {
          int chunk_size = byte_array->len;

          if ( fd < 0 && (fd = open("/tmp/b0.mp4", O_WRONLY | O_NONBLOCK, 0644)) < 0)
            {
              printf ("Error on open.\n");
            }

          // Try to write the entire buffer
          int written = write (fd, byte_array->data, chunk_size);
          if (written > 0)
            {
              g_byte_array_remove_range (byte_array, 0, written);
            }
          else
            {
              // printf ("Error on write. %d %d\n", written, chunk_size);
            }
          G_UNLOCK (buffer_lock);
        }
      else
        {
          G_UNLOCK (buffer_lock);
          usleep (10);
        }
    }
  return 1;
}

static int
l_srcbuffer_pipe_write (lua_State *L)
{
  int ret = 0;

  const char *buff;
  const char *data;
  gsize size;

  buff = luaL_checkstring (L, 1);
  size = luaL_checkint (L, 2);
  data = luaL_checkstring (L, 3);
  printf ("srcbuffer_pipe_write %s size='%lu'.\n", buff, size);

  G_LOCK (buffer_lock);
  if (byte_array->len < MAX_BYTE_ARRAY_SIZE)
    {
      byte_array = g_byte_array_append (byte_array, data, size);
      printf ("buffer size = %lu.\n", byte_array->len);
      ret = 1;
    }
  else
    {
      printf ("Buffer is full.\n");
    }
  G_UNLOCK (buffer_lock);

  lua_pushnumber (L, ret);

  return 1;
} 

static const struct luaL_Reg srcbuffer_pipe_funcs[] = {
  {"write", l_srcbuffer_pipe_write},
  {NULL, NULL}
};

int luaopen_nclua_event_srcbuffer_pipe (lua_State *L);

int
luaopen_nclua_event_srcbuffer_pipe (lua_State *L)
{
  GError *error;

  G_TYPE_INIT_WRAPPER ();
  lua_newtable (L);
  luax_newmetatable (L, SRCBUFFER_PIPE);
  luaL_setfuncs (L, srcbuffer_pipe_funcs, 0);

  byte_array = g_byte_array_new ();
  thread = g_thread_new ("pipe_flush", thread_update_pipe, NULL);

  return 1;
}
