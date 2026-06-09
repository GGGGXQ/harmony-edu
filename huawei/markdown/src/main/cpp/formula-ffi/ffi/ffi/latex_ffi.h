//
// Created on 2025/12/17.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#ifndef LATEX_LATEX_FFI_H
#define LATEX_LATEX_FFI_H

#include "latex.h"

#ifdef __cplusplus
extern "C" {
#endif

bool LaTeX_init(char *rootDir);

void LaTeX_release();

TeXRender *LaTeX_parse(char *ltx, int width, float textSize, float lineSpace, uint32_t foreground);

void LaTeX_setDebug(bool debug);

#ifdef __cplusplus
}
#endif

#endif //LATEX_LATEX_FFI_H
