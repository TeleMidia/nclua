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

#ifndef MACROS_H
#define MACROS_H

#ifdef HAVE_CONFIG_H
# include <config.h>
#endif

#include <assert.h>
#include <ctype.h>
#include <math.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>

#ifndef GNUC_PREREQ
# if defined __GNUC__ && defined __GNUC_MINOR__
#  define GNUC_PREREQ(major, minor)\
    ((__GNUC__ << 16) + __GNUC_MINOR__ >= ((major) << 16) + (minor))
# else
#  define GNUC_PREREQ(major, minor) 0
# endif
#endif

#undef ATTR_CONST
#undef ATTR_UNUSED
#undef ATTR_PRINTF_FORMAT

#if GNUC_PREREQ (2,5)
# define ATTR_CONST __attribute__ ((__const__))
# define ATTR_UNUSED __attribute__ ((__unused__))
# define ATTR_PRINTF_FORMAT(fmt, va)\
  __attribute__ ((__format__ (__printf__, fmt, va)))
#else
# define ATTR_CONST
# define ATTR_UNUSED
# define ATTR_PRINTF_FORMAT(fmt, va)
#endif

#undef ATTR_MALLOC
#undef ATTR_PURE

#if GNUC_PREREQ (2,96)
# define ATTR_MALLOC __attribute__ ((__malloc__))
# define ATTR_PURE __attribute__ ((__pure__))
#else
# define ATTR_MALLOC
# define ATTR_PURE
#endif

#undef BUILTIN_LIKELY
#undef BUILTIN_UNLIKELY

#if GNUC_PREREQ (3,0)
# define BUILTIN_LIKELY(cond) __builtin_expect ((cond), 1)
# define BUILTIN_UNLIKELY(cond) __builtin_expect ((cond), 0)
#else
# define BUILTIN_LIKELY(cond)
# define BUILTIN_UNLIKELY(cond)
#endif

#undef ATTR_NOINLINE
#undef ATTR_USED

#if GNUC_PREREQ (3,1)
# define ATTR_NOINLINE __attribute__ ((__noinline__))
# define ATTR_USED __attribute__ ((__used__))
#else
# define ATTR_NOINLINE
# define ATTR_USED
#endif

#undef ATTR_DEPRECATED

#if GNUC_PREREQ (3,2)
# define ATTR_DEPRECATED __attribute__ ((__deprecated__))
#else
# define ATTR_DEPRECATED
#endif

#undef ATTR_MAY_ALIAS
#undef ATTR_NONNULL

#if GNUC_PREREQ (3,3)
# define ATTR_MAY_ALIAS __attribute__ ((may_alias))
# define ATTR_NONNULL(params) __attribute__ ((__nonnull__ params))
#else
# define ATTR_MAY_ALIAS
# define ATTR_NONNULL(params)
#endif

#undef ATTR_USE_RESULT

#if GNUC_PREREQ (3,4)
# define ATTR_USE_RESULT __attribute__ ((__warn_unused_result__))
#else
# define ATTR_USE_RESULT
#endif

#undef PRAGMA_DIAG

#if GNUC_PREREQ (4,2)
# define _GCC_PRAGMA(x) _Pragma (STRINGIFY (x))
# define PRAGMA_DIAG(x) _GCC_PRAGMA (GCC diagnostic x)
#elif defined (__clang__)
# define _CLANG_PRAGMA(x) _Pragma (STRINGIFY (x))
# define PRAGMA_DIAG(x) _CLANG_PRAGMA (clang diagnostic x)
#else
# define PRAGMA_DIAG(x)
#endif

#undef ATTR_ARTIFICIAL

#if GNUC_PREREQ (4,3)
# define ATTR_ARTIFICIAL __attribute__ ((__artificial__))
#else
# define ATTR_ARTIFICIAL
#endif

#undef PRAGMA_DIAG_PUSH
#undef PRAGMA_DIAG_POP

#if GNUC_PREREQ (4,6) || defined (__clang__)
# define PRAGMA_DIAG_PUSH() PRAGMA_DIAG (push)
# define PRAGMA_DIAG_POP() PRAGMA_DIAG (pop)
#else
# define PRAGMA_DIAG_PUSH()
# define PRAGMA_DIAG_POP()
#endif

#undef PRAGMA_DIAG_IGNORE
#define PRAGMA_DIAG_IGNORE(x) PRAGMA_DIAG (ignored STRINGIFY (x))

#undef PRAGMA_DIAG_WARNING
#define PRAGMA_DIAG_WARNING(x) PRAGMA_DIAG (warning STRINGIFY (x))

#undef STMT_BEGIN
#undef STMT_END

#if defined __GNUC__ && !defined __STRICT_ANSI__ && !defined __cplusplus
# define STMT_BEGIN (void)(
# define STMT_END   )
#else
# define STMT_BEGIN do
# define STMT_END   while (0)
#endif

#if defined __STRICT_ANSI__
# undef inline
# define inline __inline__
#elif defined _MSC_VER && !defined __cplusplus
# undef inline
# define inline __inline
#endif

#undef arg_nonnull
#define arg_nonnull(arg) ATTR_NONNULL (arg)

#undef arg_unused
#define arg_unused(arg) arg ATTR_UNUSED

#undef likely
#define likely(cond) BUILTIN_LIKELY ((cond))

#undef unlikely
#define unlikely(cond) BUILTIN_UNLIKELY ((cond))

#ifndef TRUE
# define TRUE 1
#endif

#ifndef FALSE
# define FALSE 0
#endif

#undef ASSERT_NOT_REACHED
#define ASSERT_NOT_REACHED assert (0 && "unreachable reached!")

#undef CONCAT_
#define CONCAT_(x, y) x##y

#undef CONCAT
#define CONCAT(x, y) CONCAT_ (x, y)

#undef STRINGIFY_
#define STRINGIFY_(s) #s

#undef STRINGIFY
#define STRINGIFY(s) STRINGIFY_ (s)

#undef nelementsof
#define nelementsof(x) (sizeof ((x)) / sizeof ((x)[0]))

#undef integralof
#define integralof(x) (((char *)(x)) - ((char *) 0))

#undef pointerof
#define pointerof(x) ((void *)((char *) 0 + ((size_t)(x))))

#undef ssizeof
#define ssizeof(x) ((ptrdiff_t)(sizeof ((x))))

#undef isodd
#define isodd(n) ((n) & 1)

#undef iseven
#define iseven(n) (!isodd ((n)))

#undef sign
#define sign(x) ((x) >= 0.0 ? 1 : -1)

#undef max
#define max(x, y) (((x) > (y)) ? (x) : (y))

#undef min
#define min(x, y) (((x) < (y)) ? (x) : (y))

#undef clamp
#define clamp(x, lo, hi) (min (max ((x), (lo)), (hi)))

#undef radians
#define radians(x) ((x) * M_PI / 180)

#undef degrees
#define degrees(x) ((x) * 180 / M_PI)

#undef streq
#define streq(a, b) ((*(a) == *(b)) && strcmp ((a), (b)) == 0)

#undef strbool
#define strbool(x) ((x) ? "true" : "false")

#undef cast
#define cast(t, x) ((t)(x))

#undef deconst
#define deconst(t, x) ((t)(ptrdiff_t)(const void *)(x))

#undef devolatile
#define devolatile(t, x) ((t)(ptrdiff_t)(volatile void *)(x))

#undef dequalify
#define dequalify(t, x) ((t)(ptrdiff_t)(const volatile void *)(x))

#undef set_if_nonnull
#define set_if_nonnull(a, x) STMT_BEGIN {if (a) *(a) = (x); } STMT_END

#if !defined round && defined HAVE_ROUND && !HAVE_ROUND
# define round(x) floor (((double)(x)) + .5)
#endif

#if !defined lround && defined HAVE_LROUND && !HAVE_LROUND
static inline ATTR_CONST long int
lround (double x)
{
  return (x = round (x), (long int) x);
}
#endif

#endif /* MACROS_H */
