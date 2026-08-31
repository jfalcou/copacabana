##======================================================================================================================
##  Copacabana - Common CMake Package Tools
##  Copyright : Copacabana Project Contributors
##  SPDX-License-Identifier: BSL-1.0
##======================================================================================================================

## What copacabana's functions are expected to have left behind, checked against the example that calls them. Included
## by it, always: a failure stops the configure, which is the only moment these answers exist.

macro(COPA_EXPECT what value pattern)
  if(NOT "${value}" MATCHES "${pattern}")
    message(FATAL_ERROR "[${PROJECT_NAME}] - ${what} is '${value}', expected '${pattern}'")
  endif()
endmacro()

##======================================================================================================================
## copa_project_version
##======================================================================================================================
copa_expect("major version" "${PROJECT_VERSION_MAJOR}" "1")
copa_expect("minor version" "${PROJECT_VERSION_MINOR}" "2")
copa_expect("patch level"   "${PROJECT_VERSION_PATCH}" "3a")
copa_expect("version"       "${PROJECT_VERSION}"       "1.2.3a")

##======================================================================================================================
## copa_setup_doxygen, when there is a doxygen to find
##======================================================================================================================
if(DOXYGEN_FOUND)
  copa_expect("doxygen input"  "${PROJECT_DOXYGEN_SOURCE_DIR}" "${PROJECT_SOURCE_DIR}/doc")
  copa_expect("doxygen output" "${PROJECT_DOXYGEN_OUTPUT_DIR}" "${PROJECT_BINARY_DIR}/doxygen-output")
endif()

##======================================================================================================================
## copa_setup_standalone, when there is a python to run it
##======================================================================================================================
if(Python_FOUND)
  copa_expect("standalone target" "${PROJECT_STANDALONE_TARGET}" "standalone-example")
endif()

##======================================================================================================================
## copa_setup_pch
##======================================================================================================================
copa_expect("pch target" "${PROJECT_PCH_TARGET}" "example_pch")
