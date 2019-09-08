// ----------------------------------------------------------------------------
//
//  OSEncoding.h
//  Based on part of GNU CC.
//
//  @author     Alexander Bragin <bragin-av@roxiemobile.com>
//  @copyright  Copyright (c) 2019, Roxie Mobile Ltd. All rights reserved.
//  @link       http://www.roxiemobile.com/
//
// ----------------------------------------------------------------------------

#import <Foundation/Foundation.h>

// ----------------------------------------------------------------------------

#define _C_CONST    'r'
#define _C_IN       'n'
#define _C_INOUT    'N'
#define _C_OUT      'o'
#define _C_BYCOPY   'O'
#define _C_ONEWAY   'V'

// ----------------------------------------------------------------------------

FOUNDATION_EXPORT int objc_sizeof_type(const char *type);
FOUNDATION_EXPORT int objc_alignof_type(const char *type);
FOUNDATION_EXPORT int objc_aligned_size(const char *type);

// ----------------------------------------------------------------------------

FOUNDATION_EXPORT const char *objc_skip_type_qualifiers(const char *type);
FOUNDATION_EXPORT const char *objc_skip_typespec(const char *type);

// ----------------------------------------------------------------------------

FOUNDATION_EXPORT float objc_ntohf(float value);
FOUNDATION_EXPORT float objc_htonf(float value);

FOUNDATION_EXPORT double objc_ntohd(double value);
FOUNDATION_EXPORT double objc_htond(double value);

// ----------------------------------------------------------------------------

FOUNDATION_EXPORT size_t roxie_strlen(const char *str);
FOUNDATION_EXPORT int roxie_strcmp(const char *str1, const char *str2);

FOUNDATION_EXPORT int roxie_atoi(const char *str);

// ----------------------------------------------------------------------------
