#!/usr/bin/env python3
"""What a package manager ships, checked by consuming it the way its users are told to.

The install tree is covered by install-layout.py, which drives copa_setup_install here. What spack,
vcpkg and conan publish is a different tree, laid out by the recipe rather than by CMake, and a
consumer reaches it by pointing COPACABANA_SOURCE_DIR at a prefix and including copacabana.cmake
from it. Nothing else here exercises that path, so a change of layout would reach users through a
release before anyone noticed.

The script knows nothing of package managers: it takes the root the manager installed and consumes
it. What differs between them is that path, and only that. It calls what it can rather than only
looking: a recipe that copies the .cmake files and forgets what they read at call time passes any
check that stops at `if(COMMAND)`.

  python3 test/package-consumption.py <root holding copacabana/>
"""
import pathlib
import re
import subprocess
import sys
import tempfile

from checks import expect, report


def run(*args):
    return subprocess.run(args, capture_output=True, text=True)

# The entry points every project in the family calls. copacabana.cmake includes its siblings through
# COPACABANA_SOURCE_DIR, so a missing one means the packaged tree lost a file rather than a feature.
EXPECTED = [
    "copa_add_option",
    "copa_project_version",
    "copa_setup_install",
    "copa_setup_doxygen",
    "copa_setup_coverage",
    "copa_setup_sanitizers",
    "copa_setup_compile_cost",
    "copa_setup_precommit_hooks",
    "copa_setup_standalone",
    "copa_setup_pch",
]

CONSUMER = """cmake_minimum_required(VERSION 3.22)
project(demo LANGUAGES CXX VERSION 1.0)
include("${COPACABANA_SOURCE_DIR}/copacabana/cmake/copacabana.cmake")

foreach(name %s)
  if(COMMAND ${name})
    message(STATUS "have ${name}")
  endif()
endforeach()

## Two of them are called rather than looked at: copa_add_option reads the option machinery and
## copa_setup_install reads asset/package-config.cmake.in, which a tree missing its assets would
## only fail on here.
copa_add_option(DEMO_SWITCH "An option, to see the machinery run" OFF)

add_library(demo INTERFACE)
target_include_directories(demo INTERFACE $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/src>)
copa_setup_install(LIBRARY demo FEATURES cxx_std_20 INCLUDE ${PROJECT_SOURCE_DIR}/src)
"""


def assets(cmake):
    """The asset files the packaged scripts name, which they only open when a function is called."""
    named = set()
    for script in sorted(cmake.glob("*.cmake")):
        named.update(re.findall(r"asset/([A-Za-z0-9_.-]+)", script.read_text(encoding="utf-8")))
    return sorted(named)


def main(root):
    root = pathlib.Path(root).resolve()

    cmake = root / "copacabana" / "cmake"
    if not expect("the package carries copacabana/cmake/copacabana.cmake",
                  (cmake / "copacabana.cmake").is_file(), root):
        return report("A published package is consumable")

    missing = [name for name in assets(cmake) if not (cmake / "asset" / name).is_file()]
    expect("every asset the scripts name is in the package", not missing, ", ".join(missing))

    with tempfile.TemporaryDirectory() as tmp:
        tmp = pathlib.Path(tmp)
        consumer, build, prefix = tmp / "consumer", tmp / "build", tmp / "prefix"
        (consumer / "src").mkdir(parents=True)
        (consumer / "CMakeLists.txt").write_text(CONSUMER % " ".join(EXPECTED), encoding="utf-8")
        (consumer / "src" / "demo.hpp").write_text("#pragma once\n", encoding="utf-8")

        out = run("cmake", "-S", str(consumer), "-B", str(build), f"-DCOPACABANA_SOURCE_DIR={root}")
        if not expect("a consumer configures and calls into the package", out.returncode == 0,
                      out.stderr.strip().splitlines()[-1] if out.returncode else ""):
            return report("A published package is consumable")

        for name in EXPECTED:
            expect(f"{name} is defined", f"have {name}" in out.stdout)

        out = run("cmake", "--install", str(build), "--prefix", str(prefix))
        if expect("what copa_setup_install wrote installs", out.returncode == 0,
                  out.stderr.strip().splitlines()[-1] if out.returncode else ""):
            # package-config.cmake.in is an asset, so its absence shows up as a missing config here.
            expect("the package config lands in share/demo",
                   (prefix / "share" / "demo" / "demo-config.cmake").is_file())

    return report("A published package is consumable")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(2)
    sys.exit(main(sys.argv[1]))
