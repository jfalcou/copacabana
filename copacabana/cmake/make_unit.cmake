##======================================================================================================================
##  Copacabana - Common CMake Package Tools
##  Copyright : Copacabana Project Contributors
##  SPDX-License-Identifier: BSL-1.0
##======================================================================================================================

add_custom_target(unit)

##======================================================================================================================
## For any target of the form XXX.YYY.ZZZ, generates all the intermediate XX and XXX.YY targets that include
## allt he ones under them.
##======================================================================================================================
function(COPA_ADD_TARGET_PARENT target)
  string(REGEX REPLACE "[^.]+\\.([^.]+)$" "\\1" parent_target ${target})
  string(REGEX REPLACE "^.*\\.([^.]+)$" "\\1" suffix ${parent_target})

  if(NOT TARGET ${target})
    add_custom_target(${target})
    set_property(TARGET ${target} PROPERTY FOLDER ${suffix})
  endif()

  if(NOT parent_target STREQUAL ${target})
    copa_add_target_parent(${parent_target})
    add_dependencies(${parent_target} ${target})
  endif()
endfunction()

##======================================================================================================================
## Turn a filename to a dot-separated target name
##======================================================================================================================
function(COPA_SOURCE_TO_TARGET extension filename testname)
  string(REPLACE ".cpp" ".${extension}" base ${filename})
  string(REPLACE "/"    "." base ${base})
  string(REPLACE "\\"   "." base ${base})
  set(${testname} "${base}" PARENT_SCOPE)
endfunction()

##======================================================================================================================
## Select a test target build location
##======================================================================================================================
function(COPA_SETUP_TEST test location)
set_property( TARGET ${test}
              PROPERTY RUNTIME_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}/${location}"
            )
add_test( NAME ${test}
          WORKING_DIRECTORY "${PROJECT_BINARY_DIR}/${location}"
          COMMAND $<TARGET_FILE:${test}>
        )
endfunction()

##==================================================================================================
## Process a list of source files to generate corresponding test target
##==================================================================================================
function(COPA_MAKE_UNIT interface extension destination dependencies pch)
  foreach(file ${ARGN})
    copa_source_to_target( ${extension} ${file} test)
    add_executable(${test} ${file})

    copa_add_target_parent(${test})
    add_dependencies(unit ${test})
    add_dependencies(${test} ${dependencies})

    copa_setup_test( ${test} ${destination})
    target_link_libraries(${test} PUBLIC ${interface})

    if( NOT ${pch} EQUAL "")
      target_precompile_headers(${test} REUSE_FROM ${pch})
      add_dependencies(${test} ${pch})
    endif()

  endforeach()
endfunction()

##==================================================================================================
## Generate tests from a GLOB
##==================================================================================================
function(COPA_GLOB_UNIT)
  set(oneValueArgs  RELATIVE PATTERN INTERFACE PCH EXTENSION DESTINATION)
  set(multiValueArgs  DEPENDENCIES)
  cmake_parse_arguments(OPT "" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )

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

  file(GLOB FILES CONFIGURE_DEPENDS RELATIVE ${OPT_RELATIVE} ${OPT_PATTERN})
  copa_make_unit(${OPT_INTERFACE} ${OPT_EXTENSION} ${OPT_DESTINATION} ${OPT_DEPENDENCIES} ${OPT_PCH} ${FILES})
endfunction()
