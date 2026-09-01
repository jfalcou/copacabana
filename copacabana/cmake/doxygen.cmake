##======================================================================================================================
##  Copacabana - Common CMake Package Tools
##  Copyright : Copacabana Project Contributors
##  SPDX-License-Identifier: BSL-1.0
##======================================================================================================================

include(FetchContent)

##======================================================================================================================
## Add Doxygen building target
##======================================================================================================================
function(copa_setup_doxygen)
  set(options QUIET)
  set(oneValueArgs SOURCE DESTINATION TARGET URL GODBOLT_COMPILER GODBOLT_OPTIONS)
  set(multiValueArgs GODBOLT_LIBRARIES)
  cmake_parse_arguments(OPT "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  if(OPT_QUIET)
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

  if(NOT DEFINED OPT_URL)
    string(TOLOWER ${PROJECT_NAME} NAME)
    set(OPT_URL "https://github.com/jfalcou/${NAME}")
  endif()

  if(NOT DEFINED OPT_GODBOLT_COMPILER)
    set(OPT_GODBOLT_COMPILER "clang1600")
  endif()

  if(NOT DEFINED OPT_GODBOLT_OPTIONS)
    set(OPT_GODBOLT_OPTIONS "-O3 -std=c++20 -DNDEBUG")
  endif()

  if(DOXYGEN_FOUND)
    if(NOT OPT_QUIET)
      message(STATUS "[${PROJECT_NAME}] - Doxygen available via the ${OPT_TARGET} target")
    endif()

    ## The stylesheet is of no use without doxygen, and this is the only place that reads it, so a project that never
    ## asks for documentation - or that has no doxygen to run - downloads nothing.
    FetchContent_Declare(
      doxygen-awesome-css URL https://github.com/jothepro/doxygen-awesome-css/archive/refs/tags/v2.4.2.zip
                              DOWNLOAD_EXTRACT_TIMESTAMP TRUE)
    FetchContent_MakeAvailable(doxygen-awesome-css)
    FetchContent_GetProperties(doxygen-awesome-css SOURCE_DIR AWESOME_CSS_DIR)

    ## Compiler Explorer loads the libraries in the order given, and a snippet needs every one it includes: kyosu's
    ## examples do not build there without eve beside them. The shared header reads this rather than naming them, so
    ## one header serves every project.
    string(JOIN ":" GODBOLT_LIBRARIES ${OPT_GODBOLT_LIBRARIES})
    file(
      GENERATE
      OUTPUT "${OPT_DESTINATION}/godbolt-config.js"
      CONTENT "const GODBOLT_LIBRARIES = \"${GODBOLT_LIBRARIES}\"\n\
const GODBOLT_COMPILER  = \"${OPT_GODBOLT_COMPILER}\"\n\
const GODBOLT_OPTIONS   = \"${OPT_GODBOLT_OPTIONS}\"\n")

    set(DOXYGEN_CONFIG ${OPT_SOURCE}/Doxyfile)

    add_custom_target(
      ${OPT_TARGET}
      COMMAND
        DOXYGEN_OUPUT=${OPT_DESTINATION} DOXYGEN_PROJECT_NAME=${PROJECT_NAME} DOXYGEN_PROJECT_VERSION=${PROJECT_VERSION}
        DOXYGEN_ASSETS=${COPACABANA_SOURCE_DIR}/copacabana/cmake/asset AWESOME_ASSETS=${AWESOME_CSS_DIR}
        DOXYGEN_PROJECT_URL=${OPT_URL} DOXYGEN_STRIP=${PROJECT_SOURCE_DIR} ${DOXYGEN_EXECUTABLE} ${DOXYGEN_CONFIG}
      WORKING_DIRECTORY ${OPT_SOURCE}
      COMMENT "[${PROJECT_NAME}] - Generating API documentation with Doxygen"
      VERBATIM)

    set(PROJECT_DOXYGEN_SOURCE_DIR
        ${OPT_SOURCE}
        PARENT_SCOPE)
    set(PROJECT_DOXYGEN_OUTPUT_DIR
        ${OPT_DESTINATION}
        PARENT_SCOPE)

  else()
    message(STATUS "[${PROJECT_NAME}] - Doxygen need to be installed to generate the doxygen documentation")
  endif(DOXYGEN_FOUND)

endfunction()
