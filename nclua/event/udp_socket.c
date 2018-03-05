/* nclua.event.tcp-socket -- Non-blocking sockets.
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
#include <gio/gio.h>

#include "callback.h"

/* Registry key for the socket metatable.  */
#define SOCKET "nclua.event.udp_socket"

#define BLOCK_SIZE 1024

/* Socket object data.  */
typedef struct _socket_t
{
    GSocket *socket;      /* client socket handle */
    GSocketAddress *addr; /* endpoint for socket communication */
} socket_t;

/* Checks if the object at index INDEX is a socket.
   If CLIENT is non-NULL, stores socket's client handle in *CLIENT.
   If CONN is non-NULL, stores socket's connection handle in *CONN.  */

static inline socket_t *
socket_check(lua_State *L, int index, GSocket **socket,
             GSocketAddress **addr)
{
    socket_t *sock;
    sock = (socket_t *)luaL_checkudata(L, index, SOCKET);
    tryset(socket, sock->socket);
    tryset(addr, sock->addr);
    return sock;
}

/* Returns true if socket SOCK is connected.  */
#define socket_is_connected(sock) \
    ((sock)->socket != NULL && g_socket_is_connected((sock)->socket))

/* Throws "socket already connected" error.  */
#define error_throw_socket_already_connected(L, sock)                 \
    (lua_pushfstring(L, "socket %p already connected", (void *)sock), \
     lua_error(L))

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
l_socket_new(lua_State *L)
{
    socket_t *sock;
    guint timeout;

    luax_optudata(L, 1, SOCKET);
    timeout = (guint)CLAMP(luaL_optint(L, 2, 0), 0, INT_MAX);
    sock = (socket_t *)lua_newuserdata(L, sizeof(*sock));
    g_assert_nonnull(sock);

    sock->socket = g_socket_new(G_SOCKET_FAMILY_IPV4, G_SOCKET_TYPE_DATAGRAM, G_SOCKET_PROTOCOL_UDP, NULL);
    g_assert_nonnull(sock->socket);
    sock->addr = NULL;
    g_socket_set_timeout(sock->socket, timeout);
    luaL_setmetatable(L, SOCKET);

    printf("New socket %p \n", sock->socket);

    return 1;
}

/*-
 * socket:is_socket (obj:userdata) -> status:boolean
 *
 * Returns true if object OBJ is a socket, or false otherwise.
 */
static int
l_socket_is_socket(lua_State *L)
{
    luax_optudata(L, 1, SOCKET);
    lua_pushboolean(L, luaL_testudata(L, 2, SOCKET) != NULL);
    return 1;
}

static gboolean
gio_read_socket(GIOChannel *channel,
                GIOCondition condition,
                gpointer data)
{
    luax_callback_data_t *cb_data;
    lua_State *L;
    socket_t *sock;

    cb_data = (luax_callback_data_t *) data;
    luax_callback_data_get_data (cb_data, &L, (void **) &sock);
  //  g_assert (sock->client == G_SOCKET_CLIENT (source));

    luax_callback_data_push (cb_data);
    g_assert (lua_type (L, -1) == LUA_TFUNCTION);

    char buf[1024];
    gsize bytes_read;
    GError *error = NULL;

    if (condition & G_IO_HUP)
        return FALSE; /* this channel is done */ //unref no cbdata

/*
    printf("check socket %p \n", sock->socket);    
    GSocketAddress *addr;
    g_socket_receive_from(sock->socket, &addr, NULL, 0, NULL, error);

    if (error != NULL)
        printf("ERROR: %s\n", error->message);
*/

    g_io_channel_read_chars(channel, buf, sizeof(buf), &bytes_read,
                            &error);
    g_assert(error == NULL);

    buf[bytes_read] = '\0';                   

    lua_pushstring (L, "aaaa");
    lua_pushstring (L, "bbbb");
    lua_pushstring (L, buf);
    lua_call (L, 3, 0);

    return TRUE;
}



static int
l_socket_bind(lua_State *L)
{
    socket_t *sock;
    GSocket *socket;
    GSocketAddress *addr;
    const char *host;
    int port;
    luax_callback_data_t *cb_data;

    sock = socket_check(L, 1, &socket, &addr);
    if (unlikely(socket_is_connected(sock)))
        return error_throw_socket_already_connected(L, sock);

    port = CLAMP(luaL_checkint(L, 2), 0, G_MAXUINT16);
    luaL_checktype(L, 3, LUA_TFUNCTION);

    addr = G_SOCKET_ADDRESS(g_inet_socket_address_new(g_inet_address_new_any(G_SOCKET_FAMILY_IPV4), port));
    
    GError *err = NULL;

    if (!g_socket_bind(socket, addr, TRUE, &err)){
        //error
    }
 
    cb_data = luax_callback_data_ref (L, sock);
    int fd = g_socket_get_fd(socket);
    GIOChannel *channel = g_io_channel_unix_new(fd);
    guint source = g_io_add_watch(channel, G_IO_IN, (GIOFunc)gio_read_socket, cb_data);
    g_io_channel_unref(channel);

    return 0;
}

static int
l_socket_send(lua_State *L)
{
    socket_t *sock;
    GSocket *socket;
    GSocketAddress *addr;
    const char *host;
    const char *value;
    int port;
    size_t n_value;
    luax_callback_data_t *cb_data;
    GOutputStream *out;

    sock = socket_check(L, 1, &socket, &addr);
    if (unlikely(socket_is_connected(sock)))
        return error_throw_socket_already_connected(L, sock);

    host = luaL_checklstring(L, 2, NULL);
    port = CLAMP(luaL_checkint(L, 3), 0, G_MAXUINT16);
    value = luaL_checklstring(L, 4, &n_value);

    addr = g_inet_socket_address_new_from_string(host, port);

    GError *err = NULL;
   // g_socket_send_to(socket, addr, value, n_value, NULL, &err);
    g_socket_connect(socket, addr, NULL, &err);

    if (err != NULL)
        printf("ERROR: %s\n", err->message);

    g_socket_send(socket, value, n_value, NULL, &err);  

    if (err != NULL)
        printf("ERROR: %s\n", err->message);  

   // g_socket_close(socket, &err);
   //     printf("Error to close socket!");
       

    /*
  luaL_checktype (L, 3, LUA_TFUNCTION);

  lua_pushcclosure (L, l_socket_send_callback_closure, 3);
  cb_data = luax_callback_data_ref (L, sock);

  out = g_io_stream_get_output_stream (G_IO_STREAM (sock->conn));
  g_output_stream_write_async (out, data, n, G_PRIORITY_DEFAULT,
                               NULL, send_finished, cb_data);
*/
    return 0;
}

static const struct luaL_Reg socket_funcs[] = {
    {"new", l_socket_new},
    {"is_socket", l_socket_is_socket},
    {"bind", l_socket_bind},
    {"send", l_socket_send},
    {NULL, NULL}};

int luaopen_nclua_event_udp_socket(lua_State *L);

int luaopen_nclua_event_udp_socket(lua_State *L)
{
    G_TYPE_INIT_WRAPPER();
    lua_newtable(L);
    luax_newmetatable(L, SOCKET);
    luaL_setfuncs(L, socket_funcs, 0);
    return 1;
}