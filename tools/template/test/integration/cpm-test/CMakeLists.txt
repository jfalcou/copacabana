##======================================================================================================================
##  SAMPLE - @brief@
##  Copyright : SAMPLE Project Contributors
##  SPDX-License-Identifier: BSL-1.0
##======================================================================================================================
cmake_minimum_required(VERSION 3.18)
project(sample-cpm-test LANGUAGES CXX)
enable_testing()

message(STATUS "Testing CPM for branch ${GIT_BRANCH}")

# Setup CPM
include(cpm.cmake)

# Add dependencies
CPMAddPackage(
  NAME sample
  GIT_REPOSITORY "@remote@.git"
  GIT_TAG "${GIT_BRANCH}"
  OPTIONS "SAMPLE_BUILD_TEST OFF")

# Use sample
add_executable(test_sample ../main.cpp)
target_link_libraries(test_sample PUBLIC sample::sample)
add_test(NAME test_sample COMMAND test_sample)
