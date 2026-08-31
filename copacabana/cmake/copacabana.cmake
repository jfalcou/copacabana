##======================================================================================================================
##  Copacabana - Common CMake Package Tools
##  Copyright : Copacabana Project Contributors
##  SPDX-License-Identifier: BSL-1.0
##======================================================================================================================
include_guard(GLOBAL)

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
include( ${COPACABANA_SOURCE_DIR}/copacabana/cmake/version.cmake    )
include( ${COPACABANA_SOURCE_DIR}/copacabana/cmake/precommit.cmake  )
include( ${COPACABANA_SOURCE_DIR}/copacabana/cmake/doxygen.cmake    )
include( ${COPACABANA_SOURCE_DIR}/copacabana/cmake/install.cmake    )
include( ${COPACABANA_SOURCE_DIR}/copacabana/cmake/make_unit.cmake  )
include( ${COPACABANA_SOURCE_DIR}/copacabana/cmake/pch.cmake        )
include( ${COPACABANA_SOURCE_DIR}/copacabana/cmake/standalone.cmake )
include( ${COPACABANA_SOURCE_DIR}/copacabana/cmake/sanitizers.cmake )
include( ${COPACABANA_SOURCE_DIR}/copacabana/cmake/coverage.cmake   )
include( ${COPACABANA_SOURCE_DIR}/copacabana/cmake/cpack.cmake      )
