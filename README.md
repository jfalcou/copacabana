# Copacabana

Recurring CMake and CI plumbing for C++ projects — install rules and package config, Doxygen,
unit-test generation, sanitizers, coverage, single-header packaging — so you write it once and
never again.

Copacabana gives you two independent halves:

- **CMake functions**, named `copa_*`, that you call from your own `CMakeLists.txt`.
- **Reusable GitHub workflows and composite actions**, that you reference from your own
  `.github/workflows/`.

Take either on its own. The CMake half needs nothing but CMake 3.22 and works with any CI, or
none. The CI half assumes your project builds through CMake presets, and nothing else about it.

**What it assumes about your project.** Copacabana grew around header-only libraries and still
carries that shape in two places: `copa_setup_install` creates an `INTERFACE` target and expects
your headers under `<source>/include`, and `copa_setup_standalone` only makes sense for a library
that can be flattened into one header. Everything else — the test generator, sanitizers,
coverage, Doxygen, pre-commit, CPack — is indifferent to how your project is built.

## Getting it

Anything that puts the repository on disk works. With CPM:

```cmake
CPMAddPackage(NAME COPACABANA GITHUB_REPOSITORY jfalcou/copacabana GIT_TAG v3)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${COPACABANA_SOURCE_DIR}/copacabana/cmake)
include(${COPACABANA_SOURCE_DIR}/copacabana/cmake/copacabana.cmake)
```

With `FetchContent`, or a vendored copy, set `COPACABANA_SOURCE_DIR` to wherever it landed and
include the same file. `copacabana.cmake` includes every module, so one `include` makes all the
functions below available. It also refuses an in-source build outright.

Pin a tag rather than tracking `main`: `main` also carries Copacabana's own CI and example, which
change far more often than the parts you use. It is retagged only when something a consumer
depends on changes — `copacabana/cmake/` or the reusable workflows.

## The CMake functions

Fifteen functions, covering four things a library ends up needing whatever it does.

**Shipping it.**

| | |
|---|---|
| `copa_project_version` | version numbers and the version file |
| `copa_setup_install` | interface target, install rules, package config |
| `copa_setup_standalone` | flatten the library into one header |
| `copa_setup_cpack` | `.deb`, `.rpm` and `.zip` packages |

**Testing it.**

| | |
|---|---|
| `copa_setup_test_targets` | declare the aggregate everything gathers under |
| `copa_glob_unit` | one executable per source file, from a glob |
| `copa_make_unit` | the same, from an explicit list |
| `copa_make_single_unit` | several sources into one executable |
| `copa_glob_failure_unit` | one test per source that has to be rejected, from a glob |
| `copa_make_failure_unit` | the same, for a named source |

**Checking it.**

| | |
|---|---|
| `copa_setup_sanitizers` | ASan, UBSan, TSan, MSan |
| `copa_setup_coverage` | instrumentation, HTML report and JSON summary |

**Living with it.**

| | |
|---|---|
| `copa_setup_doxygen` | documentation target, styled |
| `copa_setup_pch` | precompiled header |
| `copa_setup_precommit_hooks` | install the git hooks |

None of them is mandatory and none depends on the others being used, except for the three
orderings listed at the end. Take `copa_glob_unit` alone if that is all you want.

The ones that have something to say take `QUIET` to silence their own `message(STATUS ...)`
lines: `copa_project_version`, `copa_setup_doxygen`, `copa_setup_standalone`,
`copa_setup_precommit_hooks`, `copa_setup_cpack`, `copa_glob_unit` and `copa_make_unit`. The
usual idiom is to derive one variable from a project-wide option and pass it to all of them:

```cmake
if(NOT MYLIB_QUIET)
  set(QUIET_OPTION "")
else()
  set(QUIET_OPTION "QUIET")
endif()
```

### `copa_project_version`

```cmake
copa_project_version(MAJOR 1 MINOR 2 PATCH 0)
```

Sets `PROJECT_VERSION` and friends, and defines the version file the install rules ship. Missing
components default to `0.1.0`.

### `copa_setup_install`

```cmake
copa_setup_install( LIBRARY mylib
                    FEATURES cxx_std_20
                    DOC     ${PROJECT_SOURCE_DIR}/LICENSE.md
                    INCLUDE ${PROJECT_SOURCE_DIR}/include/mylib
                  )
```

Creates the interface target `<LIBRARY>_lib`, its `NAMESPACE::LIBRARY` alias — `mylib::mylib`
here, which is the name everyone links against — the install rules, and the CMake package config
that makes `find_package(mylib CONFIG REQUIRED)` work downstream.

| argument | | |
|---|---|---|
| `LIBRARY` | required | target and package name |
| `NAMESPACE` | | defaults to `LIBRARY` |
| `COMPATIBILITY` | | defaults to `ExactVersion` |
| `INCLUDE` | | header directories to install |
| `DOC` | | files installed next to the headers, typically the licence |
| `FEATURES` | | compile features carried by the interface target |
| `LIB` | | extra files dropped in the library directory |

Two things it needs from you, and neither complains until install time:

- Your headers must sit under `<source>/include`, which is what the build interface points at.
- You must provide `<source>/cmake/<LIBRARY>-config.cmake`. Two lines are enough:

  ```cmake
  include("${CMAKE_CURRENT_LIST_DIR}/mylib-targets.cmake")
  set(MYLIB_LIBRARIES mylib::mylib)
  ```

The target is always an `INTERFACE` library and the version file is written `ARCH_INDEPENDENT`,
so this is the header-only path. A compiled library wants its own `install(TARGETS ...)`.

### `copa_setup_doxygen`

```cmake
copa_setup_doxygen(${QUIET_OPTION} DESTINATION "${PROJECT_BINARY_DIR}/doc")
```

Adds the Doxygen target, wired to doxygen-awesome-css and to the styling assets Copacabana
carries. `TARGET` defaults to `<project>-doxygen`, which is the name the shared documentation
workflow expects — leave it alone unless you have a reason. `SOURCE` says what to document.

`URL` is the repository the GitHub corner links to, `GODBOLT_LIBRARIES`, `GODBOLT_COMPILER` and
`GODBOLT_OPTIONS` say what an `@godbolt` example is sent to Compiler Explorer with, and the four
`COLOR_*` are the hue, saturation, lightness and gamma the whole palette is derived from — three
numbers rather than a stylesheet, so the light and dark shades cannot drift apart.

`TAGFILES` takes `<name>=<url>` entries and downloads `<url>/<name>.tag` before the target runs,
which is what makes references into another library resolve — Doxygen fetches nothing itself. It
also hands Doxygen every symbol that library documents, and those land in the search box, so the
generated index is trimmed afterwards. A URL that does not answer warns and leaves the links dead
rather than failing the configure.

```cmake
copa_setup_doxygen(DESTINATION "${PROJECT_BINARY_DIR}/doc" TAGFILES other=https://example.org/other)
```

A `head.html` beside the Doxyfile is copied verbatim into the generated `<head>`, and nothing is
emitted without it. It is where the Open Graph and Twitter tags go: what a link to the pages
unfurls into is prose about the project and absolute URLs to where it is published, neither of
which can be worked out from here:

```html
<meta name="description" content="What the library does, in one line" />
<link rel="canonical" href="https://example.org/mylib/" />
<meta property="og:title" content="MYLIB - What it is" />
<meta property="og:description" content="What the library does, in one line" />
<meta property="og:type" content="website" />
<meta property="og:url" content="https://example.org/mylib/" />
<meta property="og:image" content="https://example.org/mylib/card.png" />
<meta name="twitter:card" content="summary_large_image" />
<meta name="twitter:image" content="https://example.org/mylib/card.png" />
```

The image has to be listed in `HTML_EXTRA_FILES` to be published beside the pages, and both it and
the URLs have to be absolute: the sites that read these tags fetch them from elsewhere.

### `copa_setup_standalone`

```cmake
copa_setup_standalone( QUIET
                       FILE mylib.hpp SOURCE include ROOT mylib TARGET mylib-standalone
                       OUTPUT "${PROJECT_BINARY_DIR}"
                     )
```

Adds a target that flattens the library into a single header by inlining its own `#include`s.
`FILE` is the root header, `SOURCE` the include directory, `ROOT` the subdirectory inside it.
Give either `OUTPUT` (an absolute directory) or `DESTINATION` (relative to the source tree).

### `copa_setup_pch`

```cmake
copa_setup_pch(TARGET mylib INTERFACES mylib_test HEADERS include/mylib/mylib.hpp)
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
                PATTERN "unit/*.cpp" INTERFACE mylib_test
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

This is test-framework agnostic: it compiles and registers executables, and does not care what
they are written against. `INTERFACE` names the target carrying your framework.

**`TARGET` is what keeps benchmarks and samples out of the test run.** A unit gathered under
another aggregate is not registered with CTest, because the test target never builds it and
`ctest` would then ask for an executable that does not exist:

```cmake
copa_glob_unit(QUIET PATTERN "benchmarks/*.cpp" INTERFACE mylib_bench TARGET mylib-bench ...)
```

### `PROPERTIES`

`copa_glob_unit`, `copa_make_unit`, `copa_make_single_unit` and `copa_setup_pch` all take a
`PROPERTIES` list, passed straight to `set_target_properties` on every target they generate:

```cmake
copa_glob_unit(QUIET PATTERN "unit/*.cpp" INTERFACE mylib_test
               PROPERTIES FOLDER "tests" CXX_SCAN_FOR_MODULES OFF)
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
instrumented. Options are `ENABLE_ASAN`, `ENABLE_UBSAN`, `ENABLE_TSAN`, `ENABLE_MSAN`. GCC and
Clang only; another compiler gets nothing rather than an error. Attach it to the interface your
test units already link against, and call it *before* `add_subdirectory` so the units are created
with the flags in place.

### `copa_setup_coverage`

```cmake
copa_setup_coverage(mylib_test)
```

Instruments a target and adds `<prefix>-coverage`, which runs the suite under instrumentation,
and `<prefix>-coverage-report`, which turns the counters into an HTML report and a JSON summary.
Needs `gcovr`, and `gcov` or `llvm-cov`.

| argument | | |
|---|---|---|
| `PREFIX` | | target name prefix, defaults to the lowercased project name |
| `FILTER` | | what to report on, defaults to `<source>/include/<prefix>/` |
| `DEPENDS` | | target building the tests, defaults to `<prefix>-test` |

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

### `copa_glob_failure_unit`, `copa_make_failure_unit`

Some of what a library promises is that certain code will **not** compile. A `static_assert`
guarding an interface, a concept refusing a type: nothing exercises those, and a refactor that
disarms one is silent.

```cmake
copa_glob_failure_unit(PATTERN "failure/*.cpp" RELATIVE ${root} INTERFACE mylib_test)
```

Each source becomes a target excluded from every aggregate and a ctest that builds it. The test
passes only when the compiler rejects the source **and** says what the source declared it would
say, one line per diagnostic:

```cpp
// build error: Duplicate fields in record definition

#include <mylib/mylib.hpp>
auto bad = mylib::record{ "x"_f = 1, "x"_f = 2 };
```

The second half is the point. A check that only asks whether the build failed goes green on a
typo, a missing header or a renamed include, and proves nothing about the diagnostic it exists
to pin. The expected text lives in the source rather than in the `CMakeLists.txt` so that
editing one does not silently outdate the other.

A `static_assert` carries a message you wrote, so it reads the same everywhere. A diagnostic the
compiler words itself does not, and such a line names the compiler it belongs to:

```cpp
// build error-gcc: which is of non-class type
// build error-clang: is not a structure or union

int main() { int i = 1; i.clear(); }
```

Lines naming another compiler than the one in use are ignored, and a source left with none
reports the test skipped rather than passing on nothing.

A source that names no diagnostic at all is an error rather than a pass: there is nothing to
check.

## The reusable workflows

Called from your own `.github/workflows/`, they carry the steps; you keep the triggers and the
matrices.

```yaml
jobs:
  documentation:
    uses: jfalcou/copacabana/.github/workflows/documentation.yml@<sha> # v4
    with:
      project: mylib
```

Every one of them takes `image`, the **full container reference** to run in, defaulting to
`ghcr.io/jfalcou/compilers:v10`. Point it at your own image and nothing here cares:

```yaml
    with:
      project: mylib
      image: ghcr.io/acme/toolchain:2026.03
```

That image has to carry what the job needs — a compiler and CMake for all of them, Doxygen for
the documentation one, `gcovr` for coverage.

`project` is always the **lowercased** project name: CMake options are derived from it in upper
case, targets and paths in lower case.

| workflow | inputs | what it does |
|---|---|---|
| `documentation.yml` | `project`, `coverage` | builds `<project>-doxygen` and deploys to gh-pages |
| `integration.yml` | `project`, `cxx-compiler`, `cxx-flags` | checks the installed, FetchContent and CPM paths |
| `package-standalone.yml` | `project` | regenerates the single header and pushes the `standalone` branch |
| `sanitizers.yml` | `build-targets`, `test-targets` | ASan and UBSan, on gcc and clang |
| `coverage.yml` | `project`, `build-targets` | runs the coverage target and writes a job summary |

What each expects of your repository:

- **`documentation.yml`** — the `<PROJECT>_BUILD_DOCUMENTATION` option and the `<project>-doxygen`
  target, both of which `copa_setup_doxygen` gives you. With `coverage: true` it ships the
  coverage report alongside. Both have to reach gh-pages in a single deployment, or one wipes the
  other out, which is why coverage rides along here rather than deploying on its own.
- **`integration.yml`** — `test/integration/{install,fetch,cpm}-test/`, each a small project
  consuming yours that way.
- **`package-standalone.yml`** — a `<project>-standalone` target and a `standalone` branch.
- **`sanitizers.yml`** — the presets `gcc-sanitize` and `clang-sanitize`.
- **`coverage.yml`** — the preset `gcc-coverage` and the targets `copa_setup_coverage` generates.

**Pin by full commit SHA with the tag in a trailing comment**, not by tag. SonarCloud's
`githubactions:S7637` fails the quality gate on a `uses:` pinned to a tag from outside a trusted
organisation, and any external repository is outside. Add a `.github/dependabot.yml` for
the `github-actions` ecosystem so the SHA and its comment get maintained; pinning by SHA then
costs no more than pinning by tag.

**One trap when writing the integration tests.** Pin what your dependencies read inside those
`CMakeLists.txt`: `CPMAddPackage` carries `OPTIONS`, `FetchContent` carries nothing, so a bare
`FetchContent_MakeAvailable(dep)` leaves the dependency's own test suite registered in your
CTest, and the integration run turns into a full test run of everything you depend on.

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
when left out. Neither assumes a container, so they work on any runner.

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

plus `cmake/mylib-config.cmake` as shown under `copa_setup_install`. The `example/` directory in
this repository is the same thing, kept building by Copacabana's own CI.

## Starting a project

`tools/new-project.py` writes a repository copacabana can build, test, document and package:

```bash
tools/new-project.py mylib --brief "What it does"
```

It copies `tools/template`, a working project named sample that this repository builds and lints like any
other tree, so it cannot drift from what copacabana expects. `--presets` picks among `native`, `cross`, `cuda` and
`intel` rather than shipping the whole matrix, `--no-standalone` leaves out the single-header target, and `--remote`
decides which continuous integration is written: GitHub Actions on GitHub, a `.gitlab-ci.yml` on GitLab, none
elsewhere. `--config` reads all of it from a json file.

## Ordering, in one place

Three calls depend on when they run, and the failure when they are wrong does not say so:

1. `copa_setup_test_targets()` **before** any `copa_glob_unit` / `copa_make_unit`.
2. `copa_setup_sanitizers()` **before** `add_subdirectory(test)`, so the units are created with
   the flags.
3. `copa_setup_coverage()` **after** `add_subdirectory(test)`, so the test targets it depends on
   exist.
