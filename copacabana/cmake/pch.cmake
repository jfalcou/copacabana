##======================================================================================================================
##  Copacabana - Common CMake Package Tools
##  Copyright : Copacabana Project Contributors
##  SPDX-License-Identifier: BSL-1.0
##======================================================================================================================

##======================================================================================================================
## Setup PCH
##======================================================================================================================
function(COPA_SETUP_PCH)
  set(oneValueArgs    TARGET )
  set(multiValueArgs  INTERFACES HEADERS)
  cmake_parse_arguments(OPT "" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )

  set(PCH_LIB   "${OPT_TARGET}_pch")
  set(PCH_FILE  "${OPT_TARGET}_pch.cpp")
  file(TOUCH "${PROJECT_BINARY_DIR}/${PCH_FILE}" )
  add_library( ${PCH_LIB}   "$<BUILD_INTERFACE:${PROJECT_BINARY_DIR}/${PCH_FILE}>" )

  foreach(interface ${OPT_INTERFACES})
    target_link_libraries(${PCH_LIB} PUBLIC ${interface})
  endforeach( )

  set_property( TARGET ${PCH_LIB} PROPERTY RUNTIME_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}/unit" )

  set_target_properties ( ${PCH_LIB} PROPERTIES
                          EXCLUDE_FROM_DEFAULT_BUILD TRUE
                          EXCLUDE_FROM_ALL TRUE
                          ${MAKE_UNIT_TARGET_PROPERTIES}
                        )

  foreach(header ${OPT_HEADERS})
    target_precompile_headers(${PCH_LIB} PRIVATE ${header})
  endforeach( )

  set(PROJECT_PCH_TARGET ${PCH_LIB} PARENT_SCOPE)
endfunction()
