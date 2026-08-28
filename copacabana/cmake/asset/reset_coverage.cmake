##======================================================================================================================
##  Copacabana - Common CMake Package Tools
##  Copyright : Copacabana Project Contributors
##  SPDX-License-Identifier: BSL-1.0
##======================================================================================================================
## Drops the counters left by a previous run. Run via 'cmake -DCOVERAGE_BUILD_DIR=<dir> -P'.
## Counters stamped for object files a rebuild replaced are an error to gcov, not a thing it skips.
##======================================================================================================================
file(GLOB_RECURSE COPA_STALE_COUNTERS "${COVERAGE_BUILD_DIR}/*.gcda")

if(COPA_STALE_COUNTERS)
  file(REMOVE ${COPA_STALE_COUNTERS})
endif()
