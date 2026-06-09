#include "napi/native_api.h"
#include "latex_ffi.h"
#include "graphic_ohos_ffi.h"
#include "render_ffi.h"

#include "hilog/log.h"
#undef LOG_DOMAIN
#undef LOG_TAG
#define LOG_DOMAIN 0x3200  // Global domain macro, identifying the business domain
#define LOG_TAG "libLatex" // Global tag macro, identifying module log tags

#define LATEX_MAX_BUFFER_SIZE 4096

static napi_value getLatex(napi_env env, napi_callback_info info) {
    size_t argc = 5;
    napi_value args[5] = {nullptr};
    char latex[LATEX_MAX_BUFFER_SIZE];

    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    size_t data_Size;
    napi_get_value_string_utf8(env, args[0], latex, LATEX_MAX_BUFFER_SIZE, &data_Size);

    double value0;
    napi_get_value_double(env, args[1], &value0);

    double value1;
    napi_get_value_double(env, args[2], &value1);

    double value2;
    napi_get_value_double(env, args[3], &value2);

    uint32_t font_color;
    napi_get_value_uint32(env, args[4], &font_color);

    auto r = LaTeX_parse(latex, value0, value1, value2, font_color);

    int h = TeXRender_getHeight(r);
    int w = TeXRender_getWidth(r);
    int text_size = TeXRender_getTextSize(r);
    auto bitmap = initGraphics2D_ffi(w + (text_size / 9.0) + 1, h + (text_size / 9.0) + 1,
                                     COLOR_FORMAT_BGRA_8888); // COLOR_FORMAT_BGRA_8888 COLOR_FORMAT_RGB_565

    TeXRender_draw(r, bitmap, 0, 0, 0x00FFFFFF);

    auto out = TeXRender_toBitmap(r, bitmap, COLOR_FORMAT_BGRA_8888);

    char *data = nullptr;
    napi_value result = nullptr;
    napi_create_buffer_copy(env, out.len, out.data, reinterpret_cast<void **>(&data), &result);

    return result;
}

static napi_value initLatex(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1] = {nullptr};
    char res[LATEX_MAX_BUFFER_SIZE];

    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    size_t data_Size;
    napi_get_value_string_utf8(env, args[0], res, LATEX_MAX_BUFFER_SIZE, &data_Size);
    
//    LaTeX_init("/data/storage/el1/bundle/latex/resources/resfile/res");
    LaTeX_init(res);

    napi_value result = nullptr;
    uint32_t ret = 10;
    napi_create_uint32(env, ret, &result);

    return result;
}

EXTERN_C_START
static napi_value Init(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
        {"getLatex", nullptr, getLatex, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"initLatex", nullptr, initLatex, nullptr, nullptr, nullptr, napi_default, nullptr},
        
    };
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);

    return exports;
}
EXTERN_C_END

static napi_module demoModule = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = Init,
    .nm_modname = "latexentry",
    .nm_priv = ((void *)0),
    .reserved = {0},
};

extern "C" __attribute__((constructor)) void RegisterEntryModule(void) { napi_module_register(&demoModule); }
