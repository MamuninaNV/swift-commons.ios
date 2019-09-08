// ----------------------------------------------------------------------------
//
//  OSEncoding.m
//  Based on part of GNU CC.
//
//  @author     Alexander Bragin <bragin-av@roxiemobile.com>
//  @copyright  Copyright (c) 2019, Roxie Mobile Ltd. All rights reserved.
//  @link       http://www.roxiemobile.com/
//
// ----------------------------------------------------------------------------

#import <Foundation/Foundation.h>

#import "objc-runtime.h"

#import "OSEncoding.h"

// ----------------------------------------------------------------------------

#define SIZEOF_NETWORK_FLOAT   4
#define SIZEOF_NETWORK_DOUBLE  8

// ----------------------------------------------------------------------------

#if ((__GNUC__ == 2) && (__GNUC_MINOR__ <= 5) && !defined(__attribute__)) || NeXT_RUNTIME
# define ROUND(V, A) \
    A * ((V + A - 1) / A)
#else
# define ROUND(V, A) \
    ({ typeof(V) __v=(V); typeof(A) __a=(A); __a*((__v+__a-1)/__a); })
#endif

// ----------------------------------------------------------------------------
#pragma mark - Private Functions
// ----------------------------------------------------------------------------

static void __htonf(register unsigned char *out, register const unsigned char *in, size_t count)
{
    // libbu/htonf.c
    // @link http://brlcad.org/xref/source/src/libbu/htonf.c

    assert(sizeof(float) == SIZEOF_NETWORK_FLOAT);

    switch (CFByteOrderGetCurrent()) {

        case CFByteOrderBigEndian: {
            // First, the case where the system already operates in IEEE format
            // internally, using big-endian order. These are the lucky ones.
            memcpy(out, in, count * SIZEOF_NETWORK_FLOAT);
            return;
        }

        case CFByteOrderLittleEndian: {
            // This machine uses IEEE, but in little-endian byte order.
            for (size_t idx = count; idx > 0; idx--) {
                *out++ = in[3];
                *out++ = in[2];
                *out++ = in[1];
                *out++ = in[0];
                in += SIZEOF_NETWORK_FLOAT;
            }
            return;
        }

        default: {
            // Throw the exception.
            [NSException raise:NSGenericException format:@"ERROR, no HtoNF conversion for this machine type."];
        }
    }
}

// ----------------------------------------------------------------------------

static void __ntohf(register unsigned char *out, register const unsigned char *in, size_t count)
{
    // libbu/htonf.c
    // @link http://brlcad.org/xref/source/src/libbu/htonf.c

    assert(sizeof(float) == SIZEOF_NETWORK_FLOAT);

    switch (CFByteOrderGetCurrent()) {

        case CFByteOrderBigEndian: {
            // First, the case where the system already operates in IEEE format internally,
            // using big-endian order. These are the lucky ones.
            memcpy(out, in, count * SIZEOF_NETWORK_FLOAT);
            return;
        }

        case CFByteOrderLittleEndian: {
            // This machine uses IEEE, but in little-endian byte order.
            for (size_t idx = count; idx > 0; idx--) {
                *out++ = in[3];
                *out++ = in[2];
                *out++ = in[1];
                *out++ = in[0];
                in += SIZEOF_NETWORK_FLOAT;
            }
            return;
        }

        default: {
            // Throw the exception.
            [NSException raise:NSGenericException format:@"ERROR, no NtoHF conversion for this machine type."];
        }
    }
}

// ----------------------------------------------------------------------------

static void __htond(register unsigned char *out, register const unsigned char *in, size_t count)
{
    // libbu/htond.c
    // @link http://brlcad.org/xref/source/src/libbu/htond.c

    assert(sizeof(double) == SIZEOF_NETWORK_DOUBLE);

    switch (CFByteOrderGetCurrent()) {

        case CFByteOrderBigEndian: {
            // First, the case where the system already operates in IEEE format internally,
            // using big-endian order. These are the lucky ones.
            memcpy(out, in, count * SIZEOF_NETWORK_DOUBLE);
            return;
        }

        case CFByteOrderLittleEndian: {
            // This machine uses IEEE, but in little-endian byte order.
            for (size_t idx = count; idx > 0; idx--) {
                *out++ = in[7];
                *out++ = in[6];
                *out++ = in[5];
                *out++ = in[4];
                *out++ = in[3];
                *out++ = in[2];
                *out++ = in[1];
                *out++ = in[0];
                in += SIZEOF_NETWORK_DOUBLE;
            }
            return;
        }

        default: {
            // Throw the exception.
            [NSException raise:NSGenericException format:@"ERROR, no HtoND conversion for this machine type."];
        }
    }
}

// ----------------------------------------------------------------------------

static void __ntohd(register unsigned char *out, register const unsigned char *in, size_t count)
{
    // libbu/htond.c
    // @link http://brlcad.org/xref/source/src/libbu/htond.c

    assert(sizeof(double) == SIZEOF_NETWORK_DOUBLE);

    switch (CFByteOrderGetCurrent()) {

        case CFByteOrderBigEndian: {
            // First, the case where the system already operates in IEEE format internally,
            // using big-endian order. These are the lucky ones.
            memcpy(out, in, count * SIZEOF_NETWORK_DOUBLE);
            return;
        }

        case CFByteOrderLittleEndian: {
            // This machine uses IEEE, but in little-endian byte order.
            for (size_t idx = count; idx > 0; idx--) {
                *out++ = in[7];
                *out++ = in[6];
                *out++ = in[5];
                *out++ = in[4];
                *out++ = in[3];
                *out++ = in[2];
                *out++ = in[1];
                *out++ = in[0];
                in += SIZEOF_NETWORK_DOUBLE;
            }
            return;
        }

        default: {
            // Throw the exception.
            [NSException raise:NSGenericException format:@"ERROR, no NtoHD conversion for this machine type."];
        }
    }
}

// ----------------------------------------------------------------------------
#pragma mark - Functions
// ----------------------------------------------------------------------------

/// Returns the size of an object specified by type.

int objc_sizeof_type(const char *type)
{
    switch (*type) {

        case _C_ID: {
            return sizeof(id);
        }

        case _C_CLASS: {
            return sizeof(Class);
        }

        case _C_SEL: {
            return sizeof(SEL);
        }

        case _C_CHR: {
            return sizeof(char);
        }

        case _C_UCHR: {
            return sizeof(unsigned char);
        }

        case _C_SHT: {
            return sizeof(short);
        }

        case _C_USHT: {
            return sizeof(unsigned short);
        }

        case _C_INT: {
            return sizeof(int);
        }

        case _C_UINT: {
            return sizeof(unsigned int);
        }

        case _C_LNG: {
            return sizeof(long);
        }

        case _C_ULNG: {
            return sizeof(unsigned long);
        }

        case _C_LNG_LNG: {
            return sizeof(long long);
        }

        case _C_ULNG_LNG: {
            return sizeof(unsigned long long);
        }

        case _C_FLT: {
            return sizeof(float);
        }

        case _C_DBL: {
            return sizeof(double);
        }

        case _C_PTR:
        case _C_ATOM:
        case _C_CHARPTR: {
            return sizeof(char *);
        }

        case _C_ARY_B: {
            int len = atoi(type + 1);

            while (isdigit(*(++type))) {
                // Do nothing
            }
            return len * objc_aligned_size(type);
        }

        case _C_STRUCT_B: {
            int acc_size = 0;
            int align;

            while (*type != _C_STRUCT_E && *type++ != '=') {
                // Skip "<name>="
            }
            while (*type != _C_STRUCT_E) {
                align = objc_alignof_type(type);     // Padd to alignment
                acc_size = ROUND(acc_size, align);
                acc_size += objc_sizeof_type(type);  // Add component size
                type = objc_skip_typespec(type);     // Skip component
            }
            return acc_size;
        }

        case _C_UNION_B: {
            int max_size = 0;

            while (*type != _C_UNION_E && *type++ != '=') {
                // Do nothing
            }
            while (*type != _C_UNION_E) {
                max_size = MAX(max_size, objc_sizeof_type(type));
                type = objc_skip_typespec(type);
            }
            return max_size;
        }

        default: {
            objc_error(nil, OBJC_ERR_BAD_TYPE, "%s: Unknown type '%s'.\n", __PRETTY_FUNCTION__, type);
        }
    }
    return -1;
}

// ----------------------------------------------------------------------------

/// Returns the alignment of an object specified by type.

int objc_alignof_type(const char *type)
{
    switch (*type) {

        case _C_ID: {
            return __alignof__(id);
        }

        case _C_CLASS: {
            return __alignof__(Class);
        }

        case _C_SEL: {
            return __alignof__(SEL);
        }

        case _C_CHR: {
            return __alignof__(char);
        }

        case _C_UCHR: {
            return __alignof__(unsigned char);
        }

        case _C_SHT: {
            return __alignof__(short);
        }

        case _C_USHT: {
            return __alignof__(unsigned short);
        }

        case _C_INT: {
            return __alignof__(int);
        }

        case _C_UINT: {
            return __alignof__(unsigned int);
        }

        case _C_LNG: {
            return __alignof__(long);
        }

        case _C_ULNG: {
            return __alignof__(unsigned long);
        }

        case _C_LNG_LNG: {
            return __alignof__(long long);
        }

        case _C_ULNG_LNG: {
            return __alignof__(unsigned long long);
        }

        case _C_FLT: {
            return __alignof__(float);
        }

        case _C_DBL: {
            return __alignof__(double);
        }

        case _C_PTR:
        case _C_ATOM:
        case _C_CHARPTR: {
            return __alignof__(char *);
        }

        case _C_ARY_B: {
            while (isdigit(*(++type))) {
                // Do nothing
            }
            return objc_alignof_type(type);
        }

        case _C_STRUCT_B: {
            struct {
                int x;
                double y;
            } foo_align;

            while (*type != _C_STRUCT_E && *type++ != '=') {
                // Do nothing
            }

            if (*type != _C_STRUCT_E) {
                return MAX(objc_alignof_type(type), (int) __alignof__(foo_align));
            }
            else {
                return __alignof__(foo_align);
            }
        }

        case _C_UNION_B: {
            int max_align = 0;

            while (*type != _C_UNION_E && *type++ != '=') {
                // Do nothing
            }
            while (*type != _C_UNION_E) {
                max_align = MAX(objc_alignof_type(type), max_align);
                type = objc_skip_typespec(type);
            }
            return max_align;
        }

        default: {
            objc_error(nil, OBJC_ERR_BAD_TYPE, "%s: Unknown type '%s'.\n", __PRETTY_FUNCTION__, type);
        }
    }
    return -1;
}

// ----------------------------------------------------------------------------

/// The aligned size if the size rounded up to the nearest alignment.

int objc_aligned_size(const char *type)
{
    int size = objc_sizeof_type(type);
    int align = objc_alignof_type(type);

    return ROUND(size, align);
}

// ----------------------------------------------------------------------------
#pragma mark -
// ----------------------------------------------------------------------------

/// Skip type qualifiers. These may eventually precede typespecs occurring
/// in method prototype encodings.

inline const char *objc_skip_type_qualifiers(const char *type)
{
    // @formatter:off
    while (*type == _C_CONST
        || *type == _C_IN
        || *type == _C_INOUT
        || *type == _C_OUT
        || *type == _C_BYCOPY
        || *type == _C_ONEWAY)
    {
        type += 1;
    }
    return type;
    // @formatter:on
}

// ----------------------------------------------------------------------------

/// Skip one typespec element.  If the typespec is prepended by type
/// qualifiers, these are skipped as well.

const char *objc_skip_typespec(const char *type)
{
    type = objc_skip_type_qualifiers(type);
    switch (*type) {

        case _C_ID: {
            // An id may be annotated by the actual type if it is known with the @"ClassName" syntax

            if (*(++type) != '"') {
                return type;
            }
            else {

                while (*(++type) != '"') {
                    // Do nothing
                }
                return type + 1;
            }
        }

        case _C_CLASS:
        case _C_SEL:
        case _C_CHR:
        case _C_UCHR:
        case _C_CHARPTR:
        case _C_ATOM:
        case _C_SHT:
        case _C_USHT:
        case _C_INT:
        case _C_UINT:
        case _C_LNG:
        case _C_ULNG:
        case _C_LNG_LNG:
        case _C_ULNG_LNG:
        case _C_FLT:
        case _C_DBL:
        case _C_VOID:
        case _C_UNDEF: {
            // The following are one character type codes

            return ++type;
        }

        case _C_ARY_B: {
            // Skip digits, typespec and closing ']'

            while (isdigit(*(++type))) {
                // Do nothing
            }

            type = objc_skip_typespec(type);
            if (*type == _C_ARY_E) {
                return ++type;
            }
            else {
                objc_error(nil, OBJC_ERR_BAD_TYPE, "Bad array type '%s'.\n", type);
            }
        }

        case _C_STRUCT_B: {
            // Skip name, and elements until closing '}'

            while (*type != _C_STRUCT_E && *type++ != '=') {
                // Do nothing
            }
            while (*type != _C_STRUCT_E) {
                type = objc_skip_typespec(type);
            }
            return ++type;
        }

        case _C_UNION_B: {
            // Skip name, and elements until closing ')'

            while (*type != _C_UNION_E && *type++ != '=') {
                // Do nothing
            }
            while (*type != _C_UNION_E) {
                type = objc_skip_typespec(type);
            }
            return ++type;
        }

        case _C_PTR: {
            // Just skip the following typespec

            return objc_skip_typespec(++type);
        }

        default: {
            objc_error(nil, OBJC_ERR_BAD_TYPE, "%s: Unknown type '%s'.\n", __PRETTY_FUNCTION__, type);
        }
    }
    return NULL;
}

// ----------------------------------------------------------------------------
#pragma mark -
// ----------------------------------------------------------------------------

float objc_ntohf(float value)
{
    float result = 0;
    __ntohf((Byte *) &result, (const Byte *) &value, 1);
    return value;
}

// ----------------------------------------------------------------------------

float objc_htonf(float value)
{
    float result = 0;
    __htonf((Byte *) &result, (const Byte *) &value, 1);
    return result;
}

// ----------------------------------------------------------------------------

double objc_ntohd(double value)
{
    double result = 0;
    __ntohd((Byte *) &result, (const Byte *) &value, 1);
    return result;
}

// ----------------------------------------------------------------------------

double objc_htond(double value)
{
    double result = 0;
    __htond((Byte *) &result, (const Byte *) &value, 1);
    return result;
}

// ----------------------------------------------------------------------------
#pragma mark -
// ----------------------------------------------------------------------------

size_t roxie_strlen(const char *str)
{
    return str ? strlen(str) : 0;
}

// ----------------------------------------------------------------------------

int roxie_strcmp(const char *str1, const char *str2)
{
    if (!str1) {
        if (!str2) {
            return 0;
        }
        else {
            return -1;
        }
    }
    else {
        if (!str2) {
            return 1;
        }
        else {
            return strcmp(str1, str2);
        }
    }
}

// ----------------------------------------------------------------------------

int roxie_atoi(const char *str)
{
    return str ? atoi(str) : 0;
}

// ----------------------------------------------------------------------------
