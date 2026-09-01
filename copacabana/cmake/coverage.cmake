##======================================================================================================================
##  Copacabana - Common CMake Package Tools
##  Copyright : Copacabana Project Contributors
##  SPDX-License-Identifier: BSL-1.0
##======================================================================================================================

##======================================================================================================================
## Locate gcovr and the gcov reader that can read what this compiler writes, or say which package is missing
##
## copa_find_coverage_tools(<gcovr-out> <gcov-tool-out>)
##
## Notes carry the format version of the compiler that wrote them, and a reader from another major release accepts
## none of them - gcovr reports that as "could not infer a working directory".
##======================================================================================================================
function(copa_find_coverage_tools out_gcovr out_gcov_tool)
  find_program(GCOVR_EXECUTABLE gcovr)
  if(NOT GCOVR_EXECUTABLE)
    message(FATAL_ERROR "[${PROJECT_NAME}] - Coverage requires gcovr, install it with 'pip install gcovr'")
  endif()

  # gcovr 8 sums a header's lines once per translation unit including it instead of taking their
  # union, which on a header-only template library reports totals larger than the files themselves.
  execute_process(COMMAND ${GCOVR_EXECUTABLE} --version OUTPUT_VARIABLE GCOVR_VERSION_OUTPUT
                  OUTPUT_STRIP_TRAILING_WHITESPACE)

  if(GCOVR_VERSION_OUTPUT MATCHES "gcovr ([0-9]+)" AND CMAKE_MATCH_1 GREATER_EQUAL 8)
    message(WARNING "[${PROJECT_NAME}] - gcovr ${CMAKE_MATCH_1}.x inflates per-file totals on templates, "
                    "its numbers will not match the CI's gcovr 7.x")
  endif()

  # Notes carry the format version of the compiler that wrote them, and a reader from another major
  # release accepts none of them. gcovr calls that "could not infer a working directory".
  string(REGEX MATCH "^[0-9]+" COMPILER_MAJOR "${CMAKE_CXX_COMPILER_VERSION}")

  if(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    # Distributions usually ship no unsuffixed llvm-cov at all, hence the versioned name first.
    find_program(LLVM_COV_EXECUTABLE NAMES "llvm-cov-${COMPILER_MAJOR}" llvm-cov)

    if(NOT LLVM_COV_EXECUTABLE)
      message(
        FATAL_ERROR "[${PROJECT_NAME}] - Coverage with Clang requires llvm-cov, install package llvm-${COMPILER_MAJOR}")
    endif()

    execute_process(COMMAND ${LLVM_COV_EXECUTABLE} --version OUTPUT_VARIABLE COV_VERSION_OUTPUT
                    OUTPUT_STRIP_TRAILING_WHITESPACE)
    string(REGEX MATCH "LLVM version ([0-9]+)" _ "${COV_VERSION_OUTPUT}")
    set(COV_TOOL_NAME "llvm-cov")
    set(COV_PACKAGE "llvm-${COMPILER_MAJOR}")
    set(GCOV_TOOL "${LLVM_COV_EXECUTABLE} gcov")
  else()
    find_program(GCOV_EXECUTABLE NAMES "gcov-${COMPILER_MAJOR}" gcov)

    if(NOT GCOV_EXECUTABLE)
      message(FATAL_ERROR "[${PROJECT_NAME}] - Coverage with GCC requires gcov-${COMPILER_MAJOR}")
    endif()

    execute_process(COMMAND ${GCOV_EXECUTABLE} --version OUTPUT_VARIABLE COV_VERSION_OUTPUT
                    OUTPUT_STRIP_TRAILING_WHITESPACE)
    string(REGEX MATCH "gcov \\([^)]*\\) ([0-9]+)" _ "${COV_VERSION_OUTPUT}")
    set(COV_TOOL_NAME "gcov")
    set(COV_PACKAGE "gcc-${COMPILER_MAJOR}")
    set(GCOV_TOOL "${GCOV_EXECUTABLE}")
  endif()

  if(NOT CMAKE_MATCH_1 STREQUAL COMPILER_MAJOR)
    message(FATAL_ERROR "[${PROJECT_NAME}] - ${COV_TOOL_NAME} ${CMAKE_MATCH_1} cannot read notes written by "
                        "${CMAKE_CXX_COMPILER_ID} ${COMPILER_MAJOR}, install package ${COV_PACKAGE}")
  endif()

  set(${out_gcovr} "${GCOVR_EXECUTABLE}" PARENT_SCOPE)
  set(${out_gcov_tool} "${GCOV_TOOL}" PARENT_SCOPE)
endfunction()

##======================================================================================================================
## Instrument a target for coverage collection and setup the report generation targets
##
## copa_setup_coverage( <target>
##                      [PREFIX  <name>] # Prefix of the generated targets, defaults to the lowercased project name
##                      [FILTER  <path>] # What to report on, defaults to <source>/include/<prefix>/
##                      [DEPENDS <name>] # Target building the tests, defaults to <prefix>-test
##                    )
##
## Generates <prefix>-coverage, which runs the test suite under instrumentation, and
## <prefix>-coverage-report, which turns its counters into an HTML report and a JSON summary.
##======================================================================================================================
function(copa_setup_coverage target)
  set(oneValueArgs PREFIX FILTER DEPENDS)
  cmake_parse_arguments(OPT "" "${oneValueArgs}" "" ${ARGN})

  if(NOT OPT_PREFIX)
    string(TOLOWER "${PROJECT_NAME}" OPT_PREFIX)
  endif()

  if(NOT OPT_FILTER)
    set(OPT_FILTER "${PROJECT_SOURCE_DIR}/include/${OPT_PREFIX}/")
  endif()

  if(NOT OPT_DEPENDS)
    set(OPT_DEPENDS "${OPT_PREFIX}-test")
  endif()

  if(NOT (CMAKE_CXX_COMPILER_ID MATCHES "GNU" OR CMAKE_CXX_COMPILER_ID MATCHES "Clang"))
    message(FATAL_ERROR "[${PROJECT_NAME}] - Coverage requires GCC or Clang, got ${CMAKE_CXX_COMPILER_ID}")
  endif()

  set(COVERAGE_FLAGS --coverage)

  # Without this, GCC stores the notes' paths relative to the object file and gcov resolves none
  # of the library headers - which, for a header-only library, is the entirety of the report.
  if(CMAKE_CXX_COMPILER_ID MATCHES "GNU")
    list(APPEND COVERAGE_FLAGS -fprofile-abs-path)
  endif()

  target_compile_options(${target} INTERFACE $<$<COMPILE_LANGUAGE:CXX>:${COVERAGE_FLAGS}>)
  target_link_options(${target} INTERFACE --coverage)

  copa_find_coverage_tools(GCOVR_EXECUTABLE GCOV_TOOL)

  set(COVERAGE_DIR "${PROJECT_BINARY_DIR}/coverage")

  # Only the library itself is worth reporting on - the tests exercising it are not. The search path
  # must stay on this build tree: --root alone lets gcovr wander into a sibling build made by
  # another compiler, whose notes the local gcov refuses to read.
  set(GCOVR_COMMAND
      ${GCOVR_EXECUTABLE} "${PROJECT_BINARY_DIR}" --root "${PROJECT_SOURCE_DIR}" --filter "${OPT_FILTER}"
      --gcov-executable "${GCOV_TOOL}" --exclude-unreachable-branches --exclude-throw-branches --print-summary)

  add_custom_target(
    ${OPT_PREFIX}-coverage-report
    COMMAND ${CMAKE_COMMAND} -E make_directory "${COVERAGE_DIR}"
    COMMAND ${GCOVR_COMMAND} --html-details "${COVERAGE_DIR}/index.html" --json-summary "${COVERAGE_DIR}/summary.json"
            --json-summary-pretty
    WORKING_DIRECTORY "${PROJECT_BINARY_DIR}"
    COMMENT "[${PROJECT_NAME}] - Generating coverage report in ${COVERAGE_DIR}"
    VERBATIM)

  add_custom_target(
    ${OPT_PREFIX}-coverage
    COMMAND ${CMAKE_COMMAND} -DCOVERAGE_BUILD_DIR=${PROJECT_BINARY_DIR} -P
            "${COPACABANA_SOURCE_DIR}/copacabana/cmake/asset/reset_coverage.cmake"
    COMMAND ${CMAKE_CTEST_COMMAND} --build-config $<CONFIG> --output-on-failure
    WORKING_DIRECTORY "${PROJECT_BINARY_DIR}"
    COMMENT "[${PROJECT_NAME}] - Running the test suite under coverage"
    VERBATIM)

  add_dependencies(${OPT_PREFIX}-coverage-report ${OPT_PREFIX}-coverage)
  add_dependencies(${OPT_PREFIX}-coverage ${OPT_DEPENDS})

  message(STATUS "[${PROJECT_NAME}] - Coverage enabled for target '${target}' via ${GCOVR_EXECUTABLE}")
endfunction()
