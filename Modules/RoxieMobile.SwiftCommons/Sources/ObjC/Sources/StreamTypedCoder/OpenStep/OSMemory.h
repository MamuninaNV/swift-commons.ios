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
