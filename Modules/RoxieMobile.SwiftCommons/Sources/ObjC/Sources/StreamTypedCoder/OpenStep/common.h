/* 
   common.h

   Copyright (C) 1995, 1996 Ovidiu Predescu and Mircea Oancea.
   All rights reserved.

   Author: Ovidiu Predescu <ovidiu@bx.logicnet.ro>
	   Mircea Oancea <mircea@jupiter.elcom.pub.ro>
	   Florin Mihaila <phil@pathcom.com>
	   Bogdan Baliuc <stark@protv.ro>

   This file is part of libFoundation.

   Permission to use, copy, modify, and distribute this software and its
   documentation for any purpose and without fee is hereby granted, provided
   that the above copyright notice appear in all copies and that both that
   copyright notice and this permission notice appear in supporting
   documentation.

   We disclaim all warranties with regard to this software, including all
   implied warranties of merchantability and fitness, in no event shall
   we be liable for any special, indirect or consequential damages or any
   damages whatsoever resulting from loss of use, data or profits, whether in
   an action of contract, negligence or other tortious action, arising out of
   or in connection with the use or performance of this software.
*/

#ifndef __common_h__
#define __common_h__

// #include <config.h>
#include <Foundation/NSString.h>

#include <objc/objc-api.h>
#include "objc-config.h"

#if HAVE_STRING_H
# include <string.h>
#endif

#if HAVE_STRINGS_H
# include <strings.h>
#endif

#if HAVE_MEMORY_H
# include <memory.h>
#endif

#if !HAVE_MEMCPY
# define memcpy(d, s, n)       bcopy((s), (d), (n))
# define memmove(d, s, n)      bcopy((s), (d), (n))
#endif

#include <ctype.h>

#if HAVE_STDLIB_H
# include <stdlib.h>
#else
extern void* malloc();
extern void* calloc();
extern void* realloc();
extern void free();
extern atoi();
extern atol();
#endif

#if HAVE_LIBC_H
# define NSObject AppleNSObject
# include <libc.h>
# undef NSObject
#else
# include <unistd.h>
#endif

#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <limits.h>
#include <fcntl.h>

#if HAVE_PWD_H
# include <pwd.h>
#endif
#include <stdarg.h>

#if HAVE_PROCESS_H
#include <process.h>
#endif

#ifdef __WIN32__
#define sleep(x) Sleep(x*1000)
#endif

#include "OSMemory.h"

#if (__GNUC__ == 2) && (__GNUC_MINOR__ <= 6) && !defined(__attribute__)
#  define __attribute__(x)
#endif


@class NSString;
@class NSData;


#include <Foundation/NSObject.h>

/* Non OpenStep useful things */

// #ifndef MAX
// #define MAX(a, b) \
//     ({typeof(a) _a = (a); typeof(b) _b = (b); (_a > _b) ? _a : _b; })
// #endif

// #ifndef MIN
// #define MIN(a, b) \
//     ({typeof(a) _a = (a); typeof(b) _b = (b); (_a < _b) ? _a : _b; })
// #endif

#endif /* __common_h__ */

/*
  Local Variables:
  c-basic-offset: 4
  tab-width: 8
  End:
*/
