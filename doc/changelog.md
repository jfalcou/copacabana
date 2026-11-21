Change Log
==========

# Upcoming version

## Changes

### Breaking changes
  * Load only `GODBOLT_LIBRARIES` in Compiler Explorer requests, with no fixed library: list there every library the examples include ([#182](https://github.com/jfalcou/copacabana/pull/182))

### Features
  * Add the composite action `jfalcou/copacabana/.github/actions/image`, for building and publishing Docker images of projects on GHCR ([#167](https://github.com/jfalcou/copacabana/pull/167), [#174](https://github.com/jfalcou/copacabana/pull/174), [#184](https://github.com/jfalcou/copacabana/pull/184))
  * Add `copa_setup_heavy_pool`, for a Ninja pool of listed targets, and `compile_cost.py --heavy`, for writing that list ([#168](https://github.com/jfalcou/copacabana/pull/168))
  * Add `parallel` to matrix files, the number of build and test jobs (default 2), and per-row `build-targets`, `test-targets`, and `parallel` ([#166](https://github.com/jfalcou/copacabana/pull/166), [#169](https://github.com/jfalcou/copacabana/pull/169))
  * Accept `<name>@<version>` in `GODBOLT_LIBRARIES` ([#182](https://github.com/jfalcou/copacabana/pull/182))
  * Show CPU time per unit on the compile cost page ([#161](https://github.com/jfalcou/copacabana/pull/161))

### Fixes
  * Fix unit functions in nested projects, on unusual names, and with absolute `PATTERN` values, and failure units of other compilers under CMake 3.24 to 3.28 ([#172](https://github.com/jfalcou/copacabana/pull/172), [#178](https://github.com/jfalcou/copacabana/pull/178))
  * Fix the doxygen target with spaces in settings or paths, and replace tag files only after successful downloads ([#173](https://github.com/jfalcou/copacabana/pull/173), [#179](https://github.com/jfalcou/copacabana/pull/179))
  * Install `DOC` files of nested projects under their own names, without pre-commit hooks, and find worktree or `core.hooksPath` hooks in `copa_setup_precommit_hooks` ([#175](https://github.com/jfalcou/copacabana/pull/175))
  * Run Linux matrix containers with `--security-opt seccomp=unconfined`, for TSan and MSan on `ubuntu-26.04` ([#164](https://github.com/jfalcou/copacabana/pull/164))
  * Keep only the main header license in standalone headers, and copy literals holding `//` or `/*` whole ([#183](https://github.com/jfalcou/copacabana/pull/183))

### Template
  * Add nightly runs, `compile-cost.yml`, `package-standalone.yml`, the `external-dependencies` job, a `gcc16` row, and dispatch triggers on `ci.yml`, `documentation.yml`, and `package-standalone.yml` to scaffolds ([#160](https://github.com/jfalcou/copacabana/pull/160), [#165](https://github.com/jfalcou/copacabana/pull/165), [#177](https://github.com/jfalcou/copacabana/pull/177))
  * Scaffold only what selected presets use, and pin copacabana on the head of its `main` ([#171](https://github.com/jfalcou/copacabana/pull/171), [#185](https://github.com/jfalcou/copacabana/pull/185))
  * Refuse unknown presets, non-`https` remotes, and names over 50 characters, and name projects scaffolded into `.` after the current directory ([#171](https://github.com/jfalcou/copacabana/pull/171), [#185](https://github.com/jfalcou/copacabana/pull/185))
  * Set the processor of cross toolchains, write wasm and rvv128 test scripts with their toolchains, and let long project names pass the hooks ([#177](https://github.com/jfalcou/copacabana/pull/177), [#185](https://github.com/jfalcou/copacabana/pull/185))

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
    the caller left it out ([#152](https://github.com/jfalcou/copacabana/pull/152)):
    * `compile-cost.yml`
    * `coverage.yml`
    * `documentation.yml`
    * `integration.yml`
    * `package-standalone.yml`
    * `sanitizers.yml`
  * The job that calls `compile-cost.yml` needs two permissions ([#144](https://github.com/jfalcou/copacabana/pull/144)):
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
    once every unit workflow of its last commit has ended ([#156](https://github.com/jfalcou/copacabana/pull/156)):
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

  * `coverage.yml` takes two new inputs ([#153](https://github.com/jfalcou/copacabana/pull/153)):
    * `runs-on`, the runner label or a JSON list of labels, `ubuntu-latest` by default.
    * `parallel`, the number of compilations run at once, 2 by default.
  * `documentation.yml` and `package-standalone.yml` take `deploy-options`, CMake options
    separated by spaces, `-DMYLIB_EXTRA=ON -DMYLIB_FAST=ON` for one. A pull request runs neither
    build ([#145](https://github.com/jfalcou/copacabana/pull/145)):
    * `documentation.yml` passes them to the build that publishes the site.
    * `package-standalone.yml` passes them to the build that publishes the header.
  * `copa_setup_compile_cost` takes `EXCLUDE`, a regular expression. A unit target whose name
    matches it is not measured ([#142](https://github.com/jfalcou/copacabana/pull/142)).
  * The compile cost includes the link step, so its figures are higher than in v8 ([#112](https://github.com/jfalcou/copacabana/pull/112)).
  * `compile-cost.yml` takes `series`, a boolean, false by default. Set to `true`, it publishes the
    figures of every push to `main` on the branch `ct-measures`, one file per commit ([#112](https://github.com/jfalcou/copacabana/pull/112)).

### Fixes
  * Coverage builds use `-fprofile-update=atomic`. The threads of a test no longer corrupt the
    coverage counters. In v8, a corrupted counter went negative, and gcovr failed on it ([#155](https://github.com/jfalcou/copacabana/pull/155), [#157](https://github.com/jfalcou/copacabana/pull/157)).
  * `copa_setup_doxygen` copies the configuration of the Compiler Explorer button into the site.
    The button opens an example of the documentation on godbolt.org ([#119](https://github.com/jfalcou/copacabana/pull/119)).
  * `matrix.yml` passes `runs-on` to its jobs as JSON ([#115](https://github.com/jfalcou/copacabana/pull/115)):
    * a JSON list of labels in a matrix file, `["self-hosted", "gpu"]` for one, sends the job to
      the runner that carries them. In v8, such a job stayed queued.
    * a single label works as before.
  * `copa_setup_precommit_hooks` prints no banner when the variable `CI` is set ([#118](https://github.com/jfalcou/copacabana/pull/118)).

### Template
  * A project made from the template runs its CI on `ghcr.io/jfalcou/compilers:v11` ([#149](https://github.com/jfalcou/copacabana/pull/149)).
  * The template takes copacabana from the `main` branch of copacabana, in its `uses:` lines and
    its `GIT_TAG`. The v8 template took it from `v8`.
  * Comments in the template show where an optional package goes ([#113](https://github.com/jfalcou/copacabana/pull/113)):
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
  * Stop the shared workflows from passing on nothing ([#116](https://github.com/jfalcou/copacabana/pull/116))
  * Let a scaffolded project build with the clang macOS ships ([#111](https://github.com/jfalcou/copacabana/pull/111))

### Infrastructure
  * Test the example through the hosted matrix workflow ([#109](https://github.com/jfalcou/copacabana/pull/109))
  * Move the template to v7 ([#108](https://github.com/jfalcou/copacabana/pull/108))
  * Say what the README says, and point at the current release

### Bossa who?
[Ho-Ba-La-Lá](https://en.wikipedia.org/wiki/Jo%C3%A3o_Gilberto), João Gilberto, 1958.

# Version 7 - Garota de Ipanema

## Changes

v7 hosts the platform matrix, the rows read from a file of the caller's, adds compile cost measurement, and `copa_add_option`.

### New Features
  * Host the platform matrix, the rows staying in a file of the caller's ([#104](https://github.com/jfalcou/copacabana/pull/104))
  * Measure what every translation unit costs to compile, `copa_setup_compile_cost` and `copa_setup_time_trace` ([#102](https://github.com/jfalcou/copacabana/pull/102))
  * Declare an option and its summary line in one call, `copa_add_option` and `copa_show_options` ([#105](https://github.com/jfalcou/copacabana/pull/105))

### Infrastructure
  * Scaffold the platform matrices as files `matrix.yml` reads ([#107](https://github.com/jfalcou/copacabana/pull/107))
  * Let a scaffolded project call the hosted workflows it was told about ([#103](https://github.com/jfalcou/copacabana/pull/103))
  * Make a scaffolded project start on something that runs ([#100](https://github.com/jfalcou/copacabana/pull/100))
  * Name the compile cost files after the project ([#106](https://github.com/jfalcou/copacabana/pull/106))
  * Bump actions/upload-artifact from 4 to 7 ([#101](https://github.com/jfalcou/copacabana/pull/101))

### Bossa who?
[Garota de Ipanema](https://en.wikipedia.org/wiki/The_Girl_from_Ipanema), Antônio Carlos Jobim and Vinícius de Moraes, 1962.

# Version 6 - Fotografia

## Changes

v6 hosts the Doxygen tagfile machinery, extends the generated header, and adds a social card generator.

### New Features
  * Fix #28 and #56 - Host the tagfile machinery, so a project links to its neighbours' documentation ([#86](https://github.com/jfalcou/copacabana/pull/86))
  * Fix #84 and #75 - Generate the header, and let a project add to it ([#85](https://github.com/jfalcou/copacabana/pull/85))
  * Fix #76, #77, #78, #79 and #81 - Carry more common fragments ([#82](https://github.com/jfalcou/copacabana/pull/82))
  * Add the script that draws a project's social card, `tools/make-card.py` ([#94](https://github.com/jfalcou/copacabana/pull/94))
  * Fix #80 - Count the warnings Doxygen writes about the configuration ([#83](https://github.com/jfalcou/copacabana/pull/83))

### Infrastructure
  * Say the CMake version the code actually needs ([#95](https://github.com/jfalcou/copacabana/pull/95))
  * Say where the project lives once, in `REPOSITORY` of `copa_project_version`, and refuse an argument no `copa_*` function declares ([#89](https://github.com/jfalcou/copacabana/pull/89))
  * Stop the scaffolder guessing an account, and warning about what it accepts ([#90](https://github.com/jfalcou/copacabana/pull/90))
  * Point the README at the pages that exist, and list what it enumerated ([#91](https://github.com/jfalcou/copacabana/pull/91))

### Bug Fixes
  * Fix #92 - Keep `PROPERTIES` out of the exclusion branch ([#93](https://github.com/jfalcou/copacabana/pull/93))

### Bossa who?
[Fotografia](https://en.wikipedia.org/wiki/Ant%C3%B4nio_Carlos_Jobim), Antônio Carlos Jobim, 1959.

# Version 5 - Estrada do Sol

## Changes

v5 adds a project scaffolder and a test for what must not compile, and hosts the Doxygen setup and the pre-commit gate.

### New Features
  * Fix #8 - Test that what must not compile does not compile, with `copa_glob_failure_unit` ([#74](https://github.com/jfalcou/copacabana/pull/74))
  * Add a scaffolder for a project copacabana can build, `tools/new-project.py` ([#60](https://github.com/jfalcou/copacabana/pull/60))
  * Fix #42 - Let a package say where its config goes, and default it to what it is ([#73](https://github.com/jfalcou/copacabana/pull/73))
  * Fix #65 - Let the `config` action take extra configure arguments ([#67](https://github.com/jfalcou/copacabana/pull/67))
  * Fix #50 - Report what Doxygen said on every pull request ([#55](https://github.com/jfalcou/copacabana/pull/55))

### Infrastructure
  * Host the pre-commit gate as a reusable workflow, `precommit.yml` ([#72](https://github.com/jfalcou/copacabana/pull/72))
  * Host the Doxygen setup the fleet had copied seven times, as `base.doxyfile` ([#69](https://github.com/jfalcou/copacabana/pull/69))
  * Work out the Doxyfile lines a project should not have to write ([#71](https://github.com/jfalcou/copacabana/pull/71))
  * Fix #48 - Move the example under `test/`, where it has always belonged ([#57](https://github.com/jfalcou/copacabana/pull/57))
  * Fix #49 - Run cmake-lint over the modules ([#58](https://github.com/jfalcou/copacabana/pull/58))

### Bug Fixes
  * Fix #62 - Guard `copacabana.cmake` per directory, not globally ([#63](https://github.com/jfalcou/copacabana/pull/63))
  * Fix #64 - Cover a build holding two copacabana consumers ([#66](https://github.com/jfalcou/copacabana/pull/66))
  * Fix #59 - Replace the deprecated MSVC environment action with the ASan runtime path ([#68](https://github.com/jfalcou/copacabana/pull/68))
  * Fix #31 - Write the fragment extraction once, and reach it without jQuery ([#51](https://github.com/jfalcou/copacabana/pull/51))
  * Fix #29 - Encode the Godbolt payload as UTF-8 bytes ([#30](https://github.com/jfalcou/copacabana/pull/30))
  * Declare the commands in the case the rest of the project calls them ([#61](https://github.com/jfalcou/copacabana/pull/61))
  * Fix the defects found auditing the CMake modules ([#52](https://github.com/jfalcou/copacabana/pull/52))

### Bossa who?
[Estrada do Sol](https://en.wikipedia.org/wiki/Ant%C3%B4nio_Carlos_Jobim), Antônio Carlos Jobim and Dolores Duran, 1958.

# Version 4 - Desafinado

## Changes

v4 hosts the composite actions and the sanitizers and coverage workflows the libraries were duplicating.

### Infrastructure
  * Host the shared composite actions `config` and `test`, and the `sanitizers.yml` and `coverage.yml` workflows ([#27](https://github.com/jfalcou/copacabana/pull/27))
  * Vendor CPM.cmake in the example, at v0.43.1 ([#26](https://github.com/jfalcou/copacabana/pull/26))

### Bossa who?
[Desafinado](https://en.wikipedia.org/wiki/Desafinado), Antônio Carlos Jobim and Newton Mendonça, 1959.

# Version 3 - Chega de Saudade

## Changes

v3 lets a unit choose which aggregate target it joins.

### New Features
  * Let a unit choose which aggregate it joins ([#25](https://github.com/jfalcou/copacabana/pull/25))

### Bossa who?
[Chega de Saudade](https://en.wikipedia.org/wiki/Chega_de_Saudade), Antônio Carlos Jobim and Vinícius de Moraes, 1958.

# Version 2 - Bim Bom

## Changes

v2 adds a Dependabot configuration and fixes the container checkout.

### Infrastructure
  * Add a Dependabot configuration for the `github-actions` ecosystem ([#22](https://github.com/jfalcou/copacabana/pull/22))
  * Bump actions/checkout from 6 to 7 ([#23](https://github.com/jfalcou/copacabana/pull/23))
  * Use `GITHUB_WORKSPACE` for `safe.directory`, not the expression ([#24](https://github.com/jfalcou/copacabana/pull/24))

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
