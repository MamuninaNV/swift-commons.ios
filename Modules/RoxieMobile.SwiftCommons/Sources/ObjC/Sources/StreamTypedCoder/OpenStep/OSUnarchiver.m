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

#define FINAL static inline

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

FINAL BOOL isReferenceTag(OSTagType _tag) {
    return (_tag & REFERENCE) != 0;
}

FINAL OSTagType tagValue(OSTagType _tag) {
    return (_tag & VALUE); // Mask out bit 8
}

// ----------------------------------------------------------------------------

LF_DECLARE NSString *const OSInconsistentArchiveException =
        @"Archive is inconsistent.";

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
@property(nonatomic, strong) NSData *buffer;
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

static NSMapTable *_classToAliasMappings = NULL;  // Archive name => Decoded name

// ----------------------------------------------------------------------------
#pragma mark - Properties
// ----------------------------------------------------------------------------

@dynamic atEnd;

// ----------------------------------------------------------------------------

- (BOOL)isAtEnd {
    return (self.cursor >= [self.buffer length]);
}

// ----------------------------------------------------------------------------
#pragma mark - Methods
// ----------------------------------------------------------------------------

+ (void)initialize {

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{

        _classToAliasMappings = NSCreateMapTable(NSObjectMapKeyCallBacks, NSObjectMapValueCallBacks, 19);
    });
}

// ----------------------------------------------------------------------------

- (instancetype)initForReadingWithData:(NSData *)data {

    int minLength = (int) (OSCoderSignature.length + sizeof(OSCoderVersion) + 1);

    // Validate incoming params
    if ([data length] < minLength) {
        return nil;
    }

    // Init instance
    if (self = [super init]) {

        // Caches
        self.inObjects       = NSCreateMapTable(NSIntMapKeyCallBacks, NSObjectMapValueCallBacks, 119);
        self.inClasses       = NSCreateMapTable(NSIntMapKeyCallBacks, NSObjectMapValueCallBacks, 19);
        self.inPointers      = NSCreateMapTable(NSIntMapKeyCallBacks, NSIntMapValueCallBacks, 19);
        self.inClassAlias    = NSCreateMapTable(NSObjectMapKeyCallBacks, NSObjectMapValueCallBacks, 19);
        self.inClassVersions = NSCreateMapTable(NSObjectMapKeyCallBacks, NSObjectMapValueCallBacks, 19);

// FIXME: Uncomment!
//        // Caches
//        self.mapObjects       = [NSMapTable strongToStrongObjectsMapTable];
//        self.mapClasses       = [NSMapTable strongToStrongObjectsMapTable];
//        self.mapPointers      = [NSMapTable strongToStrongObjectsMapTable];
//        self.mapClassAlias    = [NSMapTable strongToStrongObjectsMapTable];
//        self.mapClassVersions = [NSMapTable strongToStrongObjectsMapTable];

        // Source
        self.buffer = RETAIN(data);
        self.cursor = 0;

        // Init instance variables
        self->deserData =
                (void *) [self.buffer methodForSelector:@selector(deserializeDataAt:ofObjCType:atCursor:context:)];
        self->getData =
                (void *) [self.buffer methodForSelector:@selector(deserializeBytes:length:atCursor:)];
    }

    // Done
    return self;
}

// ----------------------------------------------------------------------------

- (instancetype)init {
    return [self initForReadingWithData:[NSData data]];
}

// ----------------------------------------------------------------------------

+ (id)unarchiveObjectWithData:(NSData *)data {

    OSUnarchiver *unarchiver = [[self alloc] initForReadingWithData:data];
    id object = [unarchiver decodeObject];

    RELEASE(unarchiver);

    // Done
    return object;
}

// ----------------------------------------------------------------------------

+ (id)unarchiveObjectWithFile:(NSString *)path {

    NSData *data = [NSData dataWithContentsOfFile:path];

    if (data == nil) {
        return nil;
    }

    // Done
    return [self unarchiveObjectWithData:data];
}

// ----------------------------------------------------------------------------

+ (NSString *)classNameDecodedForArchiveClassName:(NSString *)nameInArchive {

    NSString *className = NSMapGet(_classToAliasMappings, nameInArchive);
    return (className ? className : nameInArchive);
}

// ----------------------------------------------------------------------------

+ (void)decodeClassName:(NSString *)nameInArchive asClassName:(NSString *)trueName {
    NSMapInsert(_classToAliasMappings, nameInArchive, trueName);
}

// ----------------------------------------------------------------------------

- (NSString *)classNameDecodedForArchiveClassName:(NSString *)nameInArchive {

    NSString *className = NSMapGet(self.inClassAlias, nameInArchive);
    return (className ? className : nameInArchive);
}

// ----------------------------------------------------------------------------

- (void)decodeClassName:(NSString *)nameInArchive asClassName:(NSString *)trueName {
    NSMapInsert(self.inClassAlias, nameInArchive, trueName);
}

// ----------------------------------------------------------------------------

// - (void)replaceObject:(id)object withObject:(id)newObject {
//     NSLog(@"-[%@ %s] unimplemented in %s at %d", [self class], sel_getName(_cmd), __FILE__, __LINE__);
// }

// ----------------------------------------------------------------------------

- (void)dealloc {

    if (self.buffer) {
        RELEASE(self.buffer);
        self.buffer = nil;
    }

    if (self.inObjects) {
        NSFreeMapTable(self.inObjects);
        self.inObjects = nil;
    }

    if (self.inClasses) {
        NSFreeMapTable(self.inClasses);
        self.inClasses = nil;
    }

    if (self.inPointers) {
        NSFreeMapTable(self.inPointers);
        self.inPointers = nil;
    }

    if (self.inClassAlias) {
        NSFreeMapTable(self.inClassAlias);
        self.inClassAlias = nil;
    }

    if (self.inClassVersions) {
        NSFreeMapTable(self.inClassVersions);
        self.inClassVersions = nil;
    }

    [super dealloc];
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
        [self __beginDecoding];
    }

    //NGLogT(@"decoder", @"cursor is now %i", self->cursor);

    tag         = [self readTag];
    isReference = isReferenceTag(tag);
    tag         = tagValue(tag);

    switch (tag) {
        case _C_ID:
            _checkType2(*_type, _C_ID, _C_CLASS);
            *(id *)_value = [self __decodeObject:isReference];
            break;
        case _C_CLASS:
            _checkType2(*_type, _C_ID, _C_CLASS);
            *(Class *)_value = [self __decodeClass:isReference];
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
        [self __endDecoding];
        self.decodingRoot = NO;
    }
}

// ----------------------------------------------------------------------------

- (NSInteger)versionForClassName:(NSString *)className {

    id version = NSMapGet(self.inClassVersions, className);
    return (version ? [version integerValue] : NSNotFound);
}

// ----------------------------------------------------------------------------

- (id)decodeObject {

    id object = nil;

    // Decode object
    const char type[] = {_C_ID, 0};
    [self decodeValueOfObjCType:type at:&object];

    // Done
    return AUTORELEASE(object);
}

// ----------------------------------------------------------------------------

// - (id)decodeTopLevelObjectAndReturnError:(NSError **)error {
//     NSLog(@"-[%@ %s] unimplemented in %s at %d", [self class], sel_getName(_cmd), __FILE__, __LINE__);
// }

// ----------------------------------------------------------------------------

- (void)decodeValuesOfObjCTypes:(const char *)types, ... {

    va_list args;
    va_start(args, types);

    while (types && *types) {
        [self decodeValueOfObjCType:types at:va_arg(args, void *)];
        types = objc_skip_typespec(types);
    }

    va_end(args);
}

// ----------------------------------------------------------------------------

// TODO: Refactoring is required
- (void)decodeArrayOfObjCType:(const char *)itemType count:(NSUInteger)count at:(void *)array {

    BOOL      startedDecoding = NO;
    OSTagType tag    = [self readTag];
    int       length = [self readInt];

    if (self.decodingRoot == NO) {
        self.decodingRoot = YES;
        startedDecoding = YES;
        [self __beginDecoding];
    }

    NSAssert(tag == _C_ARY_B, @"invalid type ..");
    NSAssert(count == length, @"invalid array size ..");

    // Arrays of elementary types are written optimized: the type is written
    // then the elements of array follow.
    if ((*itemType == _C_ID) || (*itemType == _C_CLASS)) { // object array
        int i;

        tag = [self readTag]; // object array
        NSAssert(tag == *itemType, @"invalid array element type ..");

        for (i = 0; i < count; i++)
            ((id *)array)[i] = [self decodeObject];
    }
    else if ((*itemType == _C_CHR) || (*itemType == _C_UCHR)) { // byte array
        tag = [self readTag];
        NSAssert((tag == _C_CHR) || (tag == _C_UCHR), @"invalid byte array type ..");

        // read buffer
        [self readBytes:array length:count];
    }
    else if (isBaseType(itemType)) {
        unsigned offset, itemSize = objc_sizeof_type(itemType);
        int      i;

        tag = [self readTag];
        NSAssert(tag == *itemType, @"invalid array base type ..");

        for (i = offset = 0; i < count; i++, offset += itemSize)
            _readObjC(self, (char *)array + offset, itemType);
    }
    else {
        IMP      decodeValue = NULL;
        unsigned offset, itemSize = objc_sizeof_type(itemType);
        int      i;

        decodeValue = [self methodForSelector:@selector(decodeValueOfObjCType:at:)];

        for (i = offset = 0; i < length; i++, offset += itemSize) {
            [self decodeValueOfObjCType:itemType at:(char *)array + offset];
        }
    }

    if (startedDecoding) {
        [self __endDecoding];
        self.decodingRoot = NO;
    }
}

// ----------------------------------------------------------------------------

- (void *)decodeBytesWithReturnedLength:(NSUInteger *)lengthp {

    NSUInteger length = [self readUnsignedInteger];
    void *bytes = nil;

    if (length > 0) {
        bytes = (void *) ((Byte *) self.buffer.bytes + self.cursor);
        self.cursor += length;
    }

    if (lengthp != nil) {
        *lengthp = length;
    }

    // Done
    return bytes;
}

// ----------------------------------------------------------------------------
#pragma mark - @protocol OSObjCTypeSerializationCallBack
// ----------------------------------------------------------------------------

- (void)serializeObjectAt:(id *)object ofObjCType:(const char *)type intoData:(NSMutableData *)data {
    [self doesNotRecognizeSelector:_cmd];
}

// ----------------------------------------------------------------------------

// TODO: Refactoring is required
- (void)deserializeObjectAt:(id *)object ofObjCType:(const char *)type fromData:(NSData *)data atCursor:(unsigned int *)cursor  {

    OSTagType tag             = 0;
    BOOL      isReference     = NO;

    tag         = [self readTag];
    isReference = isReferenceTag(tag);
    tag         = tagValue(tag);

    NSCAssert((*type == _C_ID) || (*type == _C_CLASS), @"Unexpected type.");

    switch (*type) {
        case _C_ID:
            NSAssert((*type == _C_ID) || (*type == _C_CLASS), @"Invalid type.");
            *object = [self __decodeObject:isReference];
            break;
        case _C_CLASS:
            NSAssert((*type == _C_ID) || (*type == _C_CLASS), @"Invalid type.");
            *object = [self __decodeClass:isReference];
            break;

        default:
            [NSException raise:OSInconsistentArchiveException format:@"Encountered type '%s' in object context", type];
            break;
    }
}

// ----------------------------------------------------------------------------
#pragma mark - Protected Methods
// ----------------------------------------------------------------------------

- (void)__beginDecoding {
    [self __readArchiveHeader];
}

// ----------------------------------------------------------------------------

- (void)__endDecoding {
    self.decodingRoot = NO;
}

// ----------------------------------------------------------------------------

- (void)__readArchiveHeader {

    if (self.didReadHeader == NO) {
        self.didReadHeader = YES;

        // Read archive header
        NSString *signature = [self readStringWithTag:NO];
        self.systemVersion = [self readUnsignedShort];

        if (![signature isEqualToString:OSCoderSignature]) {
            NSLog(@"WARNING: Used a different archiver (signature %@:%i).",
                    signature, [self systemVersion]);
        }
        else if ([self systemVersion] != OSCoderVersion) {
            NSLog(@"WARNING: Used a different archiver version (archiver=%i, unarchiver=%i).",
                    [self systemVersion], OSCoderVersion);
        }
    }
}

// ----------------------------------------------------------------------------

- (Class)__decodeClass:(BOOL)isReference {

    OSIdType archiveId = [self readUnsignedInteger];
    Class clazz = Nil;

    // Nil class or unused conditional class
    if (archiveId == 0) {
        return nil;
    }

    if (isReference) {
        NSAssert(archiveId, @"archiveId is 0!");

        clazz = (Class) NSMapGet(self.inClasses, (void *) (OSIdType) archiveId);
        if (clazz == nil) {
            clazz = (Class) NSMapGet(self.inObjects, (void *) (OSIdType) archiveId);
        }

        if (clazz == nil) {
            [NSException raise:OSInconsistentArchiveException format:@"Did not find referenced class %lu.", (unsigned long) archiveId];
        }
    }
    else {

        NSString *name = [self readStringWithTag:NO];
        if (name == nil) {
            [NSException raise:OSInconsistentArchiveException format:@"Could not decode class name."];
        }

        NSInteger version = [self readInteger];
        NSMapInsert(self.inClassVersions, name, @(version));

        { // check whether the class is to be replaced
            NSString *newName = NSMapGet(self.inClassAlias, name);

            if (newName) {
                name = newName;
            }
            else {
                newName = NSMapGet(_classToAliasMappings, name);
                if (newName) {
                    name = newName;
                }
            }
        }

        clazz = NSClassFromString(name);

        if (clazz == Nil) {
            [NSException raise:OSInconsistentArchiveException format:@"Class doesn't exist in this runtime."];
        }

        if ([clazz version] != version) {
            [NSException raise:OSInconsistentArchiveException format:@"Class versions do not match."];
        }

        NSMapInsert(self.inClasses, (void *) (OSIdType) archiveId, clazz);
    }

    NSAssert(clazz, @"Invalid state, class is Nil.");

    // Done
    return clazz;
}

// ----------------------------------------------------------------------------

// TODO: Refactoring is required
- (id)__decodeObject:(BOOL)isReference {

    // This method returns a retained object!
    int archiveId = [self readInt];
    id result = nil;

    // Nil object or unused conditional object
    if (archiveId == 0) {
        return nil;
    }

    if (isReference) {
        NSAssert(archiveId, @"archiveId is 0!");

        result = (id) NSMapGet(self.inObjects, (void *) (OSIdType) archiveId);
        if (result == nil) {
            result = (id) NSMapGet(self.inClasses, (void *) (OSIdType) archiveId);
        }

        if (result == nil) {
            [NSException raise:OSInconsistentArchiveException format:@"Did not find referenced object %i.", archiveId];
        }
        result = RETAIN(result);
    }
    else {
        Class class = Nil;
        id replacement = nil;

        // decode class info
        [self decodeValueOfObjCType:"#" at:&class];
        NSAssert(class, @"Could not decode class for object.");

        result = [class allocWithZone:NSDefaultMallocZone()];
        NSMapInsert(self.inObjects, (void *) (OSIdType) archiveId, result);

        replacement = [result initWithCoder:self];
        if (replacement != result) {

            replacement = RETAIN(replacement);
            NSMapRemove(self.inObjects, (void *) (OSIdType) archiveId);
            result = replacement;
            NSMapInsert(self.inObjects, (void *) (OSIdType) archiveId, result);
            RELEASE(replacement);
        }

        replacement = [result awakeAfterUsingCoder:self];
        if (replacement != result) {

            replacement = RETAIN(replacement);
            NSMapRemove(self.inObjects, (void *) (OSIdType) archiveId);
            result = replacement;
            NSMapInsert(self.inObjects, (void *) (OSIdType) archiveId, result);
            RELEASE(replacement);
        }
    }

    if (object_is_instance(result)) {
        NSAssert3([result retainCount] > 0,
                @"Invalid retain count %i for id=%i (%@).",
                (unsigned) [result retainCount],
                archiveId,
                NSStringFromClass([result class]));
    }

    return result;
}

// ----------------------------------------------------------------------------
#pragma mark -
// ----------------------------------------------------------------------------

// ******************** primitive decoding ********************

FINAL char *_readCString(OSUnarchiver *self);
FINAL void _readObjC(OSUnarchiver *self, void *_value, const char *_type);

// ******************** complex decoding **********************

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

// ******************** primitive decoding ********************

FINAL char *_readCString(OSUnarchiver *self)
{
    unsigned int position = (unsigned int) self.cursor;
    char *value = NULL;
//  self->deserData(self.buffer,
//                  @selector(deserializeDataAt:ofObjCType:atCursor:context:),
//                  &value, @encode(char *), &(position), self);
    [self.buffer deserializeDataAt:&value ofObjCType:@encode(char *) atCursor:&(position) context:self];
    self.cursor = position;
    return value;
}

FINAL void _readObjC(OSUnarchiver *self, void *_value, const char *_type)
{
    unsigned int position = (unsigned int) self.cursor;
//  self->deserData(self.buffer,
//                  @selector(deserializeDataAt:ofObjCType:atCursor:context:),
//                  _value, _type, &(position), self);
    [self.buffer deserializeDataAt:_value ofObjCType:_type atCursor:&(position) context:self];
    self.cursor = position;
}

// ----------------------------------------------------------------------------

@end /* OSUnarchiver */

// ----------------------------------------------------------------------------
