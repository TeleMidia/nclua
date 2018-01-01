/* ncluaw.h -- The NCLua wrapper (Lua-free) interface.
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

#ifndef NCLUAW_H
#define NCLUAW_H

#include <ncluaconf.h>

NCLUA_BEGIN_DECLS

#define ncluaw_t void

typedef enum _ncluaw_event_class_t
{
  NCLUAW_EVENT_KEY,
  NCLUAW_EVENT_NCL,
  NCLUAW_EVENT_POINTER,
  NCLUAW_EVENT_UNKNOWN
} ncluaw_event_class_t;

typedef struct _ncluaw_event_t
{
  ncluaw_event_class_t cls;
  union
  {
    struct
    {
      const char *type;
      const char *key;
    } key;

    struct
    {
      const char *type;
      const char *action;
      const char *name;
      const char *value;
    } ncl;

    struct
    {
      const char *type;
      int x;
      int y;
    } pointer;
  } u;
} ncluaw_event_t;

#define ncluaw_event_key_init(e, _type, _key)   \
  do {                                          \
    (e)->cls = NCLUAW_EVENT_KEY;                \
    (e)->u.key.type = _type;                    \
    (e)->u.key.key = _key;                      \
  } while (0)

#define ncluaw_event_ncl_init(e, _type, _action, _name, _value) \
  do {                                                          \
    (e)->cls = NCLUAW_EVENT_NCL;                                \
    (e)->u.ncl.type = _type;                                    \
    (e)->u.ncl.action = _action;                                \
    (e)->u.ncl.name = _name;                                    \
    (e)->u.ncl.value = _value;                                  \
  } while (0)

#define ncluaw_event_pointer_init(e, _type, _x, _y)     \
  do {                                                  \
    (e)->cls = NCLUAW_EVENT_POINTER;                    \
    (e)->u.pointer.type = _type;                        \
    (e)->u.pointer.x = _x;                              \
    (e)->u.pointer.y = _y;                              \
  } while (0)

NCLUA_API ncluaw_event_t *ncluaw_event_clone (const ncluaw_event_t *);
NCLUA_API void ncluaw_event_free (ncluaw_event_t *);
NCLUA_API int ncluaw_event_equals (const ncluaw_event_t *,
                                   const ncluaw_event_t *);

NCLUA_API ncluaw_t *ncluaw_open (const char *, int, int, char **);
NCLUA_API void ncluaw_close (ncluaw_t *);

typedef void (*ncluaw_panic_function_t) (ncluaw_t *, const char *);
NCLUA_API ncluaw_panic_function_t ncluaw_at_panic (ncluaw_t *,
                                                   ncluaw_panic_function_t);

NCLUA_API void ncluaw_cycle (ncluaw_t *);
NCLUA_API ncluaw_event_t *ncluaw_receive (ncluaw_t *);
NCLUA_API void ncluaw_send (ncluaw_t *, const ncluaw_event_t *);

#define ncluaw_send_key_event(nw, type, key)    \
  do {                                          \
    ncluaw_event_t __evt;                       \
    ncluaw_event_key_init (&__evt, type, key);  \
    ncluaw_send (nw, &__evt);                   \
  } while (0)

#define ncluaw_send_ncl_event(nw, type, action, name, value)    \
  do {                                                          \
    ncluaw_event_t __evt;                                       \
    ncluaw_event_ncl_init (&__evt, type, action, name, value);  \
    ncluaw_send (nw, &__evt);                                   \
  } while (0)

#define ncluaw_send_pointer_event(nw, type, x, y)       \
  do {                                                  \
    ncluaw_event_t __evt;                               \
    ncluaw_event_pointer_init (&__evt, type, x, y);     \
    ncluaw_send (nw, &__evt);                           \
  } while (0)

NCLUA_API void ncluaw_paint (ncluaw_t *, unsigned char *, const char *,
                             int, int, int);
NCLUA_API void ncluaw_resize (ncluaw_t *, int, int);

NCLUA_API int ncluaw_debug_dump_surface (ncluaw_t *, const char *, char **);
NCLUA_API void *ncluaw_debug_get_lua_state (ncluaw_t *);
NCLUA_API void *ncluaw_debug_get_surface (ncluaw_t *);

NCLUA_END_DECLS

#endif /* NCLUAW_H */
