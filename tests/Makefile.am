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

AM_CPPFLAGS = -I$(top_srcdir)/lib -I$(top_builddir)/lib\
 -DTOP_SRCDIR=\"$(top_srcdir)\" -DTOP_BUILDDIR=\"$(top_builddir)\"

AM_CFLAGS = $(WERROR_CFLAGS) $(WARN_CFLAGS)\
  $(LUA_CFLAGS) $(CAIRO_CFLAGS) $(GLIB_CFLAGS)

AM_LDFLAGS = -static $(LUA_LIBS) $(CAIRO_LIBS) $(GLIB_LIBS)
LDADD = $(top_builddir)/lib/libnclua.la

# Auxiliary libraries.
noinst_LTLIBRARIES = tests0.la

if OS_WIN32
tests0_export_symbols = -export-symbols tests0.def
tests0_def_dependency = tests0.def
endif

CLEANFILES += tests0.def
tests0.def:
	$(AM_V_GEN) (echo EXPORTS;\
	echo luaopen_tests0) >$@

tests0_la_DEPENDENCIES = $(tests0_def_dependency)
tests0_la_CFLAGS = $(AM_CFLAGS) $(CAIRO_CFLAGS) $(GLIB_CFLAGS)
tests0_la_LDFLAGS = -shared -module -avoid-version -no-undefined\
  -rpath '/force-shared' $(AM_LDFLAGS) $(CAIRO_LIBS) $(GLIB_LIBS)\
  $(tests0_export_symbols)

# Auxiliary programs.
noinst_PROGRAMS = libnclua-echo lua
lua_LDADD =

# Auxiliary scripts.
noinst_SCRIPTS =

# Generate env.sh and gdb.cfg if we have Perl.
if HAVE_PERL
noinst_SCRIPTS += $(builddir)/env.sh $(builddir)/gdb.cfg
CLEANFILES += $(builddir)/env.sh $(builddir)/gdb.cfg

perl_env_sh_get_tests_environment =\
  /^AM_TESTS_ENVIRONMENT\s*=\s*\\\n(.*?).\$$\(NULL\)/sm and printf "$$1";

perl_env_sh_expand_variables =\
  s/^\s*//g; s/\\//g;\
  s:\$$\(SOEXT\):$(SOEXT):g;\
  s:\$$\(builddir\):$(abs_builddir):g;\
  s:\$$\(srcdir\):$(abs_srcdir):g;\
  s:\$$\(top_builddir\):$(abs_top_builddir):g;\
  s:\$$\(top_srcdir\):$(abs_top_srcdir):g;

perl_env_sh_remove_ld_preload =\
  /^\s*export\s*LD_PRELOAD=/ or print;

$(builddir)/env.sh: $(srcdir)/Makefile
	$(AM_V_GEN)cat $(srcdir)/Makefile\
	  | $(PERL) -00 -wnle '$(perl_env_sh_get_tests_environment)'\
	  | $(PERL) -wple '$(perl_env_sh_expand_variables)'\
	  | $(PERL) -wnle '$(perl_env_sh_remove_ld_preload)' > $@

perl_gdb_cfg_replace_env_sh =\
  s/^export/set environment/;\
  s/(.*);$$/$$1/;\
  s/\"//g;

$(builddir)/gdb.cfg: $(builddir)/env.sh
	$(AM_V_GEN)cat $(builddir)/env.sh\
	  | $(PERL) -wple '$(perl_gdb_cfg_replace_env_sh)' > $@
endif

# Setup Valgrind; generate suppfile if we have M4.
if VALGRIND_TESTS
_VALGRIND = $(VALGRIND) $(VALGRIND_OPTIONS)

if HAVE_M4
noinst_SCRIPTS += $(builddir)/suppfile
CLEANFILES += $(builddir)/suppfile
VALGRIND_OPTIONS = --suppressions=$(builddir)/suppfile
$(builddir)/suppfile: $(srcdir)/suppfile.m4
	$(AM_V_GEN)$(M4) $(srcdir)/suppfile.m4 > $@
endif
else
_VALGRIND =
endif

# Setup test framework.
AM_COLOR_TESTS = always
DISABLE_HARD_ERRORS = true
TEST_EXTENSIONS = .lua .sh
LOG_COMPILER = $(_VALGRIND)
LUA_LOG_COMPILER = $(_VALGRIND) $(builddir)/lua
SH_LOG_COMPILER = $(SHELL)

# Setup tests environment.
AM_TESTS_ENVIRONMENT =\
  export MALLOC_CHECK_=1;\
  export G_DEBUG="all";\
  export G_SLICE="always-malloc";\
  export LD_LIBRARY_PATH="$(top_builddir)/nclua:$(top_builddir)/nclua/event";\
  export LD_PRELOAD="canvas$(SOEXT):stopwatch$(SOEXT):tcp_socket$(SOEXT)";\
  export LUA_PATH="$(top_srcdir)/?.lua;$(top_srcdir)/?/init.lua;$(top_srcdir)/tests/?.lua;;";\
  export LUA_CPATH="$(builddir)/.libs/?$(SOEXT);$(top_builddir)/?$(SOEXT);;";\
  $(NULL)

# Test scripts.
scripts =
# canvas
scripts += test-canvas-api.lua
scripts += test-canvas-new.lua
scripts += test-canvas-attrAntiAlias.lua
scripts += test-canvas-attrClip.lua
scripts += test-canvas-attrColor.lua
scripts += test-canvas-attrCrop.lua
scripts += test-canvas-attrFlip.lua
scripts += test-canvas-attrFont.lua
scripts += test-canvas-attrLineWidth.lua
scripts += test-canvas-attrOpacity.lua
scripts += test-canvas-attrRotation.lua
scripts += test-canvas-attrScale.lua
scripts += test-canvas-attrSize.lua
scripts += test-canvas-clear.lua
scripts += test-canvas-compose.lua
scripts += test-canvas-drawEllipse.lua
scripts += test-canvas-drawLine.lua
scripts += test-canvas-drawPolygon.lua
scripts += test-canvas-drawRect.lua
scripts += test-canvas-drawRoundRect.lua
scripts += test-canvas-drawText.lua
scripts += test-canvas-flush.lua
scripts += test-canvas-measureText.lua
scripts += test-canvas-pixel.lua
# event.queue
scripts += test-event-queue-api.lua
scripts += test-event-queue-new.lua
scripts += test-event-queue-enqueue.lua
scripts += test-event-queue-dequeue.lua
# event.engine
scripts += test-event-engine-api.lua
scripts += test-event-engine-new.lua
scripts += test-event-engine-send.lua
scripts += test-event-engine-receive.lua
scripts += test-event-engine-reset.lua
scripts += test-event-engine-cycle.lua
# event.stopwatch
scripts += test-event-stopwatch-api.lua
scripts += test-event-stopwatch-new.lua
scripts += test-event-stopwatch-get-time.lua
# event.tcp_socket
scripts += test-event-tcp-socket-api.lua
scripts += test-event-tcp-socket-new.lua
scripts += test-event-tcp-socket-is-socket.lua
scripts += test-event-tcp-socket-connect.lua
scripts += test-event-tcp-socket-send.lua
scripts += test-event-tcp-socket-receive.lua
scripts += test-event-tcp-socket-echo.lua
scripts += test-event-tcp-socket-timeout.lua
# event.tcp (handler plugin)
scripts += test-event-tcp-api.lua
scripts += test-event-tcp-check.lua
scripts += test-event-tcp-filter.lua
scripts += test-event-tcp-engine.lua
# event.user (handler plugin)
scripts += test-event-user-api.lua
scripts += test-event-user-check.lua
scripts += test-event-user-filter.lua
scripts += test-event-user-engine.lua
# event.key (pass-through plugin)
scripts += test-event-key-api.lua
scripts += test-event-key-check.lua
scripts += test-event-key-filter.lua
# event.ncl (pass-through plugin)
scripts += test-event-ncl-api.lua
scripts += test-event-ncl-check.lua
scripts += test-event-ncl-filter.lua
# event.pointer (pass-through plugin)
scripts += test-event-pointer-api.lua
scripts += test-event-pointer-check.lua
scripts += test-event-pointer-filter.lua
# event.init
scripts += test-event-init-api.lua
scripts += test-event-init-init.lua
scripts += test-event-init-load.lua
scripts += test-event-init-unload.lua
scripts += test-event-init-post.lua
scripts += test-event-init-register.lua
scripts += test-event-init-unregister.lua
scripts += test-event-init-cycle.lua
scripts += test-event-init-uptime.lua
scripts += test-event-init-timer.lua
# libnclua
scripts += test-libnclua-echo.sh
check_SCRIPTS = $(scripts)

# Test programs.
programs =
programs+= test-libnclua-open
programs+= test-libnclua-open-x
programs+= test-libnclua-close
programs+= test-libnclua-debug-get-surface
programs+= test-libnclua-debug-dump-surface
programs+= test-libnclua-paint
programs+= test-libnclua-cycle
programs+= test-libncluaw-open
programs+= test-libncluaw-at-panic
programs+= test-libncluaw-at-panic-x
programs+= test-libncluaw-event-clone
programs+= test-libncluaw-event-clone-x
programs+= test-libncluaw-event-free-x
programs+= test-libncluaw-debug-get-surface
programs+= test-libncluaw-debug-dump-surface
programs+= test-libncluaw-cycle
check_PROGRAMS = $(programs)

TESTS =\
  $(check_SCRIPTS)\
  $(check_PROGRAMS)\
  $(NULL)

# Tests that should fail.
XFAIL_TESTS =\
  test-libnclua-open-x\
  test-libncluaw-at-panic-x\
  test-libncluaw-event-clone-x\
  test-libncluaw-event-free-x\
  $(NULL)

EXTRA_DIST =\
  $(check_SCRIPTS)\
  libnclua-echo.lua\
  sample/apple-red.png\
  sample/gnu-keys.png\
  server.pl\
  server.sh\
  suppfile.m4\
  test-canvas-clear-1-ref.png\
  test-canvas-clear-2-ref.png\
  test-canvas-clear-3-ref.png\
  test-canvas-clear-4-ref.png\
  test-canvas-clear-5-ref.png\
  test-canvas-clear-6-ref.png\
  test-canvas-compose-1-ref.png\
  test-canvas-compose-2-ref.png\
  test-canvas-compose-3-ref.png\
  test-canvas-compose-4-ref.png\
  test-canvas-compose-5-ref.png\
  test-canvas-compose-6-ref.png\
  test-canvas-compose-7-ref.png\
  test-canvas-drawEllipse-1-ref.png\
  test-canvas-drawEllipse-2-ref.png\
  test-canvas-drawEllipse-3-ref.png\
  test-canvas-drawEllipse-4-ref.png\
  test-canvas-drawEllipse-5-ref.png\
  test-canvas-drawEllipse-6-ref.png\
  test-canvas-drawEllipse-7-ref.png\
  test-canvas-drawLine-1-ref.png\
  test-canvas-drawLine-2-ref.png\
  test-canvas-drawLine-3-ref.png\
  test-canvas-drawLine-4-ref.png\
  test-canvas-drawLine-5-ref.png\
  test-canvas-drawLine-6-ref.png\
  test-canvas-drawPolygon-1-ref.png\
  test-canvas-drawPolygon-2-ref.png\
  test-canvas-drawPolygon-3-ref.png\
  test-canvas-drawPolygon-4-ref.png\
  test-canvas-drawPolygon-5-ref.png\
  test-canvas-drawPolygon-6-ref.png\
  test-canvas-drawRect-1-ref.png\
  test-canvas-drawRect-2-ref.png\
  test-canvas-drawRect-3-ref.png\
  test-canvas-drawRect-4-ref.png\
  test-canvas-drawRect-5-ref.png\
  test-canvas-drawRect-6-ref.png\
  test-canvas-drawRoundRect-1-ref.png\
  test-canvas-drawRoundRect-2-ref.png\
  test-canvas-drawRoundRect-3-ref.png\
  test-canvas-drawRoundRect-4-ref.png\
  test-canvas-drawRoundRect-5-ref.png\
  test-canvas-drawRoundRect-6-ref.png\
  test-canvas-drawText-1-ref.png\
  test-canvas-drawText-2-ref.png\
  test-canvas-drawText-3-ref.png\
  test-canvas-drawText-4-ref.png\
  test-canvas-drawText-5-ref.png\
  test-canvas-drawText-6-ref.png\
  test-canvas-drawText-7-ref.png\
  test-canvas-flush-1-ref.png\
  test-canvas-flush-2-ref.png\
  test-canvas-flush-3-ref.png\
  test-canvas-flush-4-ref.png\
  test-canvas-new-1-ref.png\
  test-canvas-pixel-1-ref.png\
  test-libncluaw-cycle.lua\
  tests.h\
  tests.lua\
  $(NULL)

CLEANFILES += *.log *.trs\
  test-libnclua-debug-dump.png\
  test-libncluaw-debug-dump.png\
  $(NULL)
