##======================================================================================================================
##  Copacabana - Common CMake Package Tools
##  Copyright : Copacabana Project Contributors
##  SPDX-License-Identifier: BSL-1.0
##======================================================================================================================

##======================================================================================================================
## Add Doxygen building target
##======================================================================================================================
function(COPA_SETUP_DOXYGEN)
  set(options       QUIET   )
  set(oneValueArgs  SOURCE DESTINATION TARGET)
  cmake_parse_arguments(OPT "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )

  if(NOT ${OPT_QUIET})
    find_package(Doxygen QUIET)
  else()
    find_package(Doxygen)
  endif()

  if(NOT DEFINED OPT_TARGET)
    string(TOLOWER ${PROJECT_NAME} NAME)
    set(OPT_TARGET "${NAME}-doxygen")
  endif()

  if(NOT DEFINED OPT_SOURCE)
    set(OPT_SOURCE "${PROJECT_SOURCE_DIR}/doc")
  endif()

  if(NOT DEFINED OPT_DESTINATION)
    set(OPT_DESTINATION "${PROJECT_BINARY_DIR}/docs")
  endif()

  if (DOXYGEN_FOUND)
    if(NOT ${OPT_QUIET})
      message( STATUS "[${PROJECT_NAME}] - Doxygen available via the ${OPT_TARGET} target")
    endif()
    set(DOXYGEN_CONFIG ${OPT_SOURCE}/Doxyfile)

    add_custom_target ( ${OPT_TARGET}
                        COMMAND DOXYGEN_OUPUT=${OPT_DESTINATION}
                                DOXYGEN_PROJECT_NAME=${PROJECT_NAME}
                                DOXYGEN_PROJECT_VERSION=${PROJECT_VERSION}
                                DOXYGEN_ASSETS=${COPACABANA_SOURCE_DIR}/copacabana/cmake/asset
                                DOXYGEN_STRIP=${PROJECT_SOURCE_DIR}
                                ${DOXYGEN_EXECUTABLE} ${DOXYGEN_CONFIG}

                        WORKING_DIRECTORY ${OPT_SOURCE}
                        COMMENT "[${PROJECT_NAME}] - Generating API documentation with Doxygen"
                        VERBATIM
                      )

    set(PROJECT_DOXYGEN_SOURCE_DIR ${OPT_SOURCE}      PARENT_SCOPE)
    set(PROJECT_DOXYGEN_OUTPUT_DIR ${OPT_DESTINATION} PARENT_SCOPE)

  else()
   message( STATUS "[${PROJECT_NAME}] - Doxygen need to be installed to generate the doxygen documentation")
  endif (DOXYGEN_FOUND)

endfunction()
