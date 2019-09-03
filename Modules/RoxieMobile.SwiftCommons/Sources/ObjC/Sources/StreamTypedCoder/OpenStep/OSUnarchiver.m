// ----------------------------------------------------------------------------
//
//  OSUnarchiver.m
//  Based on part of libFoundation.
//
//  @author     Alexander Bragin <bragin-av@roxiemobile.com>
//  @copyright  Copyright (c) 2019, Roxie Mobile Ltd. All rights reserved.
//  @link       http://www.roxiemobile.com/
//
// ----------------------------------------------------------------------------

#import <dispatch/once.h>

#import "objc-runtime.h"
#import "common.h"

#import "OSUnarchiver.h"
#import "OSUnarchiver+Decoding.h"

#import "OSArchiver.h"
#import "OSUtilities.h"
#import "NSData+OpenStep.h"

// ----------------------------------------------------------------------------

#define ENCODE_AUTORELEASEPOOL 0
#define ARCHIVE_DEBUGGING      0

#define FINAL static inline

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

FINAL BOOL isReferenceTag(OSTagType _tag)
{
    return (_tag & REFERENCE) ? YES : NO;
}

FINAL OSTagType tagValue(OSTagType _tag) {
    return _tag & VALUE; // mask out bit 8
}

// ----------------------------------------------------------------------------

LF_DECLARE NSString *const OSInconsistentArchiveException =
        @"Archive is inconsistent";

// ----------------------------------------------------------------------------

@interface OSUnarchiver ()

// - Properties

@property(assign) unsigned int systemVersion;              // Archiver's version that wrote the data

// Caches
@property(nonatomic, strong) NSMapTable *inObjects;        // Decoded objects: key -> object
@property(nonatomic, strong) NSMapTable *inClasses;        // Decoded classes: key -> class info
@property(nonatomic, strong) NSMapTable *inPointers;       // Decoded pointers: key -> pointer
@property(nonatomic, strong) NSMapTable *inClassAlias;     // Archive name -> Decoded name
@property(nonatomic, strong) NSMapTable *inClassVersions;  // Archive name -> Class info

// Source
@property(nonatomic, strong) NSData *data;
@property(nonatomic, assign) NSUInteger cursor;

// Flags
@property(nonatomic, assign) BOOL decodingRoot;
@property(nonatomic, assign) BOOL didReadHeader;

// --

@end

// ----------------------------------------------------------------------------
#pragma mark -
// ----------------------------------------------------------------------------

@implementation OSUnarchiver

static NSMapTable *_classToAliasMappings = NULL; // Archive name => Decoded name

// ----------------------------------------------------------------------------
#pragma mark - Properties
// ----------------------------------------------------------------------------

@dynamic atEnd;

// ----------------------------------------------------------------------------

- (BOOL)isAtEnd {
    return (self.cursor >= [self.data length]);
}

// ----------------------------------------------------------------------------
#pragma mark - Private Methods
// ----------------------------------------------------------------------------

// TODO:

// ----------------------------------------------------------------------------
#pragma mark - Methods
// ----------------------------------------------------------------------------

+ (void)initialize
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _classToAliasMappings = NSCreateMapTable(NSObjectMapKeyCallBacks,
                                                NSObjectMapValueCallBacks,
                                                19);
    });
}

// ----------------------------------------------------------------------------

- (id)initForReadingWithData:(NSData*)_data
{
    if ((self = [super init])) {
        self.inObjects       = NSCreateMapTable(NSIntMapKeyCallBacks,
                                                 NSObjectMapValueCallBacks,
                                                 119);
        self.inClasses       = NSCreateMapTable(NSIntMapKeyCallBacks,
                                                 NSObjectMapValueCallBacks,
                                                 19);
        self.inPointers      = NSCreateMapTable(NSIntMapKeyCallBacks,
                                                 NSIntMapValueCallBacks,
                                                 19);
        self.inClassAlias    = NSCreateMapTable(NSObjectMapKeyCallBacks,
                                                 NSObjectMapValueCallBacks,
                                                 19);
        self.inClassVersions = NSCreateMapTable(NSObjectMapKeyCallBacks,
                                                 NSObjectMapValueCallBacks,
                                                 19);
        self.data = RETAIN(_data);
        self->deserData = (void *)
            [self.data methodForSelector:
                 @selector(deserializeDataAt:ofObjCType:atCursor:context:)];
        self->getData = (void *)
            [self.data methodForSelector:@selector(deserializeBytes:length:atCursor:)];
    }
    return self;
}

/* Decoding Objects */

+ (id)unarchiveObjectWithData:(NSData*)_data
{
    OSUnarchiver *unarchiver = [[self alloc] initForReadingWithData:_data];
    id           object      = [unarchiver decodeObject];

    RELEASE(unarchiver); unarchiver = nil;
  
    return object;
}
+ (id)unarchiveObjectWithFile:(NSString*)path
{
    NSData *rdata = [NSData dataWithContentsOfFile:path];
    if (!rdata) return nil;
    return [self unarchiveObjectWithData:rdata];
}


#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc
{
    RELEASE(self.data); self.data = nil;
  
    if (self.inObjects) {
        NSFreeMapTable(self.inObjects); self.inObjects = NULL; }
    if (self.inClasses) {
        NSFreeMapTable(self.inClasses); self.inClasses = NULL; }
    if (self.inPointers) {
        NSFreeMapTable(self.inPointers); self.inPointers = NULL; }
    if (self.inClassAlias) {
        NSFreeMapTable(self.inClassAlias); self.inClassAlias = NULL; }
    if (self.inClassVersions) {
        NSFreeMapTable(self.inClassVersions); self.inClassVersions = NULL; }
  
    [super dealloc];
}
#endif

/* Managing an OSUnarchiver */

- (void)setObjectZone:(NSZone *)_zone
{
    self->objectZone = _zone;
}
- (NSZone *)objectZone
{
    return self->objectZone;
}

// ******************** primitive decoding ********************

FINAL char *_readCString(OSUnarchiver *self);
FINAL void _readObjC(OSUnarchiver *self, void *_value, const char *_type);

// ******************** complex decoding **********************

- (void)decodeArchiveHeader {

    if (self.didReadHeader == NO) {
        self.didReadHeader = YES;

        // Read archive header
        NSString *signature = [self readStringWithTag:NO];
        self.systemVersion = [self readUnsignedShort];

        if (![signature isEqualToString:OSCoderSignature]) {
            NSLog(@"WARNING: Used a different archiver (signature %@:%i)",
                    signature, [self systemVersion]);
        }
        else if ([self systemVersion] != OSCoderVersion) {
            NSLog(@"WARNING: Used a different archiver version (archiver=%i, unarchiver=%i)",
                    [self systemVersion], OSCoderVersion);
        }
    }
}

- (void)beginDecoding
{
    //self->cursor = 0;
    [self decodeArchiveHeader];
}
- (void)endDecoding
{
#if 0
    NSResetMapTable(self->inObjects);
    NSResetMapTable(self->inClasses);
    NSResetMapTable(self->inPointers);
    NSResetMapTable(self->inClassAlias);
    NSResetMapTable(self->inClassVersions);
#endif

    self.decodingRoot = NO;
}

- (Class)_decodeClass:(BOOL)_isReference
{
    int   archiveId = [self readInt];
    Class result    = Nil;

    if (archiveId == 0) // Nil class or unused conditional class
        return nil;
    
    if (_isReference) {
        NSAssert(archiveId, @"archive id is 0 !");
        
        result = (Class)NSMapGet(self.inClasses, (void *)(long)archiveId);
        if (result == nil)
            result = (id)NSMapGet(self.inObjects, (void *)(long)archiveId);
        if (result == nil) {
            [NSException raise:OSInconsistentArchiveException
                         format:@"did not find referenced class %i.", archiveId];
        }
    }
    else {
        NSString  *name   = NULL;
        NSInteger version = 0;
        char      *cname  = _readCString(self);

        if (cname == NULL) {
            [NSException raise:OSInconsistentArchiveException
                         format:@"could not decode class name."];
        }
        
        name    = [NSString stringWithCString:cname encoding:NSUTF8StringEncoding];
        version = [self readLong];
        lfFree(cname); cname = NULL;
        
        if ([name lengthOfBytesUsingEncoding:NSUTF8StringEncoding] == 0) {
            [NSException raise:OSInconsistentArchiveException
                         format:@"could not allocate memory for class name."];
        }

        NSMapInsert(self.inClassVersions, name, @(version));
#if ARCHIVE_DEBUGGING
        NSLog(@"read class version %@ => %i", name, version);
#endif

        { // check whether the class is to be replaced
            NSString *newName = NSMapGet(self.inClassAlias, name);
      
            if (newName)
                name = newName;
            else {
                newName = NSMapGet(_classToAliasMappings, name);
                if (newName)
                    name = newName;
            }
        }
    
        result = NSClassFromString(name);

        if (result == Nil) {
            [NSException raise:OSInconsistentArchiveException
                         format:@"class doesn't exist in this runtime."];
        }
        name = nil;

        if ([result version] != version) {
            [NSException raise:OSInconsistentArchiveException
                         format:@"class versions do not match."];
        }

        NSMapInsert(self.inClasses, (void *)(long)archiveId, result);
#if ARCHIVE_DEBUGGING
        NSLog(@"read class %i => 0x%p", archiveId, result);
#endif
    }
  
    NSAssert(result, @"Invalid state, class is Nil.");
  
    return result;
}

- (id)_decodeObject:(BOOL)_isReference
{
    // this method returns a retained object !
    int archiveId = [self readInt];
    id  result    = nil;

    if (archiveId == 0) // nil object or unused conditional object
        return nil;

    if (_isReference) {
        NSAssert(archiveId, @"archive id is 0 !");
        
        result = (id)NSMapGet(self.inObjects, (void *)(long)archiveId);
        if (result == nil)
            result = (id)NSMapGet(self.inClasses, (void *)(long)archiveId);
        
        if (result == nil) {
            [NSException raise:OSInconsistentArchiveException
                         format:@"did not find referenced object %i.",
			 archiveId];
        }
        result = RETAIN(result);
    }
    else {
        Class class       = Nil;
        id    replacement = nil;

        // decode class info
        [self decodeValueOfObjCType:"#" at:&class];
        NSAssert(class, @"could not decode class for object.");
    
        result = [class allocWithZone:self->objectZone];
        NSMapInsert(self.inObjects, (void *)(long)archiveId, result);
        
#if ARCHIVE_DEBUGGING
        NSLog(@"read object %i => 0x%p", archiveId, result);
#endif

        replacement = [result initWithCoder:self];
        if (replacement != result) {
            /*
              NGLogT(@"decoder",
              @"object 0x%p<%s> replaced by 0x%p<%s> in initWithCoder:",
              result, class_get_class_name(*(Class *)result),
              replacement, class_get_class_name(*(Class *)replacement));
            */

            replacement = RETAIN(replacement);
            NSMapRemove(self.inObjects, (void *)(long)archiveId);
            result = replacement;
            NSMapInsert(self.inObjects, (void *)(long)archiveId, result);
            RELEASE(replacement);
        }

        replacement = [result awakeAfterUsingCoder:self];
        if (replacement != result) {
            /*
              NGLogT(@"decoder",
              @"object 0x%p<%s> replaced by 0x%p<%s> in awakeAfterUsingCoder:",
              result, class_get_class_name(*(Class *)class),
              replacement, class_get_class_name(*(Class *)replacement));
            */
      
            replacement = RETAIN(replacement);
            NSMapRemove(self.inObjects, (void *)(long)archiveId);
            result = replacement;
            NSMapInsert(self.inObjects, (void *)(long)archiveId, result);
            RELEASE(replacement);
        }

        //NGLogT(@"decoder", @"decoded object 0x%p<%@>",
        //       (unsigned)result, NSStringFromClass([result class]));
    }
    
    if (object_is_instance(result)) {
        NSAssert3([result retainCount] > 0,
                  @"invalid retain count %i for id=%i (%@) ..",
                  (unsigned) [result retainCount],
                  archiveId,
                  NSStringFromClass([result class]));
    }
    return result;
}

- (id)decodeObject
{
    id result = nil;

    [self decodeValueOfObjCType:"@" at:&result];
  
    // result is retained
    return AUTORELEASE(result);
}

FINAL void _checkType(char _code, char _reqCode)
{
    if (_code != _reqCode) {
        [NSException raise:OSInconsistentArchiveException
                     format:@"expected different typecode"];
    }
}
FINAL void _checkType2(char _code, char _reqCode1, char _reqCode2)
{
    if ((_code != _reqCode1) && (_code != _reqCode2)) {
        [NSException raise:OSInconsistentArchiveException
                     format:@"expected different typecode"];
    }
}

- (void)decodeArrayOfObjCType:(const char *)_type
  count:(unsigned int)_count
  at:(void *)_array
{
    BOOL      startedDecoding = NO;
    OSTagType tag   = [self readTag];
    int       count = [self readInt];

    if (self.decodingRoot == NO) {
        self.decodingRoot = YES;
        startedDecoding = YES;
        [self beginDecoding];
    }
  
    //NGLogT(@"decoder", @"decoding array[%i/%i] of ObjC-type '%s' array-tag='%c'",
    //       _count, count, _type, tag);
  
    NSAssert(tag == _C_ARY_B, @"invalid type ..");
    NSAssert(count == _count, @"invalid array size ..");

    // Arrays of elementary types are written optimized: the type is written
    // then the elements of array follow.
    if ((*_type == _C_ID) || (*_type == _C_CLASS)) { // object array
        int i;

        //NGLogT(@"decoder", @"decoding object-array[%i] type='%s'", _count, _type);
    
        tag = [self readTag]; // object array
        NSAssert(tag == *_type, @"invalid array element type ..");
      
        for (i = 0; i < _count; i++)
            ((id *)_array)[i] = [self decodeObject];
    }
    else if ((*_type == _C_CHR) || (*_type == _C_UCHR)) { // byte array
        tag = [self readTag];
        NSAssert((tag == _C_CHR) || (tag == _C_UCHR), @"invalid byte array type ..");

        //NGLogT(@"decoder", @"decoding byte-array[%i] type='%s' tag='%c'",
        //       _count, _type, tag);
    
        // read buffer
        [self readBytes:_array length:_count];
    }
    else if (isBaseType(_type)) {
        unsigned offset, itemSize = objc_sizeof_type(_type);
        int      i;
      
        tag = [self readTag];
        NSAssert(tag == *_type, @"invalid array base type ..");

        for (i = offset = 0; i < _count; i++, offset += itemSize)
            _readObjC(self, (char *)_array + offset, _type);
    }
    else {
        IMP      decodeValue = NULL;
        unsigned offset, itemSize = objc_sizeof_type(_type);
        int      i;

        decodeValue = [self methodForSelector:@selector(decodeValueOfObjCType:at:)];
    
        for (i = offset = 0; i < count; i++, offset += itemSize) {
//             decodeValue(self, @selector(decodeValueOfObjCType:at:),
//                         (char *)_array + offset, _type);
            [self decodeValueOfObjCType:_type at:(char *)_array + offset];
        }
    }

    if (startedDecoding) {
        [self endDecoding];
        self.decodingRoot = NO;
    }
}

/* Substituting One Class for Another */

+ (NSString *)classNameDecodedForArchiveClassName:(NSString *)nameInArchive
{
    NSString *className = NSMapGet(_classToAliasMappings, nameInArchive);
    return className ? className : nameInArchive;
}

+ (void)decodeClassName:(NSString *)nameInArchive
            asClassName:(NSString *)trueName
{
    NSMapInsert(_classToAliasMappings, nameInArchive, trueName);
}

- (NSString *)classNameDecodedForArchiveClassName:(NSString *)_nameInArchive
{
    NSString *className = NSMapGet(self.inClassAlias, _nameInArchive);
    return className ? className : _nameInArchive;
}
- (void)decodeClassName:(NSString *)nameInArchive asClassName:(NSString *)trueName
{
    NSMapInsert(self.inClassAlias, nameInArchive, trueName);
}

// ******************** primitive decoding ********************

FINAL char *_readCString(OSUnarchiver *self)
{
    unsigned int position = (unsigned int) self.cursor;
    char *value = NULL;
    self->deserData(self.data,
                    @selector(deserializeDataAt:ofObjCType:atCursor:context:),
                    &value, @encode(char *), &(position), self);
    self.cursor = position;
    return value;
}

FINAL void _readObjC(OSUnarchiver *self, void *_value, const char *_type)
{
    unsigned int position = (unsigned int) self.cursor;
    self->deserData(self.data,
                    @selector(deserializeDataAt:ofObjCType:atCursor:context:),
                    _value, _type,
                    &(position),
                    self);
    self.cursor = position;
}

// OSObjCTypeSerializationCallBack

- (void)serializeObjectAt:(id *)_object
  ofObjCType:(const char *)_type
  intoData:(NSMutableData *)_data
{
    [self doesNotRecognizeSelector:_cmd];
}

- (void)deserializeObjectAt:(id *)_object
  ofObjCType:(const char *)_type
  fromData:(NSData *)_data
  atCursor:(unsigned int *)_cursor
{
    OSTagType tag             = 0;
    BOOL      isReference     = NO;

    tag         = [self readTag];
    isReference = isReferenceTag(tag);
    tag         = tagValue(tag);

    NSCAssert(((*_type == _C_ID) || (*_type == _C_CLASS)),
              @"unexpected type ..");
  
    switch (*_type) {
        case _C_ID:
            NSAssert((*_type == _C_ID) || (*_type == _C_CLASS), @"invalid type ..");
            *_object = [self _decodeObject:isReference];
            break;
        case _C_CLASS:
            NSAssert((*_type == _C_ID) || (*_type == _C_CLASS), @"invalid type ..");
            *_object = [self _decodeClass:isReference];
            break;
      
        default:
            [NSException raise:OSInconsistentArchiveException
                         format:@"encountered type '%s' in object context",
                           _type];
            break;
    }
}

// ----------------------------------------------------------------------------
#pragma mark - @interface NSCoder
// ----------------------------------------------------------------------------

- (NSData *)decodeDataObject {

    NSData *data = nil;

    // Decode bytes
    NSUInteger length = 0;
    void *bytes = [self decodeBytesWithReturnedLength:&length];

    if ((bytes != nil) && (length > 0)) {
        data = [NSData dataWithBytes:bytes length:length];
    }
    else {
        data = [NSData data];
    }

    // Done
    return data;
}

// ----------------------------------------------------------------------------

- (void)decodeValueOfObjCType:(const char *)type at:(void *)data size:(NSUInteger)size {
    [self decodeValueOfObjCType:type at:data];
}

// ----------------------------------------------------------------------------

// TODO: Refactoring is required
- (void)decodeValueOfObjCType:(const char *)_type at:(void *)_value {

    BOOL      startedDecoding = NO;
    OSTagType tag             = 0;
    BOOL      isReference     = NO;

    if (self.decodingRoot == NO) {
        self.decodingRoot = YES;
        startedDecoding = YES;
        [self beginDecoding];
    }

    //NGLogT(@"decoder", @"cursor is now %i", self->cursor);

    tag         = [self readTag];
    isReference = isReferenceTag(tag);
    tag         = tagValue(tag);

#if ARCHIVE_DEBUGGING
    NSLog(@"decoder: decoding tag '%s%c' type '%s'",
           isReference ? "&" : "", tag, _type);
#endif

    switch (tag) {
        case _C_ID:
            _checkType2(*_type, _C_ID, _C_CLASS);
            *(id *)_value = [self _decodeObject:isReference];
            break;
        case _C_CLASS:
            _checkType2(*_type, _C_ID, _C_CLASS);
            *(Class *)_value = [self _decodeClass:isReference];
            break;

        case _C_ARY_B: {
            int        count     = atoi(_type + 1); // eg '[15I' => count = 15
            const char *itemType = _type;

            _checkType(*_type, _C_ARY_B);

            while(isdigit((int)*(++itemType))) ; // skip dimension

            [self decodeArrayOfObjCType:itemType count:count at:_value];
            break;
        }

        case _C_STRUCT_B: {
            int offset = 0;

            _checkType(*_type, _C_STRUCT_B);

            while ((*_type != _C_STRUCT_E) && (*_type++ != '=')); // skip "<name>="

            while (YES) {
                [self decodeValueOfObjCType:_type at:((char *)_value) + offset];

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

        case _C_SEL: {
            char *name = NULL;

            _checkType(*_type, tag);

            _readObjC(self, &name, @encode(char *));
            *(SEL *)_value = name ? sel_get_any_uid(name) : NULL;
            lfFree(name); name = NULL;
        }

        case _C_PTR:
            _readObjC(self, *(char **)_value, _type + 1); // skip '^'
            break;

        case _C_CHARPTR:
        case _C_CHR:     case _C_UCHR:
        case _C_SHT:     case _C_USHT:
        case _C_INT:     case _C_UINT:
        case _C_LNG:     case _C_ULNG:
        case _C_LNG_LNG: case _C_ULNG_LNG:
        case _C_FLT:     case _C_DBL:
            _checkType(*_type, tag);
            _readObjC(self, _value, _type);
            break;

        default:
            [NSException raise:OSInconsistentArchiveException
                         format:@"unsupported typecode %i found.", tag];
            break;
    }

    if (startedDecoding) {
        [self endDecoding];
        self.decodingRoot = NO;
    }
}

// ----------------------------------------------------------------------------

- (NSInteger)versionForClassName:(NSString *)className {

    id version = NSMapGet(self.inClassVersions, className);
    return (version ? [version integerValue] : NSNotFound);
}

// ----------------------------------------------------------------------------

@end /* OSUnarchiver */

// ----------------------------------------------------------------------------
