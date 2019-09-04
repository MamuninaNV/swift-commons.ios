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
#import "common.h"

#import "OSArchiver.h"
#import "OSArchiver+Encoding.h"

#import "OSUtilities.h"
#import "NSData+OpenStep.h"

// ----------------------------------------------------------------------------

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
@property(nonatomic, strong) NSMutableData *data;
@property(nonatomic, assign) NSUInteger archiveAddress;

// Flags
@property(nonatomic, assign) BOOL traceMode;                // YES if finding conditionals
@property(nonatomic, assign) BOOL didWriteHeader;
@property(nonatomic, assign) BOOL encodingRoot;

// --

@end

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
    return self.data;
}

// ----------------------------------------------------------------------------
#pragma mark - Methods
// ----------------------------------------------------------------------------

- (instancetype)initForWritingWithMutableData:(NSMutableData *)mdata {

    // Validate incoming params
    if (mdata == nil) {
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
        self.data = RETAIN(mdata);
        self.archiveAddress = 1;

        // Init instance variables
        self->classForCoder =
                @selector(classForCoder);
        self->replObjectForCoder =
                @selector(replacementObjectForCoder:);

        self->serData =
                (void *) [self.data methodForSelector:@selector(serializeDataAt:ofObjCType:context:)];
        self->addData =
                (void *) [self.data methodForSelector:@selector(appendBytes:length:)];
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
    NSData *rdata = nil;

    [archiver encodeRootObject:rootObject];
    rdata = [archiver.data copy];

    // Done
    return AUTORELEASE(rdata);
}

// ----------------------------------------------------------------------------

+ (BOOL)archiveRootObject:(id)rootObject toFile:(NSString *)path {

    NSData *rdata = [self archivedDataWithRootObject:rootObject];
    return [rdata writeToFile:path atomically:YES];
}

// ----------------------------------------------------------------------------

- (NSString *)classNameEncodedForTrueClassName:(NSString *)trueName {

    NSString *name = NSMapGet(self.outClassAlias, trueName);
    return (name ? name : trueName);
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

    if (self.data) {
        RELEASE(self.data);
    }

    if (self.outKeys) {
        NSFreeMapTable(self.outKeys);
    }

    if (self.outObjects) {
        NSFreeHashTable(self.outObjects);
    }

    if (self.outConditionals) {
        NSFreeHashTable(self.outConditionals);
    }

    if (self.outPointers) {
        NSFreeHashTable(self.outPointers);
    }

    if (self.replacements) {
        NSFreeMapTable(self.replacements);
    }

    if (self.outClassAlias) {
        NSFreeMapTable(self.outClassAlias);
    }

    [super dealloc];
}

// ----------------------------------------------------------------------------
#pragma mark - @interface NSCoder
// ----------------------------------------------------------------------------

- (void)encodeValueOfObjCType:(const char *)type at:(const void *)addr {

    if (self.traceMode) {
        [self _traceValueOfObjCType:type at:addr];
    }
    else {

        if (self.didWriteHeader == NO) {
            [self __writeArchiveHeader];
        }
        [self _encodeValueOfObjCType:type at:addr];
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

        const char type[] = {(const char) (object_is_instance(object) ? _C_ID : _C_CLASS), 0};
        [self encodeValueOfObjCType:type at:&object];
    }
    else {
        [self encodeRootObject:object];
    }
}

// ----------------------------------------------------------------------------

- (void)encodeRootObject:(id)rootObject {
    NSAutoreleasePool *pool = [[NSAutoreleasePool allocWithZone:[self zone]] init];

    [self __beginEncoding];

    NS_DURING {

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
        [self encodeObjectsWithRoot:rootObject];
        [self __writeArchiveTrailer];
    }
    NS_HANDLER {

        // Release resources
        [self __endEncoding];

        // Re-throw exception
        [localException raise];
    }
    NS_ENDHANDLER;

    // Release resources
    [self __endEncoding];

    RELEASE(pool);
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
    // Pass2: Start writing
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

// TODO: Refactoring is required
- (void)encodeArrayOfObjCType:(const char *)type count:(NSUInteger)count at:(const void *)array {

    if ((self.didWriteHeader == NO) && (self.traceMode == NO)) {
        [self __writeArchiveHeader];
    }

    // array header
    if (self.traceMode == NO) { // nothing is written during trace-mode
        [self writeTag:_C_ARY_B];
        [self writeInt:count];
    }

    // Optimize writing arrays of elementary types. If such an array has to
    // be written, write the type and then the elements of array.

    if ((*type == _C_ID) || (*type == _C_CLASS)) { // object array
        int i;

        if (self.traceMode == NO)
            [self writeTag:*type]; // object array

        for (i = 0; i < count; i++)
            [self encodeObject:((id *)array)[i]];
    }
    else if ((*type == _C_CHR) || (*type == _C_UCHR)) { // byte array
        if (self.traceMode == NO) {
            //NGLogT(@"encoder", @"encode byte-array (base='%c', count=%i)", *_type, _count);

            // write base type tag
            [self writeTag:*type];

            // write buffer
            [self writeBytes:array length:count];
        }
    }
    else if (isBaseType(type)) {
        if (self.traceMode == NO) {
            unsigned offset, itemSize = objc_sizeof_type(type);
            int      i;

            /*
              NGLogT(@"encoder",
              @"encode basetype-array (base='%c', itemSize=%i, count=%i)",
              *_type, itemSize, _count);
              */

            // write base type tag
            [self writeTag:*type];

            // write contents
            for (i = offset = 0; i < count; i++, offset += itemSize)
                _writeObjC(self, (char *)array + offset, type);
        }
    }
    else { // encoded using normal method
        IMP      encodeValue = NULL;
        unsigned offset, itemSize = objc_sizeof_type(type);
        int      i;

        encodeValue = [self methodForSelector:@selector(encodeValueOfObjCType:at:)];

        for (i = offset = 0; i < count; i++, offset += itemSize) {
//             encodeValue(self, @selector(encodeValueOfObjCType:at:),
//                         (char *)_array + offset, _type);
            [self encodeValueOfObjCType:type at:(char *)array + offset];
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

- (void)__traceObjectsWithRoot:(id)rootObject {

    // Pass 1: Start tracing for conditionals
    NS_DURING {

        self.traceMode = YES;
        [self encodeObject:rootObject];
    }
    NS_HANDLER {

        self.traceMode = NO;
        NSResetHashTable(self.outObjects);

        // Re-throw exception
        [localException raise];
    }
    NS_ENDHANDLER;

    self.traceMode = NO;
    NSResetHashTable(self.outObjects);
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

// ******************** archive id's **************************

FINAL int _archiveIdOfObject(OSArchiver *self, id _object)
{
    if (_object == nil) {
        return 0;
    }
#if 0 /* this does not work with 64bit */
    else
        return (int)_object;
#else
    else {
        int archiveId;

        archiveId = (long)NSMapGet(self.outKeys, _object);
        if (archiveId == 0) {
            archiveId = self.archiveAddress;
            NSMapInsert(self.outKeys, _object, (void*)(long)archiveId);
#if ARCHIVE_DEBUGGING
            NSLog(@"mapped 0x%p => %i", _object, archiveId);
#endif
            self.archiveAddress++;
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

FINAL void _writeCString(OSArchiver *self, const char *_value);
FINAL void _writeObjC(OSArchiver *self, const void *_value, const char *_type);

// ******************** complex encoding **********************

- (void)encodeObjectsWithRoot:(id)_root
{
    // encoding pass 2
    [self encodeObject:_root];
}

- (void)_traceObject:(id)_object
{
    if (_object == nil) // don't trace nil objects ..
        return;

    //NSLog(@"lookup 0x%p in outObjs=0x%p", _object, self.outObjects);
    
    if (NSHashGet(self.outObjects, _object) == nil) {
        //NSLog(@"lookup failed, object wasn't traced yet !");
        
        // object wasn't traced yet
        // Look-up the object in the `conditionals' set. If the object is
        // there, then remove it because it is no longer a conditional one.
        if (NSHashGet(self.outConditionals, _object)) {
            // object was marked conditional ..
            NSHashRemove(self.outConditionals, _object);
        }
        
        // mark object as traced
        NSHashInsert(self.outObjects, _object);
        
        if (object_is_instance(_object)) {
            Class archiveClass = Nil;
            id    replacement  = nil;
            
            replacement = [_object performSelector:self->replObjectForCoder
                                   withObject:self];
            
            if (replacement != _object) {
                NSMapInsert(self.replacements, _object, replacement);
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
    OSTagType tag;
    int       archiveId = _archiveIdOfObject(self, _object);

    if (_object == nil) { // nil object or class
        [self writeTag:_C_ID | REFERENCE];
        [self writeInt:archiveId];
        return;
    }
    
    tag = object_is_instance(_object) ? _C_ID : _C_CLASS;
    
    if (NSHashGet(self.outObjects, _object)) { // object was already written
        [self writeTag:tag | REFERENCE];
        [self writeInt:archiveId];
    }
    else {
        // mark object as written
        NSHashInsert(self.outObjects, _object);

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
    
        [self writeTag:tag];
        [self writeInt:archiveId];

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
            [self writeLong:[_object version]];
            if (buf) free(buf);
        }
        else {
            Class archiveClass = Nil;
            id    replacement  = nil;

            replacement = NSMapGet(self.replacements, _object);
            if (replacement) _object = replacement;

            /*
              _object = [_object performSelector:self.replObjectForCoder
              withObject:self];
            */
            archiveClass = [_object performSelector:self->classForCoder];
            
            NSAssert(archiveClass, @"no archive class found ..");

            [self encodeObject:archiveClass];
            [_object encodeWithCoder:self];
        }
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
    //       _type, [self.data length]);
  
    switch (*_type) {
        case _C_ID:
        case _C_CLASS:
            // ?? Write another tag just to be possible to read using the
            // ?? decodeObject method. (Otherwise a lookahead would be required)
            // ?? [self writeTag:*_type];
            [self _encodeObject:*(id *)_value];
            break;

        case _C_ARY_B: {
            int        count     = atoi(_type + 1); // eg '[15I' => count = 15
            const char *itemType = _type;

            while(isdigit((int)*(++itemType))) ; // skip dimension

            // Write another tag just to be possible to read using the
            // decodeArrayOfObjCType:count:at: method.
            [self writeTag:_C_ARY_B];
            [self encodeArrayOfObjCType:itemType count:count at:_value];
            break;
        }

        case _C_STRUCT_B: { // C-structure begin '{'
            int offset = 0;

            [self writeTag:'{'];

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
            [self writeTag:_C_SEL];
            _writeCString(self, (*(SEL *)_value) ? sel_get_name(*(SEL *)_value) : NULL);
            break;
      
        case _C_PTR:
            [self writeTag:*_type];
            _writeObjC(self, *(char **)_value, _type + 1);
            break;

        case _C_CHARPTR:
        case _C_CHR:     case _C_UCHR:
        case _C_SHT:     case _C_USHT:
        case _C_INT:     case _C_UINT:
        case _C_LNG:     case _C_ULNG:
        case _C_LNG_LNG: case _C_ULNG_LNG:
        case _C_FLT:     case _C_DBL:
            [self writeTag:*_type];
            _writeObjC(self, _value, _type);
            break;
      
        default:
            NSLog(@"unsupported C type %s ..", _type);
            break;
    }
}

// ******************** primitive encoding ********************

FINAL void _writeCString(OSArchiver *self, const char *_value)
{
    self->serData(self.data, @selector(serializeDataAt:ofObjCType:context:),
                  &_value, @encode(char *), self);
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
                self->serData(self.data, @selector(serializeDataAt:ofObjCType:context:),
                              _value, _type, self);
                break;

            default:
                break;
        }
    }
    else {
        self->serData(self.data, @selector(serializeDataAt:ofObjCType:context:),
                      _value, _type, self);
    }
}

// OSObjCTypeSerializationCallBack

- (void)serializeObjectAt:(id *)_object
               ofObjCType:(const char *)_type
                 intoData:(NSMutableData *)_data
{
    NSAssert(((*_type == _C_ID) || (*_type == _C_CLASS)), @"unexpected type ..");

    if (self.traceMode)
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
