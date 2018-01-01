# Makefile.am -- Template for generating Makefile via Automake.
# Copyright (C) 2013-2018 PUC-Rio/Laboratorio TeleMidia
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
# along with NCLua.  If not, see <https://www.gnu.org/licenses/>.

include $(top_srcdir)/build-aux/Makefile.am.common

AM_CPPFLAGS= -I$(top_srcdir)/lib -I$(top_builddir)/lib
AM_CFLAGS= $(WERROR_CFLAGS) $(WARN_CFLAGS)
AM_LDFLAGS= $(LIBM)

bin_PROGRAMS=

if WITH_NCLUA_GTK
bin_PROGRAMS+= nclua
endif
nclua_CFLAGS= $(AM_CFLAGS) $(CAIRO_CFLAGS)\
  $(GLIB_CFLAGS) $(GTK_CFLAGS) $(LUA_CFLAGS)
nclua_LDADD= $(top_builddir)/lib/libnclua.la
nclua_LDFLAGS= $(AM_LDFLAGS) $(CAIRO_LIBS)\
  $(GLIB_LIBS) $(GTK_LIBS) $(LUA_LIBS)
nclua_SOURCES=\
  nclua.c\
  $(NULL)

if WITH_NCLUA_GST
bin_PROGRAMS+= nclua-gst
endif
nclua_gst_CFLAGS= $(AM_CFLAGS) $(GSTREAMER_CFLAGS)
nclua_gst_LDFLAGS= $(AM_LDFLAGS) $(GSTREAMER_LIBS)
nclua_gst_SOURCES=\
  nclua-gst.c\
  $(NULL)
