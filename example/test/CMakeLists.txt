##======================================================================================================================
##  Copacabana - Common CMake Package Tools
##  Copyright : Copacabana Project Contributors
##  SPDX-License-Identifier: BSL-1.0
##======================================================================================================================

##======================================================================================================================
# Unit test Configuration
##======================================================================================================================
add_library(example_test INTERFACE)

if(CMAKE_CXX_COMPILER_ID MATCHES "MSVC")
  target_compile_options( example_test INTERFACE /W3 /EHsc /bigobj /std:c++20)
else()
  target_compile_options( example_test INTERFACE -std=c++20 -Werror -Wall -Wextra -Wconversion -Wunused-variable)
endif()

target_include_directories( example_test INTERFACE
                            ${PROJECT_SOURCE_DIR}/test
                            ${PROJECT_SOURCE_DIR}/include
                          )

copa_glob_unit(PATTERN "types/*.cpp"  DEPENDENCIES standalone-example INTERFACE example_test)
copa_glob_unit(PATTERN "values/*.cpp" DEPENDENCIES standalone-example INTERFACE example_test)
