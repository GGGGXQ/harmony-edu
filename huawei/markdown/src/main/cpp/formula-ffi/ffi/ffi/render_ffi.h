//
// Created on 2025/12/17.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#ifndef LATEX_RENDER_FFI_H
#define LATEX_RENDER_FFI_H

#include "graphic_ohos.h"
#include "latex.h"
#include "utils.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    uint8_t *data;
    int64_t len;
} UInt8Data;

void TeXRender_draw(TeXRender *r, OH_Drawing_Bitmap *bitmap, int x, int y, uint32_t background);

float TeXRender_getTextSize(TeXRender *r);

int TeXRender_getHeight(TeXRender *r);

int TeXRender_getDepth(TeXRender *r);

int TeXRender_getWidth(TeXRender *r);

float TeXRender_getBaseline(TeXRender *r);

void TeXRender_setTextSize(TeXRender *r, float size);

void TeXRender_setForeground(TeXRender *r, int c);

void TeXRender_setWidth(TeXRender *r, int width, int align);

void TeXRender_setHeight(TeXRender *r, int height, int align);

void TeXRender_finalize(TeXRender *r);

UInt8Data TeXRender_toBitmap(TeXRender *r, OH_Drawing_Bitmap *bitmap, OH_Drawing_ColorFormat colorFormat);

UInt8Data TeXRender_getMapData(TeXRender *r, OH_Drawing_Bitmap *bitmap, OH_Drawing_ColorFormat colorFormat);

#ifdef __cplusplus
}
#endif

#endif //LATEX_RENDER_FFI_H
