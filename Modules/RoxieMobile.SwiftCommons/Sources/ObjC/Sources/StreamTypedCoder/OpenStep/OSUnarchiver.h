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

#import "OSSerialization.h"

// ----------------------------------------------------------------------------

@interface OSUnarchiver : NSCoder < OSObjCTypeSerializationCallBack >
{
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

// - Properties

// Managing an Unarchiver
@property(readonly, assign, getter=isAtEnd) BOOL atEnd;
@property(readonly, assign) unsigned int systemVersion;

// - Methods

- (id)initForReadingWithData:(NSData*)data;

/* Decoding Objects */
+ (id)unarchiveObjectWithData:(NSData*)data;
+ (id)unarchiveObjectWithFile:(NSString*)path;

/* Managing an OSUnarchiver */

- (NSZone *)objectZone;
- (void)setObjectZone:(NSZone *)_zone;

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
