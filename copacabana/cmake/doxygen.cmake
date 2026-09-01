##======================================================================================================================
##  Copacabana - Common CMake Package Tools
##  Copyright : Copacabana Project Contributors
##  SPDX-License-Identifier: BSL-1.0
##======================================================================================================================

include(FetchContent)

##======================================================================================================================
##======================================================================================================================
## The two files copa_setup_doxygen generates into the output, from what its caller declared. Reads the OPT_ variables
## cmake_parse_arguments left in its caller's scope, and answers DOXYGEN_COLOR_SAT the same way.
##======================================================================================================================
macro(copa_doxygen_assets)
  ## One triplet, two consumers that had drifted apart: doxygen tints the widgets it generates from HTML_COLORSTYLE_*,
  ## and doxygen-awesome reads its own hsl() variables from a stylesheet. Writing both here is what keeps them the
  ## same colour - raberu's documentation had a red stylesheet over cyan doxygen widgets.
  ##
  ## The saturations are not the same number: doxygen's runs 0..255 where css writes a percentage.
  math(EXPR DOXYGEN_COLOR_SAT "(${OPT_COLOR_SATURATION} * 255 + 50) / 100")
  math(EXPR COLOR_DARK "${OPT_COLOR_LIGHTNESS} - 20")
  math(EXPR COLOR_LIGHT "${OPT_COLOR_LIGHTNESS} + 20")
  set(HS "${OPT_COLOR_HUE}, ${OPT_COLOR_SATURATION}%")
  file(
    GENERATE
    OUTPUT "${DOXYGEN_GENERATED}/color.css"
    CONTENT
      "html {
  --primary-dark-color: hsl(${HS}, ${COLOR_DARK}%);
  --primary-color: hsl(${HS}, ${OPT_COLOR_LIGHTNESS}%);
  --primary-light-color: hsl(${HS}, ${COLOR_LIGHT}%);

  --page-background-color: white;
  --page-foreground-color: hsl(${HS}, ${COLOR_DARK}%);
  --page-secondary-foreground-color: hsl(${HS}, ${OPT_COLOR_LIGHTNESS}%);
}
")
endmacro()

##======================================================================================================================
## What copa_setup_doxygen falls back on when its caller says nothing. The colour triplet is doxygen's own default, so
## a project that never mentions colour gets the documentation doxygen would have given it.
##======================================================================================================================
macro(copa_doxygen_defaults)
  ## The fleet spells PROJECT_NAME both ways - TTS and KUMI, spy and kyosu - so the Doxyfile cannot derive a file name
  ## or a macro name from it directly. Both spellings go out instead.
  string(TOLOWER ${PROJECT_NAME} PROJECT_LOWER)
  string(TOUPPER ${PROJECT_NAME} PROJECT_UPPER)

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

  ## Doxygen's own defaults, so a project that says nothing about colour gets what doxygen would have given it.
  if(NOT DEFINED OPT_COLOR_HUE)
    set(OPT_COLOR_HUE 220)
  endif()

  if(NOT DEFINED OPT_COLOR_SATURATION)
    set(OPT_COLOR_SATURATION 39)
  endif()

  if(NOT DEFINED OPT_COLOR_LIGHTNESS)
    set(OPT_COLOR_LIGHTNESS 45)
  endif()

  if(NOT DEFINED OPT_COLOR_GAMMA)
    set(OPT_COLOR_GAMMA 80)
  endif()
endmacro()

##======================================================================================================================
## Add Doxygen building target
##======================================================================================================================
function(copa_setup_doxygen)
  set(options QUIET)
  set(oneValueArgs
      SOURCE
      DESTINATION
      TARGET
      URL
      GODBOLT_COMPILER
      GODBOLT_OPTIONS
      COLOR_HUE
      COLOR_SATURATION
      COLOR_LIGHTNESS
      COLOR_GAMMA)
  set(multiValueArgs GODBOLT_LIBRARIES)
  cmake_parse_arguments(OPT "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  if(OPT_QUIET)
    find_package(Doxygen QUIET)
  else()
    find_package(Doxygen)
  endif()

  copa_doxygen_defaults()

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

    ## Where copacabana writes what it makes, outside what doxygen publishes.
    set(DOXYGEN_GENERATED "${CMAKE_CURRENT_BINARY_DIR}/copa-doxygen")

    ## doxygen expands $(VAR) in a Doxyfile, never in a header, so the header is configured rather than read.
    set(COPA_PROJECT_URL "${OPT_URL}")
    configure_file("${COPACABANA_SOURCE_DIR}/copacabana/cmake/asset/base.html.in" "${DOXYGEN_GENERATED}/base.html"
                   @ONLY)

    copa_doxygen_assets()

    set(DOXYGEN_CONFIG ${OPT_SOURCE}/Doxyfile)

    add_custom_target(
      ${OPT_TARGET}
      COMMAND
        DOXYGEN_OUPUT=${OPT_DESTINATION} DOXYGEN_PROJECT_NAME=${PROJECT_NAME} DOXYGEN_PROJECT_VERSION=${PROJECT_VERSION}
        DOXYGEN_ASSETS=${COPACABANA_SOURCE_DIR}/copacabana/cmake/asset AWESOME_ASSETS=${AWESOME_CSS_DIR}
        DOXYGEN_PROJECT_LOWER=${PROJECT_LOWER} DOXYGEN_PROJECT_UPPER=${PROJECT_UPPER} DOXYGEN_PROJECT_URL=${OPT_URL}
        DOXYGEN_COLOR_HUE=${OPT_COLOR_HUE} DOXYGEN_COLOR_SAT=${DOXYGEN_COLOR_SAT} DOXYGEN_COLOR_GAMMA=${OPT_COLOR_GAMMA}
        DOXYGEN_STRIP=${PROJECT_SOURCE_DIR} DOXYGEN_GENERATED=${DOXYGEN_GENERATED} ${DOXYGEN_EXECUTABLE}
        ${DOXYGEN_CONFIG}
      WORKING_DIRECTORY ${OPT_SOURCE}
      COMMENT "[${PROJECT_NAME}] - Generating API documentation with Doxygen"
      VERBATIM)

    set(PROJECT_DOXYGEN_SOURCE_DIR ${OPT_SOURCE} PARENT_SCOPE)
    set(PROJECT_DOXYGEN_OUTPUT_DIR ${OPT_DESTINATION} PARENT_SCOPE)

  else()
    message(STATUS "[${PROJECT_NAME}] - Doxygen need to be installed to generate the doxygen documentation")
  endif(DOXYGEN_FOUND)

endfunction()
