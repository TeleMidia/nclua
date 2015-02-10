/* nclua.event.http_soup -- Non-blocking, client HTTP requests.
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
#include <assert.h>

#include <lua.h>
#include <lauxlib.h>

#include <libsoup/soup.h>

#include "macros.h"
#include "luax-macros.h"
#include "luax-callback.h"

/* Registry key for the soup metatable.  */
#define SOUP "nclua.event.http_soup"

/* Soup object data.  */
typedef struct _soup_t
{
  SoupSession *session;         /* session handle */
} soup_t;

/* Check if the object at index INDEX is a soup object.
   If SESSION is non-null, stores the object's session
   handle in *SESSION.  */

static inline soup_t *
soup_check (lua_State *L, int index, SoupSession **session)
{
  soup_t *soup;
  soup = (soup_t *) luaL_checkudata (L, index, SOUP);
  test_and_set (session != NULL, *session, soup->session);
  return soup;
}

/* List of known HTTP methods.  */
static const char *const soup_method_list[] = {
  "GET", "POST", NULL
};

/* Throws an "invalid URI" error.  */
#define error_throw_invalid_uri(L, uri)                 \
  (lua_pushfstring (L, "invalid URI '%s'", uri),        \
   lua_error (L))

/* Throws an "invalid header FIELD" error.   */
#define error_throw_invalid_header(L, field, value)             \
  (lua_pushfstring (L, "invalid header %s '%s'", field, value), \
   lua_error (L))

/*-
 * soup.new ([timeout:number])
 * soup:new ([timeout:number])
 *     -> soup:userdata
 *
 * Creates a new soup session.
 *
 * If TIMEOUT is given, set the timeout for soup:request() to TIMEOUT
 * seconds.
 */
static int
l_soup_new (lua_State *L)
{
  soup_t *soup;
  guint timeout;

  luax_optudata (L, 1, SOUP);
  timeout = (guint) clamp (luaL_optint (L, 2, 0), 0, INT_MAX);
  soup = (soup_t *) lua_newuserdata (L, sizeof (*soup));
  assert (soup != NULL);
  soup->session = soup_session_new_with_options ("timeout", timeout, NULL);
  assert (soup->session != NULL);
  luaL_setmetatable (L, SOUP);

  return 1;
}

/*-
 * soup:__gc ()
 *
 * Destroys the given soup object.
 */
static int
__l_soup_gc (lua_State *L)
{
  SoupSession *session;

  soup_check (L, 1, &session);
  g_object_unref (session);

  return 0;
}

/*-
 * soup.cycle ()
 *
 * Cycles the soup engine one, i.e., process the pending requests for all
 * sessions, triggering the appropriate callbacks.
 */
static int
l_soup_cycle (arg_unused (lua_State *L))
{
  return (g_main_context_iteration (NULL, FALSE), 0);
}

/*-
 * soup:is_soup (obj:userdata) -> status:boolean
 *
 * Returns true if object OBJ is a soup object, or false otherwise.
 */
static int
l_soup_is_soup (lua_State *L)
{
  luax_optudata (L, 1, SOUP);
  lua_pushboolean (L, luaL_testudata (L, 2, SOUP) != NULL);
  return 1;
}

/*-
 * soup:request (method:string, uri:string, headers:table, body:string,
 *               callback:function)
 *
 * Makes an HTTP request with method METHOD, header HEADER, and body BODY to
 * the given URI.  Calls the callback function CALLBACK when the operation
 * is finished, i.e., when the response is available.
 *
 * If the response was successfully received, calls CALLBACK as follows:
 *
 *     CALLBACK(true, soup, method, uri, status_code, headers, body),
 *
 * where STATUS_CODE is the HTTP status code associated with the response,
 * HEADERS is a table containing the response headers, and BODY is a string
 * containing the response body.
 *
 * Otherwise, if the response could no be received, calls CALLBACK as
 * follows:
 *
 *     CALLBACK(false, soup, method, uri, errmsg),
 *
 * where ERRMSG is an error message.
 */
static void
request_finished (arg_unused (SoupSession *session),
                  SoupMessage *message, gpointer data)
{
  luax_callback_data_t *cb_data;
  lua_State *L;
  soup_t *soup;

  cb_data = (luax_callback_data_t *) data;
  luax_callback_data_get_data (cb_data, &L, (void **) &soup);

  luax_callback_data_unref (cb_data);
  assert (lua_type (L, -1) == LUA_TFUNCTION);

  if (!SOUP_STATUS_IS_TRANSPORT_ERROR (message->status_code))
    {
      SoupMessageHeadersIter it;
      const char *name;
      const char *value;

      lua_pushboolean (L, TRUE);
      lua_pushinteger (L, message->status_code);
      lua_newtable (L);
      soup_message_headers_iter_init (&it, message->response_headers);
      while (soup_message_headers_iter_next (&it, &name, &value))
        luax_setstringfield (L, -1, name, value);
      lua_pushlstring (L, message->response_body->data,
                       (size_t) message->response_body->length);
      lua_call (L, 4, 0);
    }
  else
    {
      lua_pushboolean (L, FALSE);
      lua_pushstring (L, soup_status_get_phrase (message->status_code));
      lua_call (L, 2, 0);
    }
}

static int
l_soup_request_callback_closure (lua_State *L)
{
  if (lua_toboolean (L, 1))
    {
      assert (lua_type (L, 1) == LUA_TBOOLEAN);
      assert (lua_type (L, 2) == LUA_TNUMBER);
      assert (lua_type (L, 3) == LUA_TTABLE);
      assert (lua_type (L, 4) == LUA_TSTRING);

      lua_pushvalue (L, 1);     /* true */
      luax_pushupvalue (L, 1);  /* soup */
      luax_pushupvalue (L, 2);  /* method */
      luax_pushupvalue (L, 3);  /* uri */
      lua_pushvalue (L, 2);     /* status_code */
      lua_pushvalue (L, 3);     /* headers */
      lua_pushvalue (L, 4);     /* body */

      luax_pushupvalue (L, 4);  /* callback */
      lua_insert (L, -8);
      lua_call (L, 7, 0);
    }
  else
    {
      assert (lua_type (L, 1) == LUA_TBOOLEAN);
      assert (lua_type (L, 2) == LUA_TSTRING);

      lua_pushvalue (L, 1);     /* false */
      luax_pushupvalue (L, 1);  /* soup */
      luax_pushupvalue (L, 2);  /* method */
      luax_pushupvalue (L, 3);  /* uri */
      lua_pushvalue (L, 2);     /* errmsg */

      luax_pushupvalue (L, 4);  /* callback */
      lua_insert (L, -6);
      lua_call (L, 5, 0);
    }
  return 0;
}

static int
l_soup_request (lua_State *L)
{
  soup_t *soup;
  int method;
  const char *uri;
  const char *body;
  size_t n;

  luax_callback_data_t *cb_data;
  SoupMessage *message;

  soup = soup_check (L, 1, NULL);
  method = luaL_checkoption (L, 2, NULL, soup_method_list);
  uri = luaL_checkstring (L, 3);
  luaL_checktype (L, 4, LUA_TTABLE);
  body = luaL_checklstring (L, 5, &n);
  luaL_checktype (L, 6, LUA_TFUNCTION);

  message = soup_message_new (soup_method_list[method], uri);
  if (unlikely (message == NULL))
    return error_throw_invalid_uri (L, uri);

  soup_message_body_append (message->request_body,
                            SOUP_MEMORY_COPY, body, n);
  lua_pushnil (L);
  while (lua_next (L, 4) != 0)
    {
      if (lua_isstring (L, -2) && lua_isstring (L, -1))
        {
          const char *name;
          const char *value;

          name = lua_tostring (L, -2);
          if (strpbrk (name, " \t\r\n:"))
            return error_throw_invalid_header (L, "name", name);

          value = lua_tostring (L, -1);
          if (strpbrk (value, "\r\n"))
            return error_throw_invalid_header (L, "value", value);

          soup_message_headers_append (message->request_headers, name,
                                       value);
        }
      lua_pop (L, 1);
    }

  lua_pushvalue (L, 1);         /* soup */
  lua_pushvalue (L, 2);         /* method */
  lua_pushvalue (L, 3);         /* uri */
  lua_pushvalue (L, 6);         /* callback */
  lua_pushcclosure (L, l_soup_request_callback_closure, 4);
  cb_data = luax_callback_data_ref (L, soup);

  soup_session_queue_message (soup->session, message,
                              request_finished, cb_data);
  return 0;
}

static const struct luaL_Reg soup_funcs[] = {
  {"__gc", __l_soup_gc},
  {"cycle", l_soup_cycle},
  {"is_soup", l_soup_is_soup},
  {"new", l_soup_new},
  {"request", l_soup_request},
  {NULL, NULL}
};

int luaopen_nclua_event_http_soup (lua_State *L);

int
luaopen_nclua_event_http_soup (lua_State *L)
{
  G_TYPE_INIT_WRAPPER ();
  lua_newtable (L);
  luax_newmetatable (L, SOUP);
  luaL_setfuncs (L, soup_funcs, 0);
  return 1;
}
