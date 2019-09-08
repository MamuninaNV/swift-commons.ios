// ----------------------------------------------------------------------------
//
//  OSUnknownTypeException.h
//  Based on part of libFoundation.
//
//  @author     Alexander Bragin <bragin-av@roxiemobile.com>
//  @copyright  Copyright (c) 2019, Roxie Mobile Ltd. All rights reserved.
//  @link       http://www.roxiemobile.com/
//
// ----------------------------------------------------------------------------

#include <Foundation/NSException.h>

// ----------------------------------------------------------------------------

@interface OSUnknownTypeException : NSException

// - Methods

+ (instancetype)exceptionForType:(const char *)itemType;

+ (void)raiseForType:(const char *)itemType;

// --

@end

// ----------------------------------------------------------------------------
