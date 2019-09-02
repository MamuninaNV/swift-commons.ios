// ----------------------------------------------------------------------------
//
//  OSArchiver.h
//  Based on part of libFoundation.
//
//  @author     Alexander Bragin <bragin-av@roxiemobile.com>
//  @copyright  Copyright (c) 2019, Roxie Mobile Ltd. All rights reserved.
//  @link       http://www.roxiemobile.com/
//
// ----------------------------------------------------------------------------

#ifndef __OSArchiver_H__
#define __OSArchiver_H__

// ----------------------------------------------------------------------------

#include <Foundation/NSCoder.h>
#include <Foundation/NSMapTable.h>
#include <Foundation/NSHashTable.h>

#include "OSSerialization.h"

// ----------------------------------------------------------------------------

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

// ----------------------------------------------------------------------------

#endif /* __OSArchiver_H__ */

// ----------------------------------------------------------------------------
