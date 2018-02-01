# cfg.mk -- Setup maintainer's makefile.
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

COPYRIGHT_YEAR= 2018
COPYRIGHT_HOLDER= PUC-Rio/Laboratorio TeleMidia

INDENT_EXCLUDE=\
  lib/nclua.h\
  lib/ncluaw.h\
  $(NULL)

INDENT_JOIN_EMPTY_LINES_EXCLUDE=\
  examples/luarocks/%\
  $(NULL)

INDENT_TYPES=\
  GAsyncResult\
  GError\
  GObject\
  GParamSpec\
  GValue\
  GdkEventButton\
  GdkEventConfigure\
  GdkEventKey\
  GdkEventMotion\
  GdkFrameClock\
  GstBaseSrc\
  GstBuffer\
  GstBus\
  GstCaps\
  GstClockTime\
  GstEvent\
  GstMessage\
  GstNCLuaClass\
  GstNCLua\
  GstPlugin\
  GstPushSrc\
  GtkWidget\
  SoupMessage\
  SoupRequestHTTP\
  SoupSession\
  cairo_rectangle_int_t\
  cairo_surface_t\
  cairo_t\
  canvas_t\
  gchar\
  gint\
  guint64\
  lua_State\
  luax_callback_data_t\
  ncluaw_event_t\
  ncluaw_t\
  socket_t\
  $(NULL)

SC_USELESS_IF_BEFORE_FREE_ALIASES=\
  cairo_destroy\
  cairo_region_destroy\
  cairo_surface_destroy\
  g_free\
  luax_callback_data_unref\
  ncluaw_event_free\
  pango_font_description_free\
  $(NULL)

SYNTAX_CHECK_EXCLUDE=\
  examples/luarocks/%\
  examples/pacman/%\
  tests/libnclua-echo.lua\
  $(NULL)

SC_COPYRIGHT_EXCLUDE=\
  build-aux/Makefile.am.common\
  build-aux/Makefile.am.coverage\
  build-aux/Makefile.am.env\
  build-aux/Makefile.am.gitlog\
  build-aux/Makefile.am.link\
  build-aux/Makefile.am.valgrind\
  examples/luarocks/%\
  examples/pacman/%\
  examples/www/tcp.lua\
  lib/aux-glib.h\
  lib/aux-gst.h\
  lib/aux-lua.h\
  maint.mk\
  tests/lua.c\
  $(NULL)

UPDATE_COPYRIGHT_EXCLUDE=\
  $(vc_list_exclude, $(SC_COPYRIGHT_EXCLUDE), examples/www/tcp.lua)\
  $(NULL)

SC_RULES+= sc-copyright
sc-copyright:
	$(V_at)$(build_aux)/syntax-check-copyright\
	  -b='/*' -e='*/' -t=cfg.mk\
	  $(call vc_list_exclude, $(VC_LIST_C), $(SC_COPYRIGHT_EXCLUDE))
	$(V_at)$(build_aux)/syntax-check-copyright\
	  -b='--[[' -e=']]--' -t=cfg.mk\
	  $(call vc_list_exclude, $(VC_LIST_LUA), $(SC_COPYRIGHT_EXCLUDE))
	$(V_at)$(build_aux)/syntax-check-copyright\
	  -b='#' -t=cfg.mk\
	  $(call vc_list_exclude,\
	    $(VC_LIST_AC)\
	    $(VC_LIST_AM)\
	    $(VC_LIST_MK)\
	    $(VC_LIST_PL)\
	    $(VC_LIST_SH),\
	    $(SC_COPYRIGHT_EXCLUDE))

# Copy utility stuff from gflima/autoutils project.
util:= https://github.com/gflima/autoutils/raw/master
UTIL_FILES+= build-aux/Makefile.am.common
UTIL_FILES+= build-aux/Makefile.am.coverage
UTIL_FILES+= build-aux/Makefile.am.env
UTIL_FILES+= build-aux/Makefile.am.gitlog
UTIL_FILES+= build-aux/Makefile.am.valgrind
UTIL_FILES+= build-aux/util.m4
UTIL_FILES+= lib/aux-glib.h
UTIL_FILES+= lib/aux-lua.h
UTIL_FILES+= maint.mk
UTIL_SCRIPTS+= bootstrap
UTIL_SCRIPTS+= build-aux/syntax-check
UTIL_SCRIPTS+= build-aux/syntax-check-copyright
REMOTE_FILES+= $(UTIL_FILES)
REMOTE_SCRIPTS+= $(UTIL_SCRIPTS)

fetch-remote-local:
	$(V_at)for path in $(UTIL_FILES) $(UTIL_SCRIPTS); do\
	  dir=`dirname "$$path"`;\
	  $(FETCH) -dir="$$dir" "$(util)/$$path" || exit 1;\
	done
