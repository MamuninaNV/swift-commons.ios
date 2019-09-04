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
    // source
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

// decoding

- (id)decodeObject;

/* Substituting One Class for Another */

+ (NSString *)classNameDecodedForArchiveClassName:(NSString *)nameInArchive;
+ (void)decodeClassName:(NSString *)nameInArchive asClassName:(NSString *)trueName;
- (NSString *)classNameDecodedForArchiveClassName:(NSString *)nameInArchive;
- (void)decodeClassName:(NSString *)nameInArchive asClassName:(NSString *)trueName;

// NOTE: Not supported
// - (void)replaceObject:(id)object withObject:(id)newObject;

// --

@end

// ----------------------------------------------------------------------------

FOUNDATION_EXPORT NSString *const OSInconsistentArchiveException;

// ----------------------------------------------------------------------------
