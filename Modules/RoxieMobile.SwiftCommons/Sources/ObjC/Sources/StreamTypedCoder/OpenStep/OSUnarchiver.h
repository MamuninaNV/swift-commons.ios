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

#import "OSObjCTypeSerializationCallback.h"

// ----------------------------------------------------------------------------

@interface OSUnarchiver : NSCoder <OSObjCTypeSerializationCallback>

// - Properties

// Managing an Unarchiver
@property(readonly, assign, getter=isAtEnd) BOOL atEnd;
@property(readonly, assign) unsigned int systemVersion;

// - Methods

// Initializing an Unarchiver
- (instancetype)initForReadingWithData:(NSData *)data;

// Decoding objects
+ (id)unarchiveObjectWithData:(NSData *)data;
+ (id)unarchiveObjectWithFile:(NSString *)path;

// Substituting one Class for another
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
