##======================================================================================================================
##  Copacabana - Common CMake Package Tools
##  Copyright : Copacabana Project Contributors
##  SPDX-License-Identifier: BSL-1.0
##======================================================================================================================

include(FetchContent)

##======================================================================================================================
## Downloads what TAGFILES names and works out the paths the Doxyfile reads them from.
##======================================================================================================================
macro(copa_doxygen_tagfiles)
  ## Doxygen never fetches anything itself: a tagfile has to be on disk before the target runs, and the Doxyfile
  ## has to name a path. Both are worked out here from <name>=<url>, and reach the Doxyfile as DOXYGEN_TAGS.
  set(DOXYGEN_TAGS "")
  foreach(entry IN LISTS OPT_TAGFILES)
    if(NOT entry MATCHES "^([^=]+)=(.+)$")
      message(FATAL_ERROR "[${PROJECT_NAME}] - TAGFILES wants <name>=<url>, got '${entry}'")
    endif()
    set(TAG_NAME "${CMAKE_MATCH_1}")
    set(TAG_SITE "${CMAKE_MATCH_2}")
    string(REGEX REPLACE "/$" "" TAG_SITE "${TAG_SITE}")
    set(TAG_FILE "${DOXYGEN_GENERATED}/${TAG_NAME}.tag")

    file(DOWNLOAD "${TAG_SITE}/${TAG_NAME}.tag" "${TAG_FILE}" STATUS TAG_STATUS)
    list(GET TAG_STATUS 0 TAG_CODE)
    if(NOT TAG_CODE EQUAL 0)
      message(WARNING "[${PROJECT_NAME}] - ${TAG_NAME}.tag could not be fetched (${TAG_STATUS}), "
                      "the ${TAG_NAME}:: links will be dead")
    endif()

    string(APPEND DOXYGEN_TAGS " ${TAG_FILE}=${TAG_SITE}")
  endforeach()
  string(STRIP "${DOXYGEN_TAGS}" DOXYGEN_TAGS)
endmacro()

##======================================================================================================================
## The two files copa_setup_doxygen generates into the output, from what its caller declared. Reads the OPT_ variables
## cmake_parse_arguments left in its caller's scope, and answers DOXYGEN_COLOR_SAT the same way.
##======================================================================================================================
macro(copa_doxygen_assets)
  ## One triplet, two consumers that had drifted apart: doxygen tints the widgets it generates from HTML_COLORSTYLE_*,
  ## and doxygen-awesome reads its own hsl() variables from a stylesheet. Writing both here is what keeps them the
  ## same colour: written by hand in two places they drift, and the stylesheet wins where the reader looks.
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
  ## PROJECT_NAME is spelled either way from one project to the next, so the Doxyfile cannot derive a file name
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
      GODBOLT_COMPILER
      GODBOLT_OPTIONS
      COLOR_HUE
      COLOR_SATURATION
      COLOR_LIGHTNESS
      COLOR_GAMMA)
  set(multiValueArgs GODBOLT_LIBRARIES TAGFILES)
  cmake_parse_arguments(OPT "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  copa_check_arguments()

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

    ## Compiler Explorer loads the libraries in the order given, and a snippet needs every one it includes: a project
    ## built on another does not compile there without it beside. The shared header reads this rather than naming
    ## them, so one header serves every project.
    string(JOIN ":" GODBOLT_LIBRARIES ${OPT_GODBOLT_LIBRARIES})
    file(
      GENERATE
      OUTPUT "${OPT_DESTINATION}/godbolt-config.js"
      CONTENT "const GODBOLT_LIBRARIES = \"${GODBOLT_LIBRARIES}\"\n\
const GODBOLT_COMPILER  = \"${OPT_GODBOLT_COMPILER}\"\n\
const GODBOLT_OPTIONS   = \"${OPT_GODBOLT_OPTIONS}\"\n")

    ## Where copacabana writes what it makes, outside what doxygen publishes.
    set(DOXYGEN_GENERATED "${CMAKE_CURRENT_BINARY_DIR}/copa-doxygen")

    copa_doxygen_tagfiles()

    ## doxygen expands $(VAR) in a Doxyfile, never in a header, so the header is configured rather than read.
    ## Drawn only when copa_project_version was told where the project lives. A corner pointing at a guess is worse
    ## than no corner, and the repository is said once rather than twice.
    set(COPA_GITHUB_CORNER "")
    if(COPA_PROJECT_REPOSITORY)
      set(COPA_PROJECT_URL "${COPA_PROJECT_REPOSITORY}")
      configure_file("${COPACABANA_SOURCE_DIR}/copacabana/cmake/asset/github-corner.html.in"
                     "${DOXYGEN_GENERATED}/github-corner.html" @ONLY)
      file(READ "${DOXYGEN_GENERATED}/github-corner.html" COPA_GITHUB_CORNER)
    endif()

    ## Anything a project wants in the <head> and copacabana cannot work out: the Open Graph and Twitter tags a link
    ## to these pages unfurls into are prose about the project and absolute URLs to where it is published, so they
    ## are written by the project and dropped beside its Doxyfile. Without the file the head is what it has always
    ## been, rather than a set of empty tags.
    set(COPA_EXTRA_HEAD "")
    if(EXISTS "${OPT_SOURCE}/head.html")
      file(READ "${OPT_SOURCE}/head.html" COPA_EXTRA_HEAD)
    endif()
    configure_file("${COPACABANA_SOURCE_DIR}/copacabana/cmake/asset/base.html.in" "${DOXYGEN_GENERATED}/base.html"
                   @ONLY)

    copa_doxygen_assets()

    set(DOXYGEN_CONFIG ${OPT_SOURCE}/Doxyfile)

    add_custom_target(
      ${OPT_TARGET}
      COMMAND
        DOXYGEN_OUPUT=${OPT_DESTINATION} DOXYGEN_PROJECT_NAME=${PROJECT_NAME} DOXYGEN_PROJECT_VERSION=${PROJECT_VERSION}
        DOXYGEN_ASSETS=${COPACABANA_SOURCE_DIR}/copacabana/cmake/asset AWESOME_ASSETS=${AWESOME_CSS_DIR}
        DOXYGEN_PROJECT_LOWER=${PROJECT_LOWER} DOXYGEN_PROJECT_UPPER=${PROJECT_UPPER} DOXYGEN_COLOR_HUE=${OPT_COLOR_HUE}
        DOXYGEN_COLOR_SAT=${DOXYGEN_COLOR_SAT} DOXYGEN_COLOR_GAMMA=${OPT_COLOR_GAMMA}
        DOXYGEN_STRIP=${PROJECT_SOURCE_DIR} DOXYGEN_GENERATED=${DOXYGEN_GENERATED} "DOXYGEN_TAGS=${DOXYGEN_TAGS}"
        ${DOXYGEN_EXECUTABLE} ${DOXYGEN_CONFIG}
      WORKING_DIRECTORY ${OPT_SOURCE}
      COMMENT "[${PROJECT_NAME}] - Generating API documentation with Doxygen"
      VERBATIM)

    ## Reading a tagfile also hands doxygen every symbol the other project documents, which then fills this one's
    ## search box, where most of the results then lead somewhere else. Doxygen has no setting for it, so the generated
    ## index is trimmed once the pages are written.
    if(OPT_TAGFILES)
      add_custom_command(
        TARGET ${OPT_TARGET}
        POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E env python3
                "${COPACABANA_SOURCE_DIR}/copacabana/cmake/asset/strip_external_search.py" "${OPT_DESTINATION}/search"
        COMMENT "[${PROJECT_NAME}] - Dropping the external symbols from the search index"
        VERBATIM)
    endif()

    set(PROJECT_DOXYGEN_SOURCE_DIR ${OPT_SOURCE} PARENT_SCOPE)
    set(PROJECT_DOXYGEN_OUTPUT_DIR ${OPT_DESTINATION} PARENT_SCOPE)

  else()
    message(STATUS "[${PROJECT_NAME}] - Doxygen need to be installed to generate the doxygen documentation")
  endif(DOXYGEN_FOUND)

endfunction()
