import "."/[core]

const headerquickjs = "quickjs/quickjs-libc.h"
{.passC: "-DCONFIG_VERSION=\"\"".}
{.passL: "-lm -lpthread".}
{.compile: "quickjs/quickjs-libc.c".}


proc js_init_module_std*(ctx: ptr JSContext,
    module_name: cstring): ptr JSModuleDef {.importc: "js_init_module_std",
    header: headerquickjs.}
proc js_init_module_os*(ctx: ptr JSContext,
    module_name: cstring): ptr JSModuleDef {.importc: "js_init_module_os",
    header: headerquickjs.}
proc js_std_add_helpers*(ctx: ptr JSContext, argc: cint, argv: ptr cstring) {.
    importc: "js_std_add_helpers", header: headerquickjs.}
proc js_std_loop*(ctx: ptr JSContext) {.importc: "js_std_loop",
    header: headerquickjs.}
proc js_std_free_handlers*(rt: ptr JSRuntime) {.importc: "js_std_free_handlers",
    header: headerquickjs.}
proc js_std_dump_error*(ctx: ptr JSContext) {.importc: "js_std_dump_error",
    header: headerquickjs.}
proc js_load_file*(ctx: ptr JSContext, pbuf_len: ptr cuint,
    filename: cstring): ptr uint8 {.importc: "js_load_file",
    header: headerquickjs.}
proc js_module_loader*(ctx: ptr JSContext, module_name: cstring,
    opaque: pointer): ptr JSModuleDef {.importc: "js_module_loader",
    header: headerquickjs.}
proc js_std_eval_binary*(ctx: ptr JSContext, buf: ptr uint8, buf_len: cuint,
    flags: cint) {.importc: "js_std_eval_binary", header: headerquickjs.}
