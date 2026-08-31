##======================================================================================================================
##  Copacabana - Common CMake Package Tools
##  Copyright : Copacabana Project Contributors
##  SPDX-License-Identifier: BSL-1.0
##======================================================================================================================
cmake_minimum_required(VERSION 3.24)

##======================================================================================================================
## Setup project
##======================================================================================================================
project(EXAMPLE LANGUAGES CXX)
include(${PROJECT_SOURCE_DIR}/cmake/dependencies.cmake)
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${PROJECT_SOURCE_DIR}/cmake ${COPACABANA_SOURCE_DIR}/copacabana/cmake)
include(${COPACABANA_SOURCE_DIR}/copacabana/cmake/copacabana.cmake)

##======================================================================================================================
## copa_project_version Setup a project version to be used in other functions and user defined code
copa_project_version(MAJOR 1 MINOR 2 PATCH 3a)

##======================================================================================================================
## Setup pre-commit hooks
copa_setup_precommit_hooks()

##======================================================================================================================
## Setup doxygen
copa_setup_doxygen(QUIET DESTINATION "${PROJECT_BINARY_DIR}/doxygen-output")

##======================================================================================================================
## Activate standalone target
copa_setup_standalone(FILE example.hpp SOURCE src DESTINATION include ROOT libexample TARGET standalone-example)

##======================================================================================================================
## System Installers Configuration
##======================================================================================================================
copa_setup_cpack(
  VENDOR       "Example Team"
  MAINTAINER   "Example Team - example@team.com"
  DESCRIPTION  "An example library to demonstrate Copacabana tools"
  LICENSE_FILE "${PROJECT_SOURCE_DIR}/LICENSE"
  DEB_DEPENDENCIES  "libfmt-dev (>= 10.1.1)" "cmake (>= 3.22.0)"
  RPM_DEPENDENCIES  "fmt-devel >= 10.1.1"    "cmake >= 3.22.0"
)

##======================================================================================================================
# Unit test Configuration
##======================================================================================================================
option(EXAMPLE_USE_ASAN "Enable Address & Undefined Behavior Sanitizers" OFF)
option(EXAMPLE_USE_TSAN "Enable Thread Sanitizer" OFF)
option(EXAMPLE_USE_MSAN "Enable Memory Sanitizer" OFF)
option(EXAMPLE_USE_COVERAGE "Enable coverage instrumentation" OFF)

add_library(example_test INTERFACE)

## The standard through compile features, which is how the installed library asks for it too: a raw -std= flag goes
## past CMAKE_CXX_STANDARD, past the per-compiler spelling, and past the propagation to whoever links this.
target_compile_features( example_test INTERFACE cxx_std_20 )

if(CMAKE_CXX_COMPILER_ID MATCHES "MSVC")
  target_compile_options( example_test INTERFACE /W3 /EHsc /bigobj)
else()
  target_compile_options( example_test INTERFACE -Werror -Wall -Wextra -Wconversion -Wunused-variable)
endif()

target_include_directories( example_test INTERFACE
                            ${PROJECT_SOURCE_DIR}/test
                            ${PROJECT_SOURCE_DIR}/include
                          )

# Dynamically apply sanitizers based on the options
if(EXAMPLE_USE_ASAN)
  copa_setup_sanitizers(example_test ENABLE_ASAN ENABLE_UBSAN)
elseif(EXAMPLE_USE_TSAN)
  copa_setup_sanitizers(example_test ENABLE_TSAN)
elseif(EXAMPLE_USE_MSAN)
  copa_setup_sanitizers(example_test ENABLE_MSAN)
endif()

##======================================================================================================================
## Setup PCH
##======================================================================================================================
copa_setup_pch( TARGET      example
                INTERFACES  example_test
                HEADERS     include/libexample/example.hpp
              )

##======================================================================================================================
## Setup Install
##======================================================================================================================
copa_setup_install( LIBRARY example FEATURES cxx_std_20
                    DOC     ${PROJECT_SOURCE_DIR}/LICENSE
                    INCLUDE ${PROJECT_SOURCE_DIR}/src/libexample
                  )

##======================================================================================================================
## What copacabana left behind, checked. Off by default: this is an example first, and the subdirectory below needs
## copa_expect to have been defined.
##======================================================================================================================
option(COPACABANA_SELF_TEST "Check what copacabana's functions returned" OFF)

if(COPACABANA_SELF_TEST)
  include(${CMAKE_CURRENT_LIST_DIR}/../test/assertions.cmake)
endif()

##======================================================================================================================
## Setup Testing
##======================================================================================================================
enable_testing()
add_subdirectory(test)

##======================================================================================================================
## Setup Coverage - after the test targets exist, as the coverage targets depend on them
##======================================================================================================================
if(EXAMPLE_USE_COVERAGE)
  copa_setup_coverage( example_test
                       PREFIX  example
                       FILTER  "${PROJECT_SOURCE_DIR}/include/libexample/"
                       DEPENDS example-test
                     )
endif()
