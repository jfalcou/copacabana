##======================================================================================================================
##  Copacabana - Common CMake Package Tools
##  Copyright : Copacabana Project Contributors
##  SPDX-License-Identifier: BSL-1.0
##======================================================================================================================

##==================================================================================================
## Reuse install.cmake to preapre package properly
##==================================================================================================
include("${CMAKE_CURRENT_LIST_DIR}/example-targets.cmake")
set(EXAMPLE_LIBRARIES example::example)
