##======================================================================================================================
##  Copacabana - Common CMake Package Tools
##  Copyright : Copacabana Project Contributors
##  SPDX-License-Identifier: BSL-1.0
##======================================================================================================================
## Drops the traces left by an earlier build, and the objects that go with them. Run via 'cmake -DTIME_TRACE_SCAN=<dir>
## -P', because the cleanup has to happen before the build and 'cmake -E rm' expands no wildcard.
##
## The objects go too: a trace is written as a side effect of compiling, so dropping the JSON alone leaves the build
## up to date, nothing recompiles and no trace comes back. A measurement recompiles what it measures.
##======================================================================================================================
file(GLOB_RECURSE COPA_STALE_TRACES "${TIME_TRACE_SCAN}/*.json" "${TIME_TRACE_SCAN}/*.o" "${TIME_TRACE_SCAN}/*.obj")

if(COPA_STALE_TRACES)
  file(REMOVE ${COPA_STALE_TRACES})
endif()
