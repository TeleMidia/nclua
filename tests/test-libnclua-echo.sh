#!/bin/sh -
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

export LC_ALL=C

top_srcdir=`sed -n 's/^top_srcdir[ ]*=[ ]*\(.*\)$/\1/p' Makefile`
top_builddir=`sed -n 's/^top_builddir[ ]*=[ ]*\(.*\)$/\1/p' Makefile`

LUA=$top_builddir/tests/lua
tmp="`basename $0`.tmp"

rand () { cat /dev/urandom | tr -d -c 'a-zA-Z' | fold -w 4 | head -n 1; }
send () {
  result="`$top_builddir/tests/libnclua-echo "$1"`"
  cat > "$tmp" <<EOF
local input=$1
local output=$result
for k,v in pairs (input) do assert (output[k] == v) end
for k,v in pairs (output) do assert (input[k] == v) end
os.exit (0)
EOF
  if ! $LUA "$tmp"; then
    echo 1>&2 "$result != $1"
    exit 1
  fi
}

i=1
prefix=''
while :; do
  key="`rand`"; val="`rand`"
  send "{$prefix$key=\"$val\"}"
  prefix="$prefix$key=\"$val\", "
  i=`expr $i + 1`
  if test $i -ge 32; then
    break
  fi
done
rm -f "$tmp"
