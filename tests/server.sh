#!/bin/sh
srcdir="$1"; shift
exec perl "$srcdir/server.pl" "$@" &
