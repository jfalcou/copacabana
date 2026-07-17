##======================================================================================================================
##  Copacabana - Common CMake Package Tools
##  Copyright : Copacabana Project Contributors
##  SPDX-License-Identifier: BSL-1.0
##======================================================================================================================
copa_setup_test_targets()
set(root "${CMAKE_SOURCE_DIR}/test")

if(NOT "${PROJECT_TEST_TARGET}" MATCHES "example-test")
  message(FATAL_ERROR "[${PROJECT_NAME}] - Top-level Test Target ${PROJECT_TEST_TARGET} is invalid")
endif()

copa_glob_unit( QUIET PATTERN "unit/*.cpp"
                RELATIVE ${root} DEPENDENCIES standalone-example INTERFACE example_test PCH example_pch
              )
