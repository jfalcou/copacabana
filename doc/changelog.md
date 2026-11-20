Change Log
==========

# Upcoming version

## Changes

### New Features
  * The composite action `jfalcou/copacabana/.github/actions/image` builds the Docker image of a project and publishes it on GHCR (https://github.com/jfalcou/copacabana/pull/167, https://github.com/jfalcou/copacabana/pull/174)
    - The image starts from a base image, runs a setup script of the project before its sources arrive, installs the project, and runs a finish script from the sources.
    - The sources and the setup script are mounted for their step, so no pushed layer holds them, `.git` included.
    - Every build is tagged with its day and its short commit, and a build of the default branch also with `latest`.
  * `copa_setup_heavy_pool` holds the targets of a list in a Ninja pool of depth `<PROJECT>_HEAVY_POOL`, and `compile_cost.py --heavy` writes that list from a compile cost measurement (https://github.com/jfalcou/copacabana/pull/168)
  * A matrix file takes `parallel`, the jobs of the build and of ctest, 2 by default (https://github.com/jfalcou/copacabana/pull/166)
  * A row of a matrix file sets `build-targets`, `test-targets`, and `parallel` for itself, and an empty value clears the value of the file (https://github.com/jfalcou/copacabana/pull/169)
  * The compile cost page shows the CPU time per unit, opens on the latest measurement, names its modules without the configuration folder, and reads a change under 5 % or 16 MiB as noise (https://github.com/jfalcou/copacabana/pull/161)
  * `release.yml` sends a published release to minato, which moves the pins of the libraries (https://github.com/jfalcou/copacabana/pull/159)
  * `GODBOLT_LIBRARIES` accepts `<name>@<version>`, such as `nanobench@4311`, and a name without a version still loads `trunk` (https://github.com/jfalcou/copacabana/pull/182)

### Bug Fixes
  * The unit functions work in a project nested in another one, and on odd names (https://github.com/jfalcou/copacabana/pull/172)
    - They read their sources from the current source directory, or from an absolute `ROOT`.
    - `copa_make_unit` gives a unit the extension `exe` when it names none, and strips an extension at the end of a name only.
    - A failure unit builds the top-level build tree.
    - A unit function called before `copa_setup_test_targets` creates the aggregate target it joins.
  * `copa_glob_unit` and `copa_glob_failure_unit` take an absolute `PATTERN` as it is, where it matched no source (https://github.com/jfalcou/copacabana/pull/178)
  * A failure unit naming the diagnostics of another compiler alone is skipped under CMake 3.24 to 3.28, where it failed on `cmake_language(EXIT)` (https://github.com/jfalcou/copacabana/pull/178)
  * The doxygen target passes its settings through `cmake -E env`, so a value holding a space, two tag files included, reaches doxygen whole (https://github.com/jfalcou/copacabana/pull/173)
  * A tag file downloads beside the copy of the configure before and replaces it on success alone, and doxygen reads no empty tag file (https://github.com/jfalcou/copacabana/pull/173)
  * A space in the path of the build tree or of copacabana no longer makes doxygen skip the tag files, the extra stylesheets and files, or the script of the input filter (https://github.com/jfalcou/copacabana/pull/179)
  * A project nested in another one installs its `DOC` files under its own name, and gets no target and no banner for the pre-commit hooks (https://github.com/jfalcou/copacabana/pull/175)
  * `copa_setup_precommit_hooks` reads the hook at the path `git rev-parse --git-path hooks/pre-commit` gives, the hook of the main checkout in a worktree, or of the directory `core.hooksPath` names (https://github.com/jfalcou/copacabana/pull/175)
  * The Linux matrix runs its container with `--security-opt seccomp=unconfined`, since TSan and MSan aborted on `ubuntu-26.04`, unable to disable ASLR (https://github.com/jfalcou/copacabana/pull/164)
  * The Compiler Explorer button loads only the libraries listed in `GODBOLT_LIBRARIES`, and no longer adds a fixed one to every request (https://github.com/jfalcou/copacabana/pull/182)

### Template
  * The template carries the nightly run, the dispatches, the minato ignore, `compile-cost.yml` with its presets, and `package-standalone.yml`, and `.cmake-format.py` declares every `copa_` signature (https://github.com/jfalcou/copacabana/pull/160)
  * The bug report of the template joins the Compiler Explorer request to the version of the library, the architecture, and the instruction set, and the license follows the layout of the libraries (https://github.com/jfalcou/copacabana/pull/162)
  * The template takes `SAMPLE_EXTERNAL_DEPENDENCIES`, the macro `sample_get_package`, and the job `external-dependencies` of `integration.yml`, which configures with the dependencies taken from the environment (https://github.com/jfalcou/copacabana/pull/165)
  * The scaffolder writes only what the selected presets build and run (https://github.com/jfalcou/copacabana/pull/171)
    - A preset brings the presets it inherits from, and an unknown preset stops the scaffold.
    - A job calling a shared workflow goes when one of its presets was left out.
    - The command line overrides the configuration file, and the remote is an `https` URL, a trailing `.git` dropped.
    - Both pins of copacabana, every `uses:` and the `GIT_TAG`, name one commit, the head of copacabana's `main` by default.
  * The `gcc` and `clang` presets set their compiler through `cacheVariables`, and a `gcc16` row of the Linux matrix builds the `gcc` preset with GCC 16 (https://github.com/jfalcou/copacabana/pull/177)
  * The wasm and rvv128 presets ship the scripts their toolchains run the tests through, beside the toolchain files (https://github.com/jfalcou/copacabana/pull/177)
  * A long project name passes the hooks of the project once its first `pre-commit run` laid out the CMake, and the CPM test includes the CPM of the project (https://github.com/jfalcou/copacabana/pull/177)
  * The template lists only its own library in `GODBOLT_LIBRARIES` (https://github.com/jfalcou/copacabana/pull/182)

### Infrastructure
  * `Package / Consumption` installs the checkout of the pull request through `spack develop`, where it installed the released `copacabana@8` (https://github.com/jfalcou/copacabana/pull/170)
  * `CMake / Minimum Version` runs the checks that drive CMake under CMake 3.24.3, the minimum the modules declare (https://github.com/jfalcou/copacabana/pull/178)
  * Point the README at v9.0.0 (https://github.com/jfalcou/copacabana/pull/158)
  * Bump actions/create-github-app-token from 2 to 3 (https://github.com/jfalcou/copacabana/pull/163)
  * Bump lukka/get-cmake from 4.4.5 to 4.5.0 (https://github.com/jfalcou/copacabana/pull/176)

# Version 9.0.0 - Insensatez

## Changes

v9 brings four changes to the reusable workflows:

- a workflow that runs in a container takes its image from the caller.
- every job has a time limit.
- the compile cost includes the link step.
- a new action reports how long the CI of a pull request took.

A project calls a reusable workflow from one of its jobs:
`uses: jfalcou/copacabana/.github/workflows/<name>.yml@<sha> # <tag>`.

### Breaking changes
  * Six workflows require the `image` input, which v8 set to `ghcr.io/jfalcou/compilers:v10` when
    the caller left it out (https://github.com/jfalcou/copacabana/pull/152):
    * `compile-cost.yml`
    * `coverage.yml`
    * `documentation.yml`
    * `integration.yml`
    * `package-standalone.yml`
    * `sanitizers.yml`
  * The job that calls `compile-cost.yml` needs two permissions (https://github.com/jfalcou/copacabana/pull/144):
    * `actions: read`
    * `contents: write`, with `series` or without it: GitHub checks the permissions of every job
      of a workflow before the first job starts.
  * Each job of a reusable workflow stops after `timeout` minutes, an input of each workflow, 120
    by default. In v8:
    * the jobs of `matrix.yml` stopped after 60 minutes.
    * the other jobs stopped at the GitHub limit of 360 minutes.

**Upgrading**:

1. Pin each `uses:` line on the commit of v9.0.0, by its full SHA, with the tag as a comment:
   `@95054d7b00a79414ec717fdf0b770f7c9338b789 # v9.0.0`.
2. Replace `GIT_TAG v8` with `GIT_TAG v9.0.0` in `cmake/dependencies.cmake`.
3. Add `image` under `with:` in each call to the six workflows above:
   * `ghcr.io/jfalcou/compilers:v10`, the image v8 used by default.
   * `ghcr.io/jfalcou/compilers:v11`, with GCC 16 and Clang 22.
4. Add the two permissions to the job that calls `compile-cost.yml`, as below. A job that sets
   `permissions:` gets only the permissions it lists, whatever the top of the file sets.
5. Set `timeout` in a call when one of its jobs takes more than 120 minutes.

```yaml
compile-cost:
  uses: jfalcou/copacabana/.github/workflows/compile-cost.yml@95054d7b00a79414ec717fdf0b770f7c9338b789 # v9.0.0
  permissions:
    actions: read
    contents: write
  with:
    project: mylib
    image: ghcr.io/jfalcou/compilers:v11
```

### Features
  * The action `jfalcou/copacabana/.github/actions/ci-cycle` posts one comment on a pull request,
    once every unit workflow of its last commit has ended (https://github.com/jfalcou/copacabana/pull/156):
    * the comment gives:
      * the time from the start of the first job to the end of the last one.
      * the end of each workflow, and the longest job of each workflow.
      * a chart of the jobs.
    * the chart, an SVG file, stays on the branch `ci-cycle`, which the action creates at its first
      run.
    * the action takes three inputs:
      * `sha`, the commit whose CI it reports, required.
      * `pr`, the pull request it comments on.
      * `workflow`, the text the name of every unit workflow contains, `Unit Tests` by default.
    * a workflow of the project calls it:

      ```yaml
      on:
        workflow_run:
          workflows: [Unit Tests]
          types: [completed]
      permissions:
        actions: read
        contents: write
        pull-requests: write
      jobs:
        cycle:
          if: github.event.workflow_run.conclusion != 'cancelled'
          runs-on: ubuntu-latest
          steps:
            - uses: jfalcou/copacabana/.github/actions/ci-cycle@95054d7b00a79414ec717fdf0b770f7c9338b789 # v9.0.0
              with:
                sha: ${{ github.event.workflow_run.head_sha }}
                pr: ${{ github.event.workflow_run.pull_requests[0].number }}
      ```

  * `coverage.yml` takes two new inputs (https://github.com/jfalcou/copacabana/pull/153):
    * `runs-on`, the runner label or a JSON list of labels, `ubuntu-latest` by default.
    * `parallel`, the number of compilations run at once, 2 by default.
  * `documentation.yml` and `package-standalone.yml` take `deploy-options`, CMake options
    separated by spaces, `-DMYLIB_EXTRA=ON -DMYLIB_FAST=ON` for one. A pull request runs neither
    build (https://github.com/jfalcou/copacabana/pull/145):
    * `documentation.yml` passes them to the build that publishes the site.
    * `package-standalone.yml` passes them to the build that publishes the header.
  * `copa_setup_compile_cost` takes `EXCLUDE`, a regular expression. A unit target whose name
    matches it is not measured (https://github.com/jfalcou/copacabana/pull/142).
  * The compile cost includes the link step, so its figures are higher than in v8 (https://github.com/jfalcou/copacabana/pull/112).
  * `compile-cost.yml` takes `series`, a boolean, false by default. Set to `true`, it publishes the
    figures of every push to `main` on the branch `ct-measures`, one file per commit (https://github.com/jfalcou/copacabana/pull/112).

### Fixes
  * Coverage builds use `-fprofile-update=atomic`. The threads of a test no longer corrupt the
    coverage counters. In v8, a corrupted counter went negative, and gcovr failed on it (https://github.com/jfalcou/copacabana/pull/155, https://github.com/jfalcou/copacabana/pull/157).
  * `copa_setup_doxygen` copies the configuration of the Compiler Explorer button into the site.
    The button opens an example of the documentation on godbolt.org (https://github.com/jfalcou/copacabana/pull/119).
  * `matrix.yml` passes `runs-on` to its jobs as JSON (https://github.com/jfalcou/copacabana/pull/115):
    * a JSON list of labels in a matrix file, `["self-hosted", "gpu"]` for one, sends the job to
      the runner that carries them. In v8, such a job stayed queued.
    * a single label works as before.
  * `copa_setup_precommit_hooks` prints no banner when the variable `CI` is set (https://github.com/jfalcou/copacabana/pull/118).

### Template
  * A project made from the template runs its CI on `ghcr.io/jfalcou/compilers:v11` (https://github.com/jfalcou/copacabana/pull/149).
  * The template takes copacabana from the `main` branch of copacabana, in its `uses:` lines and
    its `GIT_TAG`. The v8 template took it from `v8`.
  * Comments in the template show where an optional package goes (https://github.com/jfalcou/copacabana/pull/113):
    * `cmake/dependencies.cmake` declares it by `CPMDeclarePackage`. That file runs before the
      project declares its options.
    * `CMakeLists.txt` fetches it by `CPMGetPackage`, after the option that enables it.

### Bossa who?
[Insensatez](https://en.wikipedia.org/wiki/Insensatez), Antônio Carlos Jobim and Vinícius de
Moraes, 1961.

# Version 8 - Ho-Ba-La-Lá

## Changes

v8 makes the shared checks fail when they check nothing. The platform matrix had run no test since
v7, and six more checks were passing on an empty result.

**Upgrading**: a project repinning to v8 gets its matrix jobs running their tests again, for the
first time since v7, so expect red where something broke unnoticed. Three new keys are available:
`test-timeout` and `timeout` in a matrix file, `min-coverage` in the coverage workflow.

### Fixes
  * Stop the shared workflows from passing on nothing (https://github.com/jfalcou/copacabana/pull/116)
  * Let a scaffolded project build with the clang macOS ships (https://github.com/jfalcou/copacabana/pull/111)

### Infrastructure
  * Test the example through the hosted matrix workflow (https://github.com/jfalcou/copacabana/pull/109)
  * Move the template to v7 (https://github.com/jfalcou/copacabana/pull/108)
  * Say what the README says, and point at the current release

### Bossa who?
[Ho-Ba-La-Lá](https://en.wikipedia.org/wiki/Jo%C3%A3o_Gilberto), João Gilberto, 1958.

# Version 7 - Garota de Ipanema

## Changes

v7 hosts the platform matrix, the rows read from a file of the caller's, adds compile cost measurement, and `copa_add_option`.

### New Features
  * Host the platform matrix, the rows staying in a file of the caller's (https://github.com/jfalcou/copacabana/pull/104)
  * Measure what every translation unit costs to compile, `copa_setup_compile_cost` and `copa_setup_time_trace` (https://github.com/jfalcou/copacabana/pull/102)
  * Declare an option and its summary line in one call, `copa_add_option` and `copa_show_options` (https://github.com/jfalcou/copacabana/pull/105)

### Infrastructure
  * Scaffold the platform matrices as files `matrix.yml` reads (https://github.com/jfalcou/copacabana/pull/107)
  * Let a scaffolded project call the hosted workflows it was told about (https://github.com/jfalcou/copacabana/pull/103)
  * Make a scaffolded project start on something that runs (https://github.com/jfalcou/copacabana/pull/100)
  * Name the compile cost files after the project (https://github.com/jfalcou/copacabana/pull/106)
  * Bump actions/upload-artifact from 4 to 7 (https://github.com/jfalcou/copacabana/pull/101)

### Bossa who?
[Garota de Ipanema](https://en.wikipedia.org/wiki/The_Girl_from_Ipanema), Antônio Carlos Jobim and Vinícius de Moraes, 1962.

# Version 6 - Fotografia

## Changes

v6 hosts the Doxygen tagfile machinery, extends the generated header, and adds a social card generator.

### New Features
  * Fix #28 and #56 - Host the tagfile machinery, so a project links to its neighbours' documentation (https://github.com/jfalcou/copacabana/pull/86)
  * Fix #84 and #75 - Generate the header, and let a project add to it (https://github.com/jfalcou/copacabana/pull/85)
  * Fix #76, #77, #78, #79 and #81 - Carry more common fragments (https://github.com/jfalcou/copacabana/pull/82)
  * Add the script that draws a project's social card, `tools/make-card.py` (https://github.com/jfalcou/copacabana/pull/94)
  * Fix #80 - Count the warnings Doxygen writes about the configuration (https://github.com/jfalcou/copacabana/pull/83)

### Infrastructure
  * Say the CMake version the code actually needs (https://github.com/jfalcou/copacabana/pull/95)
  * Say where the project lives once, in `REPOSITORY` of `copa_project_version`, and refuse an argument no `copa_*` function declares (https://github.com/jfalcou/copacabana/pull/89)
  * Stop the scaffolder guessing an account, and warning about what it accepts (https://github.com/jfalcou/copacabana/pull/90)
  * Point the README at the pages that exist, and list what it enumerated (https://github.com/jfalcou/copacabana/pull/91)

### Bug Fixes
  * Fix #92 - Keep `PROPERTIES` out of the exclusion branch (https://github.com/jfalcou/copacabana/pull/93)

### Bossa who?
[Fotografia](https://en.wikipedia.org/wiki/Ant%C3%B4nio_Carlos_Jobim), Antônio Carlos Jobim, 1959.

# Version 5 - Estrada do Sol

## Changes

v5 adds a project scaffolder and a test for what must not compile, and hosts the Doxygen setup and the pre-commit gate.

### New Features
  * Fix #8 - Test that what must not compile does not compile, with `copa_glob_failure_unit` (https://github.com/jfalcou/copacabana/pull/74)
  * Add a scaffolder for a project copacabana can build, `tools/new-project.py` (https://github.com/jfalcou/copacabana/pull/60)
  * Fix #42 - Let a package say where its config goes, and default it to what it is (https://github.com/jfalcou/copacabana/pull/73)
  * Fix #65 - Let the `config` action take extra configure arguments (https://github.com/jfalcou/copacabana/pull/67)
  * Fix #50 - Report what Doxygen said on every pull request (https://github.com/jfalcou/copacabana/pull/55)

### Infrastructure
  * Host the pre-commit gate as a reusable workflow, `precommit.yml` (https://github.com/jfalcou/copacabana/pull/72)
  * Host the Doxygen setup the fleet had copied seven times, as `base.doxyfile` (https://github.com/jfalcou/copacabana/pull/69)
  * Work out the Doxyfile lines a project should not have to write (https://github.com/jfalcou/copacabana/pull/71)
  * Fix #48 - Move the example under `test/`, where it has always belonged (https://github.com/jfalcou/copacabana/pull/57)
  * Fix #49 - Run cmake-lint over the modules (https://github.com/jfalcou/copacabana/pull/58)

### Bug Fixes
  * Fix #62 - Guard `copacabana.cmake` per directory, not globally (https://github.com/jfalcou/copacabana/pull/63)
  * Fix #64 - Cover a build holding two copacabana consumers (https://github.com/jfalcou/copacabana/pull/66)
  * Fix #59 - Replace the deprecated MSVC environment action with the ASan runtime path (https://github.com/jfalcou/copacabana/pull/68)
  * Fix #31 - Write the fragment extraction once, and reach it without jQuery (https://github.com/jfalcou/copacabana/pull/51)
  * Fix #29 - Encode the Godbolt payload as UTF-8 bytes (https://github.com/jfalcou/copacabana/pull/30)
  * Declare the commands in the case the rest of the project calls them (https://github.com/jfalcou/copacabana/pull/61)
  * Fix the defects found auditing the CMake modules (https://github.com/jfalcou/copacabana/pull/52)

### Bossa who?
[Estrada do Sol](https://en.wikipedia.org/wiki/Ant%C3%B4nio_Carlos_Jobim), Antônio Carlos Jobim and Dolores Duran, 1958.

# Version 4 - Desafinado

## Changes

v4 hosts the composite actions and the sanitizers and coverage workflows the libraries were duplicating.

### Infrastructure
  * Host the shared composite actions `config` and `test`, and the `sanitizers.yml` and `coverage.yml` workflows (https://github.com/jfalcou/copacabana/pull/27)
  * Vendor CPM.cmake in the example, at v0.43.1 (https://github.com/jfalcou/copacabana/pull/26)

### Bossa who?
[Desafinado](https://en.wikipedia.org/wiki/Desafinado), Antônio Carlos Jobim and Newton Mendonça, 1959.

# Version 3 - Chega de Saudade

## Changes

v3 lets a unit choose which aggregate target it joins.

### New Features
  * Let a unit choose which aggregate it joins (https://github.com/jfalcou/copacabana/pull/25)

### Bossa who?
[Chega de Saudade](https://en.wikipedia.org/wiki/Chega_de_Saudade), Antônio Carlos Jobim and Vinícius de Moraes, 1958.

# Version 2 - Bim Bom

## Changes

v2 adds a Dependabot configuration and fixes the container checkout.

### Infrastructure
  * Add a Dependabot configuration for the `github-actions` ecosystem (https://github.com/jfalcou/copacabana/pull/22)
  * Bump actions/checkout from 6 to 7 (https://github.com/jfalcou/copacabana/pull/23)
  * Use `GITHUB_WORKSPACE` for `safe.directory`, not the expression (https://github.com/jfalcou/copacabana/pull/24)

### Bossa who?
[Bim Bom](https://en.wikipedia.org/wiki/Jo%C3%A3o_Gilberto), João Gilberto, 1958.

# Version 1 - Água de Beber

## Changes

v1 is the first tag. It provides the CMake modules a header-only library is built, tested, documented and packaged with, and three reusable workflows for its CI.

### CMake modules
  * `copa_setup_install` writes the config, the version file and the export a consumer's `find_package` reads
  * `copa_glob_unit` and `copa_setup_test_targets` register a directory of tests and the aggregate targets that build them
  * `copa_setup_standalone` assembles a single-header distribution, and `copa_setup_cpack` a `.deb` verified after the fact
  * `copa_setup_doxygen` drives a shared Doxygen setup on top of doxygen-awesome, Godbolt rendering included
  * `copa_setup_coverage`, `copa_setup_sanitizers` and `copa_setup_pch`, with the MSVC ASan runtime path handled
  * `copa_setup_precommit_hooks` installs the project's pre-commit gate

### Reusable workflows
  * `documentation.yml`, `integration.yml` and `package-standalone.yml`, called by SHA from a consumer

### Bossa who?
[Água de Beber](https://en.wikipedia.org/wiki/%C3%81gua_de_Beber), Antônio Carlos Jobim and Vinícius de Moraes, 1961.
