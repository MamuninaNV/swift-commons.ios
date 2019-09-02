/* 
   OSArchiver.h

   Copyright (C) 1998 MDlink online service center, Helge Hess
   All rights reserved.

   Author: Helge Hess (helge@mdlink.de)

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

   The code is based on the OSArchiver class done by Ovidiu Predescu which has
   the following Copyright/permission:
   ---
   The basic archiving algorithm is based on libFoundation's OSArchiver by
   Ovidiu Predescu:
   
   OSArchiver.h

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
   ---
*/
// $Id$

#ifndef __OSArchiver_H__
#define __OSArchiver_H__

#include <Foundation/NSCoder.h>
// #include <Foundation/NSSerialization.h>
#include <Foundation/NSMapTable.h>
#include <Foundation/NSHashTable.h>

#include "OSSerialization.h"

@interface OSArchiver : NSCoder < OSObjCTypeSerializationCallBack >
{
    NSHashTable *outObjects;          // objects written so far
    NSHashTable *outConditionals;     // conditional objects
    NSHashTable *outPointers;         // set of pointers
    NSMapTable  *outClassAlias;       // class name -> archive name
    NSMapTable  *replacements;        // src-object to replacement
    NSMapTable  *outKeys;             // src-address -> archive-address
    BOOL        traceMode;            // YES if finding conditionals
    BOOL        didWriteHeader;
    SEL         classForCoder;        // default: classForCoder:
    SEL         replObjectForCoder;   // default: replacementObjectForCoder:
    BOOL        encodingRoot;
    int         archiveAddress;

    // destination
    NSMutableData *data;
    void (*addData)(id, SEL, const void *, unsigned);
    void (*serData)(id, SEL, const void *, const char *, id);
}

- (id)initForWritingWithMutableData:(NSMutableData*)mdata;

/* Archiving Data */
+ (NSData*)archivedDataWithRootObject:(id)rootObject;
+ (BOOL)archiveRootObject:(id)rootObject toFile:(NSString*)path;

/* Getting Data from the OSArchiver */
- (NSMutableData *)archiverData;

/* encoding */

- (void)encodeConditionalObject:(id)_object;
- (void)encodeRootObject:(id)_object;

/* Substituting One Class for Another */

- (NSString *)classNameEncodedForTrueClassName:(NSString *)_trueName;
- (void)encodeClassName:(NSString *)_trueName intoClassName:(NSString *)_archiveName;
// not supported yet: replaceObject:withObject:

@end

#endif /* __OSArchiver_H__ */
/*
  Local Variables:
  c-basic-offset: 4
  tab-width: 8
  End:
*/
