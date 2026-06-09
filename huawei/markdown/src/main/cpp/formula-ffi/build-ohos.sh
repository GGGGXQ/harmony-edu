#! /bin/bash

mkdir -p ffi/build
mkdir -p lib
cd ffi/build

cd ffi/build

# -DCMAKE_CXX_COMPILER 和 -DCMAKE_CXX_FLAGS 路径自行设置
cmake .. -DCMAKE_VERBOSE_MAKEFILE=ON -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_COMPILER="D:/DevecoStudio_SDK/sdk/default/openharmony/native/llvm/bin/clang++.exe" -DCMAKE_CXX_FLAGS="--sysroot=D:/DevecoStudio_SDK/sdk/default/openharmony/native/sysroot --target=x86_64-linux-ohos" -DCMAKE_SYSTEM_NAME=linux -DCMAKE_SYSTEM_PROCESSOR=x86_64  -G "MinGW Makefiles" -DCMAKE_STRIP="D:/DevecoStudio_SDK/sdk/default/openharmony/native/llvm/bin/llvm-strip.exe"

# cmake .. -DCMAKE_VERBOSE_MAKEFILE=ON -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_COMPILER="D:/DevecoStudio_SDK/sdk/default/openharmony/native/llvm/bin/clang++.exe" -DCMAKE_CXX_FLAGS="--sysroot=D:/DevecoStudio_SDK/sdk/default/openharmony/native/sysroot --target=aarch64-linux-ohos" -DCMAKE_SYSTEM_NAME=linux -DCMAKE_SYSTEM_PROCESSOR=aarch64  -G "MinGW Makefiles" -DCMAKE_STRIP="D:/DevecoStudio_SDK/sdk/default/openharmony/native/llvm/bin/llvm-strip.exe"
make -j20

cp liblatex.so ../../lib/
cd ../../
cjpm build --target aarch64-linux-ohos