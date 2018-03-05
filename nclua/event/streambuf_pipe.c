/* nclua.event.streambuf_pipe -- Non-blocking Src Buffer requests.
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

#define _GNU_SOURCE

#include <config.h>
#include <string.h>
#include <stdlib.h>
#include "aux-glib.h"
#include "aux-lua.h"

#include <gio/gio.h>
#include <fcntl.h>

/* Registry key for the streambuf metatable.  */
#define STREAMBUF_PIPE "nclua.event.streambuf_pipe"
GHashTable *stream_buffers_fd;
GHashTable *stream_buffers_byte_array;
GThread    *thread;
G_LOCK_DEFINE (buffer_lock);

#define MY_PIPE_SIZE 1048576
#define MAX_BYTE_ARRAY_SIZE 3 * MY_PIPE_SIZE

int
create_stream_buf (const gchar *buffer_id)
{
  gchar *pipe_name = g_strdup_printf ("/tmp/%s.mp4", buffer_id);
  int fd = open (pipe_name, O_WRONLY | O_NONBLOCK, 0644);

  if (fd > 0)
    {
#ifdef __APPLE__
      // write fcntl for osx here
#elif defined(G_OS_UNIX)
      int ret = fcntl (fd, F_SETPIPE_SZ, MY_PIPE_SIZE);
      if (ret < 0)
        {
          perror("set pipe size failed.");
        }
#endif
      g_hash_table_insert (stream_buffers_fd, buffer_id, GINT_TO_POINTER (fd));
    }

  g_free (pipe_name);
  return fd;
}

void
update_streambuf_pipe (gpointer key, gpointer value, gpointer user_data)
{
  G_LOCK (buffer_lock);
  GByteArray *byte_array = value;

  int fd = GPOINTER_TO_INT (g_hash_table_lookup (stream_buffers_fd, key));
  if (fd < 0)
    {
      fd = create_stream_buf (key);
    }

  if (fd < 0)
    {
      goto done; // Pipe buffer is still not created.
    }

  if (byte_array->len)
    {
      int chunk_size = MY_PIPE_SIZE;
      if (chunk_size > byte_array->len)
        chunk_size = byte_array->len;

      // Try to write the entire buffer
      int written = write (fd, byte_array->data, chunk_size);
      if (written > 0)
        {
          fdatasync (fd);
          printf ("%d bytes written to pipe. chunk_size=%d, buffer=%d\n",
              written, chunk_size, byte_array->len);
          g_byte_array_remove_range (byte_array, 0, written);
        }
      else
        {
          // printf ("Error on write. %d %d\n", written, chunk_size);
        }
    }

done:
  G_UNLOCK (buffer_lock);

  return;
}

/**
 * @brief A thread that tries to write pending data on the streambuf pipe.
 */
static int
thread_update_all_pipes (gpointer data)
{
  while (TRUE)
    {
      g_hash_table_foreach (
          stream_buffers_byte_array, update_streambuf_pipe, NULL);
      usleep (100000);
    }
  return 1;
}

static int
l_streambuf_pipe_status (lua_State *L)
{
  int status = 0;
  int len = -1;
  const gchar *buff_id = luaL_checkstring (L, 1);

  G_LOCK (buffer_lock);
  if (g_hash_table_contains (stream_buffers_byte_array, buff_id))
    {
      status = 1;
      GByteArray *a = g_hash_table_lookup (stream_buffers_byte_array, buff_id);
      len = a->len;
    }
  G_UNLOCK (buffer_lock);

  lua_pushnumber (L, status);
  lua_pushnumber (L, len);

  return 2;
}

static int
l_streambuf_pipe_write (lua_State *L)
{
  int ret = 0;

  const gchar *buff;
  const gchar *data;
  gsize size;

  GByteArray *byte_array;

  buff = g_strdup (luaL_checkstring (L, 1));
  size = luaL_checkint (L, 2);
  data = luaL_checkstring (L, 3);

  G_LOCK (buffer_lock);
  if (!g_hash_table_contains (stream_buffers_byte_array, buff))
    {
      byte_array = g_byte_array_new ();
      g_hash_table_insert (stream_buffers_fd, buff, GINT_TO_POINTER (-1));
      g_hash_table_insert (stream_buffers_byte_array, buff, byte_array);
    }

  byte_array = g_hash_table_lookup (stream_buffers_byte_array, buff);

  if (byte_array->len + size < MAX_BYTE_ARRAY_SIZE)
    {
      byte_array = g_byte_array_append (byte_array, data, size);
      ret = 1;
    }
  else
    {
      // printf ("Buffer is full.\n");
    }
  G_UNLOCK (buffer_lock);

  lua_pushnumber (L, ret);
  lua_pushnumber (L, byte_array->len);

  return 2;
}

static const struct luaL_Reg streambuf_pipe_funcs[] = {
  {"write", l_streambuf_pipe_write},
  {"status", l_streambuf_pipe_status},
  {NULL, NULL}
};

int luaopen_nclua_event_streambuf_pipe (lua_State *L);

int
luaopen_nclua_event_streambuf_pipe (lua_State *L)
{
  G_TYPE_INIT_WRAPPER ();

  lua_newtable (L);
  luax_newmetatable (L, STREAMBUF_PIPE);
  luaL_setfuncs (L, streambuf_pipe_funcs, 0);

  stream_buffers_fd = g_hash_table_new (g_str_hash, g_str_equal);
  stream_buffers_byte_array = g_hash_table_new (g_str_hash, g_str_equal);

  thread = g_thread_new ("pipe_flush", thread_update_all_pipes, NULL);

  return 1;
}
