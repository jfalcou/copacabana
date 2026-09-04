# Copacabana

The CMake and CI plumbing a C++ project writes every time, written once here:

- install rules and the package config `find_package` needs
- unit-test generation, sanitizers, coverage
- a styled Doxygen setup
- single-header packaging, `.deb`, `.rpm` and `.tar.gz`

The current release is [Version 7 - Garota de Ipanema](https://github.com/jfalcou/copacabana/releases/tag/v7).

Copacabana gives you two independent halves:

- **CMake functions**, named `copa_*`, that you call from your own `CMakeLists.txt`.
- **Reusable GitHub workflows and composite actions**, that you reference from your own
  `.github/workflows/`.

Take either on its own. The CMake half needs nothing but CMake 3.24 and works with any CI, or
none. The CI half assumes your project builds through CMake presets, and nothing else about it.

## Getting it

```cmake
CPMAddPackage(NAME COPACABANA GITHUB_REPOSITORY jfalcou/copacabana GIT_TAG v7)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${COPACABANA_SOURCE_DIR}/copacabana/cmake)
include(${COPACABANA_SOURCE_DIR}/copacabana/cmake/copacabana.cmake)
```

`FetchContent` or a vendored copy work the same: set `COPACABANA_SOURCE_DIR` to wherever it landed and
include the same file. One `include` makes every function available, and an in-source build is refused
outright.

Pin a tag rather than tracking `main`, which also carries Copacabana's own CI and example. A consumer
carries **two** pins (the `GIT_TAG` here and the SHA in its `uses:` lines) and only the second is
moved by Dependabot. Change them together.

## A minimal consumer

```cmake
cmake_minimum_required(VERSION 3.24)
project(mylib LANGUAGES CXX)

include(cmake/dependencies.cmake)      # brings in CPM, then Copacabana

option(MYLIB_BUILD_TEST        "Build tests for MYLIB" ON )
option(MYLIB_ENABLE_SANITIZERS "ASan + UBSan"          OFF)
option(MYLIB_ENABLE_COVERAGE   "Coverage"              OFF)

copa_project_version(MAJOR 1 MINOR 0 PATCH 0 REPOSITORY https://github.com/you/mylib)

copa_setup_install(LIBRARY mylib FEATURES cxx_std_20 INCLUDE ${PROJECT_SOURCE_DIR}/include/mylib)
copa_setup_precommit_hooks()

if(MYLIB_BUILD_TEST)
  if(MYLIB_ENABLE_SANITIZERS)
    copa_setup_sanitizers(mylib_test ENABLE_ASAN ENABLE_UBSAN)
  endif()

  copa_setup_test_targets()
  enable_testing()
  add_subdirectory(test)

  if(MYLIB_ENABLE_COVERAGE)
    copa_setup_coverage(mylib_test)
  endif()
endif()
```

with `test/CMakeLists.txt` reduced to:

```cmake
copa_glob_unit(QUIET PATTERN "unit/*.cpp" INTERFACE mylib_test RELATIVE ${CMAKE_CURRENT_SOURCE_DIR})
```

The package config is generated for you, so there is nothing else to write. The `test/example/`
directory here is the same thing, kept building by Copacabana's own CI.

One layout is required, and only by `copa_setup_install`: the headers live under `include/`, which is
what the generated target exposes to a consumer. The rest of the tree is yours.

## Documentation

The [wiki](https://github.com/jfalcou/copacabana/wiki) has the rest:

- [CMake Functions](https://github.com/jfalcou/copacabana/wiki/CMake-Functions): the `copa_*` functions, one reference page per family
- [Reusable Workflows](https://github.com/jfalcou/copacabana/wiki/Reusable-Workflows): the workflows a consumer calls by `uses:`
- [Composite Actions](https://github.com/jfalcou/copacabana/wiki/Composite-Actions): `config` and `test`, for the matrices a project keeps
- [Project Anatomy](https://github.com/jfalcou/copacabana/wiki/Project-Anatomy): the targets, the install tree and the packages a project ends up with
- [Starting A Project](https://github.com/jfalcou/copacabana/wiki/Starting-A-Project): the scaffolder
- [What Adopting It Measured](https://github.com/jfalcou/copacabana/wiki/What-Adopting-It-Measured): what six libraries adopting this measured
