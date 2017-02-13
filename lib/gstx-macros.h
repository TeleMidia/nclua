/* Copyright (C) 2014-2017 Free Software Foundation, Inc.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.  */

/* Written by Guilherme F. Lima */

#ifndef GSTX_MACROS_H
#define GSTX_MACROS_H

#include "macros.h"

#define GSTX_INCLUDE_PROLOGUE                   \
  PRAGMA_DIAG_IGNORE (-Wbad-function-cast)      \
  PRAGMA_DIAG_PUSH ()                           \
  PRAGMA_DIAG_IGNORE (-Wcast-align)             \
  PRAGMA_DIAG_IGNORE (-Wcast-qual)              \
  PRAGMA_DIAG_IGNORE (-Wconversion)             \
  PRAGMA_DIAG_IGNORE (-Wpedantic)               \
  PRAGMA_DIAG_IGNORE (-Wsign-conversion)        \
  PRAGMA_DIAG_IGNORE (-Wvariadic-macros)

#define GSTX_INCLUDE_EPILOGUE\
  PRAGMA_DIAG_POP ()

/* *INDENT-OFF* */
GSTX_INCLUDE_PROLOGUE
#include <gst/gst.h>
GSTX_INCLUDE_EPILOGUE
/* *INDENT-ON* */

#endif /* GSTX_MACROS_H */
