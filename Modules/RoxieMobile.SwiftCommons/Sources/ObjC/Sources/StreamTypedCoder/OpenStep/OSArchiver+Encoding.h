// ----------------------------------------------------------------------------
//
//  OSArchiver+Encoding.h
//
//  @author     Alexander Bragin <bragin-av@roxiemobile.com>
//  @copyright  Copyright (c) 2019, Roxie Mobile Ltd. All rights reserved.
//  @link       http://www.roxiemobile.com/
//
// ----------------------------------------------------------------------------

#import "OSArchiver.h"
#import "OSBasicTypes.h"

// ----------------------------------------------------------------------------

@interface OSArchiver (Encoding)

// - Methods

- (void)writeBytes:(const void *)bytes length:(NSUInteger)length;

- (void)writeString:(NSString *)value withTag:(BOOL)withTag;
- (void)writeTag:(OSTagType)tag;

- (void)writeLongLong:(long long)value withTag:(BOOL)withTag;
- (void)writeLongLong:(long long)value;

- (void)writeUnsignedLongLong:(unsigned long long)value withTag:(BOOL)withTag;
- (void)writeUnsignedLongLong:(unsigned long long)value;

- (void)writeLong:(long)value withTag:(BOOL)withTag;
- (void)writeLong:(long)value;

- (void)writeUnsignedLong:(unsigned long)value withTag:(BOOL)withTag;
- (void)writeUnsignedLong:(unsigned long)value;

- (void)writeInt:(int)value withTag:(BOOL)withTag;
- (void)writeInt:(int)value;

- (void)writeUnsignedInt:(unsigned int)value withTag:(BOOL)withTag;
- (void)writeUnsignedInt:(unsigned int)value;

- (void)writeShort:(short)value withTag:(BOOL)withTag;
- (void)writeShort:(short)value;

- (void)writeUnsignedShort:(unsigned short)value withTag:(BOOL)withTag;
- (void)writeUnsignedShort:(unsigned short)value;

- (void)writeChar:(char)value withTag:(BOOL)withTag;
- (void)writeChar:(char)value;

- (void)writeUnsignedChar:(unsigned char)value withTag:(BOOL)withTag;
- (void)writeUnsignedChar:(unsigned char)value;

- (void)writeUnsignedInteger:(NSUInteger)value;
- (void)writeInteger:(NSInteger)value;

- (void)writeFloat:(float)value withTag:(BOOL)withTag;
- (void)writeFloat:(float)value;

- (void)writeDouble:(double)value withTag:(BOOL)withTag;
- (void)writeDouble:(double)value;

- (void)writeBool:(BOOL)value withTag:(BOOL)withTag;
- (void)writeBool:(BOOL)value;

// --

@end

// ----------------------------------------------------------------------------