##======================================================================================================================
##  Copacabana - Common CMake Package Tools
##  Copyright : Copacabana Project Contributors
##  SPDX-License-Identifier: BSL-1.0
##======================================================================================================================

copa_glob_unit(PATTERN "types/*.cpp"  DEPENDENCIES standalone-example INTERFACE example_test PCH example_pch)
copa_glob_unit(PATTERN "values/*.cpp" DEPENDENCIES standalone-example INTERFACE example_test PCH example_pch)
