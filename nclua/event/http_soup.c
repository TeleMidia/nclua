/* nclua.event.http_soup -- Non-blocking HTTP requests.
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
#include <strings.h>

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
  SoupRequestHTTP *request;     /* request handle */
  luaL_Buffer buffer;           /* response buffer */
  size_t buffer_size;           /* response buffer size */
  size_t serial;                /* response serial number */
  guint timeout;                /* response timeout (in seconds) */
  GCancellable *cancel;         /* used to cancel pending requests */
} soup_t;

/* Checks if the object at index INDEX is a soup object.
   If SESSION is non-null, stores object's session handle in *SESSION.
   If REQUEST is non-null, stores object's request handle in *REQUEST.  */

static inline soup_t *
soup_check (lua_State *L, int index, SoupSession **session,
            SoupRequestHTTP **request)
{
  soup_t *soup;
  soup = (soup_t *) luaL_checkudata (L, index, SOUP);
  set_if_nonnull (session, soup->session);
  set_if_nonnull (request, soup->request);
  return soup;
}

/* Throws an "invalid header FIELD" error.   */
#define error_throw_invalid_header(L, field, value)             \
  (lua_pushfstring (L, "invalid header %s '%s'", field, value), \
   lua_error (L))

/*-
 * soup.new ()
 * soup:new ()
 *     -> soup:userdata
 *
 * Creates a new soup session.
 */
static int
l_soup_new (lua_State *L)
{
  soup_t *soup;

  luax_optudata (L, 1, SOUP);
  soup = (soup_t *) lua_newuserdata (L, sizeof (*soup));
  assert (soup != NULL);        /* cannot fail */
  memset (soup, 0, sizeof (*soup));
  soup->session = soup_session_new ();
  assert (soup->session != NULL);       /* cannot fail */
  soup->cancel = g_cancellable_new ();
  assert (soup->cancel != NULL);        /* cannot fail */
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
  soup_t *soup;
  SoupSession *session;
  SoupRequestHTTP *request;

  soup = soup_check (L, 1, &session, &request);
  if (soup->cancel != NULL)
    {
      g_cancellable_cancel (soup->cancel);
      g_object_unref (soup->cancel);
    }
  if (request != NULL)
    {
      g_object_unref (request);
    }
  g_object_unref (session);

  return 0;
}

/*-
 * soup:cancel () -> status:boolean
 *
 * Cancels any ongoing HTTP requests associated with the given soup object.
 * Returns true if requests were canceled; otherwise, returns false.
 */
static int
l_soup_cancel (lua_State *L)
{
  soup_t *soup;

  soup = soup_check (L, 1, NULL, NULL);
  assert (soup->session != NULL);
  assert (soup->cancel != NULL);
  if (soup->request == NULL)
    {
      lua_pushboolean (L, FALSE);
      return 1;
    }

  g_cancellable_cancel (soup->cancel);
  g_object_unref (soup->cancel);
  soup->cancel = g_cancellable_new ();
  assert (soup->cancel != NULL);        /* cannot fail */
  g_object_unref (soup->request);
  soup->request = NULL;

  lua_pushboolean (L, TRUE);
  return 1;
}

/*-
 * soup.cycle ()
 *
 * Cycles the soup engine once, i.e., process the pending requests for all
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
 *               callback:function, [timeout:number], [buffer_size:number])
 *
 * Makes an HTTP request with method METHOD, headers HEADERS, and body BODY
 * to the given URI.  Calls the callback function CALLBACK whenever a
 * response chunk is received.
 *
 * If TIMEOUT is given, sets the request timeout to TIMEOUT seconds.
 * If BUFFER_SIZE is given, uses a buffer of BUFFER_SIZE bytes
 * (defaults to 4096 bytes) to collect the chunks of the response body.
 *
 * If a response chunk was successfully received, calls CALLBACK as follows:
 *
 *     CALLBACK(true, soup, method, uri, code, headers, body)
 *
 * where CODE is the HTTP status code associated with the response, HEADERS
 * is a table containing the response headers for this chunk, and BODY is a
 * string containing the reponse body for this chunk (an empty BODY signals
 * the last chunk).
 *
 * Otherwise, if the response could not be received, calls CALLBACK as
 * follows:
 *
 *     CALLBACK (false, soup, method, uri, nil, nil, nil, error)
 *
 * where ERROR is an error message.
 */
static void
request_finished (GObject *source, GAsyncResult *result, gpointer data)
{
  luax_callback_data_t *cb_data;
  lua_State *L;
  soup_t *soup;
  GInputStream *input;
  GError *error;
  char *buf;

  cb_data = (luax_callback_data_t *) data;
  luax_callback_data_get_data (cb_data, &L, (void **) &soup);

  input = NULL;
  if (SOUP_IS_REQUEST (source))
    {
      SoupRequest *request;

      request = SOUP_REQUEST (soup->request);
      if (unlikely (request == NULL || SOUP_REQUEST (source) != request))
        {
          error = g_error_new_literal (G_IO_ERROR, G_IO_ERROR_CANCELLED,
                                       "Operation was cancelled");
          goto fail;
        }

      error = NULL;
      input = soup_request_send_finish (request, result, &error);
      if (unlikely (error != NULL))
        goto fail;
    }
  else if (G_IS_INPUT_STREAM (source))
    {
      gssize n_received;

      input = G_INPUT_STREAM (source);
      error = NULL;
      n_received = g_input_stream_read_finish (input, result, &error);
      if (unlikely (n_received < 0))
        goto fail;

      assert (error == NULL);
      soup->serial++;

      luaL_pushresultsize (&soup->buffer, (size_t) n_received);
      luax_callback_data_push (cb_data);
      assert (lua_type (L, -1) == LUA_TFUNCTION);
      lua_pushboolean (L, TRUE);
      lua_pushvalue (L, -3);
      lua_call (L, 2, 0);

      if (n_received == 0)      /* eof */
        {
          luax_callback_data_unref (cb_data);
          g_object_unref (soup->request);
          soup->request = NULL;
          return;
        }
    }
  else
    {
      ASSERT_NOT_REACHED;       /* bad source */
    }

  assert (input != NULL);
  buf = luaL_buffinitsize (L, &soup->buffer, soup->buffer_size);
  g_input_stream_read_async (input, buf, soup->buffer_size,
                             G_PRIORITY_DEFAULT, soup->cancel,
                             request_finished, cb_data);
  return;

 fail:
  luax_callback_data_push_and_unref (cb_data);
  assert (lua_type (L, -1) == LUA_TFUNCTION);
  lua_pushboolean (L, FALSE);
  lua_pushstring (L, error->message);
  g_error_free (error);
  lua_call (L, 2, 0);
  return;
}

static int
l_soup_request_callback_closure (lua_State *L)
{
  if (lua_toboolean (L, 1))
    {
      soup_t *soup;
      SoupMessage *message;
      guint code;

      luax_pushupvalue (L, 1);
      soup = soup_check (L, -1, NULL, NULL);
      assert (soup->request != NULL);
      lua_pop (L, 1);

      message = soup_request_http_get_message (soup->request);
      assert (message != NULL);
      code = message->status_code;
      g_object_unref (message);

      assert (lua_type (L, 1) == LUA_TBOOLEAN);
      assert (lua_type (L, 2) == LUA_TSTRING);

      lua_pushvalue (L, 1);     /* true */
      luax_pushupvalue (L, 1);  /* soup */
      luax_pushupvalue (L, 2);  /* method */
      luax_pushupvalue (L, 3);  /* uri */
      lua_pushinteger (L, code);        /* code */
      if (soup->serial == 1)    /* headers */
        {
          SoupMessageHeadersIter it;
          const char *name;
          const char *value;
          lua_newtable (L);
          soup_message_headers_iter_init (&it, message->response_headers);
          while (soup_message_headers_iter_next (&it, &name, &value))
            luax_setstringfield (L, -1, name, value);
        }
      else
        {
          lua_pushnil (L);
        }
      lua_pushvalue (L, 2);     /* body */
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
      lua_pushnil (L);          /* code */
      lua_pushnil (L);          /* headers */
      lua_pushnil (L);          /* body */
      lua_pushvalue (L, 2);     /* error */
      luax_pushupvalue (L, 4);  /* callback */
      lua_insert (L, -9);
      lua_call (L, 8, 0);
    }
  return 0;
}

static int
l_soup_request (lua_State *L)
{
  soup_t *soup;
  SoupSession *session;
  SoupRequestHTTP *request;
  SoupMessage *message;
  luax_callback_data_t *cb_data;
  GError *error;

  const char *method;
  const char *uri;
  const char *body;
  size_t n;
  guint timeout;
  guint buffer_size;

  soup = soup_check (L, 1, &session, &request);
  assert (soup->session != NULL);
  assert (soup->cancel != NULL);

  if (unlikely (soup->request != NULL)) /* cancel pending request */
    {
      lua_pushcfunction (L, l_soup_cancel);
      lua_pushvalue (L, 1);
      lua_call (L, 1, 0);
    }

  method = luaL_checkstring (L, 2);
  uri = luaL_checkstring (L, 3);
  luaL_checktype (L, 4, LUA_TTABLE);
  body = luaL_checklstring (L, 5, &n);
  luaL_checktype (L, 6, LUA_TFUNCTION);
  timeout = (guint) clamp (luaL_optint (L, 7, 0), 0, INT_MAX);
  buffer_size = (guint) clamp (luaL_optint (L, 8, 4096), 1, INT_MAX);

  error = NULL;
  soup->request = soup_session_request_http (session, method, uri, &error);
  if (unlikely (error != NULL))
    {
      lua_pushfstring (L, "%s", error->message);
      g_error_free (error);
      return lua_error (L);
    }

  soup->buffer_size = buffer_size;
  soup->timeout = timeout;
  soup->serial = 0;

  if (timeout > 0)
    g_object_set (session, "timeout", timeout, NULL);

  message = soup_request_http_get_message (soup->request);
  assert (message != NULL);
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
          if (unlikely (strpbrk (name, " \t\r\n:") != NULL))
            return error_throw_invalid_header (L, "name", name);

          value = lua_tostring (L, -1);
          if (unlikely (strpbrk (value, "\r\n") != NULL))
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

  soup_request_send_async (SOUP_REQUEST (soup->request), soup->cancel,
                           request_finished, cb_data);
  return 0;
}

static const struct luaL_Reg soup_funcs[] = {
  {"__gc", __l_soup_gc},
  {"cancel", l_soup_cancel},
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
