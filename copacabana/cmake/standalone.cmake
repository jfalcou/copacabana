##======================================================================================================================
##  Copacabana - Common CMake Package Tools
##  Copyright : Copacabana Project Contributors
##  SPDX-License-Identifier: BSL-1.0
##======================================================================================================================

##======================================================================================================================
## Standalone header generation target
##======================================================================================================================
function(COPA_SETUP_STANDALONE)
  set(options       QUIET )
  set(oneValueArgs  SOURCE DESTINATION FILE ROOT TARGET)
  cmake_parse_arguments(OPT "${options}" "${oneValueArgs}" "" ${ARGN} )

  if(NOT DEFINED OPT_SOURCE)
    message(FATAL_ERROR "[${PROJECT_NAME}] - Standalone target setup header: Missing SOURCE folder")
  endif()

  if(NOT DEFINED OPT_DESTINATION)
    message(FATAL_ERROR "[${PROJECT_NAME}] - Standalone target setup header: Missing DESTINATION folder")
  endif()

  if(NOT DEFINED OPT_FILE)
    message(FATAL_ERROR "[${PROJECT_NAME}] - Standalone target setup header: Missing FILE name")
  endif()

  if(NOT DEFINED OPT_TARGET)
    set(OPT_TARGET "standalone")
  endif()

  if(NOT ${OPT_QUIET})
    find_package(Python COMPONENTS Interpreter)
  else()
      find_package(Python COMPONENTS Interpreter QUIET)
  endif()

  if(Python_FOUND)
    set(DST_FILE "${OPT_DESTINATION}/${OPT_ROOT}/${OPT_FILE}")
    add_custom_command(OUTPUT ${OPT_FILE}
      COMMAND "${Python_EXECUTABLE}"
              ${COPACABANA_SOURCE_DIR}/cmake/asset/embed.py
              ${CMAKE_CURRENT_SOURCE_DIR}/${OPT_SOURCE}/${OPT_ROOT}/${OPT_FILE}
              -I ${OPT_SOURCE}
              -o ${CMAKE_CURRENT_SOURCE_DIR}/${DST_FILE}
              --include-match ${OPT_ROOT}/*
      WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
      COMMENT "[${PROJECT_NAME}] - Generating standalone header: ${DST_FILE}"
      VERBATIM
    )

  add_custom_target( ${OPT_TARGET} DEPENDS ${OPT_FILE})

  set_property( TARGET ${OPT_TARGET} APPEND PROPERTY
                ADDITIONAL_CLEAN_FILES ${CMAKE_CURRENT_SOURCE_DIR}/${DST_FILE}
              )

  if(NOT ${OPT_QUIET})
    message(STATUS "[${PROJECT_NAME}] - Target ${OPT_TARGET} generates header ${DST_FILE}" )
  endif()

  set(PROJECT_STANDALONE_TARGET "${OPT_TARGET}" PARENT_SCOPE)
  endif()
endfunction()
