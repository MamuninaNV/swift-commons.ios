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

#import "OSEncoding.h"

// ----------------------------------------------------------------------------

#define SIZEOF_NETWORK_FLOAT   4
#define SIZEOF_NETWORK_DOUBLE  8

// ----------------------------------------------------------------------------
#pragma mark - Private Functions
// ----------------------------------------------------------------------------

static void __htonf(register unsigned char *out, register const unsigned char *in, size_t count) {

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

static void __ntohf(register unsigned char *out, register const unsigned char *in, size_t count) {

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

static void __htond(register unsigned char *out, register const unsigned char *in, size_t count) {

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

static void __ntohd(register unsigned char *out, register const unsigned char *in, size_t count) {

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

float objc_ntohf(float value) {
    float result = 0;
    __ntohf((Byte *) &result, (const Byte *) &value, 1);
    return value;
}

// ----------------------------------------------------------------------------

float objc_htonf(float value) {
    float result = 0;
    __htonf((Byte *) &result, (const Byte *) &value, 1);
    return result;
}

// ----------------------------------------------------------------------------

double objc_ntohd(double value) {
    double result = 0;
    __ntohd((Byte *) &result, (const Byte *) &value, 1);
    return result;
}

// ----------------------------------------------------------------------------

double objc_htond(double value) {
    double result = 0;
    __htond((Byte *) &result, (const Byte *) &value, 1);
    return result;
}

// ----------------------------------------------------------------------------
