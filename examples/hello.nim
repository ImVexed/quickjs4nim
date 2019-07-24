import quickjs4nim/[core, libc]

var hello = [byte(0x01), 0x04, 0x0e, 0x63, 0x6f, 0x6e, 0x73, 0x6f, 0x6c, 0x65,
    0x06, 0x6c, 0x6f, 0x67, 0x16, 0x48, 0x65, 0x6c, 0x6c, 0x6f, 0x20, 0x57,
    0x6f, 0x72, 0x6c, 0x64, 0x22, 0x65, 0x78, 0x61, 0x6d, 0x70, 0x6c, 0x65,
    0x73, 0x2f, 0x68, 0x65, 0x6c, 0x6c, 0x6f, 0x2e, 0x6a, 0x73, 0x0d, 0x00,
    0x02, 0x00, 0x9e, 0x01, 0x00, 0x01, 0x00, 0x03, 0x00, 0x00, 0x14, 0x01,
    0xa0, 0x01, 0x00, 0x00, 0x00, 0x38, 0xc4, 0x00, 0x00, 0x00, 0x42, 0xc5,
    0x00, 0x00, 0x00, 0x04, 0xc6, 0x00, 0x00, 0x00, 0x27, 0x01, 0x00, 0xd2,
    0x2b, 0x8e, 0x03, 0x01, 0x00]
var args: array[1, cstring]

var rt = JS_NewRuntime()
var ctx = JS_NewContextRaw(rt)
JS_AddIntrinsicBaseObjects(ctx)
js_std_add_helpers(ctx, 0, addr(args[0]))
js_std_eval_binary(ctx, addr(hello[0]), 87, 0)
js_std_loop(ctx)
JS_FreeContext(ctx)
JS_FreeRuntime(rt)
