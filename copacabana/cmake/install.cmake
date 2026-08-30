##======================================================================================================================
##  Copacabana - Common CMake Package Tools
##  Copyright : Copacabana Project Contributors
##  SPDX-License-Identifier: BSL-1.0
##======================================================================================================================
include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

##======================================================================================================================
## Prepare install target
##======================================================================================================================
function(COPA_SETUP_INSTALL)
  set(oneValueArgs    LIBRARY NAMESPACE COMPATIBILITY CONFIG)
  set(multiValueArgs  LIB INCLUDE DOC FEATURES)
  cmake_parse_arguments(OPT "" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )

  if(NOT DEFINED OPT_LIBRARY)
    message(FATAL_ERROR "[${PROJECT_NAME}] - Install target setup: Missing LIBRARY name")
  endif()

  if(NOT DEFINED OPT_NAMESPACE)
    set(OPT_NAMESPACE "${OPT_LIBRARY}")
  endif()

  ## What semantic versioning already promises: a consumer asking for 4.0 is served by 4.0.1. ExactVersion, the
  ## previous default, made find_package(kumi 4.0) refuse kumi 4.0.1.
  if(NOT DEFINED OPT_COMPATIBILITY)
    set(OPT_COMPATIBILITY "SameMajorVersion")
  endif()


  set(EXT_NAME      "${OPT_LIBRARY}_lib")
  set(TARGETS_NAME  "${OPT_LIBRARY}-targets")
  set(MAIN_DEST     "${CMAKE_INSTALL_LIBDIR}/${OPT_LIBRARY}")
  set(INSTALL_DEST  "${CMAKE_INSTALL_INCLUDEDIR}")
  set(DOC_DEST      "${CMAKE_INSTALL_DOCDIR}")

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

  ## Generated rather than copied, so the config gets @PACKAGE_INIT@ and its set_and_check helpers, paths that survive
  ## a relocated install prefix, and somewhere for find_dependency to go. CONFIG names another template for a package
  ## that needs more than the include and the alias.
  if(NOT DEFINED OPT_CONFIG)
    set(OPT_CONFIG "${COPACABANA_SOURCE_DIR}/copacabana/cmake/asset/package-config.cmake.in")
  endif()

  string(TOUPPER "${OPT_LIBRARY}" COPA_LIBRARY_UPPER)
  set(COPA_LIBRARY      "${OPT_LIBRARY}")
  set(COPA_NAMESPACE    "${OPT_NAMESPACE}")
  set(COPA_TARGETS_NAME "${TARGETS_NAME}")

  configure_package_config_file( "${OPT_CONFIG}"
                                 "${CMAKE_CURRENT_BINARY_DIR}/${OPT_LIBRARY}-config.cmake"
                                 INSTALL_DESTINATION "${MAIN_DEST}"
                               )

  write_basic_package_version_file( "${CMAKE_CURRENT_BINARY_DIR}/${OPT_LIBRARY}-config-version.cmake"
                                    VERSION "${PROJECT_VERSION}"
                                    COMPATIBILITY "${OPT_COMPATIBILITY}"
                                    ARCH_INDEPENDENT
                                  )

  install(FILES     "${CMAKE_CURRENT_BINARY_DIR}/${OPT_LIBRARY}-config.cmake"          DESTINATION "${MAIN_DEST}"  )
  install(FILES     "${CMAKE_CURRENT_BINARY_DIR}/${OPT_LIBRARY}-config-version.cmake"  DESTINATION "${MAIN_DEST}"  )
  install(EXPORT    ${TARGETS_NAME} NAMESPACE "${OPT_NAMESPACE}::"                    DESTINATION "${MAIN_DEST}"  )

endfunction()
