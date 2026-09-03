##======================================================================================================================
##  Copacabana - Common CMake Package Tools
##  Copyright : Copacabana Project Contributors
##  SPDX-License-Identifier: BSL-1.0
##======================================================================================================================

##======================================================================================================================
## Standalone header generation target
##======================================================================================================================
function(copa_setup_standalone)
  set(options QUIET)
  set(oneValueArgs SOURCE DESTINATION FILE ROOT TARGET OUTPUT)
  cmake_parse_arguments(OPT "${options}" "${oneValueArgs}" "" ${ARGN})

  copa_check_arguments()

  if(NOT DEFINED OPT_SOURCE)
    message(FATAL_ERROR "[${PROJECT_NAME}] - Standalone target setup header: Missing SOURCE folder")
  endif()

  if(NOT DEFINED OPT_OUTPUT)
    if(NOT DEFINED OPT_DESTINATION)
      message(FATAL_ERROR "[${PROJECT_NAME}] - Standalone target setup header: Missing DESTINATION folder")
    endif()

    set(OPT_OUTPUT "${CMAKE_CURRENT_SOURCE_DIR}/${OPT_DESTINATION}/${OPT_ROOT}")
  endif()

  if(NOT DEFINED OPT_FILE)
    message(FATAL_ERROR "[${PROJECT_NAME}] - Standalone target setup header: Missing FILE name")
  endif()

  # The name package-standalone.yml builds, and the shape the doxygen and test targets already take.
  if(NOT DEFINED OPT_TARGET)
    string(TOLOWER "${PROJECT_NAME}" PROJECT_LOWER)
    set(OPT_TARGET "${PROJECT_LOWER}-standalone")
  endif()

  if(NOT OPT_QUIET)
    find_package(Python COMPONENTS Interpreter)
  else()
    find_package(Python COMPONENTS Interpreter QUIET)
  endif()

  if(Python_FOUND)
    set(DST_FILE "${OPT_OUTPUT}/${OPT_FILE}")

    add_custom_command(
      OUTPUT ${DST_FILE}
      COMMAND
        "${Python_EXECUTABLE}" ${COPACABANA_SOURCE_DIR}/copacabana/cmake/asset/embed.py
        ${CMAKE_CURRENT_SOURCE_DIR}/${OPT_SOURCE}/${OPT_ROOT}/${OPT_FILE} -I ${OPT_SOURCE} -o ${DST_FILE}
        --include-match ${OPT_ROOT}/.*
      WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
      DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/${OPT_SOURCE}/${OPT_ROOT}/${OPT_FILE}
      COMMENT "[${PROJECT_NAME}] - Generating standalone header: ${DST_FILE}"
      VERBATIM)

    add_custom_target(${OPT_TARGET} DEPENDS ${DST_FILE} COMMENT "[${PROJECT_NAME}] - Assembling the standalone header")

    set_property(TARGET ${OPT_TARGET} APPEND PROPERTY ADDITIONAL_CLEAN_FILES ${DST_FILE})

    if(NOT OPT_QUIET)
      message(STATUS "[${PROJECT_NAME}] - Target ${OPT_TARGET} generates header ${DST_FILE}")
    endif()

    set(PROJECT_STANDALONE_TARGET "${OPT_TARGET}" PARENT_SCOPE)
  endif()
endfunction()
