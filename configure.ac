# configure.ac -- Configure template for NCLua.
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

AC_PREREQ([2.62])

AU_GIT_VERSION_GEN([nclua])
AC_INIT([NCLua],
  nclua_version_string,
 [gflima@telemidia.puc-rio.br],
 [nclua],
 [http://github.com/gflima/nclua])

AC_CONFIG_AUX_DIR([build-aux])
AC_CONFIG_MACRO_DIR([build-aux])
AC_USE_SYSTEM_EXTENSIONS
AC_CONFIG_SRCDIR([lib/nclua.h])
AC_CONFIG_HEADERS([lib/config.h])
AU_GITLOG_TO_CHANGELOG([2014-04-08])

AM_INIT_AUTOMAKE([1.14 -Wall -Werror dist-xz gnu no-dist-gzip])
AM_SILENT_RULES([yes])
AM_PROG_AR

LT_PREREQ([2.2])
LT_INIT([win32-dll])
AU_LIBTOOL_MODULE_LDFLAGS

# NCLua (package) version.
AC_SUBST([NCLUA_VERSION_MAJOR], nclua_version_major)
AC_SUBST([NCLUA_VERSION_MINOR], nclua_version_minor)
AC_SUBST([NCLUA_VERSION_MICRO], nclua_version_micro)
AC_SUBST([NCLUA_VERSION_STRING], nclua_version_string)

# Libnclua version.
# - library code modified:            REVISION++
# - interfaces changed/added/removed: REVISION=0, CURRENT++
# - interfaces added:                 AGE++
# - interfaces removed:               AGE=0
AU_LIBTOOL_VERSION([NCLUA], [1], [0], [1])

# Dependencies version.
m4_define([cairo_required_version], [1.10.2])
m4_define([glib_required_version], [2.32.4])
m4_define([gstreamer_required_version], [1.4.0])
m4_define([gtk_required_version], [3.4.2])
m4_define([lua_required_version], [5.2])
m4_define([pango_required_version], [1.30.0])
m4_define([soup_required_version], [2.42])
AC_SUBST([CAIRO_REQUIRED_VERSION], cairo_required_version)
AC_SUBST([GLIB_REQUIRED_VERSION], glib_required_version)
AC_SUBST([GSTREAMER_REQUIRED_VERSION], gstreamer_required_version)
AC_SUBST([GTK_REQUIRED_VERSION], gtk_required_version)
AC_SUBST([LUA_REQUIRED_VERSION], lua_required_version)
AC_SUBST([PANGO_REQUIRED_VERSION], pango_required_version)
AC_SUBST([SOUP_REQUIRED_VERSION], soup_required_version)

# Tool checks.
AU_PROG_CC_VISIBILITY
AU_PROG_PKG_CONFIG
AU_PROG_UNIX_TOOLS

# System checks.
AU_SYSTEM
AU_SYSTEM_MINGW

# Configure options.
AU_ARG_ENABLE_COVERAGE
AU_ARG_ENABLE_DEBUG
AU_ARG_ENABLE_VALGRIND

nw=
nw="$nw -Wsystem-headers"     # suppress system headers warnings
nw="$nw -Wpadded"             # our structs are not packed
nw="$nw -Wcast-qual"          # triggered by GLib headers
nw="$nw -Wc++-compat"         # ditto
AU_ARG_ENABLE_WARNINGS([$nw])

# Library functions.
AC_CHECK_LIBM

# Check for Lua.
AU_CHECK_LUA(lua_required_version)
LUA_LIBS="$LUA_LIBS -export-dynamic"
AS_IF([test "$au_lua_version" = 5.3],
 [AC_DEFINE([LUA_COMPAT_APIINTCASTS], [1],
   [Define to 1 to enable Lua macros for integer manipulation])])
AC_SUBST([ncluadatadir], ["${luadatadir}/$PACKAGE"])
AC_SUBST([nclualibdir], ["${lualibdir}/$PACKAGE"])

# Check for Cairo.
AU_VERSION_BREAK([cairo], cairo_required_version)
AU_CHECK_PKG([CAIRO], [cairo >= cairo_required_version],
 [AC_LANG_PROGRAM([[
#include <cairo.h>
#if CAIRO_VERSION_ENCODE \
   (CAIRO_REQUIRED_MAJOR,\
    CAIRO_REQUIRED_MINOR,\
    CAIRO_REQUIRED_MICRO) > CAIRO_VERSION
# error "cairo is too old"
#endif
 ]])],
 [AC_LANG_PROGRAM([[]], [[cairo_create (0);]])])

# Check for GLib.
AU_VERSION_BREAK([glib], glib_required_version)
AU_CHECK_PKG([GLIB],
  glib-2.0 >= glib_required_version dnl
  gobject-2.0 >= glib_required_version,
 [AC_LANG_PROGRAM([[
#include <glib.h>
#if !GLIB_CHECK_VERSION  \
    (GLIB_REQUIRED_MAJOR,\
     GLIB_REQUIRED_MINOR,\
     GLIB_REQUIRED_MICRO)
# error "glib is too old"
#endif
 ]])],
 [AC_LANG_PROGRAM([[]], [[glib_check_version (0, 0, 0);]])])

AC_MSG_CHECKING([if g_type_init must be explicitly called])
AC_LANG_PUSH([C])
saved_CFLAGS="$CFLAGS"
CFLAGS="$CFLAGS $GLIB_CFLAGS"
AC_COMPILE_IFELSE(
 [AC_LANG_PROGRAM([[
#include <glib.h>
#if !GLIB_CHECK_VERSION (2,36,0)
# error "must call g_type_init"
#endif
 ]])],
 [must_call_g_type_init=no],
 [must_call_g_type_init=yes])
CFLAGS="$saved_CFLAGS"
AS_UNSET([saved_CFLAGS])
AC_LANG_POP
AS_IF([test "$must_call_g_type_init" = yes],
 [GLIB_CFLAGS="$GLIB_CFLAGS -DMUST_CALL_G_TYPE_INIT"])
AH_VERBATIM([G_TYPE_INIT_WRAPPER],
[/* Expands to g_type_init if GLIB < 2.36.  */
#ifdef MUST_CALL_G_TYPE_INIT
# define G_TYPE_INIT_WRAPPER() g_type_init ()
#else
# define G_TYPE_INIT_WRAPPER()
#endif
])
AC_MSG_RESULT([$must_call_g_type_init])

# Check for Pango.
AU_VERSION_BREAK([pango], pango_required_version)
AU_CHECK_PKG([PANGO],
  pango >= pango_required_version dnl
  pangocairo >= pango_required_version,
 [AC_LANG_PROGRAM([[
#include <pango/pango.h>
#if !PANGO_VERSION_CHECK  \
    (PANGO_REQUIRED_MAJOR,\
     PANGO_REQUIRED_MINOR,\
     PANGO_REQUIRED_MICRO)
# error "pango is too old"
#endif
#include <pango/pangocairo.h>
 ]])],
 [AC_LANG_PROGRAM([[]], [[
pango_context_new ();
pango_cairo_create_context (0);
 ]])])

# Check for GIO (optional).
AU_CHECK_OPTIONAL_PKG([event-tcp], [build the tcp event class], [],
 [GIO], gio-2.0 >= glib_required_version,
 [AC_LANG_PROGRAM([[
#include <gio/gio.h>
#ifndef G_IO_STREAM
# error "fail"
#endif
 ]])],
 [AC_LANG_PROGRAM([[]], [[g_socket_client_new ();]])])

AU_ARG_WITH([event-geolocation],
 [build the geolocation event class], [check])
AS_IF([test "$au_check_optional_pkg_GIO" = yes],
 [AC_DEFINE([WITH_EVENT_GEOLOCATION], [1],
   [build the geolocation event class])])
AM_CONDITIONAL([WITH_EVENT_GEOLOCATION],
 [test "$au_check_optional_pkg_GIO" = yes])

# Check for SOUP (optional).
AU_VERSION_BREAK([soup], soup_required_version)
AU_CHECK_OPTIONAL_PKG([event-http], [build the http event class], [],
 [SOUP], libsoup-2.4 >= soup_required_version,
 [AC_LANG_PROGRAM([[
#include <libsoup/soup.h>
#if !SOUP_CHECK_VERSION  \
    (SOUP_REQUIRED_MAJOR,\
     SOUP_REQUIRED_MINOR,\
     SOUP_REQUIRED_MICRO)
# error "soup is too old"
#endif
 ]])],
 [AC_LANG_PROGRAM([[]], [[soup_session_new_with_options (0, 0, 0);]])])

# Check for GStreamer (optional).
AU_VERSION_BREAK([gstreamer], gstreamer_required_version)
AU_CHECK_OPTIONAL_PKG([nclua-gst],
 [build the NCLua plugin for GStreamer], [],
 [GSTREAMER],
  gstreamer-1.0 >= gstreamer_required_version dnl
  gstreamer-video-1.0 >= gstreamer_required_version,
 [AC_LANG_PROGRAM([[
#include <gst/gst.h>
#if !GST_CHECK_VERSION  \
    (GST_REQUIRED_MAJOR,\
     GST_REQUIRED_MINOR,\
     GST_REQUIRED_MICRO)
# error "gstreamer is too old"
#endif
#include <gst/video/gstvideometa.h>
 ]])],
 [AC_LANG_PROGRAM([[]], [[
gst_init (0, 0);
gst_video_info_from_caps (0, 0);
 ]])])

AC_ARG_WITH([gstpluginsdir],
 [AS_HELP_STRING([--with-gstpluginsdir=DIR],
                 [install GStreamer plugin into DIR])], [],
 [with_gstpluginsdir=`$PKG_CONFIG --variable=pluginsdir gstreamer-1.0`])
AS_IF([test -z "$with_gstpluginsdir"],
 [with_gstpluginsdir='${libdir}'/gstreamer-1.0])
AC_SUBST([gstpluginsdir], [$with_gstpluginsdir])

# Check for GTK (optional).
AU_VERSION_BREAK([gtk], gtk_required_version)
AU_CHECK_OPTIONAL_PKG([nclua-gtk], [build the nclua GTK interpreter], [],
 [GTK], gtk+-3.0 >= gtk_required_version,
 [AC_LANG_PROGRAM([[
#include <gtk/gtk.h>
#if !GTK_CHECK_VERSION  \
    (GTK_REQUIRED_MAJOR,\
     GTK_REQUIRED_MINOR,\
     GTK_REQUIRED_MICRO)
# error "gtk is too old"
#endif
 ]])],
 [AC_LANG_PROGRAM([[]], [[gtk_init (0, 0);]])])

AC_CONFIG_FILES([
Makefile
lib/Makefile
lib/nclua.pc
lib/nclua.rc
lib/ncluaconf.h
nclua/Makefile
nclua/event/Makefile
src/Makefile
tests/Makefile
])

AC_OUTPUT
AC_MSG_NOTICE([summary of main build options:

  version:            ${VERSION}
  host type:          ${host}
  install prefix:     ${prefix}
  compiler:           ${CC}
  cppflags:           ${CPPFLAGS}
  cflags:             ${CFLAGS}
  ldflags:            ${LDFLAGS}
  warning flags:      ${WERROR_CFLAGS} ${WARN_CFLAGS}
  library types:      Shared=${enable_shared}, Static=${enable_static}
  valgrind:           ${VALGRIND}

  build http:         ${with_event_http_result}
  build tcp:          ${with_event_tcp_result}
  build gstnclua:     ${with_nclua_gst_result}
  build nclua binary: ${with_nclua_gtk_result}
])
