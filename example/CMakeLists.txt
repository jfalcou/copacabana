##======================================================================================================================
##  Copacabana - Common CMake Package Tools
##  Copyright : Copacabana Project Contributors
##  SPDX-License-Identifier: BSL-1.0
##======================================================================================================================
cmake_minimum_required(VERSION 3.25)
enable_testing()

##======================================================================================================================
## Setup project
##======================================================================================================================
project(EXAMPLE LANGUAGES CXX)
include(${PROJECT_SOURCE_DIR}/cmake/dependencies.cmake)
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${PROJECT_SOURCE_DIR}/cmake ${COPACABANA_SOURCE_DIR}/cmake)
include(${COPACABANA_SOURCE_DIR}/cmake/copacabana.cmake)

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
## Setup doxygen
copa_setup_doxygen(QUIET DESTINATION "${PROJECT_BINARY_DIR}/doxygen-output")

## Testing: copa_setup_doxygen
if(NOT "${PROJECT_DOXYGEN_SOURCE_DIR}" MATCHES "${PROJECT_SOURCE_DIR}/doc")
  message(FATAL_ERROR "[${PROJECT_NAME}] - Doxygen input path ${PROJECT_DOXYGEN_SOURCE_DIR} is invalid")
endif()

if(NOT "${PROJECT_DOXYGEN_OUTPUT_DIR}" MATCHES "${PROJECT_BINARY_DIR}/doxygen-output")
  message(FATAL_ERROR "[${PROJECT_NAME}] - Doxygen output path ${PROJECT_DOXYGEN_OUTPUT_DIR} is invalid")
endif()
##======================================================================================================================
