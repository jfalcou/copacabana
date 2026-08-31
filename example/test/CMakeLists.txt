##======================================================================================================================
##  Copacabana - Common CMake Package Tools
##  Copyright : Copacabana Project Contributors
##  SPDX-License-Identifier: BSL-1.0
##======================================================================================================================
copa_setup_test_targets()
set(root "${CMAKE_SOURCE_DIR}/test")

## PROJECT_TEST_TARGET exists only in the scope that asked for it, so this one check stays where it can see it.
if(COPACABANA_SELF_TEST)
  copa_expect("test aggregate" "${PROJECT_TEST_TARGET}" "example-test")
endif()

copa_glob_unit( QUIET PATTERN "unit/*.cpp"
                RELATIVE ${root} DEPENDENCIES standalone-example INTERFACE example_test PCH example_pch
              )

##======================================================================================================================
## Samples gather under their own target, so example-test stays the tests alone
##======================================================================================================================
copa_glob_unit( QUIET PATTERN "samples/*.cpp"
                RELATIVE ${root} INTERFACE example_test TARGET example-samples
              )
