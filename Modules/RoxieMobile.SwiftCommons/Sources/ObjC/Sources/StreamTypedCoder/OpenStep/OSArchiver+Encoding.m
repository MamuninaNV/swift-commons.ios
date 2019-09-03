// ----------------------------------------------------------------------------
//
//  OSArchiver+Encoding.m
//
//  @author     Alexander Bragin <bragin-av@roxiemobile.com>
//  @copyright  Copyright (c) 2019, Roxie Mobile Ltd. All rights reserved.
//  @link       http://www.roxiemobile.com/
//
// ----------------------------------------------------------------------------

#import "objc-runtime.h"
#import "OSEncoding.h"
#import "OSArchiver+Encoding.h"

// ----------------------------------------------------------------------------

@interface OSArchiver ()

// - Properties

@property(nonatomic, assign) BOOL traceMode;  // YES if finding conditionals

// --

@end

// ----------------------------------------------------------------------------

@implementation OSArchiver (Encoding)

// ----------------------------------------------------------------------------
#pragma mark - Methods
// ----------------------------------------------------------------------------

- (void)writeBytes:(const void *)bytes length:(NSUInteger)length {
    NSAssert(self.traceMode == NO, @"Nothing can be written during trace-mode.");

    if ((length > 0) && (bytes != nil)) {
        [self.archiverData appendBytes:bytes length:length];
    }
}

// ----------------------------------------------------------------------------

- (void)writeTag:(OSTagType)tag {
    [self writeBytes:&tag length:sizeof(tag)];
}

// ----------------------------------------------------------------------------

- (void)writeString:(NSString *)value withTag:(BOOL)withTag {

    NSData *rawData = [value dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
    NSUInteger length = rawData.length;

    if (withTag) {
        [self writeTag:(OSTagType) (length >= USHRT_MAX ? _C_CHARPTR : _C_ATOM)];
    }

    [self encodeBytes:rawData.bytes length:length];
}

// ----------------------------------------------------------------------------

- (void)writeLongLong:(long long)value withTag:(BOOL)withTag {

    if (withTag) {
        [self writeTag:_C_LNG_LNG];
    }

    value = htonll(value);
    [self writeBytes:&value length:sizeof(value)];
}

- (void)writeLongLong:(long long)value {
    [self writeLongLong:value withTag:NO];
}

// ----------------------------------------------------------------------------

- (void)writeUnsignedLongLong:(unsigned long long)value withTag:(BOOL)withTag {

    if (withTag) {
        [self writeTag:_C_ULNG_LNG];
    }

    value = htonll(value);
    [self writeBytes:&value length:sizeof(value)];
}

- (void)writeUnsignedLongLong:(unsigned long long)value {
    [self writeUnsignedLongLong:value withTag:NO];
}

// ----------------------------------------------------------------------------

- (void)writeLong:(long)value withTag:(BOOL)withTag {

    if (withTag) {
        [self writeTag:_C_LNG];
    }

    value = (long) htonl(value);
    [self writeBytes:&value length:sizeof(value)];
}

- (void)writeLong:(long)value {
    [self writeLong:value withTag:NO];
}

// ----------------------------------------------------------------------------

- (void)writeUnsignedLong:(unsigned long)value withTag:(BOOL)withTag {

    if (withTag) {
        [self writeTag:_C_ULNG];
    }

    value = htonl(value);
    [self writeBytes:&value length:sizeof(value)];
}

- (void)writeUnsignedLong:(unsigned long)value {
    [self writeUnsignedLong:value withTag:NO];
}

// ----------------------------------------------------------------------------

- (void)writeInt:(int)value withTag:(BOOL)withTag {

    if (withTag) {
        [self writeTag:_C_INT];
    }

    value = htonl(value);
    [self writeBytes:&value length:sizeof(value)];
}

- (void)writeInt:(int)value {
    [self writeInt:value withTag:NO];
}

// ----------------------------------------------------------------------------

- (void)writeUnsignedInt:(unsigned int)value withTag:(BOOL)withTag {

    if (withTag) {
        [self writeTag:_C_UINT];
    }

    value = htonl(value);
    [self writeBytes:&value length:sizeof(value)];
}

- (void)writeUnsignedInt:(unsigned int)value {
    [self writeUnsignedInt:value withTag:NO];
}

// ----------------------------------------------------------------------------

- (void)writeShort:(short)value withTag:(BOOL)withTag {

    if (withTag) {
        [self writeTag:_C_SHT];
    }

    value = htons(value);
    [self writeBytes:&value length:sizeof(value)];
}

- (void)writeShort:(short)value {
    [self writeShort:value withTag:NO];
}

// ----------------------------------------------------------------------------

- (void)writeUnsignedShort:(unsigned short)value withTag:(BOOL)withTag {

    if (withTag) {
        [self writeTag:_C_USHT];
    }

    value = htons(value);
    [self writeBytes:&value length:sizeof(value)];
}

- (void)writeUnsignedShort:(unsigned short)value {
    [self writeUnsignedShort:value withTag:NO];
}

// ----------------------------------------------------------------------------

- (void)writeChar:(char)value withTag:(BOOL)withTag {

    if (withTag) {
        [self writeTag:_C_CHR];
    }

    [self writeBytes:&value length:sizeof(value)];
}

- (void)writeChar:(char)value {
    [self writeChar:value withTag:NO];
}

// ----------------------------------------------------------------------------

- (void)writeUnsignedChar:(unsigned char)value withTag:(BOOL)withTag {

    if (withTag) {
        [self writeTag:_C_UCHR];
    }

    [self writeBytes:&value length:sizeof(value)];
}

- (void)writeUnsignedChar:(unsigned char)value {
    [self writeUnsignedChar:value withTag:NO];
}

// ----------------------------------------------------------------------------

- (void)writeInteger:(NSInteger)value {

    if (value <= INT_MIN || value >= INT_MAX) {
        [self writeLong:(long) value withTag:YES];
    }
    else if (value <= SHRT_MIN || value >= SHRT_MAX) {
        [self writeInt:(int) value withTag:YES];
    }
    else if (value <= CHAR_MIN || value >= CHAR_MAX) {
        [self writeShort:(short) value withTag:YES];
    }
    else {
        [self writeChar:(char) value withTag:YES];
    }
}

// ----------------------------------------------------------------------------

- (void)writeUnsignedInteger:(NSUInteger)value {

    if (value >= UINT_MAX) {
        [self writeUnsignedLong:(unsigned long) value withTag:YES];
    }
    else if (value >= USHRT_MAX) {
        [self writeUnsignedInt:(unsigned int) value withTag:YES];
    }
    else if (value >= UCHAR_MAX) {
        [self writeUnsignedShort:(unsigned short) value withTag:YES];
    }
    else {
        [self writeUnsignedChar:(unsigned char) value withTag:YES];
    }
}

// ----------------------------------------------------------------------------

- (void)writeFloat:(float)value withTag:(BOOL)withTag {

    if (withTag) {
        [self writeTag:_C_FLT];
    }

    value = objc_htonf(value);
    [self writeBytes:&value length:sizeof(value)];
}

- (void)writeFloat:(float)value {
    return [self writeFloat:value withTag:NO];
}

// ----------------------------------------------------------------------------

- (void)writeDouble:(double)value withTag:(BOOL)withTag {

    if (withTag) {
        [self writeTag:_C_DBL];
    }

    value = objc_htond(value);
    [self writeBytes:&value length:sizeof(value)];
}

- (void)writeDouble:(double)value {
    return [self writeDouble:value withTag:NO];
}

// ----------------------------------------------------------------------------

- (void)writeBool:(BOOL)value withTag:(BOOL)withTag {

    if (withTag) {
        [self writeTag:_C_BOOL];
    }

    UInt8 ni = (value ? TRUE : FALSE);
    [self writeBytes:&ni length:sizeof(ni)];
}

- (void)writeBool:(BOOL)value {
    [self writeBool:value withTag:NO];
}

// ----------------------------------------------------------------------------

@end

// ----------------------------------------------------------------------------
