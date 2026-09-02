##======================================================================================================================
##  Copacabana - Common CMake Package Tools
##  Copyright : Copacabana Project Contributors
##  SPDX-License-Identifier: BSL-1.0
##======================================================================================================================
copa_setup_test_targets()
set(ROOT "${CMAKE_SOURCE_DIR}/test")

## PROJECT_TEST_TARGET exists only in the scope that asked for it, so this one check stays where it can see it.
copa_expect("test aggregate" "${PROJECT_TEST_TARGET}" "example-test")

copa_glob_unit(
  QUIET
  PATTERN "unit/*.cpp"
  RELATIVE ${ROOT}
  DEPENDENCIES standalone-example
  INTERFACE example_test
  PCH example_pch)

##======================================================================================================================
## Samples gather under their own target, so example-test stays the tests alone
##======================================================================================================================
copa_glob_unit(
  QUIET IMPLICIT
  PATTERN "samples/*.cpp"
  RELATIVE ${ROOT}
  INTERFACE example_test
  TARGET example-samples
  PROPERTIES FOLDER "samples")

## PROPERTIES used to share a branch with the exclusion, so asking for both left the properties unset.
get_target_property(SAMPLE_FOLDER samples.demo.exe FOLDER)
copa_expect("sample folder" "${SAMPLE_FOLDER}" "samples")

get_target_property(UNIT_EXCLUDED unit.values.value.exe EXCLUDE_FROM_ALL)
copa_expect("unit exclusion" "${UNIT_EXCLUDED}" "^TRUE$")

##======================================================================================================================
## Sources the compiler has to reject, each naming what it must say
##======================================================================================================================
copa_glob_failure_unit(
  QUIET
  PATTERN "failure/*.cpp"
  RELATIVE ${ROOT}
  INTERFACE example_test)
