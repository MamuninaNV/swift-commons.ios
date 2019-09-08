// ----------------------------------------------------------------------------
//
//  NSMutableData+OpenStep.m
//
//  @author     Alexander Bragin <bragin-av@roxiemobile.com>
//  @copyright  Copyright (c) 2019, Roxie Mobile Ltd. All rights reserved.
//  @link       http://www.roxiemobile.com/
//
// ----------------------------------------------------------------------------

// #include <Foundation/common.h>
// #include <Foundation/NSData.h>
// #include <Foundation/NSString.h>
// #include <Foundation/NSPosixFileDescriptor.h>
// #include <Foundation/NSCoder.h>
// #include <Foundation/NSURL.h>
// #include <Foundation/NSException.h>
// #include <Foundation/NSAutoreleasePool.h>
// #include <Foundation/exceptions/GeneralExceptions.h>
// 
// #include <extensions/objc-runtime.h>
// 
// #include "byte_order.h"
// #include "NSConcreteData.h"
// #include <Foundation/NSUtilities.h>

#import "objc-runtime.h"
#import "common.h"
#import "GeneralExceptions.h"
#import "NSMutableData+OpenStep.h"
#import "OSEncoding.h"

// ----------------------------------------------------------------------------

@implementation NSMutableData (OpenStep)

// ----------------------------------------------------------------------------

- (void)serializeDataAt:(const void *)data
             ofObjCType:(const char *)type
                context:(id <OSObjCTypeSerializationCallback>)callback
{
    if (data == nil || type == nil) {
        return;
    }

    switch (*type) {

        case _C_ID: {
            [callback serializeObjectAt:(id *) data ofObjCType:type intoData:self];
            break;
        }

        case _C_CHARPTR: {
            NSUInteger len;

            if (!*(void **) data) {
                [self serializeInt:-1];
                return;
            }

            len = Strlen(*(void **) data);
            [self serializeInt:len];
            [self appendBytes:*(void **) data length:len];

            break;
        }

        case _C_ARY_B: {
            int itemSize, count = Atoi(type + 1);
            const char *itemType = type;

            while (isdigit(*++itemType));
            itemSize = objc_sizeof_type(itemType);

            for (int idx = 0, offset = 0; idx < count; idx++, offset += itemSize) {
                [self serializeDataAt:((char *) data) + offset ofObjCType:itemType context:callback];
            }
            break;
        }

        case _C_STRUCT_B: {
            int offset = 0;
            int align, rem;

            while (*type != _C_STRUCT_E && *type++ != '='); // Skip "<name>="

            while (TRUE) {
                [self serializeDataAt:((char *) data) + offset ofObjCType:type context:callback];

                offset += objc_sizeof_type(type);
                type = objc_skip_typespec(type);

                if (*type != _C_STRUCT_E) {
                    align = objc_alignof_type(type);

                    if ((rem = offset % align)) {
                        offset += align - rem;
                    }
                }
                else {
                    break;
                }
            }
            break;
        }

        case _C_PTR: {
            [self serializeDataAt:*(char **) data ofObjCType:++type context:callback];
            break;
        }

        case _C_CHR:
        case _C_UCHR: {
            [self appendBytes:data length:sizeof(unsigned char)];
            break;
        }

        case _C_SHT:
        case _C_USHT: {
            [self appendBytes:data length:sizeof(unsigned short)];
            break;
        }

        case _C_INT:
        case _C_UINT: {
            [self appendBytes:data length:sizeof(unsigned int)];
            break;
        }

        case _C_LNG:
        case _C_ULNG: {
            [self appendBytes:data length:sizeof(unsigned long)];
            break;
        }

        case _C_LNG_LNG:
        case _C_ULNG_LNG: {
            [self appendBytes:data length:sizeof(unsigned long long)];
            break;
        }

        case _C_FLT: {
            [self appendBytes:data length:sizeof(float)];
            break;
        }

        case _C_DBL: {
            [self appendBytes:data length:sizeof(double)];
            break;
        }

        default: {
            [[[UnknownTypeException alloc] initForType:type] raise];
        }
    }
}

// ----------------------------------------------------------------------------

- (void)serializeInt:(int)value
{
    unsigned int ni = htonl((unsigned int) value);
    [self appendBytes:&ni length:sizeof(unsigned int)];
}

// ----------------------------------------------------------------------------

@end

// ----------------------------------------------------------------------------
