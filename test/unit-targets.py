#!/usr/bin/env python3
##======================================================================================================================
##  Copacabana - Common CMake Package Tools
##  Copyright : Copacabana Project Contributors
##  SPDX-License-Identifier: BSL-1.0
##======================================================================================================================
"""Check the targets and tests the unit functions declare, on a probe project nested in another one.

    python3 test/unit-targets.py <copacabana source directory>

The inner project sits under the outer one, as a library fetched by CPM does, so that a default resolved against the
top-level directory rather than the current one shows. Its sources are named to catch an extension stripped inside a
segment, a unit declared without an extension, an emulator command given as a list, and a glob given an absolute
pattern.
"""
import pathlib
import tempfile

from checks import cli, expect, report, run

OUTER = """cmake_minimum_required(VERSION 3.24)
project(outer LANGUAGES CXX)
add_subdirectory(inner)
"""

INNER = """cmake_minimum_required(VERSION 3.24)
project(inner LANGUAGES CXX)
set(COPACABANA_SOURCE_DIR "{root}")
include({root}/copacabana/cmake/copacabana.cmake)
enable_testing()
copa_glob_unit(QUIET PATTERN "unit/*.cpp")
copa_make_unit(QUIET FILES "solo/alone.cpp")
copa_make_single_unit(NAME "single/joined.cpp" FILES "single/joined.cpp")
copa_glob_failure_unit(QUIET)
copa_glob_unit(QUIET PATTERN "${{CMAKE_CURRENT_SOURCE_DIR}}/given/*.cpp")
copa_glob_failure_unit(QUIET PATTERN "${{CMAKE_CURRENT_SOURCE_DIR}}/refused/*.cpp")
get_target_property(single single.joined.exe EXCLUDE_FROM_ALL)
message(STATUS "single:${{single}}")
"""

SOURCES = { "unit/execution/run.cpp": "int main() {}\n"
          , "unit/plain.cpp":          "int main() {}\n"
          , "solo/alone.cpp":          "int main() {}\n"
          , "single/joined.cpp":       "int main() {}\n"
          , "failure/broken.cpp":      "// build error: 'nope' was not declared\nint main() { nope(); }\n"
          , "given/whole.cpp":         "int main() {}\n"
          , "refused/whole.cpp":       "// build error: 'nope' was not declared\nint main() { nope(); }\n"
          }


def main(root: str = ".") -> int:
    root = pathlib.Path(root).resolve()

    with tempfile.TemporaryDirectory() as tmp:
        outer = pathlib.Path(tmp, "outer")
        inner = outer / "inner"
        for name, text in SOURCES.items():
            (inner / name).parent.mkdir(parents=True, exist_ok=True)
            (inner / name).write_text(text, encoding="utf-8")
        (outer / "CMakeLists.txt").write_text(OUTER, encoding="utf-8")
        (inner / "CMakeLists.txt").write_text(INNER.format(root=root.as_posix()), encoding="utf-8")

        build = pathlib.Path(tmp, "build")
        out = run("cmake", "-G", "Ninja", "-S", str(outer), "-B", str(build),
                  "-DCMAKE_CROSSCOMPILING_CMD=qemu-probe;-L;/sysroot")
        if not expect("a nested project configures with every unit function", out.returncode == 0, out.stderr[-400:]):
            return report("The unit targets")

        listed = run("ninja", "-C", str(build), "-t", "targets").stdout
        names = {line.split(":", 1)[0] for line in listed.splitlines()}
        for target in ("unit.execution.run.exe", "unit.execution.exe", "unit.exe", "unit.plain.exe",
                       "solo.alone.exe", "solo.exe", "single.joined.exe", "failure.broken.exe", "inner-test",
                       "given.whole.exe", "refused.whole.exe"):
            expect(f"ninja knows {target}", target in names)
        expect("no target lost its extension", not any(n.endswith(".") for n in names))

        expect("a single unit stays out of all, as a globbed one does", "single:TRUE" in out.stdout)

        tests = pathlib.Path(build, "inner", "CTestTestfile.cmake").read_text(encoding="utf-8")
        expect("the emulator reaches ctest as separate words", '"qemu-probe" "-L" "/sysroot"' in tests)
        expect("a failure unit builds the top-level tree", f'-DBUILD_DIR={build.as_posix()}"' in tests)

    return report("The unit targets")


if __name__ == "__main__":
    cli(main)
