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
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <net/if.h>
#include <netdb.h>

/* Registry key for the dir metatable.  */
#define SETTINGS "nclua.settings"
#define PREFIX_INET "inet"
#define PREFIX_INET6 "inet6"

static void
push_interface (lua_State *L, int index, int fd, const char *name)
{
  int family;
  struct ifreq ifreq;
  char host[128];
  memset (&ifreq, 0, sizeof ifreq);
  strncpy (ifreq.ifr_name, name, IFNAMSIZ);
  if (ioctl (fd, SIOCGIFADDR, &ifreq) != 0)
      return;
  switch (family = ifreq.ifr_addr.sa_family)
    {
    case AF_UNSPEC:
      return;
    case AF_INET:
    case AF_INET6:
      getnameinfo (&ifreq.ifr_addr, sizeof ifreq.ifr_addr, host,
                   sizeof host, 0, 0, NI_NUMERICHOST);
      break;
    default:
      sprintf (host, "unknown (family: %d)", family);
    }
  lua_pushliteral (L, "name");
  lua_pushstring (L, name);
  lua_pushliteral (L, "address");
  lua_pushstring (L, host);
  lua_rawset (L, -5);
}

static void
push_interfaces (lua_State *L, int family)
{
  int fd;
  struct ifreq *ifreq;
  struct ifconf ifconf;
  char buf[16384];
  char fieldname[128];
  unsigned i, index;
  size_t len;

  fd = socket (family, SOCK_DGRAM, 0);
  if (fd < 0)
    {
      perror ("socket()");
      return;
    }

  ifconf.ifc_len = sizeof buf;
  ifconf.ifc_buf = buf;
  if (ioctl (fd, SIOCGIFCONF, &ifconf) != 0)
    {
      perror ("ioctl(SIOCGIFCONF)");
      return;
    }

  ifreq = ifconf.ifc_req;

  if (family == PF_INET)
    sprintf (fieldname, "inet", index);
  else
    sprintf (fieldname, "inet6", index);

  lua_pushstring (L, fieldname);
  lua_newtable (L);
  for (i = 0, index = 0; i < ifconf.ifc_len; index++)
    {
      lua_pushnumber (L, index);
      lua_newtable (L);
      push_interface (L, index, fd, ifreq->ifr_name);
      lua_rawset (L, -3);

      len = sizeof *ifreq;
      ifreq = (struct ifreq *) ((char *) ifreq + len);
      i += len;
    }
  lua_rawset (L, -5);
  lua_rawset (L, -3);
  close (fd);
}

int
luaopen_nclua_settings (lua_State *L)
{
  luax_newmetatable (L, SETTINGS);
  G_TYPE_INIT_WRAPPER ();

  // system.luaVersion
  lua_pushliteral (L, PACKAGE_VERSION);
  lua_setfield (L, -2, "luaVersion");
  lua_pushinteger (L, NCLUA_VERSION_MAJOR);
  lua_setfield (L, -2, "luaVersionMajor");
  lua_pushinteger (L, NCLUA_VERSION_MINOR);
  lua_setfield (L, -2, "luaVersionMinor");
  lua_pushinteger (L, NCLUA_VERSION_MICRO);
  lua_setfield (L, -2, "luaVersionMicro");

  // system.network
  push_interfaces (L, PF_INET);      // IPv4
  push_interfaces (L, PF_INET6);     // IPv6

  return 1;
}
