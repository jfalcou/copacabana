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

## Held in a variable so the calls below stay on one line: a wrapped argument list aligns its continuation on the
## column the list opens at, which moves with the length of the target's name.
set(SAMPLE_WARNINGS -Werror -Wall -Wextra -Wunused-variable -Wshadow)

if(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  if(CMAKE_CXX_COMPILER_FRONTEND_VARIANT STREQUAL "MSVC")
    target_compile_options(sample_tests INTERFACE $<$<COMPILE_LANGUAGE:CXX>:/W3 /EHsc>)
  else()
    target_compile_options(sample_tests INTERFACE $<$<COMPILE_LANGUAGE:CXX>:${SAMPLE_WARNINGS} -Wdocumentation>)
  endif()
elseif(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
  target_compile_options(sample_tests INTERFACE $<$<COMPILE_LANGUAGE:CXX>:/W3 /EHsc /Zc:preprocessor>)
else()
  target_compile_options(sample_tests INTERFACE $<$<COMPILE_LANGUAGE:CXX>:${SAMPLE_WARNINGS}>)
endif()

target_include_directories(sample_tests INTERFACE ${PROJECT_SOURCE_DIR}/test ${PROJECT_SOURCE_DIR}/include)
