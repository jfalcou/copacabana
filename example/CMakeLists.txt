##======================================================================================================================
##  Copacabana - Common CMake Package Tools
##  Copyright : Copacabana Project Contributors
##  SPDX-License-Identifier: BSL-1.0
##======================================================================================================================
cmake_minimum_required(VERSION 3.22)

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

## Testing: copa_project_version
if(NOT "${PROJECT_MAJOR_VERSION}" MATCHES "1")
message(FATAL_ERROR "[${PROJECT_NAME}] - Major version ${PROJECT_MAJOR_VERSION} is invalid")
endif()

if(NOT "${PROJECT_MINOR_VERSION}" MATCHES "2")
message(FATAL_ERROR "[${PROJECT_NAME}] - Minor version ${PROJECT_MINOR_VERSION} is invalid")
endif()

if(NOT "${PROJECT_PATCH_VERSION}" MATCHES "3a")
message(FATAL_ERROR "[${PROJECT_NAME}] - Patch ${PROJECT_PATCH_VERSION} is invalid")
endif()

if(NOT "${PROJECT_VERSION}" MATCHES "1.2.3a")
message(FATAL_ERROR "[${PROJECT_NAME}] - Version ${PROJECT_VERSION} is invalid")
endif()
##======================================================================================================================

##======================================================================================================================
## Setup pre-commit hooks
copa_setup_precommit_hooks()

##======================================================================================================================
## Setup doxygen
copa_setup_doxygen(QUIET DESTINATION "${PROJECT_BINARY_DIR}/doxygen-output")

## Testing: copa_setup_doxygen
if (DOXYGEN_FOUND)
  if(NOT "${PROJECT_DOXYGEN_SOURCE_DIR}" MATCHES "${PROJECT_SOURCE_DIR}/doc")
    message(FATAL_ERROR "[${PROJECT_NAME}] - Doxygen input path ${PROJECT_DOXYGEN_SOURCE_DIR} is invalid")
  endif()

  if(NOT "${PROJECT_DOXYGEN_OUTPUT_DIR}" MATCHES "${PROJECT_BINARY_DIR}/doxygen-output")
    message(FATAL_ERROR "[${PROJECT_NAME}] - Doxygen output path ${PROJECT_DOXYGEN_OUTPUT_DIR} is invalid")
  endif()
endif()
##======================================================================================================================

##======================================================================================================================
## Activate standalone target
copa_setup_standalone(FILE example.hpp SOURCE src DESTINATION include ROOT libexample TARGET standalone-example)

## Testing copa_setup_standalone
if(Python_FOUND)
  if(NOT "${PROJECT_STANDALONE_TARGET}" MATCHES "standalone-example")
    message(FATAL_ERROR "[${PROJECT_NAME}] - Standalone target ${PROJECT_STANDALONE_TARGET} is invalid")
  endif()
endif()
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

##======================================================================================================================
## Setup PCH
##======================================================================================================================
copa_setup_pch( TARGET      example
                INTERFACES  example_test
                HEADERS     include/libexample/example.hpp
              )

if(NOT "${PROJECT_PCH_TARGET}" MATCHES "example_pch")
  message(FATAL_ERROR "[${PROJECT_NAME}] - PCH Target ${PROJECT_PCH_TARGET} is invalid")
endif()

##======================================================================================================================
## Setup Install
##======================================================================================================================
copa_setup_install( LIBRARY example FEATURES cxx_std_20
                    LIB     ${PROJECT_SOURCE_DIR}/include/libexample/example.hpp
                    DOC     ${PROJECT_SOURCE_DIR}/LICENSE
                    INCLUDE ${PROJECT_SOURCE_DIR}/include/libexample
                  )

##======================================================================================================================
## Setup Testing
##======================================================================================================================
enable_testing()
add_subdirectory(test)
