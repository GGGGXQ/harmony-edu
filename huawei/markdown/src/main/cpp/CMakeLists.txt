# the minimum version of CMake.
cmake_minimum_required(VERSION 3.5.0)
project(latex)

set(NATIVERENDER_ROOT_PATH ${CMAKE_CURRENT_SOURCE_DIR})

add_subdirectory(formula-ffi/ffi)

if(DEFINED PACKAGE_FIND_FILE)
    include(${PACKAGE_FIND_FILE})
endif()

include_directories(${NATIVERENDER_ROOT_PATH}
                    ${NATIVERENDER_ROOT_PATH}/include
                    "formula-ffi/ffi/latex/src"
                    "formula-ffi/ffi/latex"
                    "formula-ffi/ffi/latex/src/xml"
                    "formula-ffi/ffi/ffi"
                    "formula-ffi/ffi/third_party_bounds_checking_function/include"
                    )

add_library(latexentry SHARED napi_init.cpp)
target_link_libraries(latexentry PUBLIC latex libace_napi.z.so libhilog_ndk.z.so)

