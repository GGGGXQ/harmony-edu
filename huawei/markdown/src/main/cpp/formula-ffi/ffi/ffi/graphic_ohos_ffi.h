//
// Created on 2025/12/17.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#ifndef LATEX_GRAPHIC_OHOS_FFI_H
#define LATEX_GRAPHIC_OHOS_FFI_H

#include <native_drawing/drawing_bitmap.h>
#include <iostream>

#ifdef __cplusplus
extern "C" {
#endif

OH_Drawing_Bitmap *initGraphics2D_ffi(uint32_t w, uint32_t h, OH_Drawing_ColorFormat colorFormat);

#ifdef __cplusplus
}
#endif

#endif //LATEX_GRAPHIC_OHOS_FFI_H

