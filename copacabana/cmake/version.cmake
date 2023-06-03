##======================================================================================================================
##  Copacabana - Common CMake Package Tools
##  Copyright : Copacabana Project Contributors
##  SPDX-License-Identifier: BSL-1.0
##======================================================================================================================

##======================================================================================================================
## Defines version related informations for project
##======================================================================================================================
function(COPA_PROJECT_VERSION)
  set(options QUIET)
  set(oneValueArgs  MAJOR MINOR PATCH)
  cmake_parse_arguments(OPT "${options}" "${oneValueArgs}" "" ${ARGN} )

  if(NOT DEFINED OPT_MAJOR)
    set(OPT_MAJOR 0)
  endif()

  if(NOT DEFINED OPT_MINOR)
    set(OPT_MINOR 1)
  endif()

  if(NOT DEFINED OPT_PATCH)
    set(OPT_PATCH 0)
  endif()

  set(VERSION "${OPT_MAJOR}.${OPT_MINOR}.${OPT_PATCH}")

  if(NOT ${OPT_QUIET})
    message(STATUS "[${PROJECT_NAME}] - Setup for version ${VERSION}")
  endif()

  set(PROJECT_MAJOR_VERSION ${OPT_MAJOR}  PARENT_SCOPE)
  set(PROJECT_MINOR_VERSION ${OPT_MINOR}  PARENT_SCOPE)
  set(PROJECT_PATCH_VERSION ${OPT_PATCH}  PARENT_SCOPE)
  set(PROJECT_VERSION       "${VERSION}"  PARENT_SCOPE)

endfunction()
