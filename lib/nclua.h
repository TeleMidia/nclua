/* nclua.h -- The NCLua core interface.
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

#ifndef NCLUA_H
#define NCLUA_H

#include <lua.h>
#include <ncluaconf.h>

NCLUA_BEGIN_DECLS

NCLUA_API int nclua_open (lua_State *, int, int, const char *const *);
NCLUA_API void nclua_close (lua_State *);
NCLUA_API void nclua_cycle (lua_State *);
NCLUA_API void nclua_receive (lua_State *);
NCLUA_API void nclua_send (lua_State *);

NCLUA_API void nclua_paint (lua_State *, unsigned char *, const char *,
                            int, int, int);
NCLUA_API void nclua_resize (lua_State *, int, int);

NCLUA_API int nclua_debug_dump_surface (lua_State *, const char *);
NCLUA_API void *nclua_debug_get_registry_index (void);
NCLUA_API void *nclua_debug_get_surface (lua_State *);

NCLUA_END_DECLS

#endif /* NCLUA_H */
