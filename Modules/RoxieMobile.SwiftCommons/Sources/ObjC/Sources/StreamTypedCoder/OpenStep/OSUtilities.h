/* 
   OSUtilities.h

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

#ifndef __OSUtilities_h__
#define __OSUtilities_h__

#include <Foundation/NSObject.h>
#include <Foundation/NSObjCRuntime.h>
#include <Foundation/NSHashTable.h>
#include <Foundation/NSMapTable.h>
#include <Foundation/NSEnumerator.h>

#include <objc/objc.h>
#include <objc/objc-api.h>
#include <stdarg.h>

@class NSObject;
@class NSString;
@class NSArray;

/*
 * Convenience functions to deal with Hash and Map Table
 */

FOUNDATION_EXPORT unsigned __NSHashObject(void* table, const void* anObject);
FOUNDATION_EXPORT unsigned __NSHashPointer(void* table, const void* anObject);
FOUNDATION_EXPORT unsigned __NSHashInteger(void* table, const void* anObject);
FOUNDATION_EXPORT unsigned __NSHashCString(void* table, const void* anObject);
FOUNDATION_EXPORT BOOL __NSCompareObjects(void* table,
        const void* anObject1, const void* anObject2);
FOUNDATION_EXPORT BOOL __NSComparePointers(void* table,
        const void* anObject1, const void* anObject2);
FOUNDATION_EXPORT BOOL __NSCompareInts(void* table,
        const void* anObject1, const void* anObject2);
FOUNDATION_EXPORT BOOL __NSCompareCString(void* table,
        const void* anObject1, const void* anObject2);
FOUNDATION_EXPORT void __NSRetainNothing(void* table, const void* anObject);
FOUNDATION_EXPORT void __NSRetainObjects(void* table, const void* anObject);
FOUNDATION_EXPORT void __NSReleaseNothing(void* table, void* anObject);
FOUNDATION_EXPORT void __NSReleaseObjects(void* table, void* anObject);
FOUNDATION_EXPORT void __NSReleasePointers(void* table, void* anObject);
FOUNDATION_EXPORT NSString* __NSDescribeObjects(void* table, const void* anObject);
FOUNDATION_EXPORT NSString* __NSDescribePointers(void* table, const void* anObject);
FOUNDATION_EXPORT NSString* __NSDescribeInts(void* table, const void* anObject);

#endif /* __OSUtilities_h__ */

/*
  Local Variables:
  c-basic-offset: 4
  tab-width: 8
  End:
*/
