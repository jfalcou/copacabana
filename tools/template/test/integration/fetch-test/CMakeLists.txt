##======================================================================================================================
##  SAMPLE - @brief@
##  Copyright : SAMPLE Project Contributors
##  SPDX-License-Identifier: BSL-1.0
##======================================================================================================================
cmake_minimum_required(VERSION 3.22)
project(sample-fetch-test LANGUAGES CXX)
enable_testing()

message(STATUS "Testing FetchContent for branch ${GIT_BRANCH}")

# Enable FetchContent
include(FetchContent)

# Retrieve SAMPLE from relative git directory
FetchContent_Declare(
  sample
  GIT_REPOSITORY "@remote@.git"
  GIT_TAG ${GIT_BRANCH})

## FetchContent has no per-package OPTIONS: what sample reads is pinned here.
set(SAMPLE_BUILD_TEST
    OFF
    CACHE BOOL "" FORCE)

# make available
FetchContent_MakeAvailable(sample)

add_executable(test_sample ../main.cpp)
target_link_libraries(test_sample PUBLIC sample::sample)
add_test(NAME test_sample COMMAND test_sample)
