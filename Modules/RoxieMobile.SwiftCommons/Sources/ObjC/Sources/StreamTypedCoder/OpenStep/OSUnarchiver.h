/* 
   OSUnarchiver.h

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
   
   OSUnarchiver.h

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

#ifndef __OSUnarchiver_H__
#define __OSUnarchiver_H__

#include <Foundation/NSCoder.h>
// #include <Foundation/NSSerialization.h>
#include <Foundation/NSMapTable.h>
#include <Foundation/NSHashTable.h>

#include "OSSerialization.h"

@interface OSUnarchiver : NSCoder < OSObjCTypeSerializationCallBack >
{
    unsigned    inArchiverVersion;    // archiver's version that wrote the data
    NSMapTable  *inObjects;           // decoded objects: key -> object
    NSMapTable  *inClasses;           // decoded classes: key -> class info
    NSMapTable  *inPointers;          // decoded pointers: key -> pointer
    NSMapTable  *inClassAlias;        // archive name -> decoded name
    NSMapTable  *inClassVersions;     // archive name -> class info
    NSZone      *objectZone;
    BOOL        decodingRoot;
    BOOL        didReadHeader;

    // source
    NSData       *data;
    unsigned int cursor;
    void (*getData)(id, SEL, void *, unsigned, unsigned *);
    void (*deserData)(id, SEL, void *, const char *, unsigned *, id);
}

- (id)initForReadingWithData:(NSData*)data;

/* Decoding Objects */
+ (id)unarchiveObjectWithData:(NSData*)data;
+ (id)unarchiveObjectWithFile:(NSString*)path;

/* Managing an OSUnarchiver */

- (BOOL)isAtEnd;
- (NSZone *)objectZone;
- (void)setObjectZone:(NSZone *)_zone;
- (unsigned int)systemVersion;

// decoding

- (id)decodeObject;

/* Substituting One Class for Another */

+ (NSString *)classNameDecodedForArchiveClassName:(NSString *)nameInArchive;
+ (void)decodeClassName:(NSString *)nameInArchive asClassName:(NSString *)trueName;
- (NSString *)classNameDecodedForArchiveClassName:(NSString *)nameInArchive;
- (void)decodeClassName:(NSString *)nameInArchive asClassName:(NSString *)trueName;
// not supported yet: replaceObject:withObject:

@end

#endif /* __OSUnarchiver_H__ */
/*
  Local Variables:
  c-basic-offset: 4
  tab-width: 8
  End:
*/
