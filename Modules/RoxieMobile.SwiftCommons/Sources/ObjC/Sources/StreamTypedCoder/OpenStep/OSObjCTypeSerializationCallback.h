// ----------------------------------------------------------------------------
//
//  OSObjCTypeSerializationCallback.h
//
//  @author     Alexander Bragin <bragin-av@roxiemobile.com>
//  @copyright  Copyright (c) 2019, Roxie Mobile Ltd. All rights reserved.
//  @link       http://www.roxiemobile.com/
//
// ----------------------------------------------------------------------------

#import <Foundation/Foundation.h>

// ----------------------------------------------------------------------------

@protocol OSObjCTypeSerializationCallback

// - Methods

- (void)serializeObjectAt:(id *)object
               ofObjCType:(const char *)itemType
                 intoData:(NSMutableData *)data;

- (void)deserializeObjectAt:(id *)object
                 ofObjCType:(const char *)itemType
                   fromData:(NSData *)data
                   atCursor:(unsigned int *)cursor;

// --

@end

// ----------------------------------------------------------------------------
