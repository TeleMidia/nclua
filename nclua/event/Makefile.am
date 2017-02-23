# Makefile.am -- Template for generating Makefile via Automake.
# Copyright (C) 2013-2017 PUC-Rio/Laboratorio TeleMidia
#
# This file is part of NCLua.
#
# NCLua is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# NCLua is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
# License for more details.
#
# You should have received a copy of the GNU General Public License
# along with NCLua.  If not, see <http://www.gnu.org/licenses/>.

include $(top_srcdir)/build-aux/Makefile.am.common
include $(top_srcdir)/build-aux/Makefile.am.link

AM_CPPFLAGS= -I$(top_srcdir)/lib -I$(top_builddir)/lib
AM_CFLAGS= $(WERROR_CFLAGS) $(WARN_CFLAGS) $(LUA_CFLAGS)
AM_LDFLAGS= -module $(LT_MODULE_LDFLAGS)

EXTRA_DIST=
noinst_HEADERS= luax-callback.h

eventlib_LTLIBRARIES=
eventlibdir= $(nclualibdir)/event
eventdatadir= $(ncluadatadir)/event

dist_eventdata_DATA=\
  check.lua\
  engine.lua\
  init.lua\
  key.lua\
  ncl.lua\
  pointer.lua\
  queue.lua\
  user.lua\
  $(NULL)

if WITH_EVENT_GEOLOCATION
dist_eventdata_DATA+= geolocation.lua
else
EXTRA_DIST+= geolocation.lua
endif

if WITH_EVENT_HTTP
dist_eventdata_DATA+= http.lua
else
EXTRA_DIST+= http.lua
endif

if WITH_EVENT_TCP
dist_eventdata_DATA+= tcp.lua
else
EXTRA_DIST+= tcp.lua
endif

if OS_WIN32
def_dependency=
endif

# http_soup
if WITH_EVENT_HTTP
eventlib_LTLIBRARIES+= http_soup.la
if OS_WIN32
http_soup_def_dependency= http_soup.def
def_dependency+= $(http_soup_def_dependency)
http_soup_export_symbols= -export-symbols $(http_soup_def_dependency)
endif
http_soup_la_DEPENDENCIES= $(http_soup_def_dependency)
http_soup_la_CFLAGS= $(AM_CFLAGS) $(SOUP_CFLAGS)
http_soup_la_LDFLAGS= $(AM_LDFLAGS) $(SOUP_LIBS)\
  $(http_soup_export_symbols)
http_soup_la_SOURCES=\
  luax-callback.h\
  http_soup.c\
  $(NULL)
endif

# stopwatch
eventlib_LTLIBRARIES+= stopwatch.la
if OS_WIN32
stopwatch_def_dependency= stopwatch.def
def_dependency+= $(stopwatch_def_dependency)
stopwatch_export_symbols= -export-symbols $(stopwatch_def_dependency)
endif
stopwatch_la_DEPENDENCIES= $(stopwatch_def_dependency)
stopwatch_la_CFLAGS= $(AM_CFLAGS) $(GLIB_CFLAGS)
stopwatch_la_LDFLAGS= $(AM_LDFLAGS) $(GLIB_LIBS)\
  $(stopwatch_export_symbols)
stopwatch_la_SOURCES=\
  stopwatch.c\
  $(NULL)

# tcp_socket
if WITH_EVENT_TCP
eventlib_LTLIBRARIES+= tcp_socket.la
if OS_WIN32
tcp_socket_def_dependency= tcp_socket.def
def_dependency+= $(tcp_socket_def_dependency)
tcp_socket_export_symbols= -export-symbols $(tcp_socket_def_dependency)
endif
tcp_socket_la_DEPENDENCIES= $(tcp_socket_def_dependency)
tcp_socket_la_CFLAGS= $(AM_CFLAGS) $(GLIB_CFLAGS) $(GIO_CFLAGS)
tcp_socket_la_LDFLAGS= $(AM_LDFLAGS) $(GLIB_LIBS) $(GIO_LIBS)\
  $(tcp_socket_export_symbols)
tcp_socket_la_SOURCES=\
  luax-callback.h\
  tcp_socket.c\
  $(NULL)
endif

# Generate .def files if we're on Win32.
if OS_WIN32
CLEANFILES+= $(def_dependency)
$(def_dependency):
	$(AM_V_GEN) (echo EXPORTS;\
	echo luaopen_nclua_event_`echo "$@" | sed s/\.def//`) >$@
endif
