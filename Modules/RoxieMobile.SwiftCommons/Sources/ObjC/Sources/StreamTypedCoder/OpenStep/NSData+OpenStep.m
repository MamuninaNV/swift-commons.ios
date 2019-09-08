// ----------------------------------------------------------------------------
//
//  NSData+OpenStep.m
//
//  @author     Alexander Bragin <bragin-av@roxiemobile.com>
//  @copyright  Copyright (c) 2019, Roxie Mobile Ltd. All rights reserved.
//  @link       http://www.roxiemobile.com/
//
// ----------------------------------------------------------------------------

#import "objc-runtime.h"
#import "byte_order.h"
#import "common.h"
#import "GeneralExceptions.h"
#import "NSData+OpenStep.h"
#import "OSEncoding.h"

// ----------------------------------------------------------------------------

@implementation NSData (OpenStep)

// ----------------------------------------------------------------------------

- (void)deserializeBytes:(void *)buffer
                  length:(unsigned int)bytes
                atCursor:(unsigned int *)cursor
{
    NSRange range = {*cursor, bytes};
    [self getBytes:buffer range:range];
    *cursor += bytes;
}

// ----------------------------------------------------------------------------

- (void)deserializeDataAt:(void *)data
               ofObjCType:(const char *)type
                 atCursor:(unsigned int *)cursor
                  context:(id <OSObjCTypeSerializationCallback>)callback
{
    if (data == nil || type == nil) {
        return;
    }

    switch (*type) {

        case _C_ID: {
            [callback deserializeObjectAt:data ofObjCType:type fromData:self atCursor:cursor];
            break;
        }

        case _C_CHARPTR: {
            volatile unsigned int len = [self deserializeIntAtCursor:cursor];

            // This statement, by taking the address of `type', forces the compiler
            // to not allocate `type' into a register.
            *(void **) data = &type;

            if (len == -1) {
                *(const char **) data = NULL;
                return;
            }

            *(char **) data = MallocAtomic(len + 1);
            (*(char **) data)[len] = 0;

            @try {
                [self deserializeBytes:*(char **) data length:len atCursor:cursor];
            }
            @catch (NSException *exception) {
                lfFree(*(char **) data);
                [exception raise];
            }

            break;
        }

        case _C_ARY_B: {
            int count, itemSize;
            const char *itemType;

            count = Atoi(type + 1);
            itemType = type;
            while (isdigit(*++itemType));
            itemSize = objc_sizeof_type(itemType);

            for (int idx = 0, offset = 0; idx < count; idx++, offset += itemSize) {
                [self deserializeDataAt:((char *) data) + offset ofObjCType:itemType atCursor:cursor context:callback];
            }
            break;
        }

        case _C_STRUCT_B: {
            int offset = 0;
            int align, rem;

            while (*type != _C_STRUCT_E && *type++ != '='); // Skip "<name>="

            while (TRUE) {
                [self deserializeDataAt:((char *) data) + offset ofObjCType:type atCursor:cursor context:callback];

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
            *(char **) data = Malloc(objc_sizeof_type(++type));

            @try {
                [self deserializeDataAt:*(char **) data ofObjCType:type atCursor:cursor context:callback];
            }
            @catch (NSException *exception) {
                lfFree(*(char **) data);
                [exception raise];
            }

            break;
        }

        case _C_CHR:
        case _C_UCHR: {
            [self deserializeBytes:data length:sizeof(unsigned char) atCursor:cursor];
            break;
        }

        case _C_SHT:
        case _C_USHT: {
            [self deserializeBytes:data length:sizeof(unsigned short) atCursor:cursor];
            break;
        }

        case _C_INT:
        case _C_UINT: {
            [self deserializeBytes:data length:sizeof(unsigned int) atCursor:cursor];
            break;
        }

        case _C_LNG:
        case _C_ULNG: {
            [self deserializeBytes:data length:sizeof(unsigned long) atCursor:cursor];
            break;
        }

        case _C_LNG_LNG:
        case _C_ULNG_LNG: {
            [self deserializeBytes:data length:sizeof(unsigned long long) atCursor:cursor];
            break;
        }

        case _C_FLT: {
            [self deserializeBytes:data length:sizeof(float) atCursor:cursor];
            break;
        }

        case _C_DBL: {
            [self deserializeBytes:data length:sizeof(double) atCursor:cursor];
            break;
        }

        default: {
            [[[UnknownTypeException alloc] initForType:type] raise];
        }
    }
}

// ----------------------------------------------------------------------------

- (unsigned int)deserializeIntAtCursor:(unsigned int *)cursor
{
    unsigned int ni, value;

    [self deserializeBytes:&ni length:sizeof(unsigned int) atCursor:cursor];
    value = network_int_to_host(ni);

    // Done
    return value;
}

// ----------------------------------------------------------------------------

@end

// ----------------------------------------------------------------------------
