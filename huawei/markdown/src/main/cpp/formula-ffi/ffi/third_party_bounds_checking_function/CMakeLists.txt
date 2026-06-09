
# the minimum version of CMake.
cmake_minimum_required(VERSION 3.5.0)
project(securec)

include_directories(${NATIVERENDER_ROOT_PATH}
                    ${NATIVERENDER_ROOT_PATH}/include
                    "include"
                    )

file(GLOB_RECURSE SRC "src/*.c")

add_library(securec SHARED ${SRC})
