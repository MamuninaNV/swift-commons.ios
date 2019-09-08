// ----------------------------------------------------------------------------
//
//  OSUnarchiver+Decoding.m
//
//  @author     Alexander Bragin <bragin-av@roxiemobile.com>
//  @copyright  Copyright (c) 2019, Roxie Mobile Ltd. All rights reserved.
//  @link       http://www.roxiemobile.com/
//
// ----------------------------------------------------------------------------

#import "objc-runtime.h"

#import "OSEncoding.h"
#import "OSUnknownTypeException.h"
#import "OSUnarchiver+Decoding.h"

// ----------------------------------------------------------------------------

#define FINAL static inline

// ----------------------------------------------------------------------------

@interface OSUnarchiver ()

// - Properties

// Source
@property(nonatomic, strong) NSData *buffer;
@property(nonatomic, assign) NSUInteger cursor;

// --

@end

// ----------------------------------------------------------------------------
#pragma mark - Private Methods
// ----------------------------------------------------------------------------

FINAL void __checkType(OSTagType type, OSTagType reqType) {
    if (type != reqType) {
        [NSException raise:OSInconsistentArchiveException format:@"Expected different typecode."];
    }
}

// ----------------------------------------------------------------------------

FINAL void __checkTypePair(OSTagType type, OSTagType reqType1, OSTagType reqType2) {
    __checkType(type, reqType1);
    __checkType(type, reqType2);
}

// ----------------------------------------------------------------------------
#pragma mark -
// ----------------------------------------------------------------------------

@implementation OSUnarchiver (Decoding)

// ----------------------------------------------------------------------------
#pragma mark - Methods
// ----------------------------------------------------------------------------

- (void)readBytes:(void *)bytes length:(NSUInteger)length {

    if ((bytes != nil) && (length > 0)) {
        [self.buffer getBytes:bytes range:NSMakeRange(self.cursor, length)];
        self.cursor += length;
    }
}

// ----------------------------------------------------------------------------

- (OSTagType)readTag {

    OSTagType tag = 0;
    [self readBytes:&tag length:sizeof(tag)];

    if (tag == 0) {
        [NSException raise:OSInconsistentArchiveException format:@"Found invalid type tag (0)."];
    }

    // Done
    return tag;
}

// ----------------------------------------------------------------------------

- (NSString *)readStringWithTag:(BOOL)withTag {

    if (withTag) {
        __checkTypePair([self readTag], _C_ATOM, _C_CHARPTR);
    }

    NSString *value = nil;

    // Decode string's data
    NSUInteger length = 0;
    Byte *bytes = [self decodeBytesWithReturnedLength:&length];

    // Build string from raw data
    if ((bytes != nil) && (length > 0)) {
        value = [[NSString alloc] initWithBytes:bytes length:length encoding:NSUTF8StringEncoding];
    }
    else {
        value = [NSString string];
    }

    // Done
    return value;
}

// ----------------------------------------------------------------------------

- (long long)readLongLongWithTag:(BOOL)withTag {

    if (withTag) {
        __checkType([self readTag], _C_LNG_LNG);
    }

    long long value = 0;
    [self readBytes:&value length:sizeof(value)];
    value = ntohll(value);

    // Done
    return value;
}

- (long long)readLongLong {
    return [self readLongLongWithTag:NO];
}

// ----------------------------------------------------------------------------

- (unsigned long long)readUnsignedLongLongWithTag:(BOOL)withTag {

    if (withTag) {
        __checkType([self readTag], _C_ULNG_LNG);
    }

    unsigned long long value = 0;
    [self readBytes:&value length:sizeof(value)];
    value = ntohll(value);

    // Done
    return value;
}

- (unsigned long long)readUnsignedLongLong {
    return [self readUnsignedLongLongWithTag:NO];
}

// ----------------------------------------------------------------------------

- (long)readLongWithTag:(BOOL)withTag {

    if (withTag) {
        __checkType([self readTag], _C_LNG);
    }

    long value = 0;
    [self readBytes:&value length:sizeof(value)];
    value = (long) ntohl(value);

    // Done
    return value;
}

- (long)readLong {
    return [self readLongWithTag:NO];
}

// ----------------------------------------------------------------------------

- (unsigned long)readUnsignedLongWithTag:(BOOL)withTag {

    if (withTag) {
        __checkType([self readTag], _C_ULNG);
    }

    unsigned long value = 0;
    [self readBytes:&value length:sizeof(value)];
    value = ntohl(value);

    // Done
    return value;
}

- (unsigned long)readUnsignedLong {
    return [self readUnsignedLongWithTag:NO];
}

// ----------------------------------------------------------------------------

- (int)readIntWithTag:(BOOL)withTag {

    if (withTag) {
        __checkType([self readTag], _C_INT);
    }

    int value = 0;
    [self readBytes:&value length:sizeof(value)];
    value = ntohl(value);

    // Done
    return value;
}

- (int)readInt {
    return [self readIntWithTag:NO];
}

// ----------------------------------------------------------------------------

- (unsigned int)readUnsignedIntWithTag:(BOOL)withTag {

    if (withTag) {
        __checkType([self readTag], _C_UINT);
    }

    unsigned int value = 0;
    [self readBytes:&value length:sizeof(value)];
    value = ntohl(value);

    // Done
    return value;
}

- (unsigned int)readUnsignedInt {
    return [self readUnsignedIntWithTag:NO];
}

// ----------------------------------------------------------------------------

- (short)readShortWithTag:(BOOL)withTag {

    if (withTag) {
        __checkType([self readTag], _C_SHT);
    }

    short value = 0;
    [self readBytes:&value length:sizeof(value)];
    value = ntohs(value);

    // Done
    return value;
}

- (short)readShort {
    return [self readShortWithTag:NO];
}

// ----------------------------------------------------------------------------

- (unsigned short)readUnsignedShortWithTag:(BOOL)withTag {

    if (withTag) {
        __checkType([self readTag], _C_USHT);
    }

    unsigned short value = 0;
    [self readBytes:&value length:sizeof(value)];
    value = ntohs(value);

    // Done
    return value;
}

- (unsigned short)readUnsignedShort {
    return [self readUnsignedShortWithTag:NO];
}

// ----------------------------------------------------------------------------

- (char)readCharWithTag:(BOOL)withTag {

    if (withTag) {
        __checkType([self readTag], _C_CHR);
    }

    char value = 0;
    [self readBytes:&value length:sizeof(value)];

    // Done
    return value;
}

- (char)readChar {
    return [self readCharWithTag:NO];
}

// ----------------------------------------------------------------------------

- (unsigned char)readUnsignedCharWithTag:(BOOL)withTag {

    if (withTag) {
        __checkType([self readTag], _C_UCHR);
    }

    unsigned char value = 0;
    [self readBytes:&value length:sizeof(value)];

    // Done
    return value;
}

- (unsigned char)readUnsignedChar {
    return [self readUnsignedCharWithTag:NO];
}

// ----------------------------------------------------------------------------

- (NSInteger)readInteger {
    NSInteger value = 0;

    // Read signed int
    OSTagType tag = [self readTag];
    switch (tag) {

        case _C_CHR: {
            value = [self readChar];
            break;
        }

        case _C_SHT: {
            value = [self readShort];
            break;
        }

        case _C_INT: {
            value = [self readInt];
            break;
        }

        case _C_LNG: {
            value = [self readLong];
            break;
        }

        default: {
            char type[] = {tag, 0};
            [OSUnknownTypeException raiseForType:type];
        }
    }

    // Done
    return value;
}

// ----------------------------------------------------------------------------

- (NSUInteger)readUnsignedInteger {
    NSUInteger value = 0;

    // Read unsigned int
    OSTagType tag = [self readTag];
    switch (tag) {

        case _C_UCHR: {
            value = [self readUnsignedChar];
            break;
        }

        case _C_USHT: {
            value = [self readUnsignedShort];
            break;
        }

        case _C_UINT: {
            value = [self readUnsignedInt];
            break;
        }

        case _C_ULNG: {
            value = [self readUnsignedLong];
            break;
        }

        default: {
            char type[] = {tag, 0};
            [OSUnknownTypeException raiseForType:type];
        }
    }

    // Done
    return value;
}

// ----------------------------------------------------------------------------

- (float)readFloatWithTag:(BOOL)withTag {

    if (withTag) {
        __checkType([self readTag], _C_FLT);
    }

    float value = 0;
    [self readBytes:&value length:sizeof(value)];
    value = objc_ntohf(value);

    // Done
    return value;
}

- (float)readFloat {
    return [self readFloatWithTag:NO];
}

// ----------------------------------------------------------------------------

- (double)readDoubleWithTag:(BOOL)withTag {

    if (withTag) {
        __checkType([self readTag], _C_DBL);
    }

    double value = 0;
    [self readBytes:&value length:sizeof(value)];
    value = objc_ntohd(value);

    // Done
    return value;
}

- (double)readDouble {
    return [self readDoubleWithTag:NO];
}

// ----------------------------------------------------------------------------

- (BOOL)readBoolWithTag:(BOOL)withTag {

    if (withTag) {
        __checkType([self readTag], _C_BOOL);
    }

    Byte value = 0;
    [self readBytes:&value length:sizeof(value)];

    // Done
    return (value != 0);
}

- (BOOL)readBool {
    return [self readBoolWithTag:NO];
}

// ----------------------------------------------------------------------------

@end

// ----------------------------------------------------------------------------
