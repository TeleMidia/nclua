# Makefile.am -- Template for generating Makefile via Automake.
# Copyright (C) 2013-2015 PUC-Rio/Laboratorio TeleMidia
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

SUBDIRS= event

AM_CPPFLAGS= -I$(top_srcdir)/lib -I$(top_builddir)/lib
AM_CFLAGS= $(WERROR_CFLAGS) $(WARN_CFLAGS) $(LUA_CFLAGS)
AM_LDFLAGS= -module $(LT_MODULE_LDFLAGS) $(LIBM) $(LUA_LIBS)

lualib_LTLIBRARIES=\
  canvas.la\
  $(NULL)

if OS_WIN32
canvas_export_symbols= -export-symbols canvas.def
canvas_def_depedency= canvas.def
endif

CLEANFILES+= canvas.def
canvas.def:
	$(AM_V_GEN) (echo EXPORTS; echo luaopen_nclua_canvas) >$@

canvas_la_DEPENDENCIES= $(canvas_def_depedency)
canvas_la_CFLAGS= $(AM_CFLAGS) $(CAIRO_CFLAGS)\
  $(GLIB_CFLAGS) $(PANGO_CFLAGS)
canvas_la_LDFLAGS= $(AM_LDFLAGS) $(CAIRO_LIBS)\
  $(GLIB_LIBS) $(PANGO_LIBS) $(canvas_export_symbols)
canvas_la_SOURCES= canvas.c canvas-color-table.h

if WITH_NCLUA_GTK
canvas_la_CFLAGS+= $(GTK_CFLAGS)
canvas_la_LDFLAGS+= $(GTK_LIBS)
endif
