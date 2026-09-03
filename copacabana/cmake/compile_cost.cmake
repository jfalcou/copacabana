##======================================================================================================================
##  Copacabana - Common CMake Package Tools
##  Copyright : Copacabana Project Contributors
##  SPDX-License-Identifier: BSL-1.0
##======================================================================================================================

##======================================================================================================================
## Record what every translation unit costs to compile, and report on it
##
## copa_setup_compile_cost( <target>
##                          [PREFIX   <name>] # Prefix of the generated targets, defaults to the lowercased project name
##                          [DEPENDS  <name>] # Target building the units to measure, defaults to <prefix>-test
##                          [BASELINE <csv>]  # An earlier measurement to report the delta against
##                        )
##
## Clang appends one line per compiler process to a CSV: the wall time, the CPU time and the peak resident memory of
## that process. Being per process, the figures do not move with -j, and writing them costs nothing measurable. The
## flag goes on the interface target so that every unit linking against it is measured, and nothing else is.
##
## Generates <prefix>-compile-cost, which drops the CSV and rebuilds DEPENDS from a clean tree so that every unit is
## in it, and <prefix>-compile-cost-report, which turns the CSV into compile-cost/summary.md, written for a job
## summary, and compile-cost/<prefix>-compile-cost.md, which holds every unit. Both land under the build tree, beside
## the CSV, compile-cost/<prefix>-compile-cost.csv: what a run attaches carries the project's name.
##
## The rebuild takes its parallelism from CMAKE_BUILD_PARALLEL_LEVEL, as any cmake --build does. A CI hands the
## reference it downloaded through COPA_COMPILE_COST_BASELINE, so a project has nothing to plumb for the delta.
##======================================================================================================================
function(copa_setup_compile_cost target)
  set(oneValueArgs PREFIX DEPENDS BASELINE)
  cmake_parse_arguments(OPT "" "${oneValueArgs}" "" ${ARGN})

  copa_check_arguments()

  if(NOT OPT_PREFIX)
    string(TOLOWER "${PROJECT_NAME}" OPT_PREFIX)
  endif()

  if(NOT OPT_DEPENDS)
    set(OPT_DEPENDS "${OPT_PREFIX}-test")
  endif()

  if(NOT OPT_BASELINE AND COPA_COMPILE_COST_BASELINE)
    set(OPT_BASELINE "${COPA_COMPILE_COST_BASELINE}")
  endif()

  if(NOT CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    message(FATAL_ERROR "[${PROJECT_NAME}] - Compile cost requires Clang, ${CMAKE_CXX_COMPILER_ID} has no "
                        "-fproc-stat-report")
  endif()

  set(COST_DIR "${PROJECT_BINARY_DIR}/compile-cost")
  set(COST_CSV "${COST_DIR}/${OPT_PREFIX}-compile-cost.csv")
  file(MAKE_DIRECTORY "${COST_DIR}")

  target_compile_options(${target} INTERFACE $<$<COMPILE_LANGUAGE:CXX>:-fproc-stat-report=${COST_CSV}>)

  # A multi-config generator files the objects under <target>.dir/<config>/, and that segment is build layout, not
  # something a reader recognises. A single-config generator has no such segment, and stripping one that is not there
  # does nothing.
  set(REPORT_COMMAND
      ${CMAKE_COMMAND} -E env python3 "${COPACABANA_SOURCE_DIR}/copacabana/cmake/asset/compile_cost.py" "${COST_CSV}"
      --title "${PROJECT_NAME} compile cost" --strip "$<CONFIG>/" --summary "${COST_DIR}/summary.md" --full
      "${COST_DIR}/${OPT_PREFIX}-compile-cost.md")

  if(OPT_BASELINE)
    list(APPEND REPORT_COMMAND --baseline "${OPT_BASELINE}")
  endif()

  # clang appends, so a line left by an earlier build would be added to rather than replaced, and a unit the build
  # found up to date writes no line at all. A measurement recompiles what it measures.
  add_custom_target(
    ${OPT_PREFIX}-compile-cost
    COMMAND ${CMAKE_COMMAND} -E rm -f "${COST_CSV}"
    COMMAND ${CMAKE_COMMAND} --build "${PROJECT_BINARY_DIR}" --config $<CONFIG> --target ${OPT_DEPENDS} --clean-first
    WORKING_DIRECTORY "${PROJECT_BINARY_DIR}"
    COMMENT "[${PROJECT_NAME}] - Measuring what ${OPT_DEPENDS} costs to compile"
    VERBATIM)

  add_custom_target(
    ${OPT_PREFIX}-compile-cost-report
    COMMAND ${REPORT_COMMAND}
    WORKING_DIRECTORY "${PROJECT_BINARY_DIR}"
    COMMENT "[${PROJECT_NAME}] - Reporting compile cost in ${COST_DIR}"
    VERBATIM)

  add_dependencies(${OPT_PREFIX}-compile-cost-report ${OPT_PREFIX}-compile-cost)

  message(STATUS "[${PROJECT_NAME}] - Compile cost of target '${target}' recorded into ${COST_CSV}")
endfunction()

##======================================================================================================================
## Break down where the compile cost of a translation unit goes, and rank it across the build
##
## copa_setup_time_trace( <target>
##                        [PREFIX  <name>] # Prefix of the generated target, defaults to the lowercased project name
##                        [DEPENDS <name>] # Target building the units to trace, defaults to <prefix>-test
##                        [SCAN    <dir>]  # Tree the traces are collected from, defaults to <build>/test
##                      )
##
## -ftime-trace makes clang write one JSON per unit with a per-phase and per-template breakdown, and ClangBuildAnalyzer
## turns a tree of those into a ranking of the costliest files, templates and functions. That ranking only means
## something over a corpus, so the target aggregates whatever DEPENDS built rather than one file at a time. It slows
## compilation down and writes about a megabyte per unit, which is why it is a local target and not something a CI
## runs: peak memory and CPU time come from copa_setup_compile_cost, which is cheap enough for every pull request.
##
## Generates <prefix>-time-trace, which drops the traces and objects an earlier build left, rebuilds DEPENDS, and
## writes the ranking to time-trace/ under the build tree.
##
## Requires ClangBuildAnalyzer, taken from the path when it is there and built from source otherwise.
##======================================================================================================================
function(copa_setup_time_trace target)
  set(oneValueArgs PREFIX DEPENDS SCAN)
  cmake_parse_arguments(OPT "" "${oneValueArgs}" "" ${ARGN})

  copa_check_arguments()

  if(NOT OPT_PREFIX)
    string(TOLOWER "${PROJECT_NAME}" OPT_PREFIX)
  endif()

  if(NOT OPT_DEPENDS)
    set(OPT_DEPENDS "${OPT_PREFIX}-test")
  endif()

  # The test tree rather than the whole build directory: ClangBuildAnalyzer built from source drops its own sources
  # under _deps, and those ship thirty-odd JSON fixtures the aggregation would take for traces.
  if(NOT OPT_SCAN)
    set(OPT_SCAN "${PROJECT_BINARY_DIR}/test")
  endif()

  if(NOT CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    message(FATAL_ERROR "[${PROJECT_NAME}] - Time trace requires Clang, ${CMAKE_CXX_COMPILER_ID} has no -ftime-trace")
  endif()

  target_compile_options(${target} INTERFACE $<$<COMPILE_LANGUAGE:CXX>:-ftime-trace>)

  find_program(CLANG_BUILD_ANALYZER_EXECUTABLE NAMES ClangBuildAnalyzer)

  if(CLANG_BUILD_ANALYZER_EXECUTABLE)
    set(ANALYZER "${CLANG_BUILD_ANALYZER_EXECUTABLE}")
    message(STATUS "[${PROJECT_NAME}] - Using ClangBuildAnalyzer from ${CLANG_BUILD_ANALYZER_EXECUTABLE}")
  else()
    # Its sources join the build but not the interface target, so they are compiled without -ftime-trace and leave no
    # trace of their own in the tree the analysis walks.
    include(FetchContent)
    FetchContent_Declare(
      ClangBuildAnalyzer
      GIT_REPOSITORY https://github.com/aras-p/ClangBuildAnalyzer.git
      GIT_TAG v1.6.0
      GIT_SHALLOW TRUE)
    FetchContent_MakeAvailable(ClangBuildAnalyzer)
    set(ANALYZER "$<TARGET_FILE:ClangBuildAnalyzer>")
    message(STATUS "[${PROJECT_NAME}] - ClangBuildAnalyzer 1.6.0 built from source")
  endif()

  set(TRACE_DIR "${PROJECT_BINARY_DIR}/time-trace")

  # The cleanup cannot be a target of its own: nothing orders a custom target before the build of another one, and a
  # tree where half the traces are left from an earlier build aggregates two states with nothing saying so.
  add_custom_target(
    ${OPT_PREFIX}-time-trace
    COMMAND ${CMAKE_COMMAND} -DTIME_TRACE_SCAN=${OPT_SCAN} -P
            "${COPACABANA_SOURCE_DIR}/copacabana/cmake/asset/reset_time_trace.cmake"
    COMMAND ${CMAKE_COMMAND} -E make_directory "${TRACE_DIR}"
    COMMAND ${CMAKE_COMMAND} --build "${PROJECT_BINARY_DIR}" --config $<CONFIG> --target ${OPT_DEPENDS}
    COMMAND ${ANALYZER} --all "${OPT_SCAN}" "${TRACE_DIR}/capture.bin"
    COMMAND ${ANALYZER} --analyze "${TRACE_DIR}/capture.bin"
    WORKING_DIRECTORY "${PROJECT_BINARY_DIR}"
    COMMENT "[${PROJECT_NAME}] - Building ${OPT_DEPENDS} with -ftime-trace, then analyzing into ${TRACE_DIR}"
    USES_TERMINAL VERBATIM)

  message(STATUS "[${PROJECT_NAME}] - Time trace of target '${target}' reported into ${TRACE_DIR}")
endfunction()
