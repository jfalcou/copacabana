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
  set_property ( TARGET ${test}
                PROPERTY RUNTIME_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}/${location}"
               )

  if(DEFINED CMAKE_CROSSCOMPILING_CMD)
    add_test( NAME ${test}
              WORKING_DIRECTORY "${PROJECT_BINARY_DIR}/${location}"
              COMMAND "${CMAKE_CROSSCOMPILING_CMD}" $<TARGET_FILE:${test}>
            )
  else()
    add_test( NAME ${test}
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
  cmake_parse_arguments(OPT "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )

  if(NOT ${OPT_QUIET})
    list(LENGTH OPT_FILES NB_TARGETS)
    message(STATUS "[${PROJECT_NAME}] - ${NB_TARGETS} targets generated for ${OPT_ROOT}")
  endif()

  foreach(file ${OPT_FILES})
    copa_source_to_target( "${OPT_EXTENSION}" "${file}" test)
    add_executable(${test} ${file})

    copa_add_target_parent(${test})
    add_dependencies(${PROJECT_TEST_TARGET} ${test})

    if(DEFINED OPT_DEPENDENCIES)
      add_dependencies(${test} ${OPT_DEPENDENCIES})
    endif()

    copa_setup_test( ${test} "${OPT_DESTINATION}")
    target_link_libraries(${test} PUBLIC ${OPT_INTERFACE})

    if(DEFINED OPT_PCH)
      target_precompile_headers(${test} REUSE_FROM ${OPT_PCH})
      add_dependencies(${test} ${OPT_PCH})
    endif()

    if(NOT ${OPT_IMPLICIT})
      set_target_properties ( ${test} PROPERTIES
                              EXCLUDE_FROM_DEFAULT_BUILD TRUE
                              EXCLUDE_FROM_ALL TRUE
                              ${MAKE_UNIT_TARGET_PROPERTIES}
                            )
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
  cmake_parse_arguments(OPT "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )

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

  if(${OPT_IMPLICIT})
    set(MAKE_IMPLICIT 1)
  else()
    set(MAKE_IMPLICIT 0)
  endif()

  file(GLOB FOUND_FILES CONFIGURE_DEPENDS RELATIVE ${OPT_RELATIVE} ${OPT_PATTERN})

  if(${OPT_QUIET})
  copa_make_unit( INTERFACE     "${OPT_INTERFACE}"
                  EXTENSION     "${OPT_EXTENSION}"
                  DESTINATION   "${OPT_DESTINATION}"
                  DEPENDENCIES  "${OPT_DEPENDENCIES}"
                  PCH           "${OPT_PCH}"
                  FILES         "${FOUND_FILES}"
                  ROOT          "${OPT_PATTERN}"
                  IMPLICIT      "${MAKE_IMPLICIT}"
                  QUIET
                )
  else()
    copa_make_unit( INTERFACE     "${OPT_INTERFACE}"
                    EXTENSION     "${OPT_EXTENSION}"
                    DESTINATION   "${OPT_DESTINATION}"
                    DEPENDENCIES  "${OPT_DEPENDENCIES}"
                    PCH           "${OPT_PCH}"
                    FILES         "${FOUND_FILES}"
                    ROOT          "${OPT_PATTERN}"
                    IMPLICIT      "${MAKE_IMPLICIT}"
                  )
  endif()
endfunction()


##======================================================================================================================
## Process a list of source files to generate a single test target
##======================================================================================================================
function(COPA_MAKE_SINGLE_UNIT)
  set(oneValueArgs    NAME INTERFACE EXTENSION ROOT DESTINATION PCH)
  set(multiValueArgs  DEPENDENCIES FILES)
  cmake_parse_arguments(OPT "" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )

  if(NOT DEFINED OPT_EXTENSION)
    set(OPT_EXTENSION "exe")
  endif()

  if(NOT DEFINED OPT_DESTINATION)
    set(OPT_DESTINATION "unit")
  endif()

  copa_source_to_target( "${OPT_EXTENSION}" "${OPT_NAME}" test)
  add_executable(${test} ${OPT_FILES})

  copa_add_target_parent(${test})
  add_dependencies(unit ${test})

  if(DEFINED OPT_DEPENDENCIES)
    add_dependencies(${test} ${OPT_DEPENDENCIES})
  endif()

  copa_setup_test( ${test} "${OPT_DESTINATION}")
  target_link_libraries(${test} PUBLIC ${OPT_INTERFACE})

  if( DEFINED OPT_PCH)
    target_precompile_headers(${test} REUSE_FROM ${OPT_PCH})
    add_dependencies(${test} ${OPT_PCH})
  endif()

endfunction()
