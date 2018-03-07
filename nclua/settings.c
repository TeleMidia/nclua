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
#include <string.h>
#include <sys/ioctl.h>
#include <net/if.h>
#include <netdb.h>

/* Registry key for the dir metatable.  */
#define SETTINGS "nclua.settings"
#define PREFIX_INET "inet"
#define PREFIX_INET6 "inet6"

/*-
 * Push settings.inet[index] properties to L
 *
 */
static void
push_one_interface (lua_State *L, int family, int fd, const char *name)
{
  int i;
  struct ifreq ifr;
  struct sockaddr_in *ipaddr;
  char address[INET_ADDRSTRLEN] = "";
  char parentIndex[INET_ADDRSTRLEN] = "";
  char mac[19] = "";
  int mtu = 0, active = 0, loopback = 0, pointToPoint,
      supportsMulticast = 0, slave = 0;

  // name and displayName
  lua_pushliteral (L, "name");
  lua_pushstring (L, name);
  lua_rawset (L, -3);
  lua_pushliteral (L, "displayName");
  lua_pushstring (L, name);
  lua_rawset (L, -3);

  // init ifr
  memset (&ifr, 0, sizeof ifr);
  strncpy (ifr.ifr_name, name, IFNAMSIZ);

  // active, loopback, pointToPoint and supportsMulticast
  if (ioctl (fd, SIOCGIFFLAGS, &ifr) != -1)
    {
      active = (ifr.ifr_flags & IFF_UP) == IFF_UP;
      loopback = (ifr.ifr_flags & IFF_LOOPBACK) == IFF_LOOPBACK;
      pointToPoint = (ifr.ifr_flags & IFF_POINTOPOINT) == IFF_POINTOPOINT;
      supportsMulticast = (ifr.ifr_flags & IFF_MULTICAST) == IFF_MULTICAST;
      slave = (ifr.ifr_flags & IFF_SLAVE) == IFF_SLAVE;
    }
  lua_pushliteral (L, "active");
  lua_pushboolean (L, active);
  lua_rawset (L, -3);
  lua_pushliteral (L, "loopback");
  lua_pushboolean (L, loopback);
  lua_rawset (L, -3);
  lua_pushliteral (L, "pointToPoint");
  lua_pushboolean (L, pointToPoint);
  lua_rawset (L, -3);
  lua_pushliteral (L, "supportsMulticast");
  lua_pushboolean (L, supportsMulticast);
  lua_rawset (L, -3);
  lua_pushliteral (L, "isSlave");
  lua_pushboolean (L, slave);
  lua_rawset (L, -3);

  // inetAddress
  if (ioctl (fd, SIOCGIFADDR, &ifr) != -1)
    {
      ipaddr = (struct sockaddr_in *) &ifr.ifr_addr;
      inet_ntop (AF_INET, &ipaddr->sin_addr, address, sizeof (address));
    }
  lua_pushliteral (L, "inetAddress");
  lua_pushstring (L, address);
  lua_rawset (L, -3);

  // inetAddress
  if (ioctl (fd, SIOCGIFSLAVE, &ifr) != -1)
    {
      ipaddr = (struct sockaddr_in *) &ifr.ifr_addr;
      inet_ntop (AF_INET, &ipaddr->sin_addr, address, sizeof (address));
    }
  lua_pushliteral (L, "parentIndex");
  lua_pushstring (L, parentIndex);
  lua_rawset (L, -3);

  // hwAddress
  if (ioctl (fd, SIOCGIFHWADDR, &ifr) != -1)
    sprintf (mac, "%02x:%02x:%02x:%02x:%02x:%02x",
             (unsigned char) ifr.ifr_hwaddr.sa_data[0],
             (unsigned char) ifr.ifr_hwaddr.sa_data[1],
             (unsigned char) ifr.ifr_hwaddr.sa_data[2],
             (unsigned char) ifr.ifr_hwaddr.sa_data[3],
             (unsigned char) ifr.ifr_hwaddr.sa_data[4],
             (unsigned char) ifr.ifr_hwaddr.sa_data[5]);
  lua_pushliteral (L, "hwAddress");
  lua_pushstring (L, mac);
  lua_rawset (L, -3);

  // mtu
  if (ioctl (fd, SIOCGIFMTU, &ifr) != -1)
    mtu = ifr.ifr_mtu;
  lua_pushliteral (L, "mtu");
  lua_pushnumber (L, mtu);
  lua_rawset (L, -3);

  // bcastAddress
  if (ioctl (fd, SIOCGIFBRDADDR, &ifr) != -1)
    {
      ipaddr = (struct sockaddr_in *) &ifr.ifr_broadaddr;
      inet_ntop (AF_INET, &ipaddr->sin_addr, address, sizeof (address));
    }
  lua_pushliteral (L, "bcastAddress");
  lua_pushstring (L, address);
  lua_rawset (L, -3);

  if (ioctl (fd, SIOCGIFNETMASK, &ifr) != -1)
    {
      ipaddr = (struct sockaddr_in *) &ifr.ifr_netmask;
      inet_ntop (AF_INET, &ipaddr->sin_addr, address, sizeof (address));
    }
  lua_pushliteral (L, "subnetMask");
  lua_pushstring (L, address);
  lua_rawset (L, -3);
}

static void
push_interfaces (lua_State *L, int family)
{
  int fd;
  struct ifreq *ifr;
  struct ifconf ifconf;
  char buf[16384];
  int i, index;
  size_t len;
  char *fieldname;

  if (family == AF_INET)
    fieldname = "inet";
  else
    fieldname = "inet6";

  // create socket for a given family
  fd = socket (family, SOCK_DGRAM, 0);
  if (fd < 0)
    {
      perror ("socket()");
      return;
    }

  // configure ifr
  ifconf.ifc_len = sizeof buf;
  ifconf.ifc_buf = buf;
  if (ioctl (fd, SIOCGIFCONF, &ifconf) != 0)
    {
      perror ("ioctl(SIOCGIFCONF)");
      return;
    }
  ifr = ifconf.ifc_req;

  // settings.inet = {}
  lua_pushstring (L, fieldname);
  lua_newtable (L);
  for (i = 0, index = 1; i < ifconf.ifc_len; index++)
    {
      // printf("%s,%d\n",fieldname, index);
      // settings.inet[index] = {}
      lua_newtable (L);
      push_one_interface (L, family, fd, ifr->ifr_name);
      lua_rawseti (L, -2, index);

      len = sizeof *ifr;
      ifr = (struct ifr *) ((char *) ifr + len);
      i += len;
    }
  lua_rawset (L, -3);
  close (fd);
}

int
luaopen_nclua_settings (lua_State *L)
{
  luax_newmetatable (L, SETTINGS);

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
  push_interfaces (L, AF_INET);  // IPv4
  push_interfaces (L, AF_INET6); // IPv6

  return 1;
}
