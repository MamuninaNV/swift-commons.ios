// ----------------------------------------------------------------------------
//
//  StreamTypedArchiver.h
//
//  @author     Alexander Bragin <bragin-av@roxiemobile.com>
//  @copyright  Copyright (c) 2016, Roxie Mobile Ltd. All rights reserved.
//  @link       http://www.roxiemobile.com/
//
// ----------------------------------------------------------------------------

#import <Foundation/Foundation.h>

// ----------------------------------------------------------------------------

@interface StreamTypedEncoder : NSCoder

// - Properties

// Getting the archived data
@property(readonly, strong) NSMutableData *archiverData;

// - Methods

// Initializing an Encoder
- (instancetype)initForWritingWithMutableData:(NSMutableData *)data;

// Archiving data
+ (NSData *)archivedDataWithRootObject:(id)rootObject;
+ (BOOL)archiveRootObject:(id)rootObject toFile:(NSString *)path;

// Encoding
- (void)encodeConditionalObject:(id)object;
- (void)encodeRootObject:(id)rootObject;

// Substituting one Class for another
- (NSString *)classNameEncodedForTrueClassName:(NSString *)trueName;
- (void)encodeClassName:(NSString *)trueName intoClassName:(NSString *)inArchiveName;

// NOTE: Not supported yet
- (void)replaceObject:(id)object withObject:(id)newObject;

// --

@end

// ----------------------------------------------------------------------------
#pragma mark -
// ----------------------------------------------------------------------------

// TODO: Refactoring is required
@interface StreamTypedDecoder : NSCoder

// -- properties

// Managing an Decoder
@property(readonly, getter=isAtEnd) BOOL atEnd;
@property(readonly) unsigned int systemVersion;

// -- functions

// Initializing an Decoder
- (instancetype)initForReadingWithData:(NSData *)data;

// Decoding objects
+ (id)unarchiveObjectWithData:(NSData *)data;
+ (id)unarchiveObjectWithFile:(NSString *)path;

// Substituting classes or objects
+ (NSString *)classNameDecodedForArchiveClassName:(NSString *)nameInArchive;
+ (void)decodeClassName:(NSString *)nameInArchive asClassName:(NSString *)trueName;

- (NSString *)classNameDecodedForArchiveClassName:(NSString *)nameInArchive;
- (void)decodeClassName:(NSString *)nameInArchive asClassName:(NSString *)trueName;
- (void)replaceObject:(id)object withObject:(id)newObject;

// --

@end

// ----------------------------------------------------------------------------
