##======================================================================================================================
##  SAMPLE - @brief@
##  Copyright : SAMPLE Project Contributors
##  SPDX-License-Identifier: BSL-1.0
##======================================================================================================================
cmake_minimum_required(VERSION 3.24)
project(sample LANGUAGES CXX)

##======================================================================================================================
option(SAMPLE_BUILD_TEST "Build tests   for SAMPLE" ON)
option(SAMPLE_BUILD_DOCUMENTATION "Build Doxygen for SAMPLE" OFF)
option(SAMPLE_ENABLE_SANITIZERS "Build tests with AddressSanitizer + UndefinedBehaviorSanitizer" OFF)
option(SAMPLE_ENABLE_COVERAGE "Build tests with code coverage instrumentation" OFF)

##======================================================================================================================
include(${PROJECT_SOURCE_DIR}/cmake/dependencies.cmake)

if(SAMPLE_BUILD_TEST)
  include(${PROJECT_SOURCE_DIR}/cmake/compiler.cmake)
endif()

##======================================================================================================================
## Project setup via copacabana
##======================================================================================================================
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${PROJECT_SOURCE_DIR}/cmake ${COPACABANA_SOURCE_DIR}/copacabana/cmake)
include(${COPACABANA_SOURCE_DIR}/copacabana/cmake/copacabana.cmake)
copa_project_version(MAJOR 0 MINOR 1 PATCH 0 REPOSITORY @remote@)

##======================================================================================================================
## Summary Display
##======================================================================================================================
if(NOT SAMPLE_QUIET)
  if(CMAKE_BUILD_TYPE)
    message(STATUS "[${PROJECT_NAME}] - Building in ${CMAKE_BUILD_TYPE} mode")
  endif()
  message(STATUS "[${PROJECT_NAME}] - Unit tests : ${SAMPLE_BUILD_TEST} (via SAMPLE_BUILD_TEST)")
  message(STATUS "[${PROJECT_NAME}] - Doxygen    : ${SAMPLE_BUILD_DOCUMENTATION} (via SAMPLE_BUILD_DOCUMENTATION)")
  message(STATUS "[${PROJECT_NAME}] - Sanitizers : ${SAMPLE_ENABLE_SANITIZERS} (via SAMPLE_ENABLE_SANITIZERS)")
  message(STATUS "[${PROJECT_NAME}] - Coverage   : ${SAMPLE_ENABLE_COVERAGE} (via SAMPLE_ENABLE_COVERAGE)")
  set(QUIET_OPTION "")
else()
  set(QUIET_OPTION "QUIET")
endif()

##======================================================================================================================
## Pre-commit hooks setup targets
##======================================================================================================================
copa_setup_precommit_hooks(${QUIET_OPTION})

##======================================================================================================================
## Install Process setup
##======================================================================================================================
copa_setup_install(
  LIBRARY sample
  FEATURES cxx_std_20
  DOC ${PROJECT_SOURCE_DIR}/LICENSE.md
  INCLUDE ${PROJECT_SOURCE_DIR}/include/sample)

##======================================================================================================================
## Setup doxygen
##======================================================================================================================
if(SAMPLE_BUILD_DOCUMENTATION)
  copa_setup_doxygen(
    ${QUIET_OPTION}
    TARGET sample-doxygen
    DESTINATION "${PROJECT_BINARY_DIR}/doc"
    GODBOLT_LIBRARIES sample tts
    COLOR_HUE 293
    COLOR_SATURATION 40)
endif()

##@if standalone@
##======================================================================================================================
## Standalone generation
##======================================================================================================================
copa_setup_standalone(
  QUIET
  FILE sample.hpp
  SOURCE include
  ROOT sample
  TARGET sample-standalone
  OUTPUT "${PROJECT_BINARY_DIR}")

##@endif@
##======================================================================================================================
## Tests setup
##======================================================================================================================
if(SAMPLE_BUILD_TEST)
  if(SAMPLE_ENABLE_SANITIZERS)
    copa_setup_sanitizers(sample_tests ENABLE_ASAN ENABLE_UBSAN)
  endif()

  enable_testing()
  add_subdirectory(test)

  # After the test targets exist, so the coverage targets can depend on them
  if(SAMPLE_ENABLE_COVERAGE)
    copa_setup_coverage(sample_tests)
  endif()
endif()
