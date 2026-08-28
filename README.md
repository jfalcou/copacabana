# Copacabana

Recurring CMake tools and CI pieces, shared by a family of header-only C++ libraries so that
none of them has to write the same install rules, Doxygen setup, unit-test globbing or GitHub
Actions workflow twice.

Copacabana gives you two things:

- **CMake functions**, named `copa_*`, that you call from your own `CMakeLists.txt`.
- **Reusable GitHub workflows and composite actions**, that you reference from your own
  `.github/workflows/`.

You can adopt either half on its own.

## Getting it

Copacabana is pulled in with CPM, before anything else:

```cmake
CPMAddPackage(NAME COPACABANA GITHUB_REPOSITORY jfalcou/copacabana GIT_TAG v3)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${COPACABANA_SOURCE_DIR}/copacabana/cmake)
include(${COPACABANA_SOURCE_DIR}/copacabana/cmake/copacabana.cmake)
```

`copacabana.cmake` includes every module, so a single `include` makes all the functions below
available. It also refuses an in-source build outright. Pin a tag rather than tracking `main`:
`main` also carries Copacabana's own CI and example, which are none of your business and change
far more often than the parts you use.

**Which tag?** Copacabana is retagged only when something a consumer depends on changes, that is
`copacabana/cmake/` or the reusable workflows. Its own CI, its example and its Dependabot
configuration land on `main` without a new tag.

## The CMake functions

Every function takes `QUIET` to silence its own `message(STATUS ...)` lines. The usual idiom is
to derive one variable from a project-wide option and pass it everywhere:

```cmake
if(NOT MYLIB_QUIET)
  set(QUIET_OPTION "")
else()
  set(QUIET_OPTION "QUIET")
endif()
```

### `copa_project_version`

```cmake
copa_project_version(MAJOR 3 MINOR 0 PATCH 0)
```

Sets `PROJECT_VERSION` and friends, and defines the version file the install rules ship. Missing
components default to `0.1.0`.

### `copa_setup_install`

```cmake
copa_setup_install( LIBRARY tts
                    FEATURES cxx_std_20
                    DOC     ${PROJECT_SOURCE_DIR}/LICENSE.md
                    INCLUDE ${PROJECT_SOURCE_DIR}/include/tts
                  )
```

Creates the interface target `<LIBRARY>_lib`, its `NAMESPACE::LIBRARY` alias — `tts::tts` here,
which is the name everyone links against — the install rules, and the CMake package config that
makes `find_package(tts CONFIG REQUIRED)` work downstream.

| argument | | |
|---|---|---|
| `LIBRARY` | required | target and package name |
| `NAMESPACE` | | defaults to `LIBRARY` |
| `COMPATIBILITY` | | defaults to `ExactVersion` |
| `INCLUDE` | | header directories to install |
| `DOC` | | files installed next to the headers, typically the licence |
| `FEATURES` | | compile features carried by the interface target |
| `LIB` | | binary artefacts, for the non header-only case |

### `copa_setup_doxygen`

```cmake
copa_setup_doxygen(${QUIET_OPTION} TARGET tts-doxygen DESTINATION "${PROJECT_BINARY_DIR}/doc")
```

Adds the Doxygen target, wired to doxygen-awesome-css and to the styling assets Copacabana
carries. `TARGET` defaults to `<project>-doxygen`, which is the name the shared documentation
workflow expects — leave it alone unless you have a reason.

### `copa_setup_standalone`

```cmake
copa_setup_standalone( QUIET
                       FILE tts.hpp SOURCE include ROOT tts TARGET tts-standalone
                       OUTPUT "${PROJECT_BINARY_DIR}"
                     )
```

Adds a target that flattens the library into a single header by inlining its own `#include`s.
`FILE` is the root header, `SOURCE` the include directory, `ROOT` the subdirectory inside it.
Give either `OUTPUT` (an absolute directory) or `DESTINATION` (relative to the source tree).

### `copa_setup_pch`

```cmake
copa_setup_pch(TARGET kyosu INTERFACES kyosu_test HEADERS include/kyosu/kyosu.hpp)
```

Builds a precompiled header from `HEADERS` and attaches it to every interface listed in
`INTERFACES`. Pass `AUTONOMOUS` when the generated translation unit must not carry a `main`.

### `copa_setup_precommit_hooks`

```cmake
copa_setup_precommit_hooks(${QUIET_OPTION})
```

Adds `<project>-setup-hooks`, which runs `pre-commit install`. Silently does nothing when the
source tree is not a git checkout or `pre-commit` is not on the path, so it is safe to call
unconditionally. Needs a `.pre-commit-config.yaml` of your own.

### `copa_setup_test_targets`

```cmake
copa_setup_test_targets()
```

Declares the `<project>-test` aggregate that every unit gathers under. **Call it before any
`copa_glob_unit` or `copa_make_unit`**, or those calls will attach to a target that does not
exist yet.

### `copa_glob_unit`

```cmake
copa_glob_unit( QUIET
                PATTERN "unit/*.cpp" INTERFACE kumi_test
                RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}
              )
```

Globs the sources matching `PATTERN` and turns each into its own executable, named after its
path with dots instead of slashes — `unit/tuple/apply.cpp` becomes `unit.tuple.apply.exe`. The
intermediate targets `unit.tuple.exe` and `unit.exe` are created too, so you can build a whole
subtree by name. Each executable is registered with CTest and hung off the project's test
aggregate.

| argument | | |
|---|---|---|
| `PATTERN` | required | glob, relative to `RELATIVE` |
| `RELATIVE` | | base directory the target names are derived from |
| `INTERFACE` | | interface target every unit links against |
| `TARGET` | | aggregate to gather under, instead of `<project>-test` |
| `EXTENSION` | | target suffix, defaults to `exe` |
| `DESTINATION` | | output subdirectory under the build tree |
| `PCH` | | precompiled header target to reuse |
| `DEPENDENCIES` | | targets each unit must wait for |
| `EXTERNALS` | | extra libraries to link |
| `IMPLICIT` | | one executable per source, without a `main` of its own |

**`TARGET` is what keeps benchmarks and samples out of the test run.** A unit gathered under
another aggregate is not registered with CTest, because the test target never builds it and
`ctest` would then ask for an executable that does not exist:

```cmake
copa_glob_unit(QUIET PATTERN "benchmarks/*.cpp" INTERFACE kyosu_bench TARGET kyosu-bench ...)
```

### `copa_make_unit` and `copa_make_single_unit`

The same machinery driven by an explicit `FILES` list rather than a glob. `copa_make_single_unit`
compiles several sources into **one** executable named by `NAME`, for a suite that has to link
as a whole.

### `copa_setup_sanitizers`

```cmake
copa_setup_sanitizers(mylib_test ENABLE_ASAN ENABLE_UBSAN)
```

Adds the sanitizer flags to an **interface** target, so everything linking against it is
instrumented. Options are `ENABLE_ASAN`, `ENABLE_UBSAN`, `ENABLE_TSAN`, `ENABLE_MSAN`. Attach it
to the interface your test units already link against, and call it *before* `add_subdirectory`
so the units are created with the flags in place.

### `copa_setup_coverage`

```cmake
copa_setup_coverage(mylib_docs)
```

Instruments a target and adds `<prefix>-coverage`, which runs the suite under instrumentation,
and `<prefix>-coverage-report`, which turns the counters into an HTML report and a JSON summary.

| argument | | |
|---|---|---|
| `PREFIX` | | target name prefix, defaults to the lowercased project name |
| `FILTER` | | what to report on, defaults to `<source>/include/<prefix>/` |
| `DEPENDS` | | target building the tests, defaults to `<prefix>-test` |

**Call it after `add_subdirectory`**, once the test targets exist — the coverage targets depend
on them.

Two constraints it enforces for you, rather than letting them fail obscurely later:

- The coverage reader must match the compiler major. `gcov-14` cannot read notes written by
  g++-15, and gcovr reports that as `could not infer a working directory`, naming neither the
  tool nor the version. Copacabana checks the pairing at configure time and tells you which
  package to install.
- gcovr 8 sums a header's lines once per translation unit including it, instead of taking their
  union, which on a header-only template library reports totals larger than the files
  themselves. Copacabana warns; **use gcovr 7.x**.

### `copa_setup_cpack`

```cmake
copa_setup_cpack(VENDOR "..." DESCRIPTION "..." LICENSE_FILE ... MAINTAINER ...)
```

Configures CPack for `.deb`, `.rpm` and `.zip`. `DEB_DEPENDENCIES` and `RPM_DEPENDENCIES` take
lists in each packager's own syntax.

## The reusable workflows

Called from your own `.github/workflows/`, they carry the steps; you keep the triggers and the
matrices.

```yaml
jobs:
  documentation:
    uses: jfalcou/copacabana/.github/workflows/documentation.yml@<sha> # v3
    with:
      project: tts
```

**Pin by full commit SHA with the tag in a trailing comment**, not by tag. SonarCloud's
`githubactions:S7637` fails the quality gate on a `uses:` pinned to a tag from outside a trusted
organisation, and `jfalcou/copacabana` counts as outside. Add a `.github/dependabot.yml` for the
`github-actions` ecosystem so the SHA and its comment get maintained; pinning by SHA then costs
no more than pinning by tag.

Every one of them takes `image`, the tag of `ghcr.io/jfalcou/compilers` to run in, defaulting to
`v10`. `project` is always the **lowercased** project name: options are derived from it in upper
case, targets and paths in lower case.

| workflow | inputs | what it does |
|---|---|---|
| `documentation.yml` | `project`, `coverage` | builds `<project>-doxygen` and deploys to gh-pages |
| `integration.yml` | `project`, `cxx-compiler`, `cxx-flags` | checks the installed, FetchContent and CPM paths |
| `package-standalone.yml` | `project` | regenerates the single header and pushes the `standalone` branch |
| `sanitizers.yml` | `build-targets`, `test-targets` | ASan and UBSan, on gcc and clang |
| `coverage.yml` | `project`, `build-targets` | runs the coverage target and writes a job summary |

`documentation.yml` also ships the coverage report when `coverage: true`. Both have to reach
gh-pages in a single deployment, or one wipes the other out — which is why coverage rides along
there rather than deploying on its own.

`integration.yml` expects `test/integration/{install,fetch,cpm}-test/` in your repository. Pin
what your dependencies read inside those `CMakeLists.txt`: `CPMAddPackage` carries `OPTIONS`,
`FetchContent` carries nothing, so a bare `FetchContent_MakeAvailable(dep)` leaves the
dependency's own test suite registered in your CTest and the integration run turns into a full
test run of everything you depend on.

`sanitizers.yml` and `coverage.yml` expect the presets `gcc-sanitize`, `clang-sanitize` and
`gcc-coverage`, and the targets `copa_setup_coverage` generates.

## The composite actions

For the workflows you keep yourself — the platform matrices — two actions wrap the preset dance:

```yaml
- uses: jfalcou/copacabana/.github/actions/config@<sha> # v4
  with:
    preset: ${{ matrix.compiler.preset }}
    config: ${{ matrix.options }}
    targets: mylib-test          # omit to build the preset default target

- uses: jfalcou/copacabana/.github/actions/test@<sha> # v4
  with:
    preset: ${{ matrix.compiler.preset }}
    config: ${{ matrix.options }}
    memcheck: true               # optional valgrind pass
```

`config` also takes `wrapper`, for a compiler wrapper such as `emcmake`, and `setup-script`, for
an environment script to source such as oneAPI's `setvars.sh`. `targets` is a space-separated
build target list on `config`, and a ctest `-R` filtering rule on `test`; both run everything
when left out.

These are not used by the reusable workflows above, which inline their steps: a `uses: ./...`
reference resolves inside the checked-out tree, which belongs to the calling project rather than
to Copacabana.

## A minimal consumer

```cmake
cmake_minimum_required(VERSION 3.22)
project(mylib LANGUAGES CXX)

include(cmake/dependencies.cmake)      # brings in CPM, then Copacabana

option(MYLIB_BUILD_TEST        "Build tests for MYLIB" ON )
option(MYLIB_ENABLE_SANITIZERS "ASan + UBSan"          OFF)
option(MYLIB_ENABLE_COVERAGE   "Coverage"              OFF)

copa_project_version(MAJOR 1 MINOR 0 PATCH 0)

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

The `example/` directory in this repository is the same thing, kept building by Copacabana's own
CI.

## Ordering, in one place

Three call orders are load-bearing, and getting them wrong fails in ways that do not name the
cause:

1. `copa_setup_test_targets()` **before** any `copa_glob_unit` / `copa_make_unit`.
2. `copa_setup_sanitizers()` **before** `add_subdirectory(test)`, so the units are created with
   the flags.
3. `copa_setup_coverage()` **after** `add_subdirectory(test)`, so the test targets it depends on
   exist.
