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

#import "objc-runtime.h"

#import "OSArchiver.h"
#import "OSArchiver+Encoding.h"

#import "OSEncoding.h"
#import "OSMemory.h"
#import "OSUtilities.h"
#import "NSMutableData+OpenStep.h"

// ----------------------------------------------------------------------------

#define FINAL static inline

static NSMapTableKeyCallBacks NSIdentityObjectMapKeyCallbacks = {
  (unsigned(*)(NSMapTable *, const void *))          __NSHashPointer,
  (BOOL(*)(NSMapTable *, const void *, const void *))__NSComparePointers,
  (void (*)(NSMapTable *, const void *anObject))     __NSRetainObjects,
  (void (*)(NSMapTable *, void *anObject))           __NSReleaseObjects,
  (NSString *(*)(NSMapTable *, const void *))        __NSDescribePointers,
  (const void *)NULL
};

// ----------------------------------------------------------------------------

NSString *const OSCoderSignature = @"roxie:stc";

UInt16 OSCoderVersion = 1909; // 2019-09

// ----------------------------------------------------------------------------

@interface OSArchiver ()

// - Properties

// Caches
@property(nonatomic, strong) NSHashTable *outObjects;       // Objects written so far
@property(nonatomic, strong) NSHashTable *outConditionals;  // Conditional objects
@property(nonatomic, strong) NSHashTable *outPointers;      // Set of pointers
@property(nonatomic, strong) NSMapTable  *outClassAlias;    // Class name -> Archive name
@property(nonatomic, strong) NSMapTable  *replacements;     // Src-object to replacement
@property(nonatomic, strong) NSMapTable  *outKeys;          // Src-address -> Archive-address

// Destination
@property(nonatomic, strong) NSMutableData *buffer;
@property(nonatomic, assign) OSIndexType archiveAddress;

// Flags
@property(nonatomic, assign) BOOL traceMode;                // YES if finding conditionals
@property(nonatomic, assign) BOOL didWriteHeader;
@property(nonatomic, assign) BOOL encodingRoot;

// --

@end

// ----------------------------------------------------------------------------
#pragma mark - Private Functions
// ----------------------------------------------------------------------------

static BOOL __isBaseType(const char *type) {

    // @formatter:off
    OSTagType tag = (OSTagType) (*type);
    switch (tag) {

        case _C_CHR:     case _C_UCHR:
        case _C_SHT:     case _C_USHT:
        case _C_INT:     case _C_UINT:
        case _C_LNG:     case _C_ULNG:
        case _C_LNG_LNG: case _C_ULNG_LNG:
        case _C_FLT:     case _C_DBL: {
            return YES;
        }

        default: {
            return NO;
        }
    }
    // @formatter:on
}

// ----------------------------------------------------------------------------

static BOOL __isCollectable(id object) {

    // @formatter:off
    return (object_is_class(object) ||
            [object isKindOfClass:[NSString class]] ||
            [object isKindOfClass:[NSNumber class]] ||
            [object isKindOfClass:[NSData   class]] ||
            [object isKindOfClass:[NSNull   class]] ||
            [object isKindOfClass:[NSValue  class]]);
    // @formatter:on
}

// ----------------------------------------------------------------------------
#pragma mark -
// ----------------------------------------------------------------------------

@implementation OSArchiver

// ----------------------------------------------------------------------------
#pragma mark - Properties
// ----------------------------------------------------------------------------

@dynamic archiverData;

// ----------------------------------------------------------------------------

- (NSMutableData *)archiverData {
    return self.buffer;
}

// ----------------------------------------------------------------------------
#pragma mark - Methods
// ----------------------------------------------------------------------------

- (instancetype)initForWritingWithMutableData:(NSMutableData *)data {

    // Validate incoming params
    if (data == nil) {
        return nil;
    }

    // Init instance
    if (self = [super init]) {

        // Caches
        self.outObjects      = NSCreateHashTable(NSNonOwnedPointerHashCallBacks, 119);
        self.outConditionals = NSCreateHashTable(NSNonOwnedPointerHashCallBacks, 119);
        self.outPointers     = NSCreateHashTable(NSNonOwnedPointerHashCallBacks, 0);
        self.replacements    = NSCreateMapTable(NSIdentityObjectMapKeyCallbacks, NSObjectMapValueCallBacks, 19);
        self.outClassAlias   = NSCreateMapTable(NSObjectMapKeyCallBacks, NSObjectMapValueCallBacks, 19);
        self.outKeys         = NSCreateMapTable(NSObjectMapKeyCallBacks, NSIntMapValueCallBacks, 119);

// FIXME: Uncomment!
//        // Caches
//        self.outObjects      = [NSHashTable hashTableWithOptions:NSHashTableStrongMemory];
//        self.outConditionals = [NSHashTable hashTableWithOptions:NSHashTableStrongMemory];
//        self.outPointers     = [NSHashTable hashTableWithOptions:NSHashTableStrongMemory];
//        self.outClassAlias   = [NSMapTable strongToStrongObjectsMapTable];
//        self.replacements    = [NSMapTable strongToStrongObjectsMapTable];
//        self.outKeys         = [NSMapTable strongToStrongObjectsMapTable];

        // Destination
        self.buffer = RETAIN(data);
        self.archiveAddress = 1;
    }

    // Done
    return self;
}

// ----------------------------------------------------------------------------

- (instancetype)init {
    return [self initForWritingWithMutableData:[NSMutableData data]];
}

// ----------------------------------------------------------------------------

+ (NSData *)archivedDataWithRootObject:(id)rootObject {

    OSArchiver *archiver = AUTORELEASE([self new]);
    NSData *data = nil;

    [archiver encodeRootObject:rootObject];
    data = [archiver.buffer copy];

    // Done
    return AUTORELEASE(data);
}

// ----------------------------------------------------------------------------

+ (BOOL)archiveRootObject:(id)rootObject toFile:(NSString *)path {

    NSData *data = [self archivedDataWithRootObject:rootObject];
    return [data writeToFile:path atomically:YES];
}

// ----------------------------------------------------------------------------

- (NSString *)classNameEncodedForTrueClassName:(NSString *)trueName {

    NSString *className = NSMapGet(self.outClassAlias, trueName);
    return (className ? className : trueName);
}

// ----------------------------------------------------------------------------

- (void)encodeClassName:(NSString *)trueName intoClassName:(NSString *)inArchiveName {
    NSMapInsert(self.outClassAlias, trueName, inArchiveName);
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

    if (self.outKeys) {
        NSFreeMapTable(self.outKeys);
        self.outKeys = nil;
    }

    if (self.outObjects) {
        NSFreeHashTable(self.outObjects);
        self.outObjects = nil;
    }

    if (self.outConditionals) {
        NSFreeHashTable(self.outConditionals);
        self.outConditionals = nil;
    }

    if (self.outPointers) {
        NSFreeHashTable(self.outPointers);
        self.outPointers = nil;
    }

    if (self.replacements) {
        NSFreeMapTable(self.replacements);
        self.replacements = nil;
    }

    if (self.outClassAlias) {
        NSFreeMapTable(self.outClassAlias);
        self.outClassAlias = nil;
    }

    [super dealloc];
}

// ----------------------------------------------------------------------------
#pragma mark - @interface NSCoder
// ----------------------------------------------------------------------------

- (void)encodeValueOfObjCType:(const char *)type at:(const void *)addr {

    if (self.traceMode) {
        [self __traceValueOfObjCType:type at:addr];
    }
    else {

        if (self.didWriteHeader == NO) {
            [self __writeArchiveHeader];
        }
        [self __encodeValueOfObjCType:type at:addr];
    }
}

// ----------------------------------------------------------------------------

- (void)encodeDataObject:(NSData *)data {

    if (self.traceMode == NO) {
        [self encodeBytes:data.bytes length:data.length];
    }
}

// ----------------------------------------------------------------------------

- (void)encodeObject:(id)object {

    if (self.encodingRoot) {

        const char type[] = {(OSTagType) (object_is_instance(object) ? _C_ID : _C_CLASS), 0};
        [self encodeValueOfObjCType:type at:&object];
    }
    else {
        [self encodeRootObject:object];
    }
}

// ----------------------------------------------------------------------------

- (void)encodeRootObject:(id)rootObject
{
    @autoreleasepool {

        [self __beginEncoding];

        @try {

            /*
             * Prepare for writing the graph objects for which `rootObject' is the root
             * node. The algorithm consists from two passes. In the first pass it
             * determines the nodes so-called 'conditionals' - the nodes encoded *only*
             * with -encodeConditionalObject:. They represent nodes that are not
             * related directly to the graph. In the second pass objects are encoded
             * normally, except for the conditional objects which are encoded as Nil.
             */

            // Pass 1: Start tracing for conditionals
            [self __traceObjectsWithRoot:rootObject];

            // Pass 2: Start writing
            [self __writeArchiveHeader];
            [self __encodeObjectsWithRoot:rootObject];
            [self __writeArchiveTrailer];
        }
        @catch (NSException *exception) {

            // Release resources
            [self __endEncoding];

            // Re-throw exception
            [exception raise];
        }

        // Release resources
        [self __endEncoding];
    }
}

// ----------------------------------------------------------------------------

// - (void)encodeBycopyObject:(id)anObject {
//     NSLog(@"-[%@ %s] unimplemented in %s at %d", [self class], sel_getName(_cmd), __FILE__, __LINE__);
// }

// ----------------------------------------------------------------------------

// - (void)encodeByrefObject:(id)anObject {
//     NSLog(@"-[%@ %s] unimplemented in %s at %d", [self class], sel_getName(_cmd), __FILE__, __LINE__);
// }

// ----------------------------------------------------------------------------

- (void)encodeConditionalObject:(id)object {

    // Pass 1: Start tracing for conditionals
    if (self.traceMode) {

        /*
         * This is the first pass of the determining the conditionals
         * algorithm. We traverse the graph and insert into the `conditionals'
         * set. In the second pass all objects that are still in this set will
         * be encoded as Nil when they receive -encodeConditionalObject:. An
         * object is removed from this set when it receives -encodeObject:.
         */

        if (object) {

            if (NSHashGet(self.outObjects, object)) {
                // Object isn't conditional any more (was stored using encodeObject:)
            }
            else if (NSHashGet(self.outConditionals, object)) {
                // Object is already stored as conditional
            }
            else {
                // Insert object in conditionals set
                NSHashInsert(self.outConditionals, object);
            }
        }
    }
    // Pass 2: Start writing
    else {

        BOOL isConditional = (NSHashGet(self.outConditionals, object) != nil);

        // If anObject is still in the ‘conditionals’ set, it is encoded as Nil.
        [self encodeObject:(isConditional ? nil : object)];
    }
}

// ----------------------------------------------------------------------------

- (void)encodeValuesOfObjCTypes:(const char *)types, ... {

    va_list args;
    va_start(args, types);

    while (types && *types) {
        [self encodeValueOfObjCType:types at:va_arg(args, void *)];
        types = objc_skip_typespec(types);
    }

    va_end(args);
}

// ----------------------------------------------------------------------------

- (void)encodeArrayOfObjCType:(const char *)type count:(NSUInteger)count at:(const void *)array {

    if ((self.didWriteHeader == NO) && (self.traceMode == NO)) {
        [self __writeArchiveHeader];
    }

    // Array header
    if (self.traceMode == NO) { // Nothing is written during trace-mode
        [self writeTag:_C_ARY_B];
        [self writeInt:(int) count];
    }

    // Optimize writing arrays of elementary types. If such an array has to
    // be written, write the type and then the elements of array.

    // Object array
    if ((*type == _C_ID) || (*type == _C_CLASS)) {

        if (self.traceMode == NO) {
            [self writeTag:*type];
        }

        for (int idx = 0; idx < count; idx++) {
            [self encodeObject:((id *) array)[idx]];
        }
    }
    // Byte array
    else if ((*type == _C_CHR) || (*type == _C_UCHR)) {

        if (self.traceMode == NO) {

            // Write base type tag
            [self writeTag:*type];

            // Write buffer
            [self writeBytes:array length:count];
        }
    }
    // Basic type
    else if (__isBaseType(type)) {

        if (self.traceMode == NO) {

            int itemSize = objc_sizeof_type(type);

            // Write base type tag
            [self writeTag:*type];

            // Write contents
            for (int idx = 0, offset = 0; idx < count; idx++, offset += itemSize) {
                _writeObjC(self, ((char *) array + offset), type);

// FIXME: Uncomment!
//                [self encodeValueOfObjCType:type at:((char *) array + offset)];
            }
        }
    }
    // Encoded using normal method
    else {

        int itemSize = objc_sizeof_type(type);
        for (int idx = 0, offset = 0; idx < count; idx++, offset += itemSize) {
            [self encodeValueOfObjCType:type at:((char *) array + offset)];
        }
    }
}

// ----------------------------------------------------------------------------

- (void)encodeBytes:(const void *)byteaddr length:(NSUInteger)length {

    if (self.traceMode == NO) {
        [self writeUnsignedInteger:length];
        [self writeBytes:byteaddr length:length];
    }
}

// ----------------------------------------------------------------------------
#pragma mark - @protocol OSObjCTypeSerializationCallBack
// ----------------------------------------------------------------------------

- (void)serializeObjectAt:(id *)object ofObjCType:(const char *)type intoData:(NSMutableData *)data {
    NSAssert((*type == _C_ID) || (*type == _C_CLASS), @"Unexpected type.");

    if (self.traceMode) {
        [self __traceObject:*object];
    }
    else {
        [self __encodeObject:*object];
    }
}

// ----------------------------------------------------------------------------

- (void)deserializeObjectAt:(id *)object ofObjCType:(const char *)type fromData:(NSData *)data atCursor:(unsigned int *)cursor {
    [self doesNotRecognizeSelector:_cmd];
}

// ----------------------------------------------------------------------------
#pragma mark - Protected Methods
// ----------------------------------------------------------------------------

- (void)__beginEncoding {

    self.traceMode = NO;
    self.encodingRoot = YES;
}

// ----------------------------------------------------------------------------

- (void)__endEncoding {

    self.traceMode = NO;
    self.encodingRoot = NO;
}

// ----------------------------------------------------------------------------

- (void)__writeArchiveHeader {

    if (self.didWriteHeader == NO) {
        self.didWriteHeader = YES;

        // Write archive header
        [self writeString:OSCoderSignature withTag:NO];
        [self writeUnsignedShort:OSCoderVersion];
    }
}

// ----------------------------------------------------------------------------

- (void)__writeArchiveTrailer {
    // Do nothing
}

// ----------------------------------------------------------------------------

- (void)__traceObject:(id)object {

    // Don't trace nil objects
    if (object == nil) {
        return;
    }

    if (NSHashGet(self.outObjects, object) == nil) {

        // Object wasn't traced yet.

        // Look-up the object in the `conditionals' set. If the object is
        // there, then remove it because it is no longer a conditional one.
        if (NSHashGet(self.outConditionals, object)) {

            // Object was marked conditional
            NSHashRemove(self.outConditionals, object);
        }

        // Mark object as traced
        NSHashInsert(self.outObjects, object);

        if (object_is_instance(object)) {

            id replacement = [object replacementObjectForCoder:self];
            if (replacement != object) {

                NSMapInsert(self.replacements, object, replacement);
                object = replacement;
            }

            Class archiveClass = Nil;
            if (object_is_instance(object)) {

                archiveClass = [object classForCoder];
            }

            [self encodeObject:archiveClass];
            [object encodeWithCoder:self];
        }
        else {
            // There are no class-variables
        }
    }
}

// ----------------------------------------------------------------------------

- (void)__traceObjectsWithRoot:(id)rootObject {

    // Pass 1: Start tracing for conditionals
    @try {

        self.traceMode = YES;
        [self encodeObject:rootObject];
    }
    @catch (NSException *exception) {

        self.traceMode = NO;
        NSResetHashTable(self.outObjects);

        // Re-throw exception
        [exception raise];
    }

    self.traceMode = NO;
    NSResetHashTable(self.outObjects);
}

// ----------------------------------------------------------------------------

- (void)__traceValueOfObjCType:(const char *)type at:(const void *)byteaddr {

    switch (*type) {

        case _C_ID:
        case _C_CLASS: {
            [self __traceObject:*(id *) byteaddr];
            break;
        }

        case _C_ARY_B: {

            const char *itemType = type;
            while (isdigit((int) *(++itemType))); // Skip dimension

            int count = atoi(type + 1); // eg '[15I' => count = 15
            [self encodeArrayOfObjCType:itemType count:count at:byteaddr];

            break;
        }

        case _C_STRUCT_B: { // C-structure begin '{'

            while ((*type != _C_STRUCT_E) && (*(type++) != '=')) {
                // Skip "<name>="
            }

            int offset = 0;
            while (YES) {

                [self encodeValueOfObjCType:type at:((char *) byteaddr) + offset];

                offset += objc_sizeof_type(type);
                type = objc_skip_typespec(type);

                if (*type != _C_STRUCT_E) { // C-structure end '}'
                    int align, remainder;

                    align = objc_alignof_type(type);
                    if ((remainder = offset % align)) {
                        offset += (align - remainder);
                    }
                }
                else {
                    break;
                }
            }
            break;
        }

        default: {
            // Do nothing
        }
    }
}

// ----------------------------------------------------------------------------

- (void)__encodeObject:(id)object {

    OSIndexType archiveId = [self __archiveIdOfObject:object];
    if (object == nil) {

        OSTagType tag = _C_ID;

        // Nil object or class
        [self writeTag:tag | REFERENCE];
        [self writeUnsignedInteger:archiveId];

        return;
    }

    BOOL isCollectable = __isCollectable(object);
    @autoreleasepool {

        OSTagType tag = (OSTagType) (object_is_instance(object) ? _C_ID : _C_CLASS);
        if (isCollectable && NSHashGet(self.outObjects, object)) {

            // Object was already written
            [self writeTag:tag | REFERENCE];
            [self writeUnsignedInteger:archiveId];
        }
        else {

            // Mark object as written
            if (isCollectable) {
                NSHashInsert(self.outObjects, object);
            }

            [self writeTag:tag];
            [self writeUnsignedInteger:archiveId];

            // A class object
            if (tag == _C_CLASS) {

                NSString *className = NSStringFromClass(object);
                className = [self classNameEncodedForTrueClassName:className];

                [self writeString:className withTag:NO];
                [self writeInteger:[object version]];
            }
            else {

                id replacement = NSMapGet(self.replacements, object) ?: [object replacementObjectForCoder:self];
                if (replacement != nil) {
                    object = replacement;
                }

                Class archiveClass = [object classForCoder];
                NSAssert(archiveClass, @"No archive class found.");

                [self encodeObject:archiveClass];
                [object encodeWithCoder:self];
            }
        }
    }
}

// ----------------------------------------------------------------------------

- (void)__encodeObjectsWithRoot:(id)rootObject {

    // Pass 2: Start writing
    [self encodeObject:rootObject];
}

// ----------------------------------------------------------------------------

// TODO: Refactoring is required
- (void)__encodeValueOfObjCType:(const char *)type at:(const void *)addr {

    OSTagType tag = (OSTagType) (*type);
    switch (tag) {

        case _C_ID:
        case _C_CLASS: {

            // ?? Write another tag just to be possible to read using the
            // ?? decodeObject method. (Otherwise a lookahead would be required)
            // ?? [self writeTag:*type];

            [self __encodeObject:*((id *) addr)];
            break;
        }

        case _C_ARY_B: {
            int count = atoi(type + 1); // eg '[15I' => count = 15
            const char *itemType = type;

            while (isdigit((int) *(++itemType))); // skip dimension

            // Write another tag just to be possible to read using the
            // decodeArrayOfObjCType:count:at: method.
            [self writeTag:_C_ARY_B];
            [self encodeArrayOfObjCType:itemType count:count at:addr];
            break;
        }

        case _C_STRUCT_B: { // C-structure begin '{'
            int offset = 0;

            [self writeTag:'{'];

            while ((*type != _C_STRUCT_E) && (*type++ != '=')); // skip "<name>="

            while (YES) {
                [self encodeValueOfObjCType:type at:((char *) addr) + offset];

                offset += objc_sizeof_type(type);
                type = objc_skip_typespec(type);

                if (*type != _C_STRUCT_E) { // C-structure end '}'
                    int align, remainder;

                    align = objc_alignof_type(type);
                    if ((remainder = offset % align)) {
                        offset += (align - remainder);
                    }
                }
                else {
                    break;
                }
            }
            break;
        }

        case _C_SEL:
            [self writeTag:_C_SEL];
            _writeCString(self, (*(SEL *) addr) ? sel_get_name(*(SEL *) addr) : NULL);
            break;

        case _C_PTR:
            [self writeTag:*type];
            _writeObjC(self, *(char **) addr, type + 1);
            break;

        case _C_CHARPTR:
        case _C_CHR:     case _C_UCHR:
        case _C_SHT:     case _C_USHT:
        case _C_INT:     case _C_UINT:
        case _C_LNG:     case _C_ULNG:
        case _C_LNG_LNG: case _C_ULNG_LNG:
        case _C_FLT:     case _C_DBL: {
            [self writeTag:*type];
            _writeObjC(self, addr, type);
            break;
        }

        default:
            NSLog(@"Unsupported C type %s.", type);
            break;
    }
}

// ----------------------------------------------------------------------------

- (OSIndexType)__archiveIdOfObject:(id)object {

    if (object == nil) {
        return 0;
    }

    OSIndexType archiveId = 0;

    // Look-up for an index of equivalent object
    if (__isCollectable(object)) {

        archiveId = (OSIndexType) NSMapGet(self.outKeys, object);
        if (archiveId == 0) {

            archiveId = (OSIndexType) self.archiveAddress++;
            NSMapInsert(self.outKeys, object, (void *) (OSIndexType) archiveId);
        }
    }
    else {
        archiveId = (OSIndexType) self.archiveAddress++;
    }

    // Done
    return archiveId;
}

// ----------------------------------------------------------------------------

- (OSIndexType)__archiveIdOfClass:(Class)clazz {
    return [self __archiveIdOfObject:clazz];
}

// ----------------------------------------------------------------------------

// ******************** primitive encoding ********************

FINAL void _writeCString(OSArchiver *self, const char *_value);
FINAL void _writeObjC(OSArchiver *self, const void *_value, const char *_type);

// ******************** primitive encoding ********************

FINAL void _writeCString(OSArchiver *self, const char *_value)
{
//  self->serData(self.buffer, @selector(serializeDataAt:ofObjCType:context:),
//                &_value, @encode(char *), self);
    [self.buffer serializeDataAt:&_value ofObjCType:@encode(char *) context:self];
}

FINAL void _writeObjC(OSArchiver *self, const void *_value, const char *_type)
{
    if ((_value == NULL) || (_type == NULL))
        return;

    if (self.traceMode) {
        // no need to track base-types in trace-mode
    
        switch (*_type) {
            case _C_ID:
            case _C_CLASS:
            case _C_CHARPTR:
            case _C_ARY_B:
            case _C_STRUCT_B:
            case _C_PTR:
//              self->serData(self.buffer, @selector(serializeDataAt:ofObjCType:context:),
//                            _value, _type, self);
                [self.buffer serializeDataAt:_value ofObjCType:_type context:self];
                break;

            default:
                break;
        }
    }
    else {
//      self->serData(self.buffer, @selector(serializeDataAt:ofObjCType:context:),
//                    _value, _type, self);
        [self.buffer serializeDataAt:_value ofObjCType:_type context:self];
    }
}

// ----------------------------------------------------------------------------

@end /* OSArchiver */

// ----------------------------------------------------------------------------
