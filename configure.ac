# configure.ac -- Configure template for NCLua.
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

AC_PREREQ([2.62])

m4_define([nclua_version_string],
  m4_esyscmd([build-aux/git-version-gen .tarball-version]))

m4_define([nclua_version_re],
 [^\([[0-9]]+\)\.\([[0-9]]+\)\.?\([[0-9]]+\)?])

m4_define([nclua_version_major],
  m4_default(m4_bregexp(nclua_version_string, nclua_version_re, [\1]), [0]))

m4_define([nclua_version_minor],
  m4_default(m4_bregexp(nclua_version_string, nclua_version_re, [\2]), [0]))

m4_define([nclua_version_micro],
  m4_default(m4_bregexp(nclua_version_string, nclua_version_re, [\3]), [0]))

AC_INIT([NCLua],
        nclua_version_string,
        [gflima@telemidia.puc-rio.br],
        [nclua], [http://github.com/gflima/nclua])

AC_CONFIG_AUX_DIR([build-aux])
AC_CONFIG_MACRO_DIR([build-aux])
AC_USE_SYSTEM_EXTENSIONS
AC_CONFIG_SRCDIR([lib/nclua.h])
AC_CONFIG_HEADERS([lib/config.h])

AM_INIT_AUTOMAKE([1.14 foreign -Wall no-define no-dist-gzip dist-xz])
AM_SILENT_RULES([yes])
AM_PROG_AR

LT_PREREQ([2.2])
LT_INIT([win32-dll])

# NCLua version.
AC_SUBST([NCLUA_VERSION_MAJOR], nclua_version_major)
AC_SUBST([NCLUA_VERSION_MINOR], nclua_version_minor)
AC_SUBST([NCLUA_VERSION_MICRO], nclua_version_micro)
AC_SUBST([NCLUA_VERSION_STRING], nclua_version_string)

# Libtool versioning.
# - library code modified:            REVISION++
# - interfaces changed/added/removed: REVISION=0, CURRENT++
# - interfaces added:                 AGE++
# - interfaces removed:               AGE=0
m4_define([nclua_libtool_current],  [0])
m4_define([nclua_libtool_revision], [0])
m4_define([nclua_libtool_age],      [0])
m4_define([nclua_libtool_current_minus_age],
 [m4_eval(nclua_libtool_current - nclua_libtool_age)])
m4_define([nclua_libtool_string],
 [nclua_libtool_current:nclua_libtool_revision:nclua_libtool_age])
AC_SUBST([NCLUA_LIBTOOL_CURRENT], nclua_libtool_current)
AC_SUBST([NCLUA_LIBTOOL_REVISION], nclua_libtool_revision)
AC_SUBST([NCLUA_LIBTOOL_AGE], nclua_libtool_age)
AC_SUBST([NCLUA_LIBTOOL_CURRENT_MINUS_AGE], nclua_libtool_current_minus_age)
AC_SUBST([NCLUA_LIBTOOL_STRING], nclua_libtool_string)

# Dependencies version.
m4_define([cairo_required_version], [1.10.2])
m4_define([glib_required_version],  [2.32.4])
m4_define([gtk_required_version],   [3.4.2])
m4_define([lua_required_version],   [5.2])
m4_define([pango_required_version], [1.30.0])
m4_define([soup_required_version],  [2.42])
AC_SUBST([CAIRO_REQUIRED_VERSION], cairo_required_version)
AC_SUBST([GLIB_REQUIRED_VERSION], glib_required_version)
AC_SUBST([GTK_REQUIRED_VERSION], gtk_required_version)
AC_SUBST([LUA_REQUIRED_VERSION], lua_required_version)
AC_SUBST([PANGO_REQUIRED_VERSION], pango_required_version)
AC_SUBST([SOUP_REQUIRED_VERSION], soup_required_version)

# Checks for tools we use.
AC_PROG_CC
AC_PROG_CPP
AM_PROG_CC_STDC
AM_PROG_CC_C_O
AC_C_CONST
AC_PROG_INSTALL

AC_PROG_SED
AC_CHECK_PROGS([M4], [m4 gm4])
AM_CONDITIONAL([HAVE_M4], [test -n "$M4"])

gl_PERL
AM_CONDITIONAL([HAVE_PERL], [test -n "$PERL"])

PKG_PROG_PKG_CONFIG
AS_IF([test -z "$PKG_CONFIG"],
 [AC_MSG_ERROR([pkg-config >= $PKGCONFIG_REQUIRED required.])])

# System checks.
AC_CANONICAL_HOST
AC_CHECK_LIBM
AC_EXEEXT
LT_SYS_MODULE_EXT
AC_SUBST([SOEXT], [$libltdl_cv_shlibext])
AC_MSG_CHECKING([for native Win32])
AS_CASE(["$host"], [*-*-mingw*],
 [nclua_os_win32=yes],
 [nclua_os_win32=no])
AC_MSG_RESULT([$nclua_os_win32])
AM_CONDITIONAL([OS_WIN32], [test "$nclua_os_win32" = yes])

AS_IF([test "$nclua_os_win32" = yes && test -z "$MINGW_ROOT"],
[MINGW_ROOT=`$SED -n 's,^\(.*\)[[ 	][ 	]]*/mingw$,\1,p' /etc/fstab`;
 AS_IF([test -z "$MINGW_ROOT"],
 [MINGW_ROOT='C:/MinGW'])])
AC_SUBST([MINGW_ROOT])

AS_IF([test "$nclua_os_win32" = yes],
 [AS_CASE(["$host"], [x86_64-*-*],
  [LIB_EXE_MACHINE_FLAG=X64],
  [LIB_EXE_MACHINE_FLAG=X86])])
AC_SUBST([LIB_EXE_MACHINE_FLAG])
AM_CONDITIONAL([OS_WIN32_X64], [test "$LIB_EXE_MACHINE_FLAG" = "X64"])

AS_IF([test "$nclua_os_win32" = yes],
 [AC_CHECK_TOOL([WINDRES], [windres])
  AS_IF([test -z "$WINDRES"],
   [AC_MSG_ERROR([windres required.])])
  AC_CHECK_TOOL([NM], [nm])
  AS_IF([test -z "$NM"],
   [AC_MSG_ERROR([nm required.])])
  AC_CHECK_TOOL([RANLIB], [ranlib], [:])
  AC_CHECK_PROG([ms_lib], [lib.exe], [yes], [no])])
AM_CONDITIONAL([HAVE_MS_LIB], [test "$ms_lib" = "yes"])

# Ensure MSVC-compatible struct packing convention is used when compiling
# for Win32 with GCC.
AS_IF([test "$nclua_os_win32" = yes],
 [AS_IF([test "$GCC" = yes],
   [AC_LIBTOOL_COMPILER_OPTION([if $compiler supports -fnative-struct],
     [nclua_cv_prog_compiler_fnative_struct],
     [-fnative-struct -c conftest.$ac_ext], [],
     [CFLAGS="$CFLAGS -fnative-struct"],
     [AC_LIBTOOL_COMPILER_OPTION([if $compiler supports -mms-bitfields],
       [nclua_cv_prog_compiler_mms_bitfields],
       [-mms-bitfields -c conftest.$ac_ext], [],
       [CFLAGS="$CFLAGS -mms-bitfields"],
       [AC_MSG_WARN([dnl
produced libraries might be incompatible with MSVC-compiled code])])])])])

# _AC_ARG_ENABLE(NAME, DESCRIPTION, DEFAULT)
# ------------------------------------------
# Check for argument --enable-NAME and sets $enable_NAME accordingly.
m4_define([_AC_ARG_ENABLE],
 [AC_ARG_ENABLE([$1],
   [AS_HELP_STRING([--enable-$1],
     [$2 [default=$3]])],
   [AS_CASE([$enableval], [yes|no], [:],
     [AC_MSG_ERROR([bad value '$enableval' for --enable-$1 option])])
    enable_[]m4_translit($1,[-],[_])=$enableval],
   [enable_[]m4_translit($1,[-],[_])=$3])])

# Enable -ansi and -pedantic compiler flags.
_AC_ARG_ENABLE([ansi], [turn on strict ansi], [no])
AS_IF([test "$enable_ansi" = yes],
 [AS_CASE([" $CFLAGS "], [*[[\ \	]]-ansi[[\ \	]]*], [:],
   [AC_LIBTOOL_COMPILER_OPTION([if $compiler supports -ansi],
     [nclua_cv_prog_compiler_ansi],
     [-ansi -c conftest.$ac_ext], [],
     [CFLAGS="$CFLAGS -ansi"])])

  AS_CASE([" $CFLAGS "], [*[[\ \	]]-pedantic[[\ \	]]*], [:],
   [AC_LIBTOOL_COMPILER_OPTION([if $compiler supports -pedantic],
     [nclua_cv_prog_compiler_pedantic],
     [-pedantic -c conftest.$ac_ext], [],
     [CFLAGS="$CFLAGS -pedantic"])])])

# Enable debugging.
_AC_ARG_ENABLE([debug], [build for debugging], [no])
AS_IF([test "$enable_debug" = yes],
 [AC_DEFINE([DEBUG], [1], [Define to 1 to enable runtime debugging])
  AS_IF([test "$GCC" = yes],
   [AS_CASE([" $CFLAGS "],
     [*[[\ \	]]-O*],
       [CFLAGS=`echo $CFLAGS | $SED 's/-O[[^ ]]* / /;s/-O[[^ ]]*$//'`])

    AS_CASE([" $CFLAGS "], [*[[\ \	]]-g*], [:],
     [AC_LIBTOOL_COMPILER_OPTION([if $compiler accepts -ggdb3],
       [nclua_cv_prog_compiler_ggdb3],
       [-ggdb3 -c conftest.$ac_ext], [],
       [CFLAGS="$CFLAGS -ggdb3"],
       [CFLAGS="$CFLAGS -g"])])],

   [AS_CASE([" $CFLAGS "], [*[[\ \	]]-g*], [:],
     [CFLAGS="$CFLAGS -g"])])])

# Enable code-coverage reports.
_AC_ARG_ENABLE([coverage], [enable coverage testing with gcov], [no])
AM_CONDITIONAL([ENABLE_COVERAGE], [test "$enable_coverage" = yes])
AS_IF([test "$enable_coverage" = yes],
 [AS_IF([test "$enable_debug" = no],
   [AC_MSG_ERROR([--enable-coverage requires --enable-debug])])

  AS_IF([test "$GCC" != yes],
   [AC_MSG_ERROR([--enable-coverage requires GCC])])

  AC_CHECK_PROGS([SHTOOL], [shtool])
  AS_IF([test -n "$SHTOOL"],
   [AS_CASE([`$SHTOOL path $CC`], [*ccache*],
     [AC_MSG_ERROR([dnl
ccache must be disabled if --enable-coverage is used
You can disable ccache by setting environment variable CCACHE_DISABLE=1])])
   ])

  AC_CHECK_PROGS([LCOV], [lcov])
  AS_IF([test -z "$LCOV"],
   [AC_MSG_ERROR([--enable-coverage requires LCOV])])

  AC_CHECK_PROGS([GENHTML], [genhtml])
  AS_IF([test -z "$GENHTML"],
   [AC_MSG_ERROR([--enable-coverate requires genhtml])])

  CFLAGS="$CFLAGS -fprofile-arcs -ftest-coverage"
  LDFLAGS="$LDFLAGS -lgcov"])

# Enable compiler warnings.
_AC_ARG_ENABLE([gcc-warnings], [turn on lots of GCC warnigns], [no])
AS_IF([test "$enable_gcc_warnings" = yes],
 [gl_WARN_ADD([-Werror], [WERROR_CFLAGS])
  AC_SUBST([WERROR_CFLAGS])

  # This, $nw, is the list of warnings we disable.
  nw=
  nw="$nw -Wsystem-headers"         # Suppress system headers warnings
  nw="$nw -Wpadded"                 # Our structs are not packed
  nw="$nw -Woverlength-strings"     # Some tests use big literals.

  gl_MANYWARN_ALL_GCC([ws])
  gl_MANYWARN_COMPLEMENT([ws], [$ws], [$nw])
  for w in $ws; do
    gl_WARN_ADD([$w])
  done

  # Some extra warnings.
  gl_WARN_ADD([-Wcast-qual])
  gl_WARN_ADD([-Wconversion])
  gl_WARN_ADD([-Wdeclaration-after-statement])
  gl_WARN_ADD([-Wfloat-equal])
  gl_WARN_ADD([-Wredundant-decls])
  gl_WARN_ADD([-Wsign-compare])
  gl_WARN_ADD([-Wsign-conversion])
  gl_WARN_ADD([-Wundef])

  # FIXME: The following is broken; C++ keyword 'and' appears in GTK header.
  # gl_WARN_ADD([-Wc++-compat])

  # clang is unduly picky about some things.
  AC_CACHE_CHECK([whether the compiler is clang], [nclua_cv_clang],
    [AC_COMPILE_IFELSE(
       [AC_LANG_PROGRAM([[
            #ifndef __clang__
              #error "not clang"
            #endif
          ]])],
       [nclua_cv_clang=yes],
       [nclua_cv_clang=no])])
  AS_IF([test "$nclua_cv_clang" = yes],
   [gl_WARN_ADD([-Wno-switch-enum])
    gl_WARN_ADD([-Wno-tautological-constant-out-of-range-compare])
    gl_WARN_ADD([-Wno-unused-command-line-argument])])

  gl_WARN_ADD([-fdiagnostics-show-option])
  gl_WARN_ADD([-funit-at-a-time])

  AC_SUBST([WARN_CFLAGS])

  AC_DEFINE([lint], [1], [Define to 1 if compiler is checking for lint.])
  AH_VERBATIM([FORTIFY_SOURCE],
[/* Enable compile-time and run-time bounds-checking, and some warnings,
   without upsetting glibc 2.15+.  */
#if !defined _FORTIFY_SOURCE && defined __OPTIMIZE__ && __OPTIMIZE__
# define _FORTIFY_SOURCE 2
#endif
  ])])

# Setup default visibility of library symbols.
gl_VISIBILITY

# Run tests under Valgrind if it is available.
gl_VALGRIND_TESTS
AM_CONDITIONAL([VALGRIND_TESTS], [test "$opt_valgrind_tests" = yes])

# Use gcc's -pipe option if available (for faster compilation).
AS_CASE([" $CFLAGS "], [*[[\ \	]]-pipe[[\ \	]]*], [:],
 [AC_LIBTOOL_COMPILER_OPTION([if $compiler supports -pipe],
   [nclua_cv_prog_compiler_pipe],
   [-pipe -c conftest.$ac_ext], [],
   [CFLAGS="$CFLAGS -pipe"])])

# Check for the functions used by macros.h.
saved_LIBS=$LIBS
LIBS="$LIBS $LIBM"
AC_CHECK_FUNCS([lround round])
LIBS=$saved_LIBS

# Check for Lua.
AC_ARG_WITH([lua_pc],
 [AS_HELP_STRING([--with-lua-pc=NAME],
                 [use NAME as the pkg-config module name for Lua])])
lua_pkg_module=$with_lua_pc
AS_IF([test -z "$lua_pkg_module"],
 [for mod in lua lua-5.2 lua5.2 lua52 lua-5.1 lua5.1 lua51; do
    PKG_CHECK_EXISTS([$mod], [lua_pkg_module=$mod; break])
  done])

AS_IF(
 [test -n "$lua_pkg_module"],
   [PKG_CHECK_MODULES([LUA], [$lua_pkg_module >= lua_required_version])],
 [test -z "$LUA_LIBS"],
   [LUA_LIBS="-llua $LIBM"])

AS_IF([test -z "$lua_pkg_module"],
 [AC_MSG_CHECKING([for LUA])])

saved_CFLAGS=$CFLAGS
saved_LIBS=$LIBS
CFLAGS="$CFLAGS $LUA_CFLAGS"
LIBS="$LDFLAGS $LUA_LIBS"
AC_TRY_LINK(
  [#include <lua.h>
],[lua_rawlen (0, 0);],
  [LUA_VERSION=5.2],
  [AC_TRY_LINK(
    [#include <lua.h>
  ],[lua_objlen (0, 0);],
    [LUA_VERSION=5.1],
    [AC_MSG_ERROR([Lua >= lua_required_version required.])])])
CFLAGS=$saved_CFLAGS
LIBS=$saved_LIBS
AC_SUBST([LUA_VERSION])

AC_ARG_WITH([lualibdir],
 [AS_HELP_STRING([--with-lualibdir=DIR],
                 [install Lua C modules into DIR])], [],
 [with_lualibdir='${libdir}'/lua/$LUA_VERSION/$PACKAGE])

AC_ARG_WITH([luadatadir],
 [AS_HELP_STRING([--with-luadatadir=DIR],
                 [install Lua scripts into DIR])], [],
 [with_luadatadir='${datadir}'/lua/$LUA_VERSION/$PACKAGE])

AC_SUBST([lualibdir], [$with_lualibdir])
AC_SUBST([luadatadir], [$with_luadatadir])

AS_IF([test -z "$lua_pkg_module"],
 [AC_MSG_RESULT([yes])])

# Check for Cairo.
PKG_CHECK_MODULES([CAIRO],
 [cairo >= cairo_required_version], [],
 [AC_MSG_ERROR([Cairo >= cairo_required_version required.])])

# Check for GLib.
PKG_CHECK_MODULES([GLIB],
 [glib-2.0 >= glib_required_version dnl
  gobject-2.0 >= glib_required_version], [],
 [AC_MSG_ERROR([GLib >= glib_required_version required.])])

AC_MSG_CHECKING([if g_type_init must be called explicitly])
PKG_CHECK_EXISTS([glib-2.0 < 2.36],
 [must_call_g_type_init=yes],
 [must_call_g_type_init=no])
AS_IF([test "$must_call_g_type_init" = yes],
 [GLIB_CFLAGS="$GLIB_CFLAGS -DMUST_CALL_G_TYPE_INIT"])
AH_VERBATIM([G_TYPE_INIT_WRAPPER],
[/* Expands to g_type_init if GLIB < 2.36; otherwise, expands to nothing.  */
#ifdef MUST_CALL_G_TYPE_INIT
# define G_TYPE_INIT_WRAPPER() g_type_init ()
#else
# define G_TYPE_INIT_WRAPPER()
#endif
])
AC_MSG_RESULT([$must_call_g_type_init])

# Check for Pango.
PKG_CHECK_MODULES([PANGO],
 [pango >= pango_required_version dnl
  pangocairo >= pango_required_version], [],
 [AC_MSG_ERROR([Pango >= pango_required_version required.])])

# Check for GIO.
PKG_CHECK_MODULES([GIO],
 [gio-2.0 >= glib_required_version], [have_gio=yes], [have_gio=no])
AS_IF([test "$have_gio" = yes],
 [AC_DEFINE([HAVE_GIO], [1], [Define to 1 if we have gio-2.0])
  AC_DEFINE([BUILD_EVENT_TCP], [1],
    [Define to 1 if tcp event class is to be built.])])
AM_CONDITIONAL([HAVE_GIO], [test "$have_gio" = yes])
AM_CONDITIONAL([BUILD_EVENT_TCP], [test "$have_gio" = yes])

# Check for SOUP.
PKG_CHECK_MODULES([SOUP],
 [libsoup-2.4 >= soup_required_version], [have_soup=yes], [have_soup=no])
AS_IF([test "$have_soup" = yes],
 [AC_DEFINE([HAVE_SOUP], [1], [Define to 1 if we have Libsoup-2.4])
  AC_DEFINE([BUILD_EVENT_HTTP], [1],
    [Define to 1 if http event class is to be built.])])
AM_CONDITIONAL([HAVE_SOUP], [test "$have_soup" = yes])
AM_CONDITIONAL([BUILD_EVENT_HTTP], [test "$have_soup" = yes])

# Check for GTK (optional).
PKG_CHECK_MODULES([GTK],
 [gtk+-3.0 >= gtk_required_version], [have_gtk=yes], [have_gtk=no])
AS_IF([test "$have_gtk" = yes],
 [AC_DEFINE([HAVE_GTK], [1], [Define to 1 if we have GTK+-3.0.])
  AC_DEFINE([BUILD_NCLUA_BIN], [1],
   [Define to 1 if nclua binary is to be built.])])
AM_CONDITIONAL([HAVE_GTK], [test "$have_gtk" = yes])
AM_CONDITIONAL([BUILD_NCLUA_BIN], [test "$have_gtk" = yes])

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

AS_IF([test "$have_gio" = no],
 [have_gio="$have_gio	(requires gio-2.0 >= glib_required_version)"])

AS_IF([test "$have_soup" = no],
 [have_soup="$have_soup	(requires libsoup-2.4 >= soup_required_version)"])

AS_IF([test "$have_gtk" = no],
 [have_gtk="$have_gtk	(requires gkt+-3.0 >= gtk_required_version)"])

AC_OUTPUT
AC_MSG_NOTICE([summary of main build options:

  Version:            ${VERSION}
  Host type:          ${host}
  Install prefix:     ${prefix}
  Compiler:           ${CC}
  Cflags:             ${CFLAGS}
  Cppflags:           ${CPPFLAGS}
  Warning flags:      ${WERROR_CFLAGS} ${WARN_CFLAGS}
  Library types:      Shared=${enable_shared}, Static=${enable_static}
  Valgrind:           ${VALGRIND}

  Build tcp:          ${have_gio}
  Build http:         ${have_soup}
  Build nclua binary: ${have_gtk}
])
