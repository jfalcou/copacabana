##======================================================================================================================
##  SAMPLE - @brief@
##  Copyright : SAMPLE Project Contributors
##  SPDX-License-Identifier: BSL-1.0
##======================================================================================================================
cmake_minimum_required(VERSION 3.22)
project(sample-install-test LANGUAGES CXX)
enable_testing()

find_package(sample CONFIG REQUIRED)
add_executable(test_sample ../main.cpp)
target_link_libraries(test_sample PUBLIC sample::sample)
add_test(NAME test_sample COMMAND test_sample)
