##======================================================================================================================
##  Copacabana - Common CMake Package Tools
##  Copyright : Copacabana Project Contributors
##  SPDX-License-Identifier: BSL-1.0
##======================================================================================================================
## DIRECTORY, not GLOBAL: including this file has side effects that belong to the scope doing the including - the
## whole CMAKE_INSTALL_* family, which install.cmake gets from GNUInstallDirs. Under GLOBAL the first consumer to
## reach the include takes them and every later one is left without, so a build holding two consumers - a library
## and the test framework it pulls - configures with an empty CMAKE_INSTALL_DOCDIR in the second.
include_guard(DIRECTORY)

##======================================================================================================================
## What cmake_parse_arguments does with a keyword it does not know: nothing. It lands in UNPARSED_ARGUMENTS, the
## setting takes its default, and a typed DESTINATON configures as quietly as a correct one. Every copa_ function
## calls this straight after parsing so that a misspelling fails where it was written.
##
## Only the unknown ones. A keyword arriving with no value is what forwarding an empty list looks like, which these
## functions do to each other, so flagging it would fail on correct code.
##======================================================================================================================
macro(copa_check_arguments)
  if(OPT_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "[${PROJECT_NAME}] - ${CMAKE_CURRENT_FUNCTION}: unknown argument(s) ${OPT_UNPARSED_ARGUMENTS}")
  endif()
endmacro()

##======================================================================================================================
## Prevent in-source build
##======================================================================================================================
## Against the top level rather than the current project, and through REALPATH so that a build directory symlinked
## into the source tree is caught as well. The CMAKE_ pair is set before project() runs, where the PROJECT_ pair is
## still empty and would compare equal.
get_filename_component(COPA_SOURCE_PATH "${CMAKE_SOURCE_DIR}" REALPATH)
get_filename_component(COPA_BINARY_PATH "${CMAKE_BINARY_DIR}" REALPATH)

if(COPA_SOURCE_PATH STREQUAL COPA_BINARY_PATH)
  message(FATAL_ERROR "[${PROJECT_NAME}]: In-source build is not supported")
endif()

##======================================================================================================================
## Sub-package
##======================================================================================================================
include(${COPACABANA_SOURCE_DIR}/copacabana/cmake/version.cmake)
include(${COPACABANA_SOURCE_DIR}/copacabana/cmake/precommit.cmake)
include(${COPACABANA_SOURCE_DIR}/copacabana/cmake/doxygen.cmake)
include(${COPACABANA_SOURCE_DIR}/copacabana/cmake/install.cmake)
include(${COPACABANA_SOURCE_DIR}/copacabana/cmake/make_unit.cmake)
include(${COPACABANA_SOURCE_DIR}/copacabana/cmake/pch.cmake)
include(${COPACABANA_SOURCE_DIR}/copacabana/cmake/standalone.cmake)
include(${COPACABANA_SOURCE_DIR}/copacabana/cmake/sanitizers.cmake)
include(${COPACABANA_SOURCE_DIR}/copacabana/cmake/coverage.cmake)
include(${COPACABANA_SOURCE_DIR}/copacabana/cmake/compile_cost.cmake)
include(${COPACABANA_SOURCE_DIR}/copacabana/cmake/cpack.cmake)
