const headerquickjs = "quickjs/quickjs.h"

{.passC: "-DCONFIG_VERSION=\"\"".}
{.passL: "-lm -lpthread".}
{.compile: "quickjs/quickjs.c".}
{.compile: "quickjs/cutils.c".}
{.compile: "quickjs/libregexp.c".}
{.compile: "quickjs/libunicode.c".}
##
##  QuickJS Javascript Engine
##
##  Copyright (c) 2017-2019 Fabrice Bellard
##  Copyright (c) 2017-2019 Charlie Gordon
##
##  Permission is hereby granted, free of charge, to any person obtaining a copy
##  of this software and associated documentation files (the "Software"), to deal
##  in the Software without restriction, including without limitation the rights
##  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
##  copies of the Software, and to permit persons to whom the Software is
##  furnished to do so, subject to the following conditions:
##
##  The above copyright notice and this permission notice shall be included in
##  all copies or substantial portions of the Software.
##
##  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
##  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
##  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
##  THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
##  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
##  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
##  THE SOFTWARE.
##

const
  QUICKJS_H* = true

type
  JSRuntime* = object
  JSContext* = object
  JSObject* = object
  JSClass* = object
  JSModuleDef* = object

type
  JSClassID* = uint32
  JSAtom* = uint32

template JS_PTR64_DEF*(a: untyped): void =
  nil

const
  JS_NAN_BOXING* = true

const                         ##  all tags with a reference count are negative
  JS_TAG_FIRST* = -10           ##  first negative tag
  JS_TAG_BIG_INT* = -10
  JS_TAG_BIG_FLOAT* = -9
  JS_TAG_SYMBOL* = -8
  JS_TAG_STRING* = -7
  JS_TAG_SHAPE* = -6            ##  used internally during GC
  JS_TAG_ASYNC_FUNCTION* = -5   ##  used internally during GC
  JS_TAG_VAR_REF* = -4          ##  used internally during GC
  JS_TAG_MODULE* = -3           ##  used internally
  JS_TAG_FUNCTION_BYTECODE* = -2 ##  used internally
  JS_TAG_OBJECT* = -1
  JS_TAG_INT* = 0
  JS_TAG_BOOL* = 1
  JS_TAG_NULL* = 2
  JS_TAG_UNDEFINED* = 3
  JS_TAG_UNINITIALIZED* = 4
  JS_TAG_CATCH_OFFSET* = 5
  JS_TAG_EXCEPTION* = 6
  JS_TAG_FLOAT64* = 7           ##  any larger tag is FLOAT64 if JS_NAN_BOXING

type
  JSRefCountHeader* {.importc: "JSRefCountHeader", header: headerquickjs, bycopy.} = object
    ref_count* {.importc: "ref_count".}: cint


type
  JSValue* = uint64

template JS_VALUE_GET_TAG*(v: untyped): untyped =
  (int)((v) shr 32)

template JS_VALUE_GET_INT*(v: untyped): untyped =
  (int)(v)

template JS_VALUE_GET_BOOL*(v: untyped): untyped =
  (int)(v)

template JS_VALUE_GET_PTR*(v: untyped): untyped =
  cast[pointer]((ptr int)(v))

template JS_MKVAL*(tag, val: untyped): untyped =
  (((uint64)(tag) shl 32) or (uint32)(val))

template JS_MKPTR*(tag, `ptr`: untyped): untyped =
  (((uint64)(tag) shl 32) or (ptr uint)(`ptr`))

const
  JS_FLOAT64_TAG_ADDEND* = (0x00000000 - JS_TAG_FIRST + 1) ##  quiet NaN encoding

proc JS_VALUE_GET_FLOAT64*(v: JSValue): cdouble {.importc: "JS_VALUE_GET_FLOAT64",
    header: headerquickjs.}

template JS_TAG_IS_FLOAT64*(tag: untyped): untyped =
  ((unsigned)((tag) - JS_TAG_FIRST) >= (JS_TAG_FLOAT64 - JS_TAG_FIRST))

##  same as JS_VALUE_GET_TAG, but return JS_TAG_FLOAT64 with NaN boxing

proc JS_VALUE_GET_NORM_TAG*(v: JSValue): cint {.importc: "JS_VALUE_GET_NORM_TAG",
    header: headerquickjs.}

template JS_VALUE_IS_BOTH_INT*(v1, v2: untyped): untyped =
  ((JS_VALUE_GET_TAG(v1) or JS_VALUE_GET_TAG(v2)) == 0)

template JS_VALUE_IS_BOTH_FLOAT*(v1, v2: untyped): untyped =
  (JS_TAG_IS_FLOAT64(JS_VALUE_GET_TAG(v1)) and
      JS_TAG_IS_FLOAT64(JS_VALUE_GET_TAG(v2)))

template JS_VALUE_GET_OBJ*(v: untyped): untyped =
  (cast[ptr JSObject](JS_VALUE_GET_PTR(v)))

template JS_VALUE_GET_STRING*(v: untyped): untyped =
  (cast[ptr JSString](JS_VALUE_GET_PTR(v)))

template JS_VALUE_HAS_REF_COUNT*(v: untyped): untyped =
  (cast[cuint](JS_VALUE_GET_TAG(v)) >= cast[cuint](JS_TAG_FIRST))

##  special values

const
  JS_NULL* = JS_MKVAL(JS_TAG_NULL, 0)
  JS_UNDEFINED* = JS_MKVAL(JS_TAG_UNDEFINED, 0)
  JS_FALSE* = JS_MKVAL(JS_TAG_BOOL, 0)
  JS_TRUE* = JS_MKVAL(JS_TAG_BOOL, 1)
  JS_EXCEPTION* = JS_MKVAL(JS_TAG_EXCEPTION, 0)
  JS_UNINITIALIZED* = JS_MKVAL(JS_TAG_UNINITIALIZED, 0)

##  flags for object properties

const
  JS_PROP_CONFIGURABLE* = (1 shl 0)
  JS_PROP_WRITABLE* = (1 shl 1)
  JS_PROP_ENUMERABLE* = (1 shl 2)
  JS_PROP_C_W_E* = (JS_PROP_CONFIGURABLE or JS_PROP_WRITABLE or JS_PROP_ENUMERABLE)
  JS_PROP_LENGTH* = (1 shl 3)     ##  used internally in Arrays
  JS_PROP_TMASK* = (3 shl 4)      ##  mask for NORMAL, GETSET, VARREF, AUTOINIT
  JS_PROP_NORMAL* = (0 shl 4)
  JS_PROP_GETSET* = (1 shl 4)
  JS_PROP_VARREF* = (2 shl 4)     ##  used internally
  JS_PROP_AUTOINIT* = (3 shl 4)   ##  used internally

##  flags for JS_DefineProperty

const
  JS_PROP_HAS_SHIFT* = 8
  JS_PROP_HAS_CONFIGURABLE* = (1 shl 8)
  JS_PROP_HAS_WRITABLE* = (1 shl 9)
  JS_PROP_HAS_ENUMERABLE* = (1 shl 10)
  JS_PROP_HAS_GET* = (1 shl 11)
  JS_PROP_HAS_SET* = (1 shl 12)
  JS_PROP_HAS_VALUE* = (1 shl 13)

##  throw an exception if false would be returned
##    (JS_DefineProperty/JS_SetProperty)

const
  JS_PROP_THROW* = (1 shl 14)

##  throw an exception if false would be returned in strict mode
##    (JS_SetProperty)

const
  JS_PROP_THROW_STRICT* = (1 shl 15)
  JS_PROP_NO_ADD* = (1 shl 16)    ##  internal use
  JS_PROP_NO_EXOTIC* = (1 shl 17) ##  internal use
  JS_DEFAULT_STACK_SIZE* = (256 * 1024)

##  JS_Eval() flags

const
  JS_EVAL_TYPE_GLOBAL* = (0 shl 0) ##  global code (default)
  JS_EVAL_TYPE_MODULE* = (1 shl 0) ##  module code
  JS_EVAL_TYPE_DIRECT* = (2 shl 0) ##  direct call (internal use)
  JS_EVAL_TYPE_INDIRECT* = (3 shl 0) ##  indirect call (internal use)
  JS_EVAL_TYPE_MASK* = (3 shl 0)
  JS_EVAL_FLAG_SHEBANG* = (1 shl 2) ##  skip first line beginning with '#!'
  JS_EVAL_FLAG_STRICT* = (1 shl 3) ##  force 'strict' mode
  JS_EVAL_FLAG_STRIP* = (1 shl 4) ##  force 'strip' mode
  JS_EVAL_FLAG_COMPILE_ONLY* = (1 shl 5) ##  internal use

type
  JSCFunction* = proc (ctx: ptr JSContext; this_val: JSValue; argc: cint;
                    argv: ptr JSValue): JSValue
  JSCFunctionMagic* = proc (ctx: ptr JSContext; this_val: JSValue; argc: cint;
                         argv: ptr JSValue; magic: cint): JSValue
  JSCFunctionData* = proc (ctx: ptr JSContext; this_val: JSValue; argc: cint;
                        argv: ptr JSValue; magic: cint; func_data: ptr JSValue): JSValue
  JSMallocState* {.importc: "JSMallocState", header: headerquickjs, bycopy.} = object
    malloc_count* {.importc: "malloc_count".}: csize
    malloc_size* {.importc: "malloc_size".}: csize
    malloc_limit* {.importc: "malloc_limit".}: csize
    opaque* {.importc: "opaque".}: pointer ##  user opaque

  JSMallocFunctions* {.importc: "JSMallocFunctions", header: headerquickjs, bycopy.} = object
    js_malloc* {.importc: "js_malloc".}: proc (s: ptr JSMallocState; size: csize): pointer
    js_free* {.importc: "js_free".}: proc (s: ptr JSMallocState; `ptr`: pointer)
    js_realloc* {.importc: "js_realloc".}: proc (s: ptr JSMallocState; `ptr`: pointer;
        size: csize): pointer
    js_malloc_usable_size* {.importc: "js_malloc_usable_size".}: proc (
        `ptr`: pointer): csize


proc JS_NewRuntime*(): ptr JSRuntime {.importc: "JS_NewRuntime", header: headerquickjs.}
##  info lifetime must exceed that of rt

proc JS_SetRuntimeInfo*(rt: ptr JSRuntime; info: cstring) {.
    importc: "JS_SetRuntimeInfo", header: headerquickjs.}
proc JS_SetMemoryLimit*(rt: ptr JSRuntime; limit: csize) {.
    importc: "JS_SetMemoryLimit", header: headerquickjs.}
proc JS_SetGCThreshold*(rt: ptr JSRuntime; gc_threshold: csize) {.
    importc: "JS_SetGCThreshold", header: headerquickjs.}
proc JS_NewRuntime2*(mf: ptr JSMallocFunctions; opaque: pointer): ptr JSRuntime {.
    importc: "JS_NewRuntime2", header: headerquickjs.}
proc JS_FreeRuntime*(rt: ptr JSRuntime) {.importc: "JS_FreeRuntime",
                                      header: headerquickjs.}
type
  JS_MarkFunc* = proc (rt: ptr JSRuntime; val: JSValue): void

proc JS_MarkValue*(rt: ptr JSRuntime; val: JSValue; mark_func: ptr JS_MarkFunc) {.
    importc: "JS_MarkValue", header: headerquickjs.}
proc JS_RunGC*(rt: ptr JSRuntime) {.importc: "JS_RunGC", header: headerquickjs.}
proc JS_IsLiveObject*(rt: ptr JSRuntime; obj: JSValue): cint {.
    importc: "JS_IsLiveObject", header: headerquickjs.}
proc JS_IsInGCSweep*(rt: ptr JSRuntime): cint {.importc: "JS_IsInGCSweep",
    header: headerquickjs.}
proc JS_NewContext*(rt: ptr JSRuntime): ptr JSContext {.importc: "JS_NewContext",
    header: headerquickjs.}
proc JS_FreeContext*(s: ptr JSContext) {.importc: "JS_FreeContext",
                                     header: headerquickjs.}
proc JS_GetContextOpaque*(ctx: ptr JSContext): pointer {.
    importc: "JS_GetContextOpaque", header: headerquickjs.}
proc JS_SetContextOpaque*(ctx: ptr JSContext; opaque: pointer) {.
    importc: "JS_SetContextOpaque", header: headerquickjs.}
proc JS_GetRuntime*(ctx: ptr JSContext): ptr JSRuntime {.importc: "JS_GetRuntime",
    header: headerquickjs.}
proc JS_SetMaxStackSize*(ctx: ptr JSContext; stack_size: csize) {.
    importc: "JS_SetMaxStackSize", header: headerquickjs.}
proc JS_SetClassProto*(ctx: ptr JSContext; class_id: JSClassID; obj: JSValue) {.
    importc: "JS_SetClassProto", header: headerquickjs.}
proc JS_GetClassProto*(ctx: ptr JSContext; class_id: JSClassID): JSValue {.
    importc: "JS_GetClassProto", header: headerquickjs.}
##  the following functions are used to select the intrinsic object to
##    save memory

proc JS_NewContextRaw*(rt: ptr JSRuntime): ptr JSContext {.
    importc: "JS_NewContextRaw", header: headerquickjs.}
proc JS_AddIntrinsicBaseObjects*(ctx: ptr JSContext) {.
    importc: "JS_AddIntrinsicBaseObjects", header: headerquickjs.}
proc JS_AddIntrinsicDate*(ctx: ptr JSContext) {.importc: "JS_AddIntrinsicDate",
    header: headerquickjs.}
proc JS_AddIntrinsicEval*(ctx: ptr JSContext) {.importc: "JS_AddIntrinsicEval",
    header: headerquickjs.}
proc JS_AddIntrinsicStringNormalize*(ctx: ptr JSContext) {.
    importc: "JS_AddIntrinsicStringNormalize", header: headerquickjs.}
proc JS_AddIntrinsicRegExpCompiler*(ctx: ptr JSContext) {.
    importc: "JS_AddIntrinsicRegExpCompiler", header: headerquickjs.}
proc JS_AddIntrinsicRegExp*(ctx: ptr JSContext) {.importc: "JS_AddIntrinsicRegExp",
    header: headerquickjs.}
proc JS_AddIntrinsicJSON*(ctx: ptr JSContext) {.importc: "JS_AddIntrinsicJSON",
    header: headerquickjs.}
proc JS_AddIntrinsicProxy*(ctx: ptr JSContext) {.importc: "JS_AddIntrinsicProxy",
    header: headerquickjs.}
proc JS_AddIntrinsicMapSet*(ctx: ptr JSContext) {.importc: "JS_AddIntrinsicMapSet",
    header: headerquickjs.}
proc JS_AddIntrinsicTypedArrays*(ctx: ptr JSContext) {.
    importc: "JS_AddIntrinsicTypedArrays", header: headerquickjs.}
proc JS_AddIntrinsicPromise*(ctx: ptr JSContext) {.
    importc: "JS_AddIntrinsicPromise", header: headerquickjs.}
proc js_string_codePointRange*(ctx: ptr JSContext; this_val: JSValue; argc: cint;
                              argv: ptr JSValue): JSValue {.
    importc: "js_string_codePointRange", header: headerquickjs.}
proc js_malloc_rt*(rt: ptr JSRuntime; size: csize): pointer {.importc: "js_malloc_rt",
    header: headerquickjs.}
proc js_free_rt*(rt: ptr JSRuntime; `ptr`: pointer) {.importc: "js_free_rt",
    header: headerquickjs.}
proc js_realloc_rt*(rt: ptr JSRuntime; `ptr`: pointer; size: csize): pointer {.
    importc: "js_realloc_rt", header: headerquickjs.}
proc js_malloc_usable_size_rt*(rt: ptr JSRuntime; `ptr`: pointer): csize {.
    importc: "js_malloc_usable_size_rt", header: headerquickjs.}
proc js_mallocz_rt*(rt: ptr JSRuntime; size: csize): pointer {.
    importc: "js_mallocz_rt", header: headerquickjs.}
proc js_malloc*(ctx: ptr JSContext; size: csize): pointer {.importc: "js_malloc",
    header: headerquickjs.}
proc js_free*(ctx: ptr JSContext; `ptr`: pointer) {.importc: "js_free",
    header: headerquickjs.}
proc js_realloc*(ctx: ptr JSContext; `ptr`: pointer; size: csize): pointer {.
    importc: "js_realloc", header: headerquickjs.}
proc js_malloc_usable_size*(ctx: ptr JSContext; `ptr`: pointer): csize {.
    importc: "js_malloc_usable_size", header: headerquickjs.}
proc js_realloc2*(ctx: ptr JSContext; `ptr`: pointer; size: csize; pslack: ptr csize): pointer {.
    importc: "js_realloc2", header: headerquickjs.}
proc js_mallocz*(ctx: ptr JSContext; size: csize): pointer {.importc: "js_mallocz",
    header: headerquickjs.}
proc js_strdup*(ctx: ptr JSContext; str: cstring): cstring {.importc: "js_strdup",
    header: headerquickjs.}
proc js_strndup*(ctx: ptr JSContext; s: cstring; n: csize): cstring {.
    importc: "js_strndup", header: headerquickjs.}
type
  JSMemoryUsage* {.importc: "JSMemoryUsage", header: headerquickjs, bycopy.} = object
    malloc_size* {.importc: "malloc_size".}: int64
    malloc_limit* {.importc: "malloc_limit".}: int64
    memory_used_size* {.importc: "memory_used_size".}: int64
    malloc_count* {.importc: "malloc_count".}: int64
    memory_used_count* {.importc: "memory_used_count".}: int64
    atom_count* {.importc: "atom_count".}: int64
    atom_size* {.importc: "atom_size".}: int64
    str_count* {.importc: "str_count".}: int64
    str_size* {.importc: "str_size".}: int64
    obj_count* {.importc: "obj_count".}: int64
    obj_size* {.importc: "obj_size".}: int64
    prop_count* {.importc: "prop_count".}: int64
    prop_size* {.importc: "prop_size".}: int64
    shape_count* {.importc: "shape_count".}: int64
    shape_size* {.importc: "shape_size".}: int64
    js_func_count* {.importc: "js_func_count".}: int64
    js_func_size* {.importc: "js_func_size".}: int64
    js_func_code_size* {.importc: "js_func_code_size".}: int64
    js_func_pc2line_count* {.importc: "js_func_pc2line_count".}: int64
    js_func_pc2line_size* {.importc: "js_func_pc2line_size".}: int64
    c_func_count* {.importc: "c_func_count".}: int64
    array_count* {.importc: "array_count".}: int64
    fast_array_count* {.importc: "fast_array_count".}: int64
    fast_array_elements* {.importc: "fast_array_elements".}: int64
    binary_object_count* {.importc: "binary_object_count".}: int64
    binary_object_size* {.importc: "binary_object_size".}: int64


proc JS_ComputeMemoryUsage*(rt: ptr JSRuntime; s: ptr JSMemoryUsage) {.
    importc: "JS_ComputeMemoryUsage", header: headerquickjs.}
proc JS_DumpMemoryUsage*(fp: ptr FILE; s: ptr JSMemoryUsage; rt: ptr JSRuntime) {.
    importc: "JS_DumpMemoryUsage", header: headerquickjs.}
##  atom support

proc JS_NewAtomLen*(ctx: ptr JSContext; str: cstring; len: cint): JSAtom {.
    importc: "JS_NewAtomLen", header: headerquickjs.}
proc JS_NewAtom*(ctx: ptr JSContext; str: cstring): JSAtom {.importc: "JS_NewAtom",
    header: headerquickjs.}
proc JS_NewAtomUInt32*(ctx: ptr JSContext; n: uint32): JSAtom {.
    importc: "JS_NewAtomUInt32", header: headerquickjs.}
proc JS_DupAtom*(ctx: ptr JSContext; v: JSAtom): JSAtom {.importc: "JS_DupAtom",
    header: headerquickjs.}
proc JS_FreeAtom*(ctx: ptr JSContext; v: JSAtom) {.importc: "JS_FreeAtom",
    header: headerquickjs.}
proc JS_FreeAtomRT*(rt: ptr JSRuntime; v: JSAtom) {.importc: "JS_FreeAtomRT",
    header: headerquickjs.}
proc JS_AtomToValue*(ctx: ptr JSContext; atom: JSAtom): JSValue {.
    importc: "JS_AtomToValue", header: headerquickjs.}
proc JS_AtomToString*(ctx: ptr JSContext; atom: JSAtom): JSValue {.
    importc: "JS_AtomToString", header: headerquickjs.}
proc JS_AtomToCString*(ctx: ptr JSContext; atom: JSAtom): cstring {.
    importc: "JS_AtomToCString", header: headerquickjs.}
##  object class support

type
  JSPropertyEnum* {.importc: "JSPropertyEnum", header: headerquickjs, bycopy.} = object
    is_enumerable* {.importc: "is_enumerable".}: cint
    atom* {.importc: "atom".}: JSAtom

  JSPropertyDescriptor* {.importc: "JSPropertyDescriptor", header: headerquickjs,
                         bycopy.} = object
    flags* {.importc: "flags".}: cint
    value* {.importc: "value".}: JSValue
    getter* {.importc: "getter".}: JSValue
    setter* {.importc: "setter".}: JSValue

  JSClassExoticMethods* {.importc: "JSClassExoticMethods", header: headerquickjs,
                         bycopy.} = object
    get_own_property* {.importc: "get_own_property".}: proc (ctx: ptr JSContext;
        desc: ptr JSPropertyDescriptor; obj: JSValue; prop: JSAtom): cint ##  Return -1 if exception (can only happen in case of Proxy object),
                                                                  ##        FALSE if the property does not exists, TRUE if it exists. If 1 is
                                                                  ##        returned, the property descriptor 'desc' is filled if != NULL.
    ##  '*ptab' should hold the '*plen' property keys. Return 0 if OK,
    ##        -1 if exception. The 'is_enumerable' field is ignored.
    ##
    get_own_property_names* {.importc: "get_own_property_names".}: proc (
        ctx: ptr JSContext; ptab: ptr ptr JSPropertyEnum; plen: ptr uint32; obj: JSValue): cint ##  return < 0 if exception, or TRUE/FALSE
    delete_property* {.importc: "delete_property".}: proc (ctx: ptr JSContext;
        obj: JSValue; prop: JSAtom): cint ##  return < 0 if exception or TRUE/FALSE
    define_own_property* {.importc: "define_own_property".}: proc (
        ctx: ptr JSContext; this_obj: JSValue; prop: JSAtom; val: JSValue;
        getter: JSValue; setter: JSValue; flags: cint): cint ##  The following methods can be emulated with the previous ones,
                                                      ##        so they are usually not needed
                                                      ##  return < 0 if exception or TRUE/FALSE
    has_property* {.importc: "has_property".}: proc (ctx: ptr JSContext; obj: JSValue;
        atom: JSAtom): cint
    get_property* {.importc: "get_property".}: proc (ctx: ptr JSContext; obj: JSValue;
        atom: JSAtom; receiver: JSValue): JSValue ##  return < 0 if exception or TRUE/FALSE
    set_property* {.importc: "set_property".}: proc (ctx: ptr JSContext; obj: JSValue;
        atom: JSAtom; value: JSValue; receiver: JSValue; flags: cint): cint

  JSClassFinalizer* = proc (rt: ptr JSRuntime; val: JSValue): void
  JSClassGCMark* = proc (rt: ptr JSRuntime; val: JSValue; mark_func: ptr JS_MarkFunc): void
  JSClassCall* = proc (ctx: ptr JSContext; func_obj: JSValue; this_val: JSValue;
                    argc: cint; argv: ptr JSValue): JSValue
  JSClassDef* {.importc: "JSClassDef", header: headerquickjs, bycopy.} = object
    class_name* {.importc: "class_name".}: cstring
    finalizer* {.importc: "finalizer".}: ptr JSClassFinalizer
    gc_mark* {.importc: "gc_mark".}: ptr JSClassGCMark
    call* {.importc: "call".}: ptr JSClassCall ##  XXX: suppress this indirection ? It is here only to save memory
                                          ##        because only a few classes need these methods
    exotic* {.importc: "exotic".}: ptr JSClassExoticMethods


proc JS_NewClassID*(pclass_id: ptr JSClassID): JSClassID {.importc: "JS_NewClassID",
    header: headerquickjs.}
proc JS_NewClass*(rt: ptr JSRuntime; class_id: JSClassID; class_def: ptr JSClassDef): cint {.
    importc: "JS_NewClass", header: headerquickjs.}
proc JS_IsRegisteredClass*(rt: ptr JSRuntime; class_id: JSClassID): cint {.
    importc: "JS_IsRegisteredClass", header: headerquickjs.}
##  value handling

proc JS_NewBool*(ctx: ptr JSContext; val: cint): JSValue {.importc: "JS_NewBool",
    header: headerquickjs.}

proc JS_NewInt32*(ctx: ptr JSContext; val: int32): JSValue {.importc: "JS_NewInt32",
    header: headerquickjs.}

proc JS_NewCatchOffset*(ctx: ptr JSContext; val: int32): JSValue {.
    importc: "JS_NewCatchOffset", header: headerquickjs.}

proc JS_NewInt64*(ctx: ptr JSContext; v: int64): JSValue {.importc: "JS_NewInt64",
    header: headerquickjs.}
proc JS_NewFloat64*(ctx: ptr JSContext; d: cdouble): JSValue {.
    importc: "JS_NewFloat64", header: headerquickjs.}

proc JS_IsNumber*(v: JSValue): cint {.importc: "JS_IsNumber", header: headerquickjs.}
proc JS_IsInteger*(v: JSValue): cint {.importc: "JS_IsInteger", header: headerquickjs.}

proc JS_IsBigFloat*(v: JSValue): cint {.importc: "JS_IsBigFloat",
                                    header: headerquickjs.}

proc JS_IsBool*(v: JSValue): cint {.importc: "JS_IsBool", header: headerquickjs.}

proc JS_IsNull*(v: JSValue): cint {.importc: "JS_IsNull", header: headerquickjs.}

proc JS_IsUndefined*(v: JSValue): cint {.importc: "JS_IsUndefined",
                                     header: headerquickjs.}

proc JS_IsException*(v: JSValue): cint {.importc: "JS_IsException",
                                     header: headerquickjs.}

proc JS_IsUninitialized*(v: JSValue): cint {.importc: "JS_IsUninitialized",
    header: headerquickjs.}

proc JS_IsString*(v: JSValue): cint {.importc: "JS_IsString", header: headerquickjs.}

proc JS_IsSymbol*(v: JSValue): cint {.importc: "JS_IsSymbol", header: headerquickjs.}

proc JS_IsObject*(v: JSValue): cint {.importc: "JS_IsObject", header: headerquickjs.}

proc JS_Throw*(ctx: ptr JSContext; obj: JSValue): JSValue {.importc: "JS_Throw",
    header: headerquickjs.}
proc JS_GetException*(ctx: ptr JSContext): JSValue {.importc: "JS_GetException",
    header: headerquickjs.}
proc JS_IsError*(ctx: ptr JSContext; val: JSValue): cint {.importc: "JS_IsError",
    header: headerquickjs.}
proc JS_EnableIsErrorProperty*(ctx: ptr JSContext; enable: cint) {.
    importc: "JS_EnableIsErrorProperty", header: headerquickjs.}
proc JS_ResetUncatchableError*(ctx: ptr JSContext) {.
    importc: "JS_ResetUncatchableError", header: headerquickjs.}
proc JS_NewError*(ctx: ptr JSContext): JSValue {.importc: "JS_NewError",
    header: headerquickjs.}

proc JS_ThrowOutOfMemory*(ctx: ptr JSContext): JSValue {.
    importc: "JS_ThrowOutOfMemory", header: headerquickjs.}

proc JS_FreeValue*(ctx: ptr JSContext; v: JSValue) {.importc: "JS_FreeValue",
    header: headerquickjs.}

proc JS_FreeValueRT*(rt: ptr JSRuntime; v: JSValue) {.importc: "JS_FreeValueRT",
    header: headerquickjs.}

proc JS_DupValue*(ctx: ptr JSContext; v: JSValue): JSValue {.importc: "JS_DupValue",
    header: headerquickjs.}

proc JS_ToBool*(ctx: ptr JSContext; val: JSValue): cint {.importc: "JS_ToBool",
    header: headerquickjs.}

proc JS_ToInt32*(ctx: ptr JSContext; pres: ptr int32; val: JSValue): cint {.
    importc: "JS_ToInt32", header: headerquickjs.}
proc JS_ToUint32*(ctx: ptr JSContext; pres: ptr uint32; val: JSValue): cint {.inline.} =
  return JS_ToInt32(ctx, cast[ptr int32](pres), val)

proc JS_ToInt64*(ctx: ptr JSContext; pres: ptr int64; val: JSValue): cint {.
    importc: "JS_ToInt64", header: headerquickjs.}
proc JS_ToIndex*(ctx: ptr JSContext; plen: ptr uint64; val: JSValue): cint {.
    importc: "JS_ToIndex", header: headerquickjs.}
proc JS_ToFloat64*(ctx: ptr JSContext; pres: ptr cdouble; val: JSValue): cint {.
    importc: "JS_ToFloat64", header: headerquickjs.}
proc JS_NewStringLen*(ctx: ptr JSContext; str1: cstring; len1: cint): JSValue {.
    importc: "JS_NewStringLen", header: headerquickjs.}
proc JS_NewString*(ctx: ptr JSContext; str: cstring): JSValue {.
    importc: "JS_NewString", header: headerquickjs.}
proc JS_NewAtomString*(ctx: ptr JSContext; str: cstring): JSValue {.
    importc: "JS_NewAtomString", header: headerquickjs.}
proc JS_ToString*(ctx: ptr JSContext; val: JSValue): JSValue {.importc: "JS_ToString",
    header: headerquickjs.}
proc JS_ToPropertyKey*(ctx: ptr JSContext; val: JSValue): JSValue {.
    importc: "JS_ToPropertyKey", header: headerquickjs.}
proc JS_ToCStringLen*(ctx: ptr JSContext; plen: ptr cint; val1: JSValue; cesu8: cint): cstring {.
    importc: "JS_ToCStringLen", header: headerquickjs.}
proc JS_ToCString*(ctx: ptr JSContext; val1: JSValue): cstring {.
    importc: "JS_ToCString", header: headerquickjs.}

proc JS_FreeCString*(ctx: ptr JSContext; `ptr`: cstring) {.importc: "JS_FreeCString",
    header: headerquickjs.}
proc JS_NewObjectProtoClass*(ctx: ptr JSContext; proto: JSValue; class_id: JSClassID): JSValue {.
    importc: "JS_NewObjectProtoClass", header: headerquickjs.}
proc JS_NewObjectClass*(ctx: ptr JSContext; class_id: cint): JSValue {.
    importc: "JS_NewObjectClass", header: headerquickjs.}
proc JS_NewObjectProto*(ctx: ptr JSContext; proto: JSValue): JSValue {.
    importc: "JS_NewObjectProto", header: headerquickjs.}
proc JS_NewObject*(ctx: ptr JSContext): JSValue {.importc: "JS_NewObject",
    header: headerquickjs.}
proc JS_IsFunction*(ctx: ptr JSContext; val: JSValue): cint {.importc: "JS_IsFunction",
    header: headerquickjs.}
proc JS_IsConstructor*(ctx: ptr JSContext; val: JSValue): cint {.
    importc: "JS_IsConstructor", header: headerquickjs.}
proc JS_NewArray*(ctx: ptr JSContext): JSValue {.importc: "JS_NewArray",
    header: headerquickjs.}
proc JS_IsArray*(ctx: ptr JSContext; val: JSValue): cint {.importc: "JS_IsArray",
    header: headerquickjs.}
proc JS_GetPropertyInternal*(ctx: ptr JSContext; obj: JSValue; prop: JSAtom;
                            receiver: JSValue; throw_ref_error: cint): JSValue {.
    importc: "JS_GetPropertyInternal", header: headerquickjs.}
proc JS_GetProperty*(ctx: ptr JSContext; this_obj: JSValue; prop: JSAtom): JSValue {.
    importc: "JS_GetProperty", header: headerquickjs.}

proc JS_GetPropertyStr*(ctx: ptr JSContext; this_obj: JSValue; prop: cstring): JSValue {.
    importc: "JS_GetPropertyStr", header: headerquickjs.}
proc JS_GetPropertyUint32*(ctx: ptr JSContext; this_obj: JSValue; idx: uint32): JSValue {.
    importc: "JS_GetPropertyUint32", header: headerquickjs.}
proc JS_SetPropertyInternal*(ctx: ptr JSContext; this_obj: JSValue; prop: JSAtom;
                            val: JSValue; flags: cint): cint {.
    importc: "JS_SetPropertyInternal", header: headerquickjs.}
proc JS_SetProperty*(ctx: ptr JSContext; this_obj: JSValue; prop: JSAtom; val: JSValue): cint {.
    importc: "JS_SetProperty", header: headerquickjs.}

proc JS_SetPropertyUint32*(ctx: ptr JSContext; this_obj: JSValue; idx: uint32;
                          val: JSValue): cint {.importc: "JS_SetPropertyUint32",
    header: headerquickjs.}
proc JS_SetPropertyInt64*(ctx: ptr JSContext; this_obj: JSValue; idx: int64;
                         val: JSValue): cint {.importc: "JS_SetPropertyInt64",
    header: headerquickjs.}
proc JS_SetPropertyStr*(ctx: ptr JSContext; this_obj: JSValue; prop: cstring;
                       val: JSValue): cint {.importc: "JS_SetPropertyStr",
    header: headerquickjs.}
proc JS_HasProperty*(ctx: ptr JSContext; this_obj: JSValue; prop: JSAtom): cint {.
    importc: "JS_HasProperty", header: headerquickjs.}
proc JS_IsExtensible*(ctx: ptr JSContext; obj: JSValue): cint {.
    importc: "JS_IsExtensible", header: headerquickjs.}
proc JS_PreventExtensions*(ctx: ptr JSContext; obj: JSValue): cint {.
    importc: "JS_PreventExtensions", header: headerquickjs.}
proc JS_DeleteProperty*(ctx: ptr JSContext; obj: JSValue; prop: JSAtom; flags: cint): cint {.
    importc: "JS_DeleteProperty", header: headerquickjs.}
proc JS_SetPrototype*(ctx: ptr JSContext; obj: JSValue; proto_val: JSValue): cint {.
    importc: "JS_SetPrototype", header: headerquickjs.}
proc JS_GetPrototype*(ctx: ptr JSContext; val: JSValue): JSValue {.
    importc: "JS_GetPrototype", header: headerquickjs.}
proc JS_ParseJSON*(ctx: ptr JSContext; buf: cstring; buf_len: csize; filename: cstring): JSValue {.
    importc: "JS_ParseJSON", header: headerquickjs.}
proc JS_Call*(ctx: ptr JSContext; func_obj: JSValue; this_obj: JSValue; argc: cint;
             argv: ptr JSValue): JSValue {.importc: "JS_Call", header: headerquickjs.}
proc JS_Invoke*(ctx: ptr JSContext; this_val: JSValue; atom: JSAtom; argc: cint;
               argv: ptr JSValue): JSValue {.importc: "JS_Invoke",
    header: headerquickjs.}
proc JS_CallConstructor*(ctx: ptr JSContext; func_obj: JSValue; argc: cint;
                        argv: ptr JSValue): JSValue {.importc: "JS_CallConstructor",
    header: headerquickjs.}
proc JS_CallConstructor2*(ctx: ptr JSContext; func_obj: JSValue; new_target: JSValue;
                         argc: cint; argv: ptr JSValue): JSValue {.
    importc: "JS_CallConstructor2", header: headerquickjs.}
proc JS_Eval*(ctx: ptr JSContext; input: cstring; input_len: csize; filename: cstring;
             eval_flags: cint): JSValue {.importc: "JS_Eval", header: headerquickjs.}
const
  JS_EVAL_BINARY_LOAD_ONLY* = (1 shl 0) ##  only load the module

proc JS_EvalBinary*(ctx: ptr JSContext; buf: ptr uint8; buf_len: csize; flags: cint): JSValue {.
    importc: "JS_EvalBinary", header: headerquickjs.}
proc JS_GetGlobalObject*(ctx: ptr JSContext): JSValue {.
    importc: "JS_GetGlobalObject", header: headerquickjs.}
proc JS_IsInstanceOf*(ctx: ptr JSContext; val: JSValue; obj: JSValue): cint {.
    importc: "JS_IsInstanceOf", header: headerquickjs.}
proc JS_DefineProperty*(ctx: ptr JSContext; this_obj: JSValue; prop: JSAtom;
                       val: JSValue; getter: JSValue; setter: JSValue; flags: cint): cint {.
    importc: "JS_DefineProperty", header: headerquickjs.}
proc JS_DefinePropertyValue*(ctx: ptr JSContext; this_obj: JSValue; prop: JSAtom;
                            val: JSValue; flags: cint): cint {.
    importc: "JS_DefinePropertyValue", header: headerquickjs.}
proc JS_DefinePropertyValueUint32*(ctx: ptr JSContext; this_obj: JSValue;
                                  idx: uint32; val: JSValue; flags: cint): cint {.
    importc: "JS_DefinePropertyValueUint32", header: headerquickjs.}
proc JS_DefinePropertyValueStr*(ctx: ptr JSContext; this_obj: JSValue; prop: cstring;
                               val: JSValue; flags: cint): cint {.
    importc: "JS_DefinePropertyValueStr", header: headerquickjs.}
proc JS_DefinePropertyGetSet*(ctx: ptr JSContext; this_obj: JSValue; prop: JSAtom;
                             getter: JSValue; setter: JSValue; flags: cint): cint {.
    importc: "JS_DefinePropertyGetSet", header: headerquickjs.}
proc JS_SetOpaque*(obj: JSValue; opaque: pointer) {.importc: "JS_SetOpaque",
    header: headerquickjs.}
proc JS_GetOpaque*(obj: JSValue; class_id: JSClassID): pointer {.
    importc: "JS_GetOpaque", header: headerquickjs.}
proc JS_GetOpaque2*(ctx: ptr JSContext; obj: JSValue; class_id: JSClassID): pointer {.
    importc: "JS_GetOpaque2", header: headerquickjs.}
type
  JSFreeArrayBufferDataFunc* = proc (rt: ptr JSRuntime; opaque: pointer; `ptr`: pointer): void

proc JS_NewArrayBuffer*(ctx: ptr JSContext; buf: ptr uint8; len: csize;
                       free_func: ptr JSFreeArrayBufferDataFunc; opaque: pointer;
                       is_shared: cint): JSValue {.importc: "JS_NewArrayBuffer",
    header: headerquickjs.}
proc JS_NewArrayBufferCopy*(ctx: ptr JSContext; buf: ptr uint8; len: csize): JSValue {.
    importc: "JS_NewArrayBufferCopy", header: headerquickjs.}
proc JS_DetachArrayBuffer*(ctx: ptr JSContext; obj: JSValue) {.
    importc: "JS_DetachArrayBuffer", header: headerquickjs.}
proc JS_GetArrayBuffer*(ctx: ptr JSContext; psize: ptr csize; obj: JSValue): ptr uint8 {.
    importc: "JS_GetArrayBuffer", header: headerquickjs.}
##  return != 0 if the JS code needs to be interrupted

type
  JSInterruptHandler* = proc (rt: ptr JSRuntime; opaque: pointer): cint

proc JS_SetInterruptHandler*(rt: ptr JSRuntime; cb: ptr JSInterruptHandler;
                            opaque: pointer) {.importc: "JS_SetInterruptHandler",
    header: headerquickjs.}
##  if can_block is TRUE, Atomics.wait() can be used

proc JS_SetCanBlock*(rt: ptr JSRuntime; can_block: cint) {.importc: "JS_SetCanBlock",
    header: headerquickjs.}

##  return the module specifier (allocated with js_malloc()) or NULL if
##    exception

type
  JSModuleNormalizeFunc* = proc (ctx: ptr JSContext; module_base_name: cstring;
                              module_name: cstring; opaque: pointer): cstring
  JSModuleLoaderFunc* = proc (ctx: ptr JSContext; module_name: cstring; opaque: pointer): ptr JSModuleDef

##  module_normalize = NULL is allowed and invokes the default module
##    filename normalizer

proc JS_SetModuleLoaderFunc*(rt: ptr JSRuntime;
                            module_normalize: ptr JSModuleNormalizeFunc;
                            module_loader: ptr JSModuleLoaderFunc; opaque: pointer) {.
    importc: "JS_SetModuleLoaderFunc", header: headerquickjs.}
##  JS Job support

type
  JSJobFunc* = proc (ctx: ptr JSContext; argc: cint; argv: ptr JSValue): JSValue

proc JS_EnqueueJob*(ctx: ptr JSContext; job_func: ptr JSJobFunc; argc: cint;
                   argv: ptr JSValue): cint {.importc: "JS_EnqueueJob",
    header: headerquickjs.}
proc JS_IsJobPending*(rt: ptr JSRuntime): cint {.importc: "JS_IsJobPending",
    header: headerquickjs.}
proc JS_ExecutePendingJob*(rt: ptr JSRuntime; pctx: ptr ptr JSContext): cint {.
    importc: "JS_ExecutePendingJob", header: headerquickjs.}
##  Object Writer/Reader (currently only used to handle precompiled code)

const
  JS_WRITE_OBJ_BYTECODE* = (1 shl 0) ##  allow function/module
  JS_WRITE_OBJ_BSWAP* = (1 shl 1) ##  byte swapped output

proc JS_WriteObject*(ctx: ptr JSContext; psize: ptr csize; obj: JSValue; flags: cint): ptr uint8 {.
    importc: "JS_WriteObject", header: headerquickjs.}
const
  JS_READ_OBJ_BYTECODE* = (1 shl 0) ##  allow function/module
  JS_READ_OBJ_ROM_DATA* = (1 shl 1) ##  avoid duplicating 'buf' data

proc JS_ReadObject*(ctx: ptr JSContext; buf: ptr uint8; buf_len: csize; flags: cint): JSValue {.
    importc: "JS_ReadObject", header: headerquickjs.}
proc JS_EvalFunction*(ctx: ptr JSContext; fun_obj: JSValue; this_obj: JSValue): JSValue {.
    importc: "JS_EvalFunction", header: headerquickjs.}
##  C function definition

type                          ##  XXX: should rename for namespace isolation
  JSCFunctionEnum* {.size: sizeof(cint).} = enum
    JS_CFUNC_generic, JS_CFUNC_generic_magic, JS_CFUNC_constructor,
    JS_CFUNC_constructor_magic, JS_CFUNC_constructor_or_func,
    JS_CFUNC_constructor_or_func_magic, JS_CFUNC_f_f, JS_CFUNC_f_f_f,
    JS_CFUNC_getter, JS_CFUNC_setter, JS_CFUNC_getter_magic, JS_CFUNC_setter_magic,
    JS_CFUNC_iterator_next
  JSCFunctionType* {.importc: "JSCFunctionType", header: headerquickjs, bycopy.} = object {.
      union.}
    generic* {.importc: "generic".}: ptr JSCFunction
    generic_magic* {.importc: "generic_magic".}: proc (ctx: ptr JSContext;
        this_val: JSValue; argc: cint; argv: ptr JSValue; magic: cint): JSValue
    constructor* {.importc: "constructor".}: ptr JSCFunction
    constructor_magic* {.importc: "constructor_magic".}: proc (ctx: ptr JSContext;
        new_target: JSValue; argc: cint; argv: ptr JSValue; magic: cint): JSValue
    constructor_or_func* {.importc: "constructor_or_func".}: ptr JSCFunction
    f_f* {.importc: "f_f".}: proc (a1: cdouble): cdouble
    f_f_f* {.importc: "f_f_f".}: proc (a1: cdouble; a2: cdouble): cdouble
    getter* {.importc: "getter".}: proc (ctx: ptr JSContext; this_val: JSValue): JSValue
    setter* {.importc: "setter".}: proc (ctx: ptr JSContext; this_val: JSValue;
                                     val: JSValue): JSValue
    getter_magic* {.importc: "getter_magic".}: proc (ctx: ptr JSContext;
        this_val: JSValue; magic: cint): JSValue
    setter_magic* {.importc: "setter_magic".}: proc (ctx: ptr JSContext;
        this_val: JSValue; val: JSValue; magic: cint): JSValue
    iterator_next* {.importc: "iterator_next".}: proc (ctx: ptr JSContext;
        this_val: JSValue; argc: cint; argv: ptr JSValue; pdone: ptr cint; magic: cint): JSValue



proc JS_NewCFunction2*(ctx: ptr JSContext; `func`: ptr JSCFunction; name: cstring;
                      length: cint; cproto: JSCFunctionEnum; magic: cint): JSValue {.
    importc: "JS_NewCFunction2", header: headerquickjs.}
proc JS_NewCFunctionData*(ctx: ptr JSContext; `func`: ptr JSCFunctionData;
                         length: cint; magic: cint; data_len: cint; data: ptr JSValue): JSValue {.
    importc: "JS_NewCFunctionData", header: headerquickjs.}
proc JS_NewCFunction*(ctx: ptr JSContext; `func`: ptr JSCFunction; name: cstring;
                     length: cint): JSValue {.importc: "JS_NewCFunction",
    header: headerquickjs.}

proc JS_NewCFunctionMagic*(ctx: ptr JSContext; `func`: ptr JSCFunctionMagic;
                          name: cstring; length: cint; cproto: JSCFunctionEnum;
                          magic: cint): JSValue {.importc: "JS_NewCFunctionMagic",
    header: headerquickjs.}

##  C property definition

type
  INNER_C_STRUCT_nimterop_1493119302_602* {.importc: "no_name",
      header: headerquickjs, bycopy.} = object
    length* {.importc: "length".}: uint8 ##  XXX: should move outside union
    cproto* {.importc: "cproto".}: uint8 ##  XXX: should move outside union
    cfunc* {.importc: "cfunc".}: JSCFunctionType

  INNER_C_STRUCT_nimterop_1493119302_607* {.importc: "no_name",
      header: headerquickjs, bycopy.} = object
    get* {.importc: "get".}: JSCFunctionType
    set* {.importc: "set".}: JSCFunctionType

  INNER_C_STRUCT_nimterop_1493119302_611* {.importc: "no_name",
      header: headerquickjs, bycopy.} = object
    name* {.importc: "name".}: cstring
    base* {.importc: "base".}: cint

  INNER_C_STRUCT_nimterop_1493119302_615* {.importc: "no_name",
      header: headerquickjs, bycopy.} = object
    tab* {.importc: "tab".}: ptr JSCFunctionListEntry
    len* {.importc: "len".}: cint

  INNER_C_UNION_nimterop_1493119302_601* {.importc: "no_name",
      header: headerquickjs, bycopy.} = object {.union.}
    `func`* {.importc: "func".}: INNER_C_STRUCT_nimterop_1493119302_602
    getset* {.importc: "getset".}: INNER_C_STRUCT_nimterop_1493119302_607
    alias* {.importc: "alias".}: INNER_C_STRUCT_nimterop_1493119302_611
    prop_list* {.importc: "prop_list".}: INNER_C_STRUCT_nimterop_1493119302_615
    str* {.importc: "str".}: cstring
    i32* {.importc: "i32".}: int32
    i64* {.importc: "i64".}: int64
    f64* {.importc: "f64".}: cdouble

  JSCFunctionListEntry* {.importc: "JSCFunctionListEntry", header: headerquickjs,
                         bycopy.} = object
    name* {.importc: "name".}: cstring
    prop_flags* {.importc: "prop_flags".}: uint8
    def_type* {.importc: "def_type".}: uint8
    magic* {.importc: "magic".}: int16
    u* {.importc: "u".}: INNER_C_UNION_nimterop_1493119302_601


const
  JS_DEF_CFUNC* = 0
  JS_DEF_CGETSET* = 1
  JS_DEF_CGETSET_MAGIC* = 2
  JS_DEF_PROP_STRING* = 3
  JS_DEF_PROP_INT32* = 4
  JS_DEF_PROP_INT64* = 5
  JS_DEF_PROP_DOUBLE* = 6
  JS_DEF_PROP_UNDEFINED* = 7
  JS_DEF_OBJECT* = 8
  JS_DEF_ALIAS* = 9

proc JS_SetPropertyFunctionList*(ctx: ptr JSContext; obj: JSValue;
                                tab: ptr JSCFunctionListEntry; len: cint) {.
    importc: "JS_SetPropertyFunctionList", header: headerquickjs.}
##  C module definition

type
  JSModuleInitFunc* = proc (ctx: ptr JSContext; m: ptr JSModuleDef): cint

proc JS_NewCModule*(ctx: ptr JSContext; name_str: cstring;
                   `func`: ptr JSModuleInitFunc): ptr JSModuleDef {.
    importc: "JS_NewCModule", header: headerquickjs.}
##  can only be called before the module is instantiated

proc JS_AddModuleExport*(ctx: ptr JSContext; m: ptr JSModuleDef; name_str: cstring): cint {.
    importc: "JS_AddModuleExport", header: headerquickjs.}
proc JS_AddModuleExportList*(ctx: ptr JSContext; m: ptr JSModuleDef;
                            tab: ptr JSCFunctionListEntry; len: cint): cint {.
    importc: "JS_AddModuleExportList", header: headerquickjs.}
##  can only be called after the module is instantiated

proc JS_SetModuleExport*(ctx: ptr JSContext; m: ptr JSModuleDef; export_name: cstring;
                        val: JSValue): cint {.importc: "JS_SetModuleExport",
    header: headerquickjs.}
proc JS_SetModuleExportList*(ctx: ptr JSContext; m: ptr JSModuleDef;
                            tab: ptr JSCFunctionListEntry; len: cint): cint {.
    importc: "JS_SetModuleExportList", header: headerquickjs.}