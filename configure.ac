# configure.ac -- Configure template for NCLua.
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

m4_define([nclua_version_string],
  m4_esyscmd([build-aux/git-version-gen .tarball-version]))

m4_define([nclua_version_re],
 [^\([[0-9]]+\)\.\([[0-9]]+\)\.?\([[0-9]]+\)?])

m4_define([nclua_version_major],
  m4_default(m4_bregexp(nclua_version_string, nclua_version_re, [\1]),
   [m4_fatal([bad major version number])]))

m4_define([nclua_version_minor],
  m4_default(m4_bregexp(nclua_version_string, nclua_version_re, [\2]),
   [m4_fatal([bad minor version number])]))

m4_define([nclua_version_micro],
  m4_default(m4_bregexp(nclua_version_string, nclua_version_re, [\3]), [0]))

AC_PREREQ([2.62])
AC_INIT([NCLua],
        nclua_version_string,
        [gflima@telemidia.puc-rio.br],
        [nclua], [http://www.telemidia.puc-rio.br/~gflima])

AC_CONFIG_AUX_DIR([build-aux])
AC_CONFIG_MACRO_DIR([build-aux])
AC_USE_SYSTEM_EXTENSIONS
AC_CONFIG_SRCDIR([lib/nclua.h])
AC_CONFIG_HEADERS([lib/config.h])

AC_SUBST([NCLUA_VERSION_MAJOR], nclua_version_major)
AC_SUBST([NCLUA_VERSION_MINOR], nclua_version_minor)
AC_SUBST([NCLUA_VERSION_MICRO], nclua_version_micro)
AC_SUBST([NCLUA_VERSION_STRING], nclua_version_string)

# library code modified:            REVISION++
# interfaces changed/added/removed: REVISION=0, CURRENT++
# interfaces added:                 AGE++
# interfaces removed:               AGE=0
m4_define([nclua_libtool_current],  [0])
m4_define([nclua_libtool_revision], [0])
m4_define([nclua_libtool_age],      [0])
m4_define([nclua_libtool_string],
 [nclua_libtool_current:nclua_libtool_revision:nclua_libtool_age])
AC_SUBST([NCLUA_LIBTOOL_CURRENT], nclua_libtool_current)
AC_SUBST([NCLUA_LIBTOOL_REVISION], nclua_libtool_revision)
AC_SUBST([NCLUA_LIBTOOL_AGE], nclua_libtool_age)
AC_SUBST([NCLUA_LIBTOOL_STRING], nclua_libtool_string)

m4_define([lua_required_version],   [5.2])
m4_define([cairo_required_version], [1.10.2])
m4_define([glib_required_version],  [2.32.4])
m4_define([pango_required_version], [1.30.0])
m4_define([gtk_required_version],   [3.4.2])
AC_SUBST([LUA_REQUIRED_VERSION], lua_required_version)
AC_SUBST([CAIRO_REQUIRED_VERSION], cairo_required_version)
AC_SUBST([PANGO_REQUIRED_VERSION], pango_required_version)
AC_SUBST([GTK_REQUIRED_VERSION], gtk_required_version)

AM_INIT_AUTOMAKE([1.14 -Wall dist-xz foreign gnu no-define no-dist-gzip])
AM_MAINTAINER_MODE([enable])
AM_SILENT_RULES([yes])
AM_PROG_AR

AC_PROG_CC
AC_PROG_CPP
AM_PROG_CC_C_O

LT_PREREQ([2.2])
LT_INIT([disable-static win32-dll])

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
AS_IF([test x"$enable_ansi" = xyes],
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
AS_IF([test x"$enable_debug" = xyes],
 [AC_DEFINE([DEBUG], [1], [Define to 1 to enable runtime debugging])
  AS_IF([test x"$GCC" = xyes],
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
AM_CONDITIONAL([ENABLE_COVERAGE], [test x"$enable_coverage" = xyes])
AS_IF([test x"$enable_coverage" = xyes],
 [AS_IF([test x"$enable_debug" = xno],
   [AC_MSG_ERROR([--enable-coverage requires --enable-debug])])

  AS_IF([test x"$GCC" != xyes],
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
AS_IF([test x"$enable_gcc_warnings" = xyes],
 [gl_WARN_ADD([-Werror], [WERROR_CFLAGS])
  AC_SUBST([WERROR_CFLAGS])

  # This, $nw, is the list of warnings we disable.
  nw=
  nw="$nw -Wsystem-headers"         # Suppress system headers warnings
  nw="$nw -Wpadded"                 # Our structs are not packed

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
  gl_WARN_ADD([-Wswitch-enum])
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
  AS_IF([test x"$nclua_cv_clang" = xyes],
   [gl_WARN_ADD([-Wno-tautological-constant-out-of-range-compare])
    gl_WARN_ADD([-Wno-unused-command-line-argument])])

  gl_WARN_ADD([-fdiagnostics-show-option])
  gl_WARN_ADD([-funit-at-a-time])

  AC_SUBST([WARN_CFLAGS])

  AC_DEFINE([lint], [1], [Define to 1 if compiler is checking for lint.])
  AH_VERBATIM([FORTIFY_SOURCE], [
/* Enable compile-time and run-time bounds-checking, and some warnings,
   without upsetting glibc 2.15+.  */
#if !defined _FORTIFY_SOURCE && defined __OPTIMIZE__ && __OPTIMIZE__
# define _FORTIFY_SOURCE 2
#endif
  ])])

# Setup default visibility of library symbols.
gl_VISIBILITY

# Run tests under Valgrind if it is available.
gl_VALGRIND_TESTS
AM_CONDITIONAL([VALGRIND_TESTS], [test x"$opt_valgrind_tests" = xyes])

# Use gcc's -pipe option if available (for faster compilation).
AS_CASE([" $CFLAGS "], [*[[\ \	]]-pipe[[\ \	]]*], [:],
 [AC_LIBTOOL_COMPILER_OPTION([if $compiler supports -pipe],
   [nclua_cv_prog_compiler_pipe],
   [-pipe -c conftest.$ac_ext], [],
   [CFLAGS="$CFLAGS -pipe"])])

# Check for the functions used by macros.h.
saved_LIBS=$LIBS
LIBS="$LIBS -lm"
AC_CHECK_FUNCS([lround round])
LIBS=$saved_LIBS

# Check for M4.
AC_CHECK_PROGS([M4], [m4 gm4])
AM_CONDITIONAL([HAVE_M4], [test -n "$M4"])

# Check for Perl.
gl_PERL
AM_CONDITIONAL([HAVE_PERL], [test -n "$PERL"])

# Check for pkg-config.
PKG_PROG_PKG_CONFIG

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
   [LUA_LIBS='-llua -lm'])

saved_CFLAGS=$CFLAGS
saved_LDFLAGS=$LDFLAGS
CFLAGS="$CFLAGS $LUA_CFLAGS"
LDFLAGS="$LDFLAGS $LUA_LIBS"
AC_TRY_LINK(
  [#include <lua.h>
],[lua_rawlen (0, 0);],
  [LUA_VERSION=5.2],
  [AC_TRY_LINK(
    [#include <lua.h>
  ],[lua_objlen (0, 0);],
    [LUA_VERSION=5.1],
    [AC_MSG_ERROR([Lua >= lua_required_version is required.])])])
CFLAGS=$saved_CFLAGS
LDFLAGS=$saved_LDFLAGS
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

# Check for Cairo.
PKG_CHECK_MODULES([CAIRO],
 [cairo >= cairo_required_version], [],
 [AC_MSG_ERROR([Cairo >= cairo_required_version is required.])])

# Check for GLib.
PKG_CHECK_MODULES([GLIB],
 [glib-2.0 >= glib_required_version], [],
 [AC_MSG_ERROR([GLib >= glib_required_version is required.])])

# Check for GIO.
PKG_CHECK_MODULES([GIO],
 [gio-2.0 >= glib_required_version], [],
 [AC_MSG_ERROR([GIO > glib_required_version is required.])])

# Check for Pango.
PKG_CHECK_MODULES([PANGO],
 [pango >= pango_required_version dnl
  pangocairo >= pango_required_version], [],
 [AC_MSG_ERROR([Pango >= pango_required_version is required.])])

# Check for GTK.
PKG_CHECK_MODULES([GTK],
 [gtk+-3.0 >= gtk_required_version], [have_gtk=yes], [have_gtk=no])
AS_IF([test x"$have_gtk" = xyes],
 [AC_DEFINE([HAVE_GTK], [1], [Define to 1 if we have GTK+-3.0.])])
AM_CONDITIONAL([HAVE_GTK], [test x"$have_gtk" = xyes])

AC_CONFIG_FILES([
Makefile
lib/Makefile
lib/nclua.pc
lib/ncluaconf.h
nclua/Makefile
nclua/event/Makefile
src/Makefile
tests/Makefile
])

AC_OUTPUT
AC_MSG_NOTICE([summary of main build options:

  Version:            ${VERSION}
  Host type:          ${host}
  Install prefix:     ${prefix}
  Compiler:           cc: ${CC} cflags: ${CFLAGS} cppflags: ${CPPFLAGS}
  Warning flags:      ${WERROR_CFLAGS} ${WARN_CFLAGS}
  Library types:      Shared=${enable_shared}, Static=${enable_static}
  Valgrind:           ${VALGRIND}
])
