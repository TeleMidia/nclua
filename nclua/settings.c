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
#include "ncluaconf.h"

/* Registry key for the dir metatable.  */
#define SETTINGS "nclua.settings"

int
luaopen_nclua_settings (lua_State *L)
{
  char *buf = "";

  G_TYPE_INIT_WRAPPER ();
  luax_newmetatable (L, SETTINGS);
  lua_pushliteral (L, PACKAGE_VERSION);
  lua_setfield (L, -2, "luaVersion");
  lua_pushinteger (L, NCLUA_VERSION_MAJOR);
  lua_setfield (L, -2, "luaVersionMajor");
  lua_pushinteger (L, NCLUA_VERSION_MINOR);
  lua_setfield (L, -2, "luaVersionMinor");
  lua_pushinteger (L, NCLUA_VERSION_MICRO);
  lua_setfield (L, -2, "luaVersionMicro");
  return 1;
}
