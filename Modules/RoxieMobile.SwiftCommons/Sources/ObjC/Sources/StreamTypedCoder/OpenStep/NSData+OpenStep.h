// ----------------------------------------------------------------------------
//
//  NSData+OpenStep.h
//
//  @author     Alexander Bragin <bragin-av@roxiemobile.com>
//  @copyright  Copyright (c) 2019, Roxie Mobile Ltd. All rights reserved.
//  @link       http://www.roxiemobile.com/
//
// ----------------------------------------------------------------------------

#import "OSObjCTypeSerializationCallback.h"

// ----------------------------------------------------------------------------

@interface NSData (OpenStep)

// - Methods

- (void)deserializeBytes:(void *)buffer
                  length:(unsigned int)bytes
                atCursor:(unsigned int *)cursor;

- (void)deserializeDataAt:(void *)data
               ofObjCType:(const char *)type
                 atCursor:(unsigned int *)cursor
                  context:(id <OSObjCTypeSerializationCallback>)callback;

- (unsigned int)deserializeIntAtCursor:(unsigned int *)cursor;

// --

@end

// ----------------------------------------------------------------------------

@interface NSMutableData (OpenStep)

// - Methods

- (void)serializeDataAt:(const void *)data
             ofObjCType:(const char *)type
                context:(id <OSObjCTypeSerializationCallback>)callback;

- (void)serializeInt:(int)value;

// --

@end

// ----------------------------------------------------------------------------
