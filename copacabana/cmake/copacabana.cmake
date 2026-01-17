##======================================================================================================================
##  Copacabana - Common CMake Package Tools
##  Copyright : Copacabana Project Contributors
##  SPDX-License-Identifier: BSL-1.0
##======================================================================================================================

##======================================================================================================================
## Prevent in-source build
##======================================================================================================================
if (${PROJECT_SOURCE_DIR} STREQUAL ${PROJECT_BINARY_DIR})
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
