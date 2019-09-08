// ----------------------------------------------------------------------------
//
//  OSMemory.h
//  Based on part of GNU CC.
//
//  @author     Alexander Bragin <bragin-av@roxiemobile.com>
//  @copyright  Copyright (c) 2019, Roxie Mobile Ltd. All rights reserved.
//  @link       http://www.roxiemobile.com/
//
// ----------------------------------------------------------------------------

#import "objc-runtime.h"

#import "OSMemory.h"

// ----------------------------------------------------------------------------

/*
** Hook functions for memory allocation and disposal.
** This makes it easy to substitute garbage collection systems
** such as Boehm's GC by assigning these function pointers
** to the GC's allocation routines.  By default these point
** to the ANSI standard malloc, realloc, free, etc.
**
** Users should call the normal objc routines above for
** memory allocation and disposal within their programs.
*/

void *(*_objc_malloc)(size_t) = malloc;
void *(*_objc_atomic_malloc)(size_t) = malloc;
void *(*_objc_valloc)(size_t) = malloc;
void *(*_objc_realloc)(void *, size_t) = realloc;
void *(*_objc_calloc)(size_t, size_t) = calloc;
void (*_objc_free)(void *) = free;

// ----------------------------------------------------------------------------
#pragma mark - Functions
// ----------------------------------------------------------------------------

void *objc_malloc(size_t size)
{
    void *res = (*_objc_malloc)(size);
    if (!res) {
        objc_error(nil, OBJC_ERR_MEMORY, "Virtual memory exhausted.\n");
    }
    return res;
}

// ----------------------------------------------------------------------------

void *objc_atomic_malloc(size_t size)
{
    void *res = (*_objc_atomic_malloc)(size);
    if (!res) {
        objc_error(nil, OBJC_ERR_MEMORY, "Virtual memory exhausted.\n");
    }
    return res;
}

// ----------------------------------------------------------------------------

void *objc_valloc(size_t size)
{
    void *res = (*_objc_valloc)(size);
    if (!res) {
        objc_error(nil, OBJC_ERR_MEMORY, "Virtual memory exhausted.\n");
    }
    return res;
}

// ----------------------------------------------------------------------------

void *objc_realloc(void *mem, size_t size)
{
    void *res = (*_objc_realloc)(mem, size);
    if (!res) {
        objc_error(nil, OBJC_ERR_MEMORY, "Virtual memory exhausted.\n");
    }
    return res;
}

// ----------------------------------------------------------------------------

void *objc_calloc(size_t nelem, size_t size)
{
    void *res = (*_objc_calloc)(nelem, size);
    if (!res) {
        objc_error(nil, OBJC_ERR_MEMORY, "Virtual memory exhausted.\n");
    }
    return res;
}

// ----------------------------------------------------------------------------

void objc_free(void *mem)
{
    if (!mem) {
        (*_objc_free)(mem);
    }
}

// ----------------------------------------------------------------------------
