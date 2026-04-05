##======================================================================================================================
##  Copacabana - Common CMake Package Tools
##  Copyright : Copacabana Project Contributors
##  SPDX-License-Identifier: BSL-1.0
##======================================================================================================================

##======================================================================================================================
## Setup CPack for generating system installers (.deb, .rpm, .zip)
##======================================================================================================================
function(COPA_SETUP_CPACK)
  set(options QUIET)
  set(oneValueArgs VENDOR DESCRIPTION LICENSE_FILE MAINTAINER)
  set(multiValueArgs DEB_DEPENDENCIES RPM_DEPENDENCIES)
  cmake_parse_arguments(OPT "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  if(NOT OPT_VENDOR)
    set(OPT_VENDOR "Copacabana User")
  endif()
  if(NOT OPT_DESCRIPTION)
    set(OPT_DESCRIPTION "A C++ library packaged with Copacabana.")
  endif()
  if(NOT OPT_MAINTAINER)
    set(OPT_MAINTAINER "${OPT_VENDOR}")
  endif()

# Format DEB dependencies (Requires parentheses for versions: package (>= 1.0))
  if(OPT_DEB_DEPENDENCIES)
    list(JOIN OPT_DEB_DEPENDENCIES ", " FORMATTED_DEB_DEPS)
    set(CPACK_DEBIAN_PACKAGE_DEPENDS "${FORMATTED_DEB_DEPS}")
  endif()

  # Format RPM dependencies (Requires spaces for versions: package >= 1.0)
  if(OPT_RPM_DEPENDENCIES)
    list(JOIN OPT_RPM_DEPENDENCIES ", " FORMATTED_RPM_DEPS)
    set(CPACK_RPM_PACKAGE_REQUIRES "${FORMATTED_RPM_DEPS}")
  endif()

  set(CPACK_PACKAGE_NAME "${PROJECT_NAME}")
  set(CPACK_PACKAGE_VENDOR "${OPT_VENDOR}")
  set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "${OPT_DESCRIPTION}")
  set(CPACK_PACKAGE_VERSION_MAJOR "${PROJECT_MAJOR_VERSION}")
  set(CPACK_PACKAGE_VERSION_MINOR "${PROJECT_MINOR_VERSION}")
  set(CPACK_PACKAGE_VERSION_PATCH "${PROJECT_PATCH_VERSION}")
  set(CPACK_PACKAGE_CONTACT "${OPT_MAINTAINER}")

  if(OPT_LICENSE_FILE)
    set(CPACK_RESOURCE_FILE_LICENSE "${OPT_LICENSE_FILE}")
  endif()

  # FIX: Use robust, built-in CMake global properties for OS detection
  if(APPLE)
    set(CPACK_GENERATOR "TGZ;DragNDrop")
  elseif(UNIX)
    set(CPACK_GENERATOR "TGZ;DEB;RPM")
    set(CPACK_DEBIAN_PACKAGE_MAINTAINER "${OPT_MAINTAINER}")
  elseif(WIN32)
    set(CPACK_GENERATOR "ZIP")
  endif()

  # Include the native CPack module to finalize generation
  include(CPack)

  if(NOT OPT_QUIET)
    message(STATUS "[${PROJECT_NAME}] - Configured CPack for generators: ${CPACK_GENERATOR}")
  endif()
endfunction()