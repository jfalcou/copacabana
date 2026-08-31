##======================================================================================================================
##  Copacabana - Common CMake Package Tools
##  Copyright : Copacabana Project Contributors
##  SPDX-License-Identifier: BSL-1.0
##======================================================================================================================

##======================================================================================================================
## Setup PCH
##======================================================================================================================
function(COPA_SETUP_PCH)
  set(options         AUTONOMOUS        )
  set(oneValueArgs    TARGET            )
  set(multiValueArgs  INTERFACES HEADERS PROPERTIES)
  cmake_parse_arguments(OPT "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )

  set(PCH_LIB   "${OPT_TARGET}_pch")
  set(PCH_FILE  "${OPT_TARGET}_pch.cpp")

  if(NOT OPT_AUTONOMOUS)
    file(WRITE "${PROJECT_BINARY_DIR}/${PCH_FILE}" "int main() {}" )
  else()
    file(TOUCH "${PROJECT_BINARY_DIR}/${PCH_FILE}"  )
  endif()

  add_executable( ${PCH_LIB}   "${PROJECT_BINARY_DIR}/${PCH_FILE}" )

  if(DEFINED PROJECT_STANDALONE_TARGET)
    add_dependencies(${PCH_LIB} ${PROJECT_STANDALONE_TARGET} )
  endif()

  foreach(interface ${OPT_INTERFACES})
    target_link_libraries(${PCH_LIB} PRIVATE ${interface})
  endforeach( )

  set_property( TARGET ${PCH_LIB} PROPERTY RUNTIME_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}/unit" )
  # cmake-lint: disable=E1120
  set_target_properties ( ${PCH_LIB} PROPERTIES
                          EXCLUDE_FROM_DEFAULT_BUILD TRUE
                          EXCLUDE_FROM_ALL TRUE
                          ${OPT_PROPERTIES}
                        )

  foreach(header ${OPT_HEADERS})
    target_precompile_headers(${PCH_LIB} PRIVATE "${PROJECT_SOURCE_DIR}/${header}")
  endforeach( )

  set(PROJECT_PCH_TARGET ${PCH_LIB} PARENT_SCOPE)
endfunction()
