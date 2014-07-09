# Makefile.am -- Template for generating Makefile via Automake.
# Copyright (C) 2013-2014 PUC-Rio/Laboratorio TeleMidia
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

AM_CPPFLAGS = -I$(top_srcdir)/lib -I$(top_builddir)/lib
AM_CFLAGS = $(WERROR_CFLAGS) $(WARN_CFLAGS) $(LUA_CFLAGS)
AM_LDFLAGS = -shared -module -avoid-version  -no-undefined $(LUA_LIBS)

eventlibdir = $(lualibdir)/event
eventdatadir = $(luadatadir)/event

eventlib_LTLIBRARIES =\
  socket.la\
  stopwatch.la\
  $(NULL)

dist_eventdata_DATA =\
  check.lua\
  engine.lua\
  init.lua\
  key.lua\
  ncl.lua\
  pointer.lua\
  queue.lua\
  tcp.lua\
  user.lua\
  $(NULL)

if OS_WIN32
socket_export_symbols = -export-symbols socket.def
socket_def_dependency = socket.def

stopwatch_export_symbols = -export-symbols stopwatch.def
stopwatch_def_dependency = stopwatch.def
endif

CLEANFILES += socket.def stopwatch.def
socket.def stopwatch.def:
	$(AM_V_GEN) (echo EXPORTS;\
	echo luaopen_nclua_event_`echo "$@" | sed s/\.def//`) >$@

socket_la_DEPENDENCIES = $(socket_def_dependency)
socket_la_CFLAGS = $(AM_CFLAGS) $(GLIB_CFLAGS) $(GIO_CFLAGS)
socket_la_LDFLAGS = $(AM_LDFLAGS) $(GLIB_LIBS) $(GIO_LIBS)\
  $(socket_export_symbols)

stopwatch_la_DEPENDENCIES = $(stopwatch_def_dependency)
stopwatch_la_CFLAGS = $(AM_CFLAGS) $(GLIB_CFLAGS)
stopwatch_la_LDFLAGS = $(AM_LDFLAGS) $(GLIB_LIBS)\
  $(stopwatch_export_symbols)
