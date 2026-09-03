##======================================================================================================================
##  Copacabana - Common CMake Package Tools
##  Copyright : Copacabana Project Contributors
##  SPDX-License-Identifier: BSL-1.0
##======================================================================================================================

##======================================================================================================================
## Declare an option and remember it for the summary
##
## copa_add_option( <name> <help> <default>
##                  [LABEL <text>] # What the summary calls it, defaults to the name without the project's prefix
##                )
##
## The same three arguments as option(), so a call converts by changing the word. What it adds is the memory: every
## option declared this way is listed by copa_show_options, in this order, so that a new option cannot be added to a
## project without reaching its summary. The list is kept per project, a build holding two consumers keeping two.
##======================================================================================================================
function(copa_add_option name help default)
  set(oneValueArgs LABEL)
  cmake_parse_arguments(OPT "" "${oneValueArgs}" "" ${ARGN})

  copa_check_arguments()

  option(${name} "${help}" ${default})

  # TTS_COMPILE_COST reads "Compile cost": the prefix goes, the rest is words.
  if(NOT DEFINED OPT_LABEL)
    string(TOUPPER "${PROJECT_NAME}_" PREFIX)
    string(REGEX REPLACE "^${PREFIX}" "" OPT_LABEL "${name}")
    string(REPLACE "_" " " OPT_LABEL "${OPT_LABEL}")
    string(TOLOWER "${OPT_LABEL}" OPT_LABEL)
    # Spliced rather than replaced by a regex: CMake's ^ matches again after every replacement it makes.
    string(SUBSTRING "${OPT_LABEL}" 0 1 FIRST)
    string(SUBSTRING "${OPT_LABEL}" 1 -1 REST)
    string(TOUPPER "${FIRST}" FIRST)
    set(OPT_LABEL "${FIRST}${REST}")
  endif()

  set_property(GLOBAL APPEND PROPERTY "COPA_OPTIONS_${PROJECT_NAME}" "${name}")
  set_property(GLOBAL PROPERTY "COPA_OPTION_LABEL_${name}" "${OPT_LABEL}")
endfunction()

##======================================================================================================================
## Print the build type and every option copa_add_option declared, aligned
##
## copa_show_options( [QUIET] )
##
##   [MYLIB] - Building in Debug mode
##   [MYLIB] - Unit tests   : ON (via MYLIB_BUILD_TEST)
##   [MYLIB] - Compile cost : OFF (via MYLIB_COMPILE_COST)
##
## Nothing is printed when the project's quiet option is on, or when QUIET is passed. That option, <PROJECT>_QUIET, is
## declared here, since this is what reads it: a project has one switch for its whole configure output, and it
## exists whether or not the project thought of declaring it. It is not listed in the summary it silences.
##
## The function exists so that the summary is one call rather than one line per option, written by hand and
## forgotten for the last one added.
##======================================================================================================================
function(copa_show_options)
  set(options QUIET)
  cmake_parse_arguments(OPT "${options}" "" "" ${ARGN})

  copa_check_arguments()

  string(TOUPPER "${PROJECT_NAME}_QUIET" PROJECT_QUIET)
  option(${PROJECT_QUIET} "Silence the configure output of ${PROJECT_NAME}" OFF)

  if(OPT_QUIET OR ${PROJECT_QUIET})
    return()
  endif()

  if(CMAKE_BUILD_TYPE)
    message(STATUS "[${PROJECT_NAME}] - Building in ${CMAKE_BUILD_TYPE} mode")
  endif()

  get_property(NAMES GLOBAL PROPERTY "COPA_OPTIONS_${PROJECT_NAME}")

  set(WIDTH 0)
  foreach(name IN LISTS NAMES)
    get_property(LABEL GLOBAL PROPERTY "COPA_OPTION_LABEL_${name}")
    string(LENGTH "${LABEL}" SIZE)
    if(SIZE GREATER WIDTH)
      set(WIDTH ${SIZE})
    endif()
  endforeach()

  foreach(name IN LISTS NAMES)
    get_property(LABEL GLOBAL PROPERTY "COPA_OPTION_LABEL_${name}")
    string(LENGTH "${LABEL}" SIZE)
    math(EXPR PADDING "${WIDTH} - ${SIZE}")
    string(REPEAT " " ${PADDING} PAD)
    message(STATUS "[${PROJECT_NAME}] - ${LABEL}${PAD} : ${${name}} (via ${name})")
  endforeach()
endfunction()
