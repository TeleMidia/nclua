/* nclua.event.socket -- Non-blocking sockets.
   Copyright (C) 2013-2014 PUC-Rio/Laboratorio TeleMidia

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
#include <assert.h>

#include <lua.h>
#include <lauxlib.h>

#include <glib.h>
#include <glib-object.h>
#include <gio/gio.h>

#include "macros.h"
#include "luax-macros.h"

/* Registry key for the socket metatable.  */
#define SOCKET "nclua.event.socket"

/* Socket object data.  */
typedef struct _socket_t
{
  GSocketClient *client;        /* client socket handle */
  GSocketConnection *conn;      /* connection handle */
} socket_t;

/* Checks if the object at index INDEX is a socket.
   If CLIENT is non-NULL, stores socket's client handle at *CLIENT.
   If CONN is non-NULL, stores socket's connection handle at *CONN.  */

static inline socket_t *
socket_check (lua_State *L, int index, GSocketClient ** client,
              GSocketConnection ** conn)
{
  socket_t *sock;
  sock = (socket_t *) luaL_checkudata (L, index, SOCKET);
  test_and_set (client != NULL, *client, sock->client);
  test_and_set (conn != NULL, *conn, sock->conn);
  return sock;
}

/* Returns true if socket SOCK is connected.  */
#define socket_is_connected(sock) \
  ((sock)->conn != NULL && g_socket_connection_is_connected ((sock)->conn))

/* Throws "socket already connected" error.  */
#define error_throw_socket_already_connected(L, sock)                   \
  (lua_pushfstring (L, "socket %p already connected", (void *) sock),   \
   lua_error (L))

/* Throws "socket not connected" error.  */
#define error_throw_socket_not_connected(L, sock)                       \
  (lua_pushfstring (L, "socket %p not connected", (void *) sock),       \
   lua_error (L))

/* Registry key for the socket registry.  The socket registry is a global
   table used by sockets to pass Lua data to C callbacks.  We use this local
   registry to avoid polluting the global Lua registry.  */
#define SOCKET_REGISTRY_INDEX (deconst (void *, &_socket_registry_index))
static const int _socket_registry_index = 0;

/* Initializes the socket registry.  */

static inline void
socket_init_registry (lua_State *L)
{
  lua_pushvalue (L, LUA_REGISTRYINDEX);
  lua_newtable (L);
  lua_rawsetp (L, -2, SOCKET_REGISTRY_INDEX);
  lua_pop (L, 1);
}

/* Pushes the socket registry onto stack.  */

static inline void
socket_get_registry (lua_State *L)
{
  lua_pushvalue (L, LUA_REGISTRYINDEX);
  lua_rawgetp (L, -1, SOCKET_REGISTRY_INDEX);
  lua_remove (L, -2);
}

/* Socket callback-data object data.  */
typedef struct _socket_callback_data_t
{
  lua_State *L;
  socket_t *socket;
  int ref;
} socket_callback_data_t;

/* Creates new callback-data object.  */

static socket_callback_data_t *
socket_callback_data_new (lua_State *L, socket_t *sock, int ref)
{
  socket_callback_data_t *data;
  data = (socket_callback_data_t *) g_malloc (sizeof (*data));
  assert (data != NULL);
  data->L = L;
  data->socket = sock;
  data->ref = ref;
  return data;
}

/* Destroys the given callback-data object.  */
#define socket_callback_data_free(data) g_free (data)

/* Gets the Lua state and socket object associated with callback-data object
   DATA and stores them, respectively, into *L and *SOCKET.  */

static inline void
socket_callback_data_get_data (socket_callback_data_t *data,
                               lua_State **L, socket_t **sock)
{
  test_and_set (L != NULL, *L, data->L);
  test_and_set (sock != NULL, *sock, data->socket);
}

/* Allocates a new callback-data object in the socket registry for the
   object at the top of stack (and pops the object).  Returns the allocated
   callback-data object.  */

static socket_callback_data_t *
socket_callback_data_ref (lua_State *L, socket_t *sock)
{
  socket_callback_data_t *data;
  socket_get_registry (L);
  lua_insert (L, -2);
  data = socket_callback_data_new (L, sock, luaL_ref (L, -2));
  lua_pop (L, 1);
  return data;
}

/* Pushes onto stack the value associated with callback-data object DATA,
   releases its reference in the socket registry, and destroys DATA.  */

static void
socket_callback_data_unref (socket_callback_data_t *data)
{
  lua_State *L;
  L = data->L;
  socket_get_registry (L);
  lua_rawgeti (L, -1, data->ref);
  luaL_unref (L, -2, data->ref);
  lua_remove (L, -2);
  socket_callback_data_free (data);
}

/*-
 * socket.new ([timeout:number])
 * socket:new ([timeout:number])
 *       -> socket:userdata
 *
 * Creates a new client socket.
 *
 * If TIMEOUT is given, set the timeout for socket:connect(), socket:send(),
 * and socket:receive() to TIMEOUT seconds.
 */
static int
l_socket_new (lua_State *L)
{
  socket_t *sock;
  guint timeout;

  luax_optudata (L, 1, SOCKET);
  timeout = (guint) range (luaL_optint (L, 2, 0), 0, INT_MAX);
  sock = (socket_t *) lua_newuserdata (L, sizeof (*sock));
  sock->client = g_socket_client_new ();
  sock->conn = NULL;
  g_socket_client_set_timeout (sock->client, timeout);
  luaL_setmetatable (L, SOCKET);

  return 1;
}

/*-
 * socket:__gc ()
 *
 * Destroys the given socket object.
 */
static int
__l_socket_gc (lua_State *L)
{
  GSocketClient *client;
  GSocketConnection *conn;

  socket_check (L, 1, &client, &conn);
  g_object_unref (client);

  if (conn != NULL)
    g_object_unref (conn);

  return 0;
}

/*-
 * socket:connect (host:string, port:number, callback:function)
 *
 * Attempts to create a connection to host HOST on port PORT through the
 * given socket; calls the callback function CALLBACK when the operation
 * is finished.
 *
 * If the connection was successfully established, calls CALLBACK as
 * follows: CALLBACK(true, socket, host, port).
 *
 * Otherwise, if the connection could not be established, calls CALLBACK as
 * follows: CALLBACK(false, socket, host, port, errmsg), where ERRMSG is an
 * error message.
 */
static void
connect_finished (GObject *source, GAsyncResult *result, gpointer data)
{
  socket_callback_data_t *cb_data;
  lua_State *L;
  socket_t *sock;
  GSocketConnection *conn;
  GError *error;

  cb_data = (socket_callback_data_t *) data;
  socket_callback_data_get_data (cb_data, &L, &sock);
  assert (sock->client == G_SOCKET_CLIENT (source));

  socket_callback_data_unref (cb_data);
  assert (lua_type (L, -1) == LUA_TFUNCTION);

  error = NULL;
  conn = g_socket_client_connect_finish (sock->client, result, &error);
  if (conn != NULL)
    {
      assert (error == NULL);
      sock->conn = conn;
      lua_pushboolean (L, TRUE);
      lua_call (L, 1, 0);
    }
  else
    {
      lua_pushboolean (L, FALSE);
      lua_pushstring (L, error->message);
      g_error_free (error);
      lua_call (L, 2, 0);
    }
}

static int
l_socket_connect_callback_closure (lua_State *L)
{
  if (lua_toboolean (L, 1))
    {
      assert (lua_type (L, 1) == LUA_TBOOLEAN);

      lua_pushvalue (L, 1);     /* true */
      luax_pushupvalue (L, 1);  /* socket */
      luax_pushupvalue (L, 2);  /* host */
      luax_pushupvalue (L, 3);  /* port */
      luax_pushupvalue (L, 4);  /* callback */
      lua_insert (L, -5);
      lua_call (L, 4, 0);
    }
  else
    {
      assert (lua_type (L, 1) == LUA_TBOOLEAN);
      assert (lua_type (L, 2) == LUA_TSTRING);

      lua_pushvalue (L, 1);     /* false */
      luax_pushupvalue (L, 1);  /* socket */
      luax_pushupvalue (L, 2);  /* host */
      luax_pushupvalue (L, 3);  /* port */
      lua_pushvalue (L, 2);     /* errmsg */
      luax_pushupvalue (L, 4);  /* callback */
      lua_insert (L, -6);
      lua_call (L, 5, 0);
    }
  return 0;
}

static int
l_socket_connect (lua_State *L)
{
  socket_t *sock;
  GSocketClient *client;
  const char *host;
  int port;
  socket_callback_data_t *cb_data;

  sock = socket_check (L, 1, &client, NULL);
  if (unlikely (socket_is_connected (sock)))
    return error_throw_socket_already_connected (L, sock);

  host = luaL_checkstring (L, 2);
  port = range (luaL_checkint (L, 3), 0, G_MAXUINT16);
  luaL_checktype (L, 4, LUA_TFUNCTION);

  lua_pushcclosure (L, l_socket_connect_callback_closure, 4);
  cb_data = socket_callback_data_ref (L, sock);

  g_socket_client_connect_to_host_async (client, host, (guint16) port, NULL,
                                         connect_finished, cb_data);
  return 0;
}

/*-
 * socket:cycle ()
 *
 * Cycles the socket engine once, i.e., process the pending operations for
 * all sockets, triggering the appropriated callbacks.
 */
static int
l_socket_cycle (arg_unused (lua_State *L))
{
  return (g_main_context_iteration (NULL, FALSE), 0);
}

/*-
 * socket:disconnect (callback:function)
 *
 * Attempts to disconnect the given socket and calls the callback function
 * CALLBACK when the operation is finished.
 *
 * If the socket was successfully disconnected, calls CALLBACK as follows:
 * CALLBACK(true, socket).
 *
 * Otherwise, if some error occurs while disconnecting, calls CALLBACK as
 * follows: CALLBACK(false, socket, errmsg), where ERRMSG is an error
 * message.
 */
static void
disconnect_finished (GObject *source, GAsyncResult *result, gpointer data)
{
  socket_callback_data_t *cb_data;
  lua_State *L;
  socket_t *sock;
  GIOStream *stream;
  GError *error;
  gboolean status;

  cb_data = (socket_callback_data_t *) data;
  socket_callback_data_get_data (cb_data, &L, &sock);

  stream = G_IO_STREAM (sock->conn);
  assert (stream == G_IO_STREAM (source));

  socket_callback_data_unref (cb_data);
  assert (lua_type (L, -1) == LUA_TFUNCTION);

  error = NULL;
  status = g_io_stream_close_finish (stream, result, &error);
  if (status)
    {
      assert (error == NULL);
      lua_pushboolean (L, TRUE);
      lua_call (L, 1, 0);
      g_object_unref (sock->conn);
      sock->conn = NULL;
    }
  else
    {
      lua_pushboolean (L, FALSE);
      lua_pushstring (L, error->message);
      g_error_free (error);
      lua_call (L, 2, 0);
    }
}

static int
l_socket_disconnect_callback_closure (lua_State *L)
{
  if (lua_toboolean (L, 1))
    {
      assert (lua_type (L, 1) == LUA_TBOOLEAN);

      lua_pushvalue (L, 1);     /* true */
      luax_pushupvalue (L, 1);  /* socket */
      luax_pushupvalue (L, 2);  /* callback */
      lua_insert (L, -3);
      lua_call (L, 2, 0);
    }
  else
    {
      assert (lua_type (L, 1) == LUA_TBOOLEAN);
      assert (lua_type (L, 2) == LUA_TSTRING);

      lua_pushvalue (L, 1);     /* false */
      luax_pushupvalue (L, 1);  /* socket */
      lua_pushvalue (L, 2);     /* errmsg */
      luax_pushupvalue (L, 2);  /* callback */
      lua_insert (L, -4);
      lua_call (L, 3, 0);
    }
  return 0;
}

static int
l_socket_disconnect (lua_State *L)
{
  socket_t *sock;
  socket_callback_data_t *cb_data;

  sock = socket_check (L, 1, NULL, NULL);
  if (unlikely (!socket_is_connected (sock)))
    return error_throw_socket_not_connected (L, sock);

  luaL_checktype (L, 2, LUA_TFUNCTION);

  lua_pushcclosure (L, l_socket_disconnect_callback_closure, 2);
  cb_data = socket_callback_data_ref (L, sock);

  g_io_stream_close_async (G_IO_STREAM (sock->conn),
                           G_PRIORITY_DEFAULT, NULL,
                           disconnect_finished, cb_data);
  return 0;
}

/*-
 * socket:is_connected () -> status:boolean
 *
 * Returns true if the given socket is connected.
 */
static int
l_socket_is_connected (lua_State *L)
{
  socket_t *sock;
  sock = socket_check (L, 1, NULL, NULL);
  lua_pushboolean (L, socket_is_connected (sock));
  return 1;
}

/*-
 * socket:is_socket (obj:userdata) -> status: boolean
 *
 * Returns true if object OBJ is a socket, or false otherwise.
 */
static int
l_socket_is_socket (lua_State *L)
{
  luax_optudata (L, 1, SOCKET);
  lua_pushboolean (L, luaL_testudata (L, 2, SOCKET) != NULL);
  return 1;
}

/*-
 * socket:receive (n:number, callback:function)
 *
 * Attempts to receive N bytes through the given socket and calls the
 * callback function CALLBACK when the operation is finished.
 *
 * If the data was successfully received, calls CALLBACK as follows:
 * CALLBACK(true, socket, data), where DATA is the received data or the
 * empty string, which indicates end-of-file.
 *
 * Otherwise, if that could not be received, calls CALLBACK as follows:
 * CALLBACK(false, socket, errmsg), where ERRMSG is an error message.
 */
static void
receive_finished (GObject *source, GAsyncResult *result, gpointer data)
{
  socket_callback_data_t *cb_data;
  lua_State *L;
  socket_t *sock;
  GError *error;
  GInputStream *in;
  gssize n_received;

  cb_data = (socket_callback_data_t *) data;
  socket_callback_data_get_data (cb_data, &L, &sock);

  in = g_io_stream_get_input_stream (G_IO_STREAM (sock->conn));
  assert (in == G_INPUT_STREAM (source));

  socket_callback_data_unref (cb_data);
  assert (lua_type (L, -1) == LUA_TFUNCTION);

  error = NULL;
  n_received = g_input_stream_read_finish (in, result, &error);
  if (n_received >= 0)
    {
      assert (error == NULL);
      lua_pushboolean (L, TRUE);
      lua_pushinteger (L, n_received);
      lua_call (L, 2, 0);
    }
  else
    {
      lua_pushboolean (L, FALSE);
      lua_pushstring (L, error->message);
      g_error_free (error);
      lua_call (L, 2, 0);
    }
}

static int
l_socket_receive_callback_closure (lua_State *L)
{
  if (lua_toboolean (L, 1))
    {
      char *buf;
      lua_Unsigned n_received;

      assert (lua_type (L, 1) == LUA_TBOOLEAN);
      assert (lua_type (L, 2) == LUA_TNUMBER);

      lua_pushvalue (L, 1);     /* true */
      luax_pushupvalue (L, 1);  /* socket */

      buf = (char *) lua_touserdata (L, lua_upvalueindex (4));
      n_received = luaL_checkunsigned (L, 2);
      lua_pushlstring (L, buf, n_received);     /* data */

      luax_pushupvalue (L, 3);  /* callback */
      lua_insert (L, -4);
      lua_call (L, 3, 0);
    }
  else
    {
      assert (lua_type (L, 1) == LUA_TBOOLEAN);
      assert (lua_type (L, 2) == LUA_TSTRING);

      lua_pushvalue (L, 1);     /* false */
      luax_pushupvalue (L, 1);  /* socket */
      lua_pushvalue (L, 2);     /* errmsg */
      luax_pushupvalue (L, 3);  /* callback */
      lua_insert (L, -4);
      lua_call (L, 3, 0);
    }
  return 0;
}

static int
l_socket_receive (lua_State *L)
{
  socket_t *sock;
  lua_Unsigned n;
  socket_callback_data_t *cb_data;
  GInputStream *in;
  char *buf;

  sock = socket_check (L, 1, NULL, NULL);
  if (unlikely (!socket_is_connected (sock)))
    return error_throw_socket_not_connected (L, sock);

  n = luaL_checkunsigned (L, 2);
  luaL_argcheck (L, n > 0, 2, "cannot receive zero bytes");
  luaL_checktype (L, 3, LUA_TFUNCTION);
  buf = (char *) lua_newuserdata (L, sizeof (*buf) * n);

  lua_pushcclosure (L, l_socket_receive_callback_closure, 4);
  cb_data = socket_callback_data_ref (L, sock);

  in = g_io_stream_get_input_stream (G_IO_STREAM (sock->conn));
  g_input_stream_read_async (in, buf, n, G_PRIORITY_DEFAULT,
                             NULL, receive_finished, cb_data);
  return 0;
}

/*-
 * socket:send (data:string, callback:function)
 *
 * Attempts to send data DATA through the given socket and calls the
 * callback function CALLBACK when the operation is finished.
 *
 * If the data was successfully sent, calls CALLBACK as follows:
 * CALLBACK(true, socket, data_left), where DATA_LEFT is the suffix of the
 * original DATA that could not be sent.
 *
 * Otherwise, if the data could not be sent, calls CALLBACK as follows:
 * CALLBACK(false, socket, errmsg), where ERRMSG is an error message.
 */
static void
send_finished (GObject *source, GAsyncResult *result, gpointer data)
{
  socket_callback_data_t *cb_data;
  lua_State *L;
  socket_t *sock;
  GOutputStream *out;
  GError *error;
  gssize n_sent;

  cb_data = (socket_callback_data_t *) data;
  socket_callback_data_get_data (cb_data, &L, &sock);

  out = g_io_stream_get_output_stream (G_IO_STREAM (sock->conn));
  assert (out == G_OUTPUT_STREAM (source));

  socket_callback_data_unref (cb_data);
  assert (lua_type (L, -1) == LUA_TFUNCTION);

  error = NULL;
  n_sent = g_output_stream_write_finish (out, result, &error);
  if (error == NULL)
    {
      assert (n_sent >= 0);
      lua_pushboolean (L, TRUE);
      lua_pushinteger (L, n_sent);
      lua_call (L, 2, 0);
    }
  else
    {
      lua_pushboolean (L, FALSE);
      lua_pushstring (L, error->message);
      g_error_free (error);
      lua_call (L, 2, 0);
    }
}

static int
l_socket_send_callback_closure (lua_State *L)
{
  if (lua_toboolean (L, 1))
    {
      lua_Unsigned n_sent;
      const char *data;
      size_t n;

      assert (lua_type (L, 1) == LUA_TBOOLEAN);
      assert (lua_type (L, 2) == LUA_TNUMBER);

      lua_pushvalue (L, 1);     /* true */
      luax_pushupvalue (L, 1);  /* socket */

      n_sent = luaL_checkunsigned (L, 2);
      data = luaL_checklstring (L, lua_upvalueindex (2), &n);
      assert (n_sent <= n);
      lua_pushlstring (L, data + n_sent, n - n_sent);   /* data */

      luax_pushupvalue (L, 3);  /* callback */
      lua_insert (L, -4);
      lua_call (L, 3, 0);
    }
  else
    {
      assert (lua_type (L, 1) == LUA_TBOOLEAN);
      assert (lua_type (L, 2) == LUA_TSTRING);

      lua_pushvalue (L, 1);     /* false */
      luax_pushupvalue (L, 1);  /* socket */
      lua_pushvalue (L, 2);     /* errmsg */
      luax_pushupvalue (L, 3);  /* callback */
      lua_insert (L, -4);
      lua_call (L, 3, 0);
    }
  return 0;
}

static int
l_socket_send (lua_State *L)
{
  socket_t *sock;
  const char *data;
  size_t n;
  socket_callback_data_t *cb_data;
  GOutputStream *out;

  sock = socket_check (L, 1, NULL, NULL);
  if (unlikely (!socket_is_connected (sock)))
    return error_throw_socket_not_connected (L, sock);

  data = luaL_checklstring (L, 2, &n);
  luaL_checktype (L, 3, LUA_TFUNCTION);

  lua_pushcclosure (L, l_socket_send_callback_closure, 3);
  cb_data = socket_callback_data_ref (L, sock);

  out = g_io_stream_get_output_stream (G_IO_STREAM (sock->conn));
  g_output_stream_write_async (out, data, n, G_PRIORITY_DEFAULT,
                               NULL, send_finished, cb_data);
  return 0;
}

static const struct luaL_Reg socket_funcs[] = {
  {"new", l_socket_new},
  {"__gc", __l_socket_gc},
  {"connect", l_socket_connect},
  {"cycle", l_socket_cycle},
  {"disconnect", l_socket_disconnect},
  {"is_connected", l_socket_is_connected},
  {"is_socket", l_socket_is_socket},
  {"receive", l_socket_receive},
  {"send", l_socket_send},
  {NULL, NULL}
};

int luaopen_nclua_event_socket (lua_State *L);

int
luaopen_nclua_event_socket (lua_State *L)
{
  G_TYPE_INIT_WRAPPER ();
  socket_init_registry (L);
  luax_newmetatable (L, SOCKET);
  luaL_setfuncs (L, socket_funcs, 0);
  return 1;
}
