// ----------------------------------------------------------------------------
//
//  OSMemory.h
//  Based on part of GNU CC.
//
//  @author     Alexander Bragin <bragin-av@roxiemobile.com>
//  @copyright  Copyright (c) 2019, Roxie Mobile Ltd. All rights reserved.
//  @link       http://www.roxiemobile.com/
//
// ----------------------------------------------------------------------------

#include <objc/objc-api.h>
#include <Foundation/Foundation.h>

#import "objc-config.h"

// ----------------------------------------------------------------------------

#if LIB_FOUNDATION_BOEHM_GC

#  ifndef RETAIN
#    define RETAIN(object)      ((id) object)
#  endif
#  ifndef RELEASE
#    define RELEASE(object)
#  endif
#  ifndef AUTORELEASE
#    define AUTORELEASE(object) ((id) object)
#  endif

#else // LIB_FOUNDATION_BOEHM_GC

#  ifndef RETAIN
#    define RETAIN(object)      [object retain]
#  endif
#  ifndef RELEASE
#    define RELEASE(object)     [object release]
#  endif
#  ifndef AUTORELEASE
#    define AUTORELEASE(object) [object autorelease]
#  endif

#endif // LIB_FOUNDATION_BOEHM_GC

// ----------------------------------------------------------------------------

/*
** Standard functions for memory allocation and disposal.
** Users should use these functions in their ObjC programs so
** that they work properly with garbage collectors as well as
** can take advantage of the exception/error handling available.
*/

void *objc_malloc(size_t size);
void *objc_atomic_malloc(size_t size);
void *objc_valloc(size_t size);
void *objc_realloc(void *mem, size_t size);
void *objc_calloc(size_t nelem, size_t size);
void objc_free(void *mem);

// ----------------------------------------------------------------------------
