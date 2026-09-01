##======================================================================================================================
##  Copacabana - Common CMake Package Tools
##  Copyright : Copacabana Project Contributors
##  SPDX-License-Identifier: BSL-1.0
##======================================================================================================================
function(copa_setup_test_targets)
  string(TOLOWER ${PROJECT_NAME} NAME)
  set(PROJECT_TEST_TARGET "${NAME}-test")

  if(NOT TARGET ${PROJECT_TEST_TARGET})
    add_custom_target(${PROJECT_TEST_TARGET} COMMENT "[${PROJECT_NAME}] - Building every test")
  endif()

  # Named whether or not this call is the one that creates it: a second directory calling in still needs to be told
  # what the aggregate is called.
  set(PROJECT_TEST_TARGET "${PROJECT_TEST_TARGET}" PARENT_SCOPE)
endfunction()

##======================================================================================================================
## Resolve which aggregate a unit belongs to. Defaults to the project's test target, so callers that
## say nothing keep gathering everything there; naming one keeps benchmarks or samples out of it.
##======================================================================================================================
function(copa_aggregate_target requested out)
  if(requested STREQUAL "")
    set(${out} "${PROJECT_TEST_TARGET}" PARENT_SCOPE)
  else()
    if(NOT TARGET ${requested})
      add_custom_target(${requested} COMMENT "[${PROJECT_NAME}] - Building every unit gathered under ${requested}")
    endif()
    set(${out} "${requested}" PARENT_SCOPE)
  endif()
endfunction()

##======================================================================================================================
## For any target of the form XXX.YYY.ZZZ.exe, generates all the intermediate XXX.YYY.exe and XXX.exe targets
##======================================================================================================================
function(copa_add_target_parent target extension)
  # Strip the extension first to look at the 'stem' logic
  string(REPLACE ".${extension}" "" stem "${target}")

  if(stem MATCHES "\\.")
    # Strip the last part of the stem
    string(REGEX REPLACE "\\.[^.]+$" "" parent_stem "${stem}")

    # Re-attach the extension for the parent target name
    set(parent_target "${parent_stem}.${extension}")

    if(NOT TARGET ${parent_target})
      add_custom_target(${parent_target} COMMENT "[${PROJECT_NAME}] - Building every unit under ${parent_stem}")

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
function(copa_source_to_target extension filename testname)
  string(REPLACE "/" "." base "${filename}")
  string(REPLACE "\\" "." base "${base}")
  string(REGEX REPLACE "\\.[^.]+$" ".${extension}" base "${base}")
  set(${testname} "${base}" PARENT_SCOPE)
endfunction()

##======================================================================================================================
## Select a test target build location
##======================================================================================================================
function(copa_setup_test test location register)
  set_property(TARGET ${test} PROPERTY RUNTIME_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}/${location}")

  # A unit gathered under another aggregate is not a test: declaring it to ctest would ask for an
  # executable that the test target never builds.
  if(NOT register)
    return()
  endif()

  if(DEFINED CMAKE_CROSSCOMPILING_CMD)
    add_test(NAME ${test} WORKING_DIRECTORY "${PROJECT_BINARY_DIR}/${location}" COMMAND "${CMAKE_CROSSCOMPILING_CMD}"
                                                                                        $<TARGET_FILE:${test}>)
  else()
    add_test(NAME ${test} WORKING_DIRECTORY "${PROJECT_BINARY_DIR}/${location}" COMMAND $<TARGET_FILE:${test}>)
  endif()
endfunction()

##======================================================================================================================
## Process a list of source files to generate corresponding test target
##======================================================================================================================
function(copa_make_unit)
  set(options QUIET)
  set(oneValueArgs
      INTERFACE
      EXTENSION
      ROOT
      DESTINATION
      PCH
      IMPLICIT
      TARGET)
  set(multiValueArgs DEPENDENCIES FILES EXTERNALS PROPERTIES)
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
      copa_aggregate_target("${OPT_TARGET}" aggregate)
      add_dependencies(${aggregate} ${test})

      if(DEFINED OPT_DEPENDENCIES)
        add_dependencies(${test} ${OPT_DEPENDENCIES})
      endif()

      set(IS_TEST FALSE)
      if(aggregate STREQUAL "${PROJECT_TEST_TARGET}")
        set(IS_TEST TRUE)
      endif()
      copa_setup_test(${test} "${OPT_DESTINATION}" ${IS_TEST})
      target_link_libraries(${test} PRIVATE ${OPT_INTERFACE})

      if(OPT_EXTERNALS)
        target_link_libraries(${test} PRIVATE ${OPT_EXTERNALS})
      endif()

      if(DEFINED OPT_PCH)
        target_precompile_headers(${test} REUSE_FROM ${OPT_PCH})
        add_dependencies(${test} ${OPT_PCH})
      endif()

      if(NOT OPT_IMPLICIT)
        ## cmake-lint cannot count the pairs a variable expands to
        # cmake-lint: disable=E1120
        set_target_properties(${test} PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD TRUE EXCLUDE_FROM_ALL TRUE
                                                 ${OPT_PROPERTIES})
      endif()
    endif()
  endforeach()
endfunction()

##==================================================================================================
## Generate tests from a GLOB
##==================================================================================================
function(copa_glob_unit)
  set(options QUIET IMPLICIT)
  set(oneValueArgs
      RELATIVE
      PATTERN
      INTERFACE
      PCH
      EXTENSION
      DESTINATION
      TARGET)
  set(multiValueArgs DEPENDENCIES EXTERNALS PROPERTIES)
  cmake_parse_arguments(OPT "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  if(NOT DEFINED OPT_INTERFACE)
    set(OPT_INTERFACE "")
  endif()
  if(NOT DEFINED OPT_EXTERNALS)
    set(OPT_EXTERNALS "")
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
    INTERFACE
    "${OPT_INTERFACE}"
    EXTENSION
    "${OPT_EXTENSION}"
    DESTINATION
    "${OPT_DESTINATION}"
    EXTERNALS
    ${OPT_EXTERNALS}
    DEPENDENCIES
    "${OPT_DEPENDENCIES}"
    PCH
    "${OPT_PCH}"
    FILES
    "${FOUND_FILES}"
    ROOT
    "${OPT_PATTERN}"
    IMPLICIT
    "${MAKE_IMPLICIT}"
    TARGET
    "${OPT_TARGET}"
    PROPERTIES
    ${OPT_PROPERTIES}
    ${QUIET_ARG})
endfunction()

##======================================================================================================================
## Process a list of source files to generate a single test target
##======================================================================================================================
function(copa_make_single_unit)
  set(oneValueArgs
      NAME
      INTERFACE
      EXTENSION
      ROOT
      DESTINATION
      PCH
      TARGET)
  set(multiValueArgs DEPENDENCIES FILES EXTERNALS PROPERTIES)
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
    copa_aggregate_target("${OPT_TARGET}" aggregate)
    add_dependencies(${aggregate} ${test})

    if(DEFINED OPT_DEPENDENCIES)
      add_dependencies(${test} ${OPT_DEPENDENCIES})
    endif()

    set(IS_TEST FALSE)
    if(aggregate STREQUAL "${PROJECT_TEST_TARGET}")
      set(IS_TEST TRUE)
    endif()
    copa_setup_test(${test} "${OPT_DESTINATION}" ${IS_TEST})
    target_link_libraries(${test} PRIVATE ${OPT_INTERFACE})

    if(OPT_EXTERNALS)
      target_link_libraries(${test} PRIVATE ${OPT_EXTERNALS})
    endif()

    if(DEFINED OPT_PCH)
      target_precompile_headers(${test} REUSE_FROM ${OPT_PCH})
      add_dependencies(${test} ${OPT_PCH})
    endif()

    if(OPT_PROPERTIES)
      ## cmake-lint cannot count the pairs a variable expands to
      # cmake-lint: disable=E1120
      set_target_properties(${test} PROPERTIES ${OPT_PROPERTIES})
    endif()
  endif()
endfunction()
