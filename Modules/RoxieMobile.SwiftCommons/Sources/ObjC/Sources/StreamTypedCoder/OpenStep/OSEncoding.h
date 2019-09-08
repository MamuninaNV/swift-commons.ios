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

int objc_sizeof_type(const char *type);
int objc_alignof_type(const char *type);
int objc_aligned_size(const char *type);

// ----------------------------------------------------------------------------

const char *objc_skip_type_qualifiers(const char *type);
const char *objc_skip_typespec(const char *type);

// ----------------------------------------------------------------------------

float objc_ntohf(float value);
float objc_htonf(float value);

double objc_ntohd(double value);
double objc_htond(double value);

// ----------------------------------------------------------------------------

size_t roxie_strlen(const char *str);
int roxie_strcmp(const char *str1, const char *str2);

// ----------------------------------------------------------------------------

int roxie_atoi(const char *str);

// ----------------------------------------------------------------------------
