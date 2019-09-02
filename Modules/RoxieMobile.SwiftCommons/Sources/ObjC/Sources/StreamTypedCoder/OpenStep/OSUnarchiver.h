// ----------------------------------------------------------------------------
//
//  OSUnarchiver.h
//  Based on part of libFoundation.
//
//  @author     Alexander Bragin <bragin-av@roxiemobile.com>
//  @copyright  Copyright (c) 2019, Roxie Mobile Ltd. All rights reserved.
//  @link       http://www.roxiemobile.com/
//
// ----------------------------------------------------------------------------

#ifndef __OSUnarchiver_H__
#define __OSUnarchiver_H__

// ----------------------------------------------------------------------------

#include <Foundation/NSCoder.h>
#include <Foundation/NSMapTable.h>
#include <Foundation/NSHashTable.h>

#include "OSSerialization.h"

// ----------------------------------------------------------------------------

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

// ----------------------------------------------------------------------------

#endif /* __OSUnarchiver_H__ */

// ----------------------------------------------------------------------------
