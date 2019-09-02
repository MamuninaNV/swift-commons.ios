// ----------------------------------------------------------------------------
//
//  OSArchiver.m
//  Based on part of libFoundation.
//
//  @author     Alexander Bragin <bragin-av@roxiemobile.com>
//  @copyright  Copyright (c) 2019, Roxie Mobile Ltd. All rights reserved.
//  @link       http://www.roxiemobile.com/
//
// ----------------------------------------------------------------------------

#include <Foundation/NSData.h>
#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSException.h>

#include "objc-runtime.h"
#include "common.h"
#include "OSUtilities.h"
#include "OSArchiver.h"
#include "NSData+OpenStep.h"

// ----------------------------------------------------------------------------

#define ENCODE_AUTORELEASEPOOL 0
#define ARCHIVE_DEBUGGING      0

#define FINAL static inline

typedef unsigned char NSTagType;

#define REFERENCE 128
#define VALUE     127

static NSMapTableKeyCallBacks NSIdentityObjectMapKeyCallbacks = {
  (unsigned(*)(NSMapTable *, const void *))          __NSHashPointer,
  (BOOL(*)(NSMapTable *, const void *, const void *))__NSComparePointers,
  (void (*)(NSMapTable *, const void *anObject))     __NSRetainObjects,
  (void (*)(NSMapTable *, void *anObject))           __NSReleaseObjects,
  (NSString *(*)(NSMapTable *, const void *))        __NSDescribePointers,
  (const void *)NULL
};

FINAL BOOL isBaseType(const char *_type)
{
    switch (*_type) {
        case _C_CHR:     case _C_UCHR:
        case _C_SHT:     case _C_USHT:
        case _C_INT:     case _C_UINT:
        case _C_LNG:     case _C_ULNG:
        case _C_LNG_LNG: case _C_ULNG_LNG:
        case _C_FLT:     case _C_DBL:
            return YES;

        default:
            return NO;
    }
}

FINAL BOOL isReferenceTag(NSTagType _tag)
{
    return (_tag & REFERENCE) ? YES : NO;
}

FINAL NSTagType tagValue(NSTagType _tag) {
    return _tag & VALUE; // mask out bit 8
}

static const char *OSCoderSignature = "roxie:stc";  // Stream Typed Coder
static int         OSCoderVersion   = 1909;         // 2019-09

@implementation OSArchiver

- (id)initForWritingWithMutableData:(NSMutableData *)_data
{
    if ((self = [super init])) {
        self->classForCoder      = @selector(classForCoder);
        self->replObjectForCoder = @selector(replacementObjectForCoder:);
        
        self->outObjects      = NSCreateHashTable(NSNonOwnedPointerHashCallBacks, 119);
        self->outConditionals = NSCreateHashTable(NSNonOwnedPointerHashCallBacks, 119);
        self->outPointers     = NSCreateHashTable(NSNonOwnedPointerHashCallBacks, 0);
        self->replacements    = NSCreateMapTable(NSIdentityObjectMapKeyCallbacks,
                                                 NSObjectMapValueCallBacks,
                                                 19);
        self->outClassAlias   = NSCreateMapTable(NSObjectMapKeyCallBacks,
                                                 NSObjectMapValueCallBacks,
                                                 19);
        self->outKeys         = NSCreateMapTable(NSObjectMapKeyCallBacks,
                                                 NSIntMapValueCallBacks,
                                                 119);

        self->archiveAddress = 1;

        self->data    = RETAIN(_data);
        self->serData = (void *)
            [self->data methodForSelector:@selector(serializeDataAt:ofObjCType:context:)];
        self->addData = (void *)
            [self->data methodForSelector:@selector(appendBytes:length:)];
    }
    return self;
}

- (id)init
{
    return [self initForWritingWithMutableData:[NSMutableData data]];
}

+ (NSData *)archivedDataWithRootObject:(id)_root
{
    OSArchiver *archiver = AUTORELEASE([self new]);
    NSData     *rdata    = nil;
    
    [archiver encodeRootObject:_root];
    rdata = [archiver->data copy];
    return AUTORELEASE(rdata);
}
+ (BOOL)archiveRootObject:(id)_root toFile:(NSString *)_path
{
    NSData *rdata = [self archivedDataWithRootObject:_root];
    return [rdata writeToFile:_path atomically:YES];
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc
{
    RELEASE(self->data);
    
    if (self->outKeys)         NSFreeMapTable(self->outKeys);
    if (self->outObjects)      NSFreeHashTable(self->outObjects);
    if (self->outConditionals) NSFreeHashTable(self->outConditionals);
    if (self->outPointers)     NSFreeHashTable(self->outPointers);
    if (self->replacements)    NSFreeMapTable(self->replacements);
    if (self->outClassAlias)   NSFreeMapTable(self->outClassAlias);
  
    [super dealloc];
}
#endif

// ******************** Getting Data from the OSArchiver ******

- (NSMutableData *)archiverData
{
    return self->data;
}

// ******************** archive id's **************************

FINAL int _archiveIdOfObject(OSArchiver *self, id _object)
{
    if (_object == nil)
        return 0;
#if 0 /* this does not work with 64bit */
    else
        return (int)_object;
#else
    else {
        int archiveId;

        archiveId = (long)NSMapGet(self->outKeys, _object);
        if (archiveId == 0) {
            archiveId = self->archiveAddress;
            NSMapInsert(self->outKeys, _object, (void*)(long)archiveId);
#if ARCHIVE_DEBUGGING
            NSLog(@"mapped 0x%p => %i", _object, archiveId);
#endif
            self->archiveAddress++;
        }

        return archiveId;
    }
#endif
}
FINAL int _archiveIdOfClass(OSArchiver *self, Class _class)
{
    return _archiveIdOfObject(self, _class);
}

// ******************** primitive encoding ********************

FINAL void _writeBytes(OSArchiver *self, const void *_bytes, unsigned _len);

FINAL void _writeTag  (OSArchiver *self, NSTagType _tag);

FINAL void _writeChar (OSArchiver *self, char _value);
FINAL void _writeShort(OSArchiver *self, short _value);
FINAL void _writeInt  (OSArchiver *self, int _value);
FINAL void _writeLong (OSArchiver *self, long _value);
FINAL void _writeFloat(OSArchiver *self, float _value);

FINAL void _writeCString(OSArchiver *self, const char *_value);
FINAL void _writeObjC(OSArchiver *self, const void *_value, const char *_type);

// ******************** complex encoding **********************

- (void)beginEncoding
{
    self->traceMode    = NO;
    self->encodingRoot = YES;
}
- (void)endEncoding
{
#if 0
    NSResetHashTable(self->outObjects);
    NSResetHashTable(self->outConditionals);
    NSResetHashTable(self->outPointers);
    NSResetMapTable(self->outClassAlias);
    NSResetMapTable(self->replacements);
    NSResetMapTable(self->outKeys);
#endif

    self->traceMode      = NO;
    self->encodingRoot   = NO;
}

- (void)writeArchiveHeader
{
    if (self->didWriteHeader == NO) {
        _writeCString(self, OSCoderSignature);
        _writeInt(self, OSCoderVersion);
        self->didWriteHeader = YES;
    }
}
- (void)writeArchiveTrailer
{
}

- (void)traceObjectsWithRoot:(id)_root
{
    // encoding pass 1
    NS_DURING {
        self->traceMode = YES;
        [self encodeObject:_root];
    }
    NS_HANDLER {
        self->traceMode = NO;
        NSResetHashTable(self->outObjects);
        [localException raise];
    }
    NS_ENDHANDLER;
    
    self->traceMode = NO;
    NSResetHashTable(self->outObjects);
}

- (void)encodeObjectsWithRoot:(id)_root
{
    // encoding pass 2
    [self encodeObject:_root];
}

- (void)encodeRootObject:(id)_object
{
#if ENCODE_AUTORELEASEPOOL
    NSAutoreleasePool *pool =
        [[NSAutoreleasePool allocWithZone:[self zone]] init];
#endif
    
    [self beginEncoding];

    NS_DURING {
        /*
         * Prepare for writing the graph objects for which `rootObject' is the root
         * node. The algorithm consists from two passes. In the first pass it
         * determines the nodes so-called 'conditionals' - the nodes encoded *only*
         * with -encodeConditionalObject:. They represent nodes that are not
         * related directly to the graph. In the second pass objects are encoded
         * normally, except for the conditional objects which are encoded as nil.
         */

        // pass1: start tracing for conditionals
        [self traceObjectsWithRoot:_object];
        
        // pass2: start writing
        [self writeArchiveHeader];
        [self encodeObjectsWithRoot:_object];
        [self writeArchiveTrailer];
    }
    NS_HANDLER {
        [self endEncoding]; // release resources
        [localException raise];
    }
    NS_ENDHANDLER;
    
    [self endEncoding]; // release resources

#if ENCODE_AUTORELEASEPOOL
    RELEASE(pool); pool = nil;
#endif
}

- (void)encodeConditionalObject:(id)_object
{
    if (self->traceMode) { // pass 1
        /*
         * This is the first pass of the determining the conditionals
         * algorithm. We traverse the graph and insert into the `conditionals'
         * set. In the second pass all objects that are still in this set will
         * be encoded as nil when they receive -encodeConditionalObject:. An
         * object is removed from this set when it receives -encodeObject:.
         */

        if (_object) {
            if (NSHashGet(self->outObjects, _object))
                // object isn't conditional any more .. (was stored using encodeObject:)
                ;
            else if (NSHashGet(self->outConditionals, _object))
                // object is already stored as conditional
                ;
            else
                // insert object in conditionals set
                NSHashInsert(self->outConditionals, _object);
        }
    }
    else { // pass 2
        BOOL isConditional;

        isConditional = (NSHashGet(self->outConditionals, _object) != nil);

        // If anObject is still in the `conditionals' set, it is encoded as nil.
        [self encodeObject:isConditional ? nil : _object];
    }
}

- (void)_traceObject:(id)_object
{
    if (_object == nil) // don't trace nil objects ..
        return;

    //NSLog(@"lookup 0x%p in outObjs=0x%p", _object, self->outObjects);
    
    if (NSHashGet(self->outObjects, _object) == nil) {
        //NSLog(@"lookup failed, object wasn't traced yet !");
        
        // object wasn't traced yet
        // Look-up the object in the `conditionals' set. If the object is
        // there, then remove it because it is no longer a conditional one.
        if (NSHashGet(self->outConditionals, _object)) {
            // object was marked conditional ..
            NSHashRemove(self->outConditionals, _object);
        }
        
        // mark object as traced
        NSHashInsert(self->outObjects, _object);
        
        if (object_is_instance(_object)) {
            Class archiveClass = Nil;
            id    replacement  = nil;
            
            replacement = [_object performSelector:self->replObjectForCoder
                                   withObject:self];
            
            if (replacement != _object) {
                NSMapInsert(self->replacements, _object, replacement);
                _object = replacement;
            }
            
            if (object_is_instance(_object)) {
                archiveClass = [_object performSelector:self->classForCoder];
            }
            
            [self encodeObject:archiveClass];
            [_object encodeWithCoder:self];
        }
        else {
            // there are no class-variables ..
        }
    }
}
- (void)_encodeObject:(id)_object
{
    NSTagType tag;
    int       archiveId = _archiveIdOfObject(self, _object);

    if (_object == nil) { // nil object or class
        _writeTag(self, _C_ID | REFERENCE);
        _writeInt(self, archiveId);
        return;
    }
    
    tag = object_is_instance(_object) ? _C_ID : _C_CLASS;
    
    if (NSHashGet(self->outObjects, _object)) { // object was already written
        _writeTag(self, tag | REFERENCE);
        _writeInt(self, archiveId);
    }
    else {
        // mark object as written
        NSHashInsert(self->outObjects, _object);

        /*
          if (tag == _C_CLASS) { // a class object
          NGLogT(@"encoder", @"encoding class %s:%i ..",
          class_get_class_name(_object), [_object version]);
          }
          else {
          NGLogT(@"encoder", @"encoding object 0x%p<%s> ..",
          _object, class_get_class_name(*(Class *)_object));
          }
        */
    
        _writeTag(self, tag);
        _writeInt(self, archiveId);

        if (tag == _C_CLASS) { // a class object
            NSString *className;
            NSUInteger len;
            char *buf;
            
            className = NSStringFromClass(_object);
            className = [self classNameEncodedForTrueClassName:className];
            len = [className lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
            buf = malloc(len + 4);
            [className getCString:buf maxLength:len + 4 encoding:NSUTF8StringEncoding]; buf[len] = '\0';
            
            _writeCString(self, buf);
            _writeLong(self, [_object version]);
            if (buf) free(buf);
        }
        else {
            Class archiveClass = Nil;
            id    replacement  = nil;

            replacement = NSMapGet(self->replacements, _object);
            if (replacement) _object = replacement;

            /*
              _object = [_object performSelector:self->replObjectForCoder
              withObject:self];
            */
            archiveClass = [_object performSelector:self->classForCoder];
            
            NSAssert(archiveClass, @"no archive class found ..");

            [self encodeObject:archiveClass];
            [_object encodeWithCoder:self];
        }
    }
}

- (void)encodeObject:(id)_object
{
    if (self->encodingRoot) {
        [self encodeValueOfObjCType:
                object_is_instance(_object) ? "@" : "#"
              at:&_object];
    }
    else {
        [self encodeRootObject:_object];
    }
}

- (void)_traceValueOfObjCType:(const char *)_type at:(const void *)_value
{
    //NSLog(@"_tracing value at 0x%p of type %s", _value, _type);
    
    switch (*_type) {
        case _C_ID:
        case _C_CLASS:
            //NSLog(@"_traceObject 0x%p", *(id *)_value);
            [self _traceObject:*(id *)_value];
            break;
        
        case _C_ARY_B: {
            int        count     = atoi(_type + 1); // eg '[15I' => count = 15
            const char *itemType = _type;
            while(isdigit((int)*(++itemType))) ; // skip dimension
            [self encodeArrayOfObjCType:itemType count:count at:_value];
            break;
        }

        case _C_STRUCT_B: { // C-structure begin '{'
            int offset = 0;

            while ((*_type != _C_STRUCT_E) && (*_type++ != '=')); // skip "<name>="
        
            while (YES) {
                [self encodeValueOfObjCType:_type at:((char *)_value) + offset];
            
                offset += objc_sizeof_type(_type);
                _type  =  objc_skip_typespec(_type);
            
                if(*_type != _C_STRUCT_E) { // C-structure end '}'
                    int align, remainder;
                    
                    align = objc_alignof_type(_type);
                    if((remainder = offset % align))
                        offset += (align - remainder);
                }
                else
                    break;
            }
            break;
        }
    }
}

- (void)_encodeValueOfObjCType:(const char *)_type at:(const void *)_value
{
    //NGLogT(@"encoder", @"encoding value of ObjC-type '%s' at %i",
    //       _type, [self->data length]);
  
    switch (*_type) {
        case _C_ID:
        case _C_CLASS:
            // ?? Write another tag just to be possible to read using the
            // ?? decodeObject method. (Otherwise a lookahead would be required)
            // ?? _writeTag(self, *_type);
            [self _encodeObject:*(id *)_value];
            break;

        case _C_ARY_B: {
            int        count     = atoi(_type + 1); // eg '[15I' => count = 15
            const char *itemType = _type;

            while(isdigit((int)*(++itemType))) ; // skip dimension

            // Write another tag just to be possible to read using the
            // decodeArrayOfObjCType:count:at: method.
            _writeTag(self, _C_ARY_B);
            [self encodeArrayOfObjCType:itemType count:count at:_value];
            break;
        }

        case _C_STRUCT_B: { // C-structure begin '{'
            int offset = 0;

            _writeTag(self, '{');

            while ((*_type != _C_STRUCT_E) && (*_type++ != '=')); // skip "<name>="
        
            while (YES) {
                [self encodeValueOfObjCType:_type at:((char *)_value) + offset];
            
                offset += objc_sizeof_type(_type);
                _type  =  objc_skip_typespec(_type);
            
                if(*_type != _C_STRUCT_E) { // C-structure end '}'
                    int align, remainder;
                    
                    align = objc_alignof_type(_type);
                    if((remainder = offset % align))
                        offset += (align - remainder);
                }
                else
                    break;
            }
            break;
        }

        case _C_SEL:
            _writeTag(self, _C_SEL);
            _writeCString(self, (*(SEL *)_value) ? sel_get_name(*(SEL *)_value) : NULL);
            break;
      
        case _C_PTR:
            _writeTag(self, *_type);
            _writeObjC(self, *(char **)_value, _type + 1);
            break;

        case _C_CHARPTR:
        case _C_CHR:     case _C_UCHR:
        case _C_SHT:     case _C_USHT:
        case _C_INT:     case _C_UINT:
        case _C_LNG:     case _C_ULNG:
        case _C_LNG_LNG: case _C_ULNG_LNG:
        case _C_FLT:     case _C_DBL:
            _writeTag(self, *_type);
            _writeObjC(self, _value, _type);
            break;
      
        default:
            NSLog(@"unsupported C type %s ..", _type);
            break;
    }
}

- (void)encodeValueOfObjCType:(const char *)_type
                           at:(const void *)_value
{
    if (self->traceMode) {
        //NSLog(@"trace value at 0x%p of type %s", _value, _type);
        [self _traceValueOfObjCType:_type at:_value];
    }
    else {
        if (self->didWriteHeader == NO)
            [self writeArchiveHeader];
  
        [self _encodeValueOfObjCType:_type at:_value];
    }
}

- (void)encodeArrayOfObjCType:(const char *)_type
                        count:(unsigned int)_count
                           at:(const void *)_array
{

    if ((self->didWriteHeader == NO) && (self->traceMode == NO))
        [self writeArchiveHeader];

    //NGLogT(@"encoder", @"%s array[%i] of ObjC-type '%s'",
    //       self->traceMode ? "tracing" : "encoding", _count, _type);
  
    // array header
    if (self->traceMode == NO) { // nothing is written during trace-mode
        _writeTag(self, _C_ARY_B);
        _writeInt(self, _count);
    }

    // Optimize writing arrays of elementary types. If such an array has to
    // be written, write the type and then the elements of array.

    if ((*_type == _C_ID) || (*_type == _C_CLASS)) { // object array
        int i;

        if (self->traceMode == NO)
            _writeTag(self, *_type); // object array

        for (i = 0; i < _count; i++)
            [self encodeObject:((id *)_array)[i]];
    }
    else if ((*_type == _C_CHR) || (*_type == _C_UCHR)) { // byte array
        if (self->traceMode == NO) {
            //NGLogT(@"encoder", @"encode byte-array (base='%c', count=%i)", *_type, _count);

            // write base type tag
            _writeTag(self, *_type);

            // write buffer
            _writeBytes(self, _array, _count);
        }
    }
    else if (isBaseType(_type)) {
        if (self->traceMode == NO) {
            unsigned offset, itemSize = objc_sizeof_type(_type);
            int      i;

            /*
              NGLogT(@"encoder",
              @"encode basetype-array (base='%c', itemSize=%i, count=%i)",
              *_type, itemSize, _count);
              */

            // write base type tag
            _writeTag(self, *_type);

            // write contents
            for (i = offset = 0; i < _count; i++, offset += itemSize)
                _writeObjC(self, (char *)_array + offset, _type);
        }
    }
    else { // encoded using normal method
        IMP      encodeValue = NULL;
        unsigned offset, itemSize = objc_sizeof_type(_type);
        int      i;

        encodeValue = [self methodForSelector:@selector(encodeValueOfObjCType:at:)];

        for (i = offset = 0; i < _count; i++, offset += itemSize) {
//             encodeValue(self, @selector(encodeValueOfObjCType:at:),
//                         (char *)_array + offset, _type);
            [self encodeValueOfObjCType:_type at:(char *)_array + offset];
        }
    }
}

// Substituting One Class for Another

- (NSString *)classNameEncodedForTrueClassName:(NSString *)_trueName
{
    NSString *name = NSMapGet(self->outClassAlias, _trueName);
    return name ? name : _trueName;
}
- (void)encodeClassName:(NSString *)_name intoClassName:(NSString *)_archiveName
{
    NSMapInsert(self->outClassAlias, _name, _archiveName);
}

// ******************** primitive encoding ********************

FINAL void _writeBytes(OSArchiver *self, const void *_bytes, unsigned _len)
{
    NSCAssert(self->traceMode == NO, @"nothing can be written during trace-mode ..");
    self->addData(self->data, @selector(appendBytes:length:), _bytes, _len);
}
FINAL void _writeTag(OSArchiver *self, NSTagType _tag)
{
    unsigned char t = _tag;
    NSCAssert(self, @"invalid self ..");
    _writeBytes(self, &t, sizeof(t));
}
FINAL void _writeChar(OSArchiver *self, char _value)
{
    _writeBytes(self, &_value, sizeof(_value));
}

FINAL void _writeShort(OSArchiver *self, short _value)
{
    self->serData(self->data, @selector(serializeDataAt:ofObjCType:context:),
                  &_value, @encode(short), self);
}
FINAL void _writeInt(OSArchiver *self, int _value)
{
    self->serData(self->data, @selector(serializeDataAt:ofObjCType:context:),
                  &_value, @encode(int), self);
}
FINAL void _writeLong(OSArchiver *self, long _value)
{
    self->serData(self->data, @selector(serializeDataAt:ofObjCType:context:),
                  &_value, @encode(long), self);
}
FINAL void _writeFloat(OSArchiver *self, float _value)
{
    self->serData(self->data, @selector(serializeDataAt:ofObjCType:context:),
                  &_value, @encode(float), self);
}

FINAL void _writeCString(OSArchiver *self, const char *_value)
{
    self->serData(self->data, @selector(serializeDataAt:ofObjCType:context:),
                  &_value, @encode(char *), self);
}

FINAL void _writeObjC(OSArchiver *self, const void *_value, const char *_type)
{
    if ((_value == NULL) || (_type == NULL))
        return;

    if (self->traceMode) {
        // no need to track base-types in trace-mode
    
        switch (*_type) {
            case _C_ID:
            case _C_CLASS:
            case _C_CHARPTR:
            case _C_ARY_B:
            case _C_STRUCT_B:
            case _C_PTR:
                self->serData(self->data, @selector(serializeDataAt:ofObjCType:context:),
                              _value, _type, self);
                break;

            default:
                break;
        }
    }
    else {
        self->serData(self->data, @selector(serializeDataAt:ofObjCType:context:),
                      _value, _type, self);
    }
}

// OSObjCTypeSerializationCallBack

- (void)serializeObjectAt:(id *)_object
               ofObjCType:(const char *)_type
                 intoData:(NSMutableData *)_data
{
    NSAssert(((*_type == _C_ID) || (*_type == _C_CLASS)), @"unexpected type ..");

    if (self->traceMode)
        [self _traceObject:*_object];
    else
        [self _encodeObject:*_object];
}
- (void)deserializeObjectAt:(id *)_object
        ofObjCType:(const char *)_type
        fromData:(NSData *)_data
        atCursor:(unsigned int *)_cursor
{
    [self doesNotRecognizeSelector:_cmd];
}

// ----------------------------------------------------------------------------

@end /* OSArchiver */

// ----------------------------------------------------------------------------
