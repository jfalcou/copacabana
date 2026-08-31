##======================================================================================================================
##  Copacabana - Common CMake Package Tools
##  Copyright : Copacabana Project Contributors
##  SPDX-License-Identifier: BSL-1.0
##======================================================================================================================
## Two consumers of copacabana in one build. The subdirectory includes copacabana.cmake first, in its own scope; this
## one includes it after. Including it has side effects that belong to the including scope - the CMAKE_INSTALL_ family
## GNUInstallDirs defines - so a guard that fires once for the whole build leaves this scope without them, and
## copa_setup_install then installs to nowhere. This is copacabana#62.
cmake_minimum_required(VERSION 3.22)
project(guard LANGUAGES CXX)

if(NOT DEFINED COPACABANA_SOURCE_DIR)
  message(FATAL_ERROR "[guard] - pass -DCOPACABANA_SOURCE_DIR=<path to a copacabana checkout>")
endif()

add_subdirectory(consumer)

include(${COPACABANA_SOURCE_DIR}/copacabana/cmake/copacabana.cmake)

if(NOT CMAKE_INSTALL_DOCDIR)
  message(
    FATAL_ERROR "[guard] - CMAKE_INSTALL_DOCDIR is empty here, so copacabana.cmake was skipped in this scope after the "
                "subdirectory included it. include_guard is GLOBAL where it has to be DIRECTORY.")
endif()

message(STATUS "[guard] - both scopes have CMAKE_INSTALL_DOCDIR: ${CMAKE_INSTALL_DOCDIR}")
