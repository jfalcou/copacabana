# SAMPLE

@brief@

## Getting it

```cmake
CPMAddPackage(NAME SAMPLE GIT_REPOSITORY @remote@ GIT_TAG main)
target_link_libraries(mine PRIVATE sample::sample)
```

Or point CMake at an installed copy:

```cmake
find_package(sample REQUIRED)
target_link_libraries(mine PRIVATE sample::sample)
```

## Building it

```bash
cmake -S . -B build -G Ninja
cmake --build build --target sample-test
ctest --test-dir build
```

`SAMPLE_BUILD_DOCUMENTATION=ON` adds the `sample-doxygen` target, `SAMPLE_ENABLE_SANITIZERS=ON`
builds the tests under ASan and UBSan, and `SAMPLE_ENABLE_COVERAGE=ON` adds `sample-coverage-report`.
