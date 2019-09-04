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

#import "OSSerialization.h"

// ----------------------------------------------------------------------------

@interface OSArchiver : NSCoder <OSObjCTypeSerializationCallBack>
{
    SEL         classForCoder;        // default: classForCoder:
    SEL         replObjectForCoder;   // default: replacementObjectForCoder:

    // destination
    void (*addData)(id, SEL, const void *, unsigned);
    void (*serData)(id, SEL, const void *, const char *, id);
}

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

// NOTE: Not supported
// - (void)replaceObject:(id)object withObject:(id)newObject;

// --

@end

// ----------------------------------------------------------------------------

FOUNDATION_EXPORT NSString *const OSCoderSignature;
FOUNDATION_EXPORT UInt16 OSCoderVersion;

// ----------------------------------------------------------------------------
