# maint.mk -- Maintainer's makefile.
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

ME:= $(firstword $(MAKEFILE_LIST))
all: usage
.PHONY: all


# Prints usage message and exits.
perl_usage =\
  BEGIN {\
    $$/ = "";\
    print "Usage: $(MAKE) -f $(ME) TARGET";\
    print "Maintainer\047s makefile; the following targets are supported:";\
    print "";\
  }\
  /\#\s([^\n]+)\n(\.PHONY:|SC_RULES\+=)\s([\w-]+)\n/ and do {\
    my $$tgt = $$3;\
    my $$doc = lc $$1;\
    $$doc =~ s/\.//;\
    printf ("  %-20s  %s\n", $$tgt, $$doc);\
  };\
  END { print ""; }\
  $(NULL)

.PHONY: usage
usage:
	@perl -wnle '$(perl_usage)' $(ME)


OPTIONS?= --enable-ansi --enable-debug --enable-gcc-warnings
EXTRA?=

# Bootstraps project for debugging.
.PHONY: bootstrap
bootstrap:
	./bootstrap
	./configure CFLAGS="" $(OPTIONS) $(EXTRA)


perl_dist_get_version:=\
  /^VERSION\s*=\s*(.*)$$/ and print $$1;\
  $(NULL)

dist_get_version = $(shell perl -wlne '$(perl_dist_get_version)' Makefile)
VERSION = $(call dist_get_version)

# Outputs project version.
.PHONY: dist-get-version
dist-get-version:
	@echo $(VERSION)


# Makes Debian binaries.
.PHONY: dist-deb
dist-deb:
	@$(MAKE) dist
	@set -e;\
	test -f Makefile || exit 1;\
	version=$(VERSION);\
	package=nclua-$$version;\
	rm -rf ./$@ && mkdir -p ./$@;\
	mv $$package.tar.xz ./$@/nclua_$$version.orig.tar.xz;\
	(cd ./$@ && tar -xf nclua_$$version.orig.tar.xz);\
	cp -r ./contrib/debian ./$@/nclua-$$version;\
	(cd ./$@/nclua-$$version && debuild -us -uc);\
	rm -rf ./$@/nclua-$$version


# Makes mingw32 binaries.
.PHONY: dist-win32
dist-win32:
	@set -e;\
	test -f Makefile || exit 1;\
	version=$(VERSION);\
	package=nclua-$$version;\
	rm -rf ./$@;\
	./configure --prefix=$(PWD)/$$package-win32;\
	make install;\
	cp ./AUTHORS ./$$package-win32/AUTHORS.txt;\
	cp ./COPYING ./$$package-win32/COPYING.txt;\
	cp ./README.md ./$$package-win32/README.md.txt;\
	find ./$$package-win32 -name '*.la' -delete;\
	zip -r ./$$package-win32.zip ./$$package-win32;\
	rm -rf ./$$package-win32;\
	make distclean


gnulib_git:= http://git.savannah.gnu.org/cgit/gnulib.git/plain
misc_git:= https://github.com/gflima/misc/raw/master

# Fetches remote files.
.PHONY: fetch-remote
fetch-remote:
	@set -e;\
	fetch () { wget -O "$$2/`basename $$1`" "$$1"; };\
	fetch $(gnulib_git)/build-aux/git-version-gen ./build-aux;\
	fetch $(gnulib_git)/build-aux/gitlog-to-changelog ./build-aux;\
	fetch $(gnulib_git)/build-aux/useless-if-before-free ./build-aux;\
	fetch $(gnulib_git)/m4/manywarnings.m4 ./build-aux;\
	fetch $(gnulib_git)/m4/perl.m4 ./build-aux;\
	fetch $(gnulib_git)/m4/valgrind-tests.m4 ./build-aux;\
	fetch $(gnulib_git)/m4/visibility.m4 ./build-aux;\
	fetch $(gnulib_git)/m4/warnings.m4 ./build-aux;\
	fetch $(misc_git)/bootstrap .;\
	fetch $(misc_git)/luax-macros.h ./lib;\
	fetch $(misc_git)/macros.h ./lib;\
	fetch $(misc_git)/syntax-check ./build-aux;\
	chmod +x ./bootstrap ./build-aux/syntax-check;\
	true


# Lists project files.
vc_list_exclude = $(filter-out $(2), $(1))
VC_LIST_AC:= $(shell git ls-files '*.ac')
VC_LIST_ALL:= $(shell git ls-files | perl -wnle '-T and print;')
VC_LIST_AM:= $(shell git ls-files '*.am' 'build-aux/Makefile.am.*')
VC_LIST_C:= $(shell git ls-files '*.[ch]')
VC_LIST_LUA:= $(shell git ls-files '*.lua')
VC_LIST_MK:= $(shell git ls-files '*.mk')
VC_LIST_SH:= $(shell git ls-files '*.sh')


perl_after_indent_type_list:=\
  GAsyncResult\
  GObject\
  GdkEventKey\
  GdkFrameClock\
  GtkWidget\
  SoupMessage\
  SoupSession\
  cairo_rectangle_int_t\
  cairo_surface_t\
  cairo_t\
  canvas_t\
  lua_State\
  luax_callback_data_t\
  ncluaw_event_t\
  ncluaw_t\
  socket_t\
  $(NULL)

perl_after_indent:=\
  s:{\s+([\w\"]):{$$1:g;\
  s:([\w\"\-])\s+}:$$1}:g;\
  $$t=join "|", qw($(perl_after_indent_type_list));\
  s:($$t)(\s\*+)\s+(\w):$$1$$2$$3:g;\
  $(NULL)

perl_indent_join_empty_lines:=\
  my @files = @ARGV;\
  $$^I = "~";\
  for my $$file (@files) {\
    local $$/;\
    @ARGV = $$file;\
    while (<>) {\
      s/\n\n\n+/\n\n/gs;\
      print;\
    }\
  }\
  $(NULL)

INDENT?= indent
INDENT_OPTIONS:=\
  --else-endif-column0\
  --gnu-style --indent-label-1\
  --leave-preprocessor-space\
  --no-tabs\
  -l76\
  $(NULL)

INDENT_EXCLUDE:=\
  lib/nclua.h\
  lib/ncluaw.h\
  $(NULL)

INDENT_JOIN_EMPTY_LINES_EXCLUDE:=\
  build-aux/git-version-gen\
  build-aux/warnings.m4\
  examples/luarocks/%\
  $(NULL)

INDENT_VC_LIST_C =\
  $(call vc_list_exclude, $(VC_LIST_C), $(INDENT_EXCLUDE))\
  $(NULL)

# Formats source code.
.PHONY: indent
indent:
	@$(INDENT) $(INDENT_OPTIONS) $(INDENT_VC_LIST_C)
	@$(INDENT) $(INDENT_OPTIONS) $(INDENT_VC_LIST_C)
	@perl -i'~' -wple '$(perl_after_indent)' $(INDENT_VC_LIST_C)
	@perl -we '$(perl_indent_join_empty_lines)'\
	  $(call vc_list_exclude, $(VC_LIST_ALL),\
            $(INDENT_JOIN_EMPTY_LINES_EXCLUDE))


perl_list_c_names:=\
  (/^()()(\w+)\s*\(/ or /^(static\s+)?(const\s+)?\w+\s+\**(\w+)\s+=/)\
  and print "$$ARGV:$$.:$$3";\
  eof and close ARGV;\
  $(NULL)

perl_list_lua_names:=\
  (/^(local\s+)?function\s*([\w\.]+?)\s*\(/ or /^(local\s+)?(\w+)\s*=/)\
  and print "$$ARGV:$$.:$$2";\
  eof and close ARGV;\
  $(NULL)

perl_list_mk_names:=\
  (/^([\w\-]+?):/ or /^(\w+\s*)=/)\
  and print "$$ARGV:$$.:$$1";\
  eof and close ARGV;
  $(NULL)

# Lists names of C functions and variables.
.PHONY: list-c-names
list-c-names:
	@perl -wnle '$(perl_list_c_names)' $(VC_LIST_C)

# Lists names of Lua functions and variables.
.PHONY: list-lua-names
list-lua-names:
	@perl -wnle '$(perl_list_lua_names)' $(VC_LIST_LUA)

# Lists names of Makefile targets and variables.
.PHONY: list-mk-names
list-mk-names:
	@perl -wnle '$(perl_list_mk_names)' $(VC_LIST_MK)


# Checks for untracked files.
.PHONY: maintainer-clean-diff
maintainer-clean-diff:
	@test `git ls-files --other | wc -l` -ne 0 &&\
	  { echo "error: untracked files not removed by maintainer-clean";\
	    git ls-files --other; exit 1;  } || :


SC_AVOID_IF_BEFORE_FREE_ALIASES:=\
  cairo_destroy\
  cairo_region_destroy\
  cairo_surface_destroy\
  g_free\
  luax_callback_data_unref\
  ncluaw_event_free\
  pango_font_description_free\
  $(NULL)


SC_BASE_EXCLUDE:=\
  examples/pacman/%\
  examples/luarocks/%\
  tests/libnclua-echo.lua\
  $(NULL)

# Runs build-aux/syntax-check script.
SC_RULES+= sc-base
sc-base:
	@./build-aux/syntax-check\
	  $(call vc_list_exclude,\
	    $(VC_LIST_C) $(VC_LIST_LUA) $(VC_LIST_PL) $(VC_LIST_SH),\
	    $(SC_BASE_EXCLUDE))


SC_COPYRIGHT_EXCLUDE_C:=\
  lib/luax-macros.h\
  lib/macros.h\
  $(NULL)

SC_COPYRIGHT_EXCLUDE_LUA:=\
  examples/luarocks/%\
  examples/pacman/%\
  examples/www/tcp.lua\
  $(NULL)

SC_COPYRIGHT_EXCLUDE_SH:=\
  $(NULL)

SC_COPYRIGHT_LIST_C =\
  $(call vc_list_exclude, $(VC_LIST_C), $(SC_COPYRIGHT_EXCLUDE_C))

SC_COPYRIGHT_LIST_LUA =\
  $(call vc_list_exclude, $(VC_LIST_LUA), $(SC_COPYRIGHT_EXCLUDE_LUA))

SC_COPYRIGHT_LIST_SH =\
  $(call vc_list_exclude,\
    $(VC_LIST_AC) $(VC_LIST_AM) $(VC_LIST_MK) $(VC_LIST_PL) $(VC_LIST_SH),\
    $(SC_COPYRIGHT_EXCLUDE_SH))

# Checks copyright notice.
SC_RULES+= sc-copyright
sc-copyright:
	@./build-aux/syntax-check-copyright -b='/*' -e='*/'\
	  $(SC_COPYRIGHT_LIST_C)
	@./build-aux/syntax-check-copyright -b='--[[' -e=']]--'\
	  $(SC_COPYRIGHT_LIST_LUA)
	@./build-aux/syntax-check-copyright -b='#'\
	  $(SC_COPYRIGHT_LIST_SH)


perl_sc_make_indent:=\
  /^\t?\ \S/ and print "$$ARGV:$$.:\n-->$$_\n";\
  eof and close ARGV;\
  $(NULL)

# Checks indentation in Makefiles.
SC_RULES+= sc-make-indent
sc-make-indent:
	@perl -wnle '$(perl_sc_make_indent)' $(VC_LIST_AM) $(VC_LIST_MK)


# Checks for useless if before free().
SC_RULES+= sc-useless-if-before-free
sc-useless-if-before-free:
	@./build-aux/useless-if-before-free\
	  $(SC_AVOID_IF_BEFORE_FREE_ALIASES:%=--name=%)\
	  $(VC_LIST_C) && exit 1 || :;


# Run all syntax checks.
.PHONY: syntax-check
.PHONY: $(SC_RULES)
syntax-check: $(SC_RULES)


COPYRIGHT_YEAR:= 2015
COPYRIGHT_HOLDER:= PUC-Rio/Laboratorio TeleMidia

perl_update_copyright:=\
  s:(\W*Copyright\s\(C\)\s\d+)-?\d*(\s\Q$(COPYRIGHT_HOLDER)\E\b)\
   :$$1-$(COPYRIGHT_YEAR)$$2:x;

# Updates copyright year.
.PHONY: update-copyright
update-copyright:
	perl -i'~' -wple '$(perl_update_copyright)' $(VC_LIST_ALL)
