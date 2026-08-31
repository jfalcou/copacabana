##======================================================================================================================
##  SAMPLE - @brief@
##  Copyright : SAMPLE Project Contributors
##  SPDX-License-Identifier: BSL-1.0
##======================================================================================================================

##======================================================================================================================
## Compiler options for Tests
##======================================================================================================================
add_library(sample_tests INTERFACE)

target_compile_features(sample_tests INTERFACE cxx_std_20)

if(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  if(CMAKE_CXX_COMPILER_FRONTEND_VARIANT STREQUAL "MSVC")
    target_compile_options(sample_tests INTERFACE $<$<COMPILE_LANGUAGE:CXX>:/W3 /EHsc>)
  else()
    target_compile_options(sample_tests INTERFACE $<$<COMPILE_LANGUAGE:CXX>:-Werror -Wall -Wextra -Wunused-variable
                                                  -Wshadow -Wdocumentation>)
  endif()
elseif(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
  target_compile_options(sample_tests INTERFACE $<$<COMPILE_LANGUAGE:CXX>:/W3 /EHsc /Zc:preprocessor>)
else()
  target_compile_options(sample_tests INTERFACE $<$<COMPILE_LANGUAGE:CXX>:-Werror -Wall -Wextra -Wunused-variable
                                                -Wshadow>)
endif()

target_include_directories(sample_tests INTERFACE ${PROJECT_SOURCE_DIR}/test ${PROJECT_SOURCE_DIR}/include)
