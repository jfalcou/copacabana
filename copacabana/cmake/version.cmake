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
  set(oneValueArgs MAJOR MINOR PATCH)
  cmake_parse_arguments(OPT "${options}" "${oneValueArgs}" "" ${ARGN})

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

  if(NOT OPT_QUIET)
    message(STATUS "[${PROJECT_NAME}] - Setup for version ${VERSION}")
  endif()

  ## Under the names project(VERSION) would have used, so a project has one spelling to read rather than two that
  ## say the same thing with the words in a different order. What keeps this function is the patch level: project()
  ## takes digits only, and a version like 1.2.3a has to come from somewhere.
  set(PROJECT_VERSION_MAJOR
      ${OPT_MAJOR}
      PARENT_SCOPE)
  set(PROJECT_VERSION_MINOR
      ${OPT_MINOR}
      PARENT_SCOPE)
  set(PROJECT_VERSION_PATCH
      ${OPT_PATCH}
      PARENT_SCOPE)
  set(PROJECT_VERSION
      "${VERSION}"
      PARENT_SCOPE)

endfunction()
