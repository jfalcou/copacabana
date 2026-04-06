##======================================================================================================================
##  Copacabana - Common CMake Package Tools
##  Copyright : Copacabana Project Contributors
##  SPDX-License-Identifier: BSL-1.0
##======================================================================================================================
function(COPA_SETUP_TEST_TARGETS)
  string(TOLOWER ${PROJECT_NAME} NAME)
  set(PROJECT_TEST_TARGET "${NAME}-test")
  if(NOT TARGET ${PROJECT_TEST_TARGET})
    add_custom_target(${PROJECT_TEST_TARGET})
    set(PROJECT_TEST_TARGET "${PROJECT_TEST_TARGET}" PARENT_SCOPE)
  endif()
endfunction()

##======================================================================================================================
## For any target of the form XXX.YYY.ZZZ.exe, generates all the intermediate XXX.YYY.exe and XXX.exe targets
##======================================================================================================================
function(COPA_ADD_TARGET_PARENT target extension)
  # Strip the extension first to look at the 'stem' logic
  string(REPLACE ".${extension}" "" stem "${target}")

  if(stem MATCHES "\\.")
    # Strip the last part of the stem
    string(REGEX REPLACE "\\.[^.]+$" "" parent_stem "${stem}")

    # Re-attach the extension for the parent target name
    set(parent_target "${parent_stem}.${extension}")

    if(NOT TARGET ${parent_target})
      add_custom_target(${parent_target})

      # Extract suffix for IDE folder grouping
      string(REGEX REPLACE "^.*\\.([^.]+)$" "\\1" folder_suffix ${parent_stem})
      set_property(TARGET ${parent_target} PROPERTY FOLDER ${folder_suffix})
    endif()

    # Link and recurse
    if(NOT parent_target STREQUAL target)
      add_dependencies(${parent_target} ${target})
      copa_add_target_parent(${parent_target} ${extension})
    endif()
  endif()
endfunction()

##======================================================================================================================
## Turn a filename to a dot-separated target name
##======================================================================================================================
function(COPA_SOURCE_TO_TARGET extension filename testname)
  string(REPLACE "/" "." base "${filename}")
  string(REPLACE "\\" "." base "${base}")
  string(REGEX REPLACE "\\.[^.]+$" ".${extension}" base "${base}")
  set(${testname} "${base}" PARENT_SCOPE)
endfunction()

##======================================================================================================================
## Select a test target build location
##======================================================================================================================
function(COPA_SETUP_TEST test location)
  set_property(TARGET ${test} PROPERTY RUNTIME_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}/${location}")

  if(DEFINED CMAKE_CROSSCOMPILING_CMD)
    add_test(
      NAME ${test}
      WORKING_DIRECTORY "${PROJECT_BINARY_DIR}/${location}"
      COMMAND "${CMAKE_CROSSCOMPILING_CMD}" $<TARGET_FILE:${test}>
    )
  else()
    add_test(
      NAME ${test}
      WORKING_DIRECTORY "${PROJECT_BINARY_DIR}/unit"
      COMMAND $<TARGET_FILE:${test}>
    )
  endif()
endfunction()

##======================================================================================================================
## Process a list of source files to generate corresponding test target
##======================================================================================================================
function(COPA_MAKE_UNIT)
  set(options         QUIET)
  set(oneValueArgs    INTERFACE EXTENSION ROOT DESTINATION PCH IMPLICIT)
  set(multiValueArgs  DEPENDENCIES FILES)
  cmake_parse_arguments(OPT "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  if(NOT OPT_QUIET)
    list(LENGTH OPT_FILES NB_TARGETS)
    message(STATUS "[${PROJECT_NAME}] - ${NB_TARGETS} targets generated for ${OPT_ROOT}")
  endif()

  foreach(file ${OPT_FILES})
    copa_source_to_target("${OPT_EXTENSION}" "${file}" test)

    if(NOT TARGET ${test})
      add_executable(${test} ${file})

      copa_add_target_parent(${test} "${OPT_EXTENSION}")
      add_dependencies(${PROJECT_TEST_TARGET} ${test})

      if(DEFINED OPT_DEPENDENCIES)
        add_dependencies(${test} ${OPT_DEPENDENCIES})
      endif()

      copa_setup_test(${test} "${OPT_DESTINATION}")
      target_link_libraries(${test} PUBLIC ${OPT_INTERFACE})

      if(DEFINED OPT_PCH)
        target_precompile_headers(${test} REUSE_FROM ${OPT_PCH})
        add_dependencies(${test} ${OPT_PCH})
      endif()

      if(NOT OPT_IMPLICIT)
        set_target_properties(
          ${test} PROPERTIES
          EXCLUDE_FROM_DEFAULT_BUILD TRUE
          EXCLUDE_FROM_ALL TRUE
          ${MAKE_UNIT_TARGET_PROPERTIES}
        )
      endif()
    endif()
  endforeach()
endfunction()

##==================================================================================================
## Generate tests from a GLOB
##==================================================================================================
function(COPA_GLOB_UNIT)
  set(options         QUIET IMPLICIT)
  set(oneValueArgs    RELATIVE PATTERN INTERFACE PCH EXTENSION DESTINATION)
  set(multiValueArgs  DEPENDENCIES)
  cmake_parse_arguments(OPT "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  if(NOT DEFINED OPT_INTERFACE)
    set(OPT_INTERFACE "")
  endif()
  if(NOT DEFINED OPT_PCH)
    set(OPT_PCH "")
  endif()
  if(NOT DEFINED OPT_DESTINATION)
    set(OPT_DESTINATION "unit")
  endif()
  if(NOT DEFINED OPT_EXTENSION)
    set(OPT_EXTENSION "exe")
  endif()
  if(NOT DEFINED OPT_RELATIVE)
    set(OPT_RELATIVE "${CMAKE_SOURCE_DIR}/test")
  endif()
  if(NOT DEFINED OPT_PATTERN)
    set(OPT_PATTERN "*.cpp")
  endif()

  set(MAKE_IMPLICIT 0)
  if(OPT_IMPLICIT)
    set(MAKE_IMPLICIT 1)
  endif()

  file(GLOB_RECURSE FOUND_FILES CONFIGURE_DEPENDS RELATIVE ${OPT_RELATIVE} ${OPT_PATTERN})

  set(QUIET_ARG "")
  if(OPT_QUIET)
    set(QUIET_ARG "QUIET")
  endif()

  copa_make_unit(
    INTERFACE     "${OPT_INTERFACE}"
    EXTENSION     "${OPT_EXTENSION}"
    DESTINATION   "${OPT_DESTINATION}"
    DEPENDENCIES  "${OPT_DEPENDENCIES}"
    PCH           "${OPT_PCH}"
    FILES         "${FOUND_FILES}"
    ROOT          "${OPT_PATTERN}"
    IMPLICIT      "${MAKE_IMPLICIT}"
    ${QUIET_ARG}
  )
endfunction()

##======================================================================================================================
## Process a list of source files to generate a single test target
##======================================================================================================================
function(COPA_MAKE_SINGLE_UNIT)
  set(oneValueArgs    NAME INTERFACE EXTENSION ROOT DESTINATION PCH)
  set(multiValueArgs  DEPENDENCIES FILES)
  cmake_parse_arguments(OPT "" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  if(NOT DEFINED OPT_EXTENSION)
    set(OPT_EXTENSION "exe")
  endif()
  if(NOT DEFINED OPT_DESTINATION)
    set(OPT_DESTINATION "unit")
  endif()

  copa_source_to_target("${OPT_EXTENSION}" "${OPT_NAME}" test)

  if(NOT TARGET ${test})
    add_executable(${test} ${OPT_FILES})

    copa_add_target_parent(${test} "${OPT_EXTENSION}")
    add_dependencies(${PROJECT_TEST_TARGET} ${test})

    if(DEFINED OPT_DEPENDENCIES)
      add_dependencies(${test} ${OPT_DEPENDENCIES})
    endif()

    copa_setup_test(${test} "${OPT_DESTINATION}")
    target_link_libraries(${test} PUBLIC ${OPT_INTERFACE})

    if(DEFINED OPT_PCH)
      target_precompile_headers(${test} REUSE_FROM ${OPT_PCH})
      add_dependencies(${test} ${OPT_PCH})
    endif()
  endif()
endfunction()