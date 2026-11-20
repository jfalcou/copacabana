##======================================================================================================================
##  Copacabana - Common CMake Package Tools
##  Copyright : Copacabana Project Contributors
##  SPDX-License-Identifier: BSL-1.0
##======================================================================================================================

##======================================================================================================================
## The aggregate of every test of the project, <lowercased project name>-test
##======================================================================================================================
function(copa_test_target out)
  string(TOLOWER "${PROJECT_NAME}" name)
  set(${out} "${name}-test" PARENT_SCOPE)
endfunction()

##======================================================================================================================
## Declare the aggregate of every test, named in PROJECT_TEST_TARGET for the callers that read it
##======================================================================================================================
function(copa_setup_test_targets)
  copa_test_target(target)

  if(NOT TARGET ${target})
    add_custom_target(${target} COMMENT "[${PROJECT_NAME}] - Building every test")
  endif()

  set(PROJECT_TEST_TARGET "${target}" PARENT_SCOPE)
endfunction()

##======================================================================================================================
## Resolve which aggregate a unit belongs to, the project's test target by default, created on first use. Naming
## another keeps benchmarks or samples out of the tests.
##======================================================================================================================
function(copa_aggregate_target requested out)
  if(requested STREQUAL "")
    copa_test_target(requested)
  endif()

  if(NOT TARGET ${requested})
    add_custom_target(${requested} COMMENT "[${PROJECT_NAME}] - Building every unit gathered under ${requested}")
  endif()

  set(${out} "${requested}" PARENT_SCOPE)
endfunction()

##======================================================================================================================
## For any target of the form XXX.YYY.ZZZ.exe, generates all the intermediate XXX.YYY.exe and XXX.exe targets
##======================================================================================================================
function(copa_add_target_parent target extension)
  # Do not strip with string(REPLACE): it also removes ".exe" from a segment such as "execution".
  string(REGEX REPLACE "\\.${extension}$" "" stem "${target}")

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

    add_dependencies(${parent_target} ${target})
    copa_add_target_parent(${parent_target} ${extension})
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
## Declare one source that has to be rejected by the compiler
##======================================================================================================================
function(copa_make_failure_unit)
  set(options QUIET)
  set(oneValueArgs FILE INTERFACE ROOT NAME)
  cmake_parse_arguments(OPT "${options}" "${oneValueArgs}" "" ${ARGN})

  copa_check_arguments()

  if(NOT DEFINED OPT_ROOT)
    set(OPT_ROOT "${CMAKE_CURRENT_SOURCE_DIR}")
  endif()

  if(NOT DEFINED OPT_NAME)
    copa_source_to_target("exe" "${OPT_FILE}" OPT_NAME)
  endif()

  ## Out of every aggregate: building it is what the test does, so anything that builds it outside the test turns a
  ## passing check into a failing build.
  add_executable(${OPT_NAME} EXCLUDE_FROM_ALL "${OPT_ROOT}/${OPT_FILE}")
  if(OPT_INTERFACE)
    target_link_libraries(${OPT_NAME} PUBLIC ${OPT_INTERFACE})
  endif()

  add_test(
    NAME ${OPT_NAME}
    COMMAND
      ${CMAKE_COMMAND} "-DBUILD_DIR=${CMAKE_BINARY_DIR}" "-DTARGET=${OPT_NAME}" "-DSOURCE=${OPT_ROOT}/${OPT_FILE}"
      "-DCONFIG=$<CONFIG>" "-DCOMPILER=${CMAKE_CXX_COMPILER_ID}" -P
      "${COPACABANA_SOURCE_DIR}/copacabana/cmake/asset/expect_failure.cmake")

  ## A source naming only the diagnostics of another compiler has nothing to check here, so ctest reports it skipped.
  set_tests_properties(${OPT_NAME} PROPERTIES SKIP_REGULAR_EXPRESSION "expect_failure: skipped, ")
  ## The tests all build one shared tree, and two builds at once clash: MSBuild on ZERO_CHECK.tlog, ninja silently.
  set_tests_properties(${OPT_NAME} PROPERTIES RESOURCE_LOCK "copa-build-tree")

  if(NOT OPT_QUIET)
    message(STATUS "[${PROJECT_NAME}] - ${OPT_FILE} is expected not to compile")
  endif()
endfunction()

##======================================================================================================================
## Declare every source under a pattern as one that has to be rejected
##======================================================================================================================
function(copa_glob_failure_unit)
  set(options QUIET)
  set(oneValueArgs RELATIVE PATTERN INTERFACE)
  cmake_parse_arguments(OPT "${options}" "${oneValueArgs}" "" ${ARGN})

  copa_check_arguments()

  if(NOT DEFINED OPT_RELATIVE)
    set(OPT_RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}")
  endif()

  if(NOT DEFINED OPT_PATTERN)
    set(OPT_PATTERN "failure/*.cpp")
  endif()

  set(QUIET_ARG "")
  if(OPT_QUIET)
    set(QUIET_ARG "QUIET")
  endif()

  if(NOT IS_ABSOLUTE "${OPT_PATTERN}")
    set(OPT_PATTERN "${OPT_RELATIVE}/${OPT_PATTERN}")
  endif()
  file(GLOB_RECURSE FOUND_FILES CONFIGURE_DEPENDS RELATIVE "${OPT_RELATIVE}" "${OPT_PATTERN}")
  foreach(file ${FOUND_FILES})
    copa_make_failure_unit(
      ${QUIET_ARG}
      FILE "${file}"
      ROOT "${OPT_RELATIVE}"
      INTERFACE "${OPT_INTERFACE}")
  endforeach()
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
    # Do not quote the command: a command with arguments is a CMake list, which has to reach ctest as separate words.
    add_test(NAME ${test} WORKING_DIRECTORY "${PROJECT_BINARY_DIR}/${location}" COMMAND ${CMAKE_CROSSCOMPILING_CMD}
                                                                                        $<TARGET_FILE:${test}>)
  else()
    add_test(NAME ${test} WORKING_DIRECTORY "${PROJECT_BINARY_DIR}/${location}" COMMAND $<TARGET_FILE:${test}>)
  endif()
endfunction()

##======================================================================================================================
## Wire one unit: its parent targets, its aggregate, its test, its links, its precompiled header, and its properties
##======================================================================================================================
function(copa_configure_unit test)
  set(options IMPLICIT)
  set(oneValueArgs EXTENSION DESTINATION PCH TARGET)
  set(multiValueArgs SOURCES LIBRARIES DEPENDENCIES PROPERTIES)
  cmake_parse_arguments(UNIT "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  add_executable(${test} ${UNIT_SOURCES})

  copa_add_target_parent(${test} "${UNIT_EXTENSION}")
  copa_aggregate_target("${UNIT_TARGET}" aggregate)
  add_dependencies(${aggregate} ${test})

  if(UNIT_DEPENDENCIES)
    add_dependencies(${test} ${UNIT_DEPENDENCIES})
  endif()

  copa_test_target(tests)
  set(register FALSE)
  if(aggregate STREQUAL tests)
    set(register TRUE)
  endif()
  copa_setup_test(${test} "${UNIT_DESTINATION}" ${register})

  if(UNIT_LIBRARIES)
    target_link_libraries(${test} PRIVATE ${UNIT_LIBRARIES})
  endif()

  if(UNIT_PCH)
    target_precompile_headers(${test} REUSE_FROM ${UNIT_PCH})
  endif()

  if(NOT UNIT_IMPLICIT)
    set_target_properties(${test} PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD TRUE EXCLUDE_FROM_ALL TRUE)
  endif()

  if(UNIT_PROPERTIES)
    ## cmake-lint cannot count the pairs a variable expands to
    # cmake-lint: disable=E1120
    set_target_properties(${test} PROPERTIES ${UNIT_PROPERTIES})
  endif()
endfunction()

##======================================================================================================================
## Where the sources of a unit are read from: an absolute ROOT, the current directory otherwise, where a relative ROOT
## only labels the units
##======================================================================================================================
function(copa_unit_base root out)
  set(base "")
  if(IS_ABSOLUTE "${root}")
    set(base "${root}/")
  endif()
  set(${out} "${base}" PARENT_SCOPE)
endfunction()

##======================================================================================================================
## Process a list of source files to generate one test target each
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

  copa_check_arguments()

  if(NOT OPT_EXTENSION)
    set(OPT_EXTENSION "exe")
  endif()
  if(NOT OPT_DESTINATION)
    set(OPT_DESTINATION "unit")
  endif()

  set(IMPLICIT_ARG "")
  if(OPT_IMPLICIT)
    set(IMPLICIT_ARG "IMPLICIT")
  endif()

  copa_unit_base("${OPT_ROOT}" base)

  if(NOT OPT_QUIET)
    list(LENGTH OPT_FILES NB_TARGETS)
    message(STATUS "[${PROJECT_NAME}] - ${NB_TARGETS} targets generated for ${OPT_ROOT}")
  endif()

  foreach(file ${OPT_FILES})
    copa_source_to_target("${OPT_EXTENSION}" "${file}" test)

    if(NOT TARGET ${test})
      copa_configure_unit(
        ${test}
        ${IMPLICIT_ARG}
        SOURCES
        "${base}${file}"
        EXTENSION
        "${OPT_EXTENSION}"
        DESTINATION
        "${OPT_DESTINATION}"
        PCH
        "${OPT_PCH}"
        TARGET
        "${OPT_TARGET}"
        LIBRARIES
        ${OPT_INTERFACE}
        ${OPT_EXTERNALS}
        DEPENDENCIES
        ${OPT_DEPENDENCIES}
        PROPERTIES
        ${OPT_PROPERTIES})
    endif()
  endforeach()
endfunction()

##======================================================================================================================
## Generate tests from a GLOB, the pattern read from RELATIVE, the current source directory by default
##======================================================================================================================
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

  copa_check_arguments()

  if(NOT DEFINED OPT_RELATIVE)
    set(OPT_RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}")
  endif()
  if(NOT DEFINED OPT_PATTERN)
    set(OPT_PATTERN "*.cpp")
  endif()

  if(NOT IS_ABSOLUTE "${OPT_PATTERN}")
    set(OPT_PATTERN "${OPT_RELATIVE}/${OPT_PATTERN}")
  endif()
  file(GLOB_RECURSE FOUND_FILES CONFIGURE_DEPENDS RELATIVE "${OPT_RELATIVE}" "${OPT_PATTERN}")

  set(FLAGS "")
  if(OPT_QUIET)
    list(APPEND FLAGS "QUIET")
  endif()

  set(MAKE_IMPLICIT 0)
  if(OPT_IMPLICIT)
    set(MAKE_IMPLICIT 1)
  endif()

  copa_make_unit(
    INTERFACE "${OPT_INTERFACE}"
    EXTENSION "${OPT_EXTENSION}"
    DESTINATION "${OPT_DESTINATION}"
    EXTERNALS ${OPT_EXTERNALS}
    DEPENDENCIES ${OPT_DEPENDENCIES}
    PCH "${OPT_PCH}"
    FILES ${FOUND_FILES}
    ROOT "${OPT_RELATIVE}"
    IMPLICIT "${MAKE_IMPLICIT}"
    TARGET "${OPT_TARGET}"
    PROPERTIES ${OPT_PROPERTIES} ${FLAGS})
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

  copa_check_arguments()

  if(NOT OPT_EXTENSION)
    set(OPT_EXTENSION "exe")
  endif()
  if(NOT OPT_DESTINATION)
    set(OPT_DESTINATION "unit")
  endif()

  copa_unit_base("${OPT_ROOT}" base)
  list(TRANSFORM OPT_FILES PREPEND "${base}")

  copa_source_to_target("${OPT_EXTENSION}" "${OPT_NAME}" test)

  if(NOT TARGET ${test})
    copa_configure_unit(
      ${test}
      SOURCES
      ${OPT_FILES}
      EXTENSION
      "${OPT_EXTENSION}"
      DESTINATION
      "${OPT_DESTINATION}"
      PCH
      "${OPT_PCH}"
      TARGET
      "${OPT_TARGET}"
      LIBRARIES
      ${OPT_INTERFACE}
      ${OPT_EXTERNALS}
      DEPENDENCIES
      ${OPT_DEPENDENCIES}
      PROPERTIES
      ${OPT_PROPERTIES})
  endif()
endfunction()
