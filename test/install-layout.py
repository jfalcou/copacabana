#!/usr/bin/env python3
"""Where copa_setup_install puts a package, checked by installing one and looking.

find_package searches both trees, so a wrong destination is not a failure a consumer would ever
report - it is only visible from the outside, which is what this does. It drives the example
through each of the three ways of choosing, and ends by having a consumer find one.

  python3 test/install-layout.py <copacabana source directory>
"""
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile

CONSUMER = """cmake_minimum_required(VERSION 3.22)
project(consumer LANGUAGES CXX)
find_package(example 1.2 REQUIRED)
add_executable(use main.cpp)
target_link_libraries(use PRIVATE example::example)
"""

failures = []


def run(*args, **kwargs):
    return subprocess.run(args, capture_output=True, text=True, **kwargs)


def install(source, extra, prefix, build):
    """Configure the example with `extra` appended to its copa_setup_install call, then install it."""
    call = pathlib.Path(source, "test/example/CMakeLists.txt")
    original = call.read_text(encoding="utf-8")
    anchor = "  INCLUDE ${PROJECT_SOURCE_DIR}/src/libexample)"
    if extra:
        call.write_text(original.replace(anchor, f"  INCLUDE ${{PROJECT_SOURCE_DIR}}/src/libexample\n  {extra})"),
                        encoding="utf-8")
    try:
        out = run("cmake", "-S", f"{source}/test/example", "-B", str(build), "-G", "Ninja",
                  f"-DCPM_COPACABANA_SOURCE={source}", "-DEXAMPLE_BUILD_TEST=OFF",
                  f"-DCMAKE_INSTALL_PREFIX={prefix}")
        if out.returncode:
            return out.stderr
        out = run("cmake", "--install", str(build))
        return out.stderr if out.returncode else ""
    finally:
        call.write_text(original, encoding="utf-8")


def where(prefix):
    found = list(pathlib.Path(prefix).rglob("example-config.cmake"))
    return str(found[0].relative_to(prefix)) if found else None


def main(source):
    source = pathlib.Path(source).resolve()

    cases = [
        ("nothing said", "", "share/example/example-config.cmake"),
        ("ARCH_INDEPENDENT NO", "ARCH_INDEPENDENT NO", "lib/cmake/example/example-config.cmake"),
        ("DESTINATION", "DESTINATION lib/cmake/elsewhere", "lib/cmake/elsewhere/example-config.cmake"),
    ]

    with tempfile.TemporaryDirectory() as tmp:
        tmp = pathlib.Path(tmp)
        for name, extra, expected in cases:
            prefix, build = tmp / f"{name}-prefix", tmp / f"{name}-build"
            error = install(source, extra, prefix, build)
            if error:
                failures.append(f"{name}: install failed - {error.strip().splitlines()[-1]}")
                continue
            seen = where(prefix)
            if seen != expected:
                failures.append(f"{name}: config is at {seen}, expected {expected}")

            # The version file only claims to work on any architecture when the package says it does.
            version = next(pathlib.Path(prefix).rglob("example-config-version.cmake"), None)
            if version:
                claims = "CMAKE_SIZEOF_VOID_P" not in version.read_text(encoding="utf-8")
                wants = extra != "ARCH_INDEPENDENT NO"
                if claims != wants:
                    failures.append(f"{name}: version file {'ignores' if claims else 'checks'} the pointer width")

        # What all of it is for: a consumer asking for the package by name finds it.
        prefix = tmp / "nothing said-prefix"
        consumer, build = tmp / "consumer", tmp / "consumer-build"
        consumer.mkdir()
        (consumer / "CMakeLists.txt").write_text(CONSUMER, encoding="utf-8")
        (consumer / "main.cpp").write_text("#include <libexample/example.hpp>\nint main(){ return 0; }\n",
                                           encoding="utf-8")
        out = run("cmake", "-S", str(consumer), "-B", str(build), "-G", "Ninja", f"-DCMAKE_PREFIX_PATH={prefix}")
        if out.returncode:
            failures.append(f"find_package: {out.stderr.strip().splitlines()[-1]}")
        else:
            out = run("cmake", "--build", str(build))
            if out.returncode:
                failures.append("consumer does not build against the installed package")

    for f in failures:
        print(f"  FAIL  {f}")
    print(f"{len(failures)} failure(s)")
    return 1 if failures else 0


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(2)
    sys.exit(main(sys.argv[1]))
