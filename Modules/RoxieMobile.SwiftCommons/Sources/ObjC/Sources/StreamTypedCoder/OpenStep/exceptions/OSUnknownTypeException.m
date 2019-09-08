// ----------------------------------------------------------------------------
//
//  OSUnknownTypeException.m
//  Based on part of libFoundation.
//
//  @author     Alexander Bragin <bragin-av@roxiemobile.com>
//  @copyright  Copyright (c) 2019, Roxie Mobile Ltd. All rights reserved.
//  @link       http://www.roxiemobile.com/
//
// ----------------------------------------------------------------------------

#import "OSUnknownTypeException.h"
#import "OSMemory.h"

// ----------------------------------------------------------------------------

@implementation OSUnknownTypeException

// ----------------------------------------------------------------------------
#pragma mark - Methods
// ----------------------------------------------------------------------------

+ (instancetype)exceptionForType:(const char *)itemType
{
    NSString *type = [NSString stringWithCString:itemType encoding:NSUTF8StringEncoding];
    NSString *message = [NSString stringWithFormat:@"Unknown Objective-C type encoding '%s'.", itemType];

    // Create exception
    OSUnknownTypeException *object = [[OSUnknownTypeException alloc]
            initWithName:NSInvalidArgumentException reason:message userInfo:@{@"type": type}];

    // Done
    return AUTORELEASE(object);
}

// ----------------------------------------------------------------------------

+ (void)raiseForType:(const char *)itemType
{
    [[self exceptionForType:itemType] raise];
}

// ----------------------------------------------------------------------------

@end

// ----------------------------------------------------------------------------
