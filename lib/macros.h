/* Copyright (C) 2014-2015 Free Software Foundation, Inc.

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

#if defined HAVE_CONFIG_H
# include <config.h>
#endif
#include <assert.h>
#include <ctype.h>
#include <math.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>

#if defined __GNUC__ && defined __GNUC_MINOR__
# define GNUC_PREREQ(major, minor)\
   ((__GNUC__ << 16) + __GNUC_MINOR__ >= ((major) << 16) + (minor))
#else
# define GNUC_PREREQ(major, minor) 0
#endif

#if GNUC_PREREQ (2,5)
# define ATTRIBUTE_CONST __attribute__ ((__const__))
#else
# define ATTRIBUTE_CONST
#endif

#if GNUC_PREREQ (2,5)
# define ATTRIBUTE_UNUSED __attribute ((__unused__))
#else
# define ATTRIBUTE_UNUSED
#endif

#if GNUC_PREREQ (2,5)
# define ATTRIBUTE_PRINTF_FORMAT(fmt, va) __attribute__ ((__format__ (__printf__, fmt, va)))
#else
# define ATTRIBUTE_PRINTF_FORMAT(fmt, va)
#endif

#if GNUC_PREREQ (2,96)
# define ATTRIBUTE_MALLOC __attribute__ ((__malloc__))
#else
# define ATTRIBUTE_MALLOC
#endif

#if GNUC_PREREQ (2,96)
# define ATTRIBUTE_PURE __attribute__ ((__pure__))
#else
# define ATTRIBUTE_PURE
#endif

#if GNUC_PREREQ (3,1)
# define ATTRIBUTE_NOINLINE __attribute__ ((__noinline__))
#else
# define ATTRIBUTE_NOINLINE
#endif

#if GNUC_PREREQ (3,1)
# define ATTRIBUTE_USED __attribute__ ((__used__))
#else
# define ATTRIBUTE_USED
#endif

#if GNUC_PREREQ (3,2)
# define ATTRIBUTE_DEPRECATED __attribute__ ((__deprecated__))
#else
# define ATTRIBUTE_DEPRECATED
#endif

#if GNUC_PREREQ (3,3)
# define ATTRIBUTE_NONNULL(params) __attribute__ ((__nonnull__ params))
#else
# define ATTRIBUTE_NONNULL(params)
#endif

#if GNUC_PREREQ (3,4)
# define ATTRIBUTE_WARN_UNUSED_RESULT __attribute__ ((__warn_unused_result__))
#else
# define ATTRIBUTE_WARN_UNUSED_RESULT
#endif

#if GNUC_PREREQ (4,3)
# define ATTRIBUTE_ARTIFICIAL __attribute__ ((__artificial__))
#else
# define ATTRIBUTE_ARTIFICIAL
#endif

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

#define arg_nonnull(arg)   ATTRIBUTE_NONNULL (arg)
#define arg_unused(arg)    arg ATTRIBUTE_UNUSED
#define ATTR_CONST         ATTRIBUTE_CONST
#define ATTR_DEPRECATED    ATTRIBUTE_DEPRECATED
#define ATTR_MALLOC        ATTRIBUTE_MALLOC
#define ATTR_PRINTF_FORMAT ATTRIBUTE_PRINTF_FORMAT
#define ATTR_PURE          ATTRIBUTE_PURE
#define ATTR_UNUSED        ATTRIBUTE_UNUSED
#define ATTR_USE_RESULT    ATTRIBUTE_WARN_UNUSED_RESULT

#if GNUC_PREREQ (3,0)
# define likely(cond)    __builtin_expect((cond), 1)
# define unlikely(cond)  __builtin_expect((cond), 0)
#else
# define likely(cond)
# define unlikely(cond)
#endif

#if !defined TRUE
# define TRUE 1
#endif

#if !defined FALSE
# define FALSE 0
#endif

#if !defined EXIT_SUCCESS
# define EXIT_SUCCESS 0
#endif

#if !defined EXIT_FAILURE
# define EXIT_FAILURE 1
#endif

#define ASSERT_NOT_REACHED (assert (!"reached"), abort ())
#define CONCAT(x, y)     CONCAT_ (x, y)
#define CONCAT_(x, y)    x##y
#define STRINGIFY(s)     STRINGIFY_ (s)
#define STRINGIFY_(s)    #s
#define nelementsof(x)   (sizeof (x) / sizeof (x[0]))
#define integralof(x)    (((char *)(x)) - ((char *) 0))
#define pointerof(x)     ((void *)((char *) 0 + ((size_t) x)))
#define ssizeof(x)       ((ptrdiff_t) sizeof (x))
#define isodd(n)         ((n) & 1)
#define iseven(n)        (!isodd (n))
#define sign(x)          ((x) >= 0.0 ? 1 : -1)
#define max(x, y)        (((x) > (y)) ? (x) : (y))
#define min(x, y)        (((x) < (y)) ? (x) : (y))
#define clamp(x, lo, hi) (min (max (x, lo), hi))
#define radians(x)       (x * M_PI / 180)
#define degrees(x)       (x * 180 / M_PI)
#define streq(a, b)      ((*(a) == *(b)) && strcmp (a, b) == 0)

#define cast(t, x)       ((t)(x))
#define deconst(t, x)    ((t)(ptrdiff_t)(const void *)(x))
#define devolatile(t, x) ((t)(ptrdiff_t)(volatile void *)(x))
#define dequalify(t, x)  ((t)(ptrdiff_t)(const volatile void *)(x))
#define test_and_set(c, x, y) STMT_BEGIN {if (c) x = y; } STMT_END

#if !defined round && defined HAVE_ROUND && !HAVE_ROUND
# define round(x) floor (((double) x) + .5)
#endif

#if !defined lround && defined HAVE_LROUND && !HAVE_LROUND
static inline ATTR_CONST long int
lround (double x)
{
  return (x = round (x), (long int) x);
}
#endif

#endif /* MACROS_H */
