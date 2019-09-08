// ----------------------------------------------------------------------------
//
//  NSMutableData+OpenStep.h
//
//  @author     Alexander Bragin <bragin-av@roxiemobile.com>
//  @copyright  Copyright (c) 2019, Roxie Mobile Ltd. All rights reserved.
//  @link       http://www.roxiemobile.com/
//
// ----------------------------------------------------------------------------

#import "OSObjCTypeSerializationCallback.h"

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
