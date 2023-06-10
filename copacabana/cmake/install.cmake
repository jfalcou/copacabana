##======================================================================================================================
##  Copacabana - Common CMake Package Tools
##  Copyright : Copacabana Project Contributors
##  SPDX-License-Identifier: BSL-1.0
##======================================================================================================================
include(GNUInstallDirs)

##======================================================================================================================
## Prepare install target
##======================================================================================================================
function(COPA_SETUP_INSTALL)
  set(oneValueArgs    LIBRARY NAMESPACE )
  set(multiValueArgs  LIB INCLUDE DOC FEATURES)
  cmake_parse_arguments(OPT "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )

  if(NOT DEFINED OPT_LIBRARY)
    message(FATAL_ERROR "[${PROJECT_NAME}] - Install target setup: Missing LIBRARY name")
  endif()

  if(NOT DEFINED OPT_NAMESPACE)
    set(OPT_NAMESPACE "${OPT_LIBRARY}")
  endif()

  set(EXT_NAME      "${OPT_LIBRARY}_lib")
  set(TARGETS_NAME  "${OPT_LIBRARY}-targets")
  set(MAIN_DEST     "${CMAKE_INSTALL_LIBDIR}/${OPT_LIBRARY}-${PROJECT_VERSION}")
  set(INSTALL_DEST  "${CMAKE_INSTALL_INCLUDEDIR}/${OPT_LIBRARY}-${PROJECT_VERSION}")
  set(DOC_DEST      "${CMAKE_INSTALL_DOCDIR}-${PROJECT_VERSION}")

  add_library(${EXT_NAME} INTERFACE)
  target_include_directories( ${EXT_NAME} INTERFACE
                              $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/include>
                              $<INSTALL_INTERFACE:${INSTALL_DEST}>
                            )

  if(DEFINED OPT_FEATURES)
    target_compile_features(${EXT_NAME} INTERFACE ${OPT_FEATURES})
  endif()
#
  set_target_properties(${EXT_NAME} PROPERTIES EXPORT_NAME ${OPT_LIBRARY})
  add_library("${OPT_NAMESPACE}::${OPT_LIBRARY}" ALIAS ${EXT_NAME})

  install(TARGETS   ${EXT_NAME} EXPORT ${TARGETS_NAME} DESTINATION "${MAIN_DEST}")

  foreach(folder ${OPT_INCLUDE})
    install(DIRECTORY  ${folder}    DESTINATION "${INSTALL_DEST}" )
  endforeach()

  foreach(file ${OPT_LIB})
    install(FILES  ${file}    DESTINATION "${MAIN_DEST}" )
  endforeach()

  foreach(file ${OPT_DOC})
    install(FILES  ${file}    DESTINATION "${DOC_DEST}" )
  endforeach()

  install(FILES     "${PROJECT_SOURCE_DIR}/cmake/${OPT_LIBRARY}-config.cmake" DESTINATION "${MAIN_DEST}"  )
  install(EXPORT    ${TARGETS_NAME} NAMESPACE "${OPT_NAMESPACE}::"            DESTINATION "${MAIN_DEST}"  )

endfunction()
