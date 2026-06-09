/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights reserved.
 */

#include "latex.h"

#ifdef __OS_ohos__

#include <ctype.h>
#include <string>

using namespace std;
using namespace tex;

#ifdef __cplusplus
extern "C" {
#endif

bool LaTeX_init(char *rootDir) {
    try {
        LaTeX::init(rootDir);
        return true;
    } catch (ex_tex& e) {
        return false;
    }
}

void LaTeX_release() {
    LaTeX::release();
}

TeXRender *LaTeX_parse(char *ltx, int width, float textSize, float lineSpace, uint32_t foreground) {
    wstring value;
    value = utf82wide(ltx);
    const wchar_t *wstr = value.c_str();
    try {
        TeXRender *r = LaTeX::parse(value, width, textSize, lineSpace, foreground);
        return r;
    } catch (exception& e) {
        return nullptr;
    }
}

void LaTeX_setDebug(bool debug) {
    LaTeX::setDebug(debug);
}

#ifdef __cplusplus
}
#endif

#endif  // __OS_ohos__
