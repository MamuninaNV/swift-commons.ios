// ----------------------------------------------------------------------------
//
//  OSUnarchiver+Decoding.h
//
//  @author     Alexander Bragin <bragin-av@roxiemobile.com>
//  @copyright  Copyright (c) 2019, Roxie Mobile Ltd. All rights reserved.
//  @link       http://www.roxiemobile.com/
//
// ----------------------------------------------------------------------------

#import "OSUnarchiver.h"
#import "OSBasicTypes.h"

// ----------------------------------------------------------------------------

@interface OSUnarchiver (Decoding)

// - Methods

- (void)readBytes:(void *)bytes length:(NSUInteger)length;

- (NSString *)readStringWithTag:(BOOL)withTag;
- (OSTagType)readTag;

- (long long)readLongLongWithTag:(BOOL)withTag;
- (long long)readLongLong;

- (unsigned long long)readUnsignedLongLongWithTag:(BOOL)withTag;
- (unsigned long long)readUnsignedLongLong;

- (long)readLongWithTag:(BOOL)withTag;
- (long)readLong;

- (unsigned long)readUnsignedLongWithTag:(BOOL)withTag;
- (unsigned long)readUnsignedLong;

- (int)readIntWithTag:(BOOL)withTag;
- (int)readInt;

- (unsigned int)readUnsignedIntWithTag:(BOOL)withTag;
- (unsigned int)readUnsignedInt;

- (short)readShortWithTag:(BOOL)withTag;
- (short)readShort;

- (unsigned short)readUnsignedShortWithTag:(BOOL)withTag;
- (unsigned short)readUnsignedShort;

- (char)readCharWithTag:(BOOL)withTag;
- (char)readChar;

- (unsigned char)readUnsignedCharWithTag:(BOOL)withTag;
- (unsigned char)readUnsignedChar;

- (NSUInteger)readUnsignedInteger;
- (NSInteger)readInteger;

- (float)readFloatWithTag:(BOOL)withTag;
- (float)readFloat;

- (double)readDoubleWithTag:(BOOL)withTag;
- (double)readDouble;

- (BOOL)readBoolWithTag:(BOOL)withTag;
- (BOOL)readBool;

// --

@end

// ----------------------------------------------------------------------------
