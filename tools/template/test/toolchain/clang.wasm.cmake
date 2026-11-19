##======================================================================================================================
##  SAMPLE - @brief@
##  Copyright : SAMPLE Project Contributors
##  SPDX-License-Identifier: BSL-1.0
##======================================================================================================================
set(CMAKE_C_COMPILER emcc)
set(CMAKE_CXX_COMPILER em++)

## We do test exceptions
set(CMAKE_CXX_FLAGS "-fexceptions -msimd128")

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

set(CMAKE_FIND_ROOT_PATH "$ENV{EMSDK}/upstream/emscripten/cache/sysroot/")

set(CMAKE_CROSSCOMPILING_CMD ${CMAKE_CURRENT_LIST_DIR}/run_wasm.sh)
