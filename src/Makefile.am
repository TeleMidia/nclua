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

AM_CPPFLAGS = -I$(top_srcdir)/lib -I$(top_builddir)/lib
AM_CFLAGS = $(WERROR_CFLAGS) $(WARN_CFLAGS)\
  $(LUA_CFLAGS) $(CAIRO_CFLAGS) $(GLIB_CFLAGS) $(GTK_CFLAGS)
AM_LDFLAGS = $(LUA_LIBS) $(CAIRO_LIBS) $(GLIB_LIBS) $(GTK_LIBS)
LDADD = $(top_builddir)/lib/libnclua.la

if HAVE_GTK
bin_PROGRAMS = nclua
endif
