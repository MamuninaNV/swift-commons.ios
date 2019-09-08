/* 
   GeneralExceptions.m

   Copyright (C) 1995, 1996 Ovidiu Predescu and Mircea Oancea.
   All rights reserved.

   Author: Ovidiu Predescu <ovidiu@bx.logicnet.ro>

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

#include <stdarg.h>
#include <stdio.h>
#include <Foundation/NSString.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSValue.h>

// #include <extensions/NSException.h>
// #include <extensions/exceptions/GeneralExceptions.h>

#include "GeneralExceptions.h"

#if GNUSTEP_BASE_LIBRARY || LIBOBJECTS_LIBRARY
# define name_ivar     e_name
# define reason_ivar   e_reason
# define userInfo_ivar e_info
#else
# define name_ivar     name
# define reason_ivar   reason
# define userInfo_ivar userInfo
#endif


@implementation OSUnknownTypeException
- initForType:(const char*)type
{
    self = [self initWithName:NSInvalidArgumentException
		    reason:@"Unknown Objective-C type encoding"
		    userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
			    [NSString stringWithCString:type encoding:NSUTF8StringEncoding], @"type",
			    nil]];
    return self;
}
@end /* OSUnknownTypeException */


/*
  Local Variables:
  c-basic-offset: 4
  tab-width: 8
  End:
*/

