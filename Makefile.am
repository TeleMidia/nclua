# Makefile.am -- Template for generating Makefile via Automake.
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

include $(top_srcdir)/build-aux/Makefile.am.common

SUBDIRS= lib nclua src tests
ACLOCAL_AMFLAGS= -I build-aux ${ACLOCAL_FLAGS}

# Setup code coverage.
include $(top_srcdir)/build-aux/Makefile.am.coverage
COVERAGE_EXCLUDE+= tests/\* lib/macros.h lib/luax-macros.h

# Setup version.
BUILT_SOURCES= .version
.version:
	$(AM_V_GEN)echo $(VERSION) > $@-t && mv $@-t $@

# Prepare distribution.
include $(top_srcdir)/build-aux/Makefile.am.gitlog
dist-hook:
	@echo $(VERSION) > $(distdir)/.tarball-version
	@cp -r $(srcdir)/contrib $(srcdir)/examples $(distdir)

EXTRA_DIST=\
  .version\
  README.md\
  bootstrap\
  build-aux/git-log-fix\
  build-aux/git-version-gen\
  build-aux/gitlog-to-changelog\
  build-aux/manywarnings.m4\
  build-aux/perl.m4\
  build-aux/syntax-check-copyright\
  build-aux/syntax-check\
  build-aux/useless-if-before-free\
  build-aux/util.m4\
  build-aux/warnings.m4\
  maint.mk\
  $(NULL)

# Generate README from README.md if we have Perl.
if HAVE_PERL
BUILT_SOURCES+= README
CLEANFILES+= README
EXTRA_DIST+= README
endif

perl_strip_md_id_or_path_re= [\w\.\-/:]
perl_strip_md=\
  BEGIN { $$n = 0; }\
  s, , ,g;\
  s,`($(perl_strip_md_id_or_path_re)+)`,$$1,g;\
  s,^!.*$$,,g;\
  s,\[[^\]]+]\(($(perl_strip_md_id_or_path_re)+)\),$$1,g;\
  $$n >= 2 and print;\
  $$n++;\
  $(NULL)

README: README.md
	$(AM_V_GEN)$(PERL) -wnle '$(perl_strip_md)' README.md > $@

DISTCLEANFILES+=\
  config.cache\
  $(NULL)

MAINTAINERCLEANFILES+=\
  .version\
  ChangeLog\
  INSTALL\
  aclocal.m4\
  build-aux/ar-lib\
  build-aux/compile\
  build-aux/config.guess\
  build-aux/config.sub\
  build-aux/depcomp\
  build-aux/install-sh\
  build-aux/libtool.m4\
  build-aux/ltmain.sh\
  build-aux/ltoptions.m4\
  build-aux/ltsugar.m4\
  build-aux/ltversion.m4\
  build-aux/lt~obsolete.m4\
  build-aux/missing\
  build-aux/mkinstalldirs\
  build-aux/test-driver\
  configure\
  lib/config.h.in\
  lib/config.h.in~\
  $(NULL)
