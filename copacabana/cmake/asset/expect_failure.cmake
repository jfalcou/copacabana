##======================================================================================================================
##  Copacabana - Common CMake Package Tools
##  Copyright : Copacabana Project Contributors
##  SPDX-License-Identifier: BSL-1.0
##======================================================================================================================
## Builds one target that is meant not to compile, and passes only if it did not compile for the stated reason.
##
## The reasons are read from the source rather than named here, one per line:
##
##   // build error: Duplicate fields in record definition
##
## A diagnostic the compiler words itself, rather than one quoting a static_assert, differs from compiler to compiler.
## Such a line names the one it belongs to, and is ignored under any other:
##
##   // build error-gcc: which is of non-class type
##   // build error-clang: is not a structure or union
##
## A source whose every line names another compiler than the one in use has nothing left to check, so the test reports
## itself skipped rather than passing on nothing.
##
##   cmake -DBUILD_DIR=... -DTARGET=... -DSOURCE=... -DCONFIG=... -DCOMPILER=... -P expect_failure.cmake
##======================================================================================================================
cmake_minimum_required(VERSION 3.22)

set(SKIPPED 77)

foreach(var BUILD_DIR TARGET SOURCE)
  if(NOT DEFINED ${var})
    message(FATAL_ERROR "expect_failure: ${var} is required")
  endif()
endforeach()

file(STRINGS "${SOURCE}" DECLARED REGEX "^[ \t]*//[ \t]*build error(-[A-Za-z]+)?:")
if(NOT DECLARED)
  message(FATAL_ERROR "expect_failure: ${SOURCE} says nothing it should fail with.\n"
                      "Add a '// build error: <text>' line for each diagnostic the compiler has to emit.")
endif()

## CMAKE_CXX_COMPILER_ID spells them GNU and AppleClang, where someone writing a test says gcc and clang.
string(TOLOWER "${COMPILER}" IN_USE)
if(IN_USE STREQUAL "gnu")
  set(IN_USE "gcc")
elseif(IN_USE STREQUAL "appleclang")
  set(IN_USE "clang")
endif()

set(EXPECTED "")
foreach(line IN LISTS DECLARED)
  string(REGEX MATCH "^[ \t]*//[ \t]*build error(-[A-Za-z]+)?:" MARKER "${line}")
  string(REGEX REPLACE "^[ \t]*//[ \t]*build error-?" "" TAG "${MARKER}")
  string(REGEX REPLACE ":$" "" TAG "${TAG}")
  string(TOLOWER "${TAG}" TAG)

  if(TAG STREQUAL "" OR TAG STREQUAL IN_USE)
    string(REGEX REPLACE "^[ \t]*//[ \t]*build error(-[A-Za-z]+)?:[ \t]*" "" WANTED "${line}")
    string(STRIP "${WANTED}" WANTED)
    list(APPEND EXPECTED "${WANTED}")
  endif()
endforeach()

if(NOT EXPECTED)
  message(STATUS "${SOURCE} names no diagnostic for ${IN_USE}")
  cmake_language(EXIT ${SKIPPED})
endif()

set(BUILD_ARGS --build "${BUILD_DIR}" --target "${TARGET}")
if(DEFINED CONFIG AND NOT CONFIG STREQUAL "")
  list(APPEND BUILD_ARGS --config "${CONFIG}")
endif()

execute_process(
  COMMAND "${CMAKE_COMMAND}" ${BUILD_ARGS}
  RESULT_VARIABLE BUILD_RESULT
  OUTPUT_VARIABLE BUILD_OUTPUT
  ERROR_VARIABLE BUILD_ERRORS)
set(DIAGNOSTICS "${BUILD_OUTPUT}${BUILD_ERRORS}")

if(BUILD_RESULT EQUAL 0)
  string(REPLACE ";" "\n  " WANTED_LIST "${EXPECTED}")
  message(FATAL_ERROR "${SOURCE} compiled, and it is written to be rejected.\n"
                      "It was to be turned down with:\n  ${WANTED_LIST}")
endif()

## Failing is not enough. A typo, a missing include or a renamed header fails too, and would leave the check green
## while proving nothing about the diagnostic it is there to pin.
set(MISSING "")
foreach(WANTED IN LISTS EXPECTED)
  string(FIND "${DIAGNOSTICS}" "${WANTED}" found)
  if(found EQUAL -1)
    list(APPEND MISSING "${WANTED}")
  endif()
endforeach()

if(MISSING)
  string(REPLACE ";" "\n  " MISSING "${MISSING}")
  message(FATAL_ERROR "${SOURCE} failed to build, but not for what it says.\n"
                      "Never said:\n  ${MISSING}\n\nWhat the compiler said:\n${DIAGNOSTICS}")
endif()
