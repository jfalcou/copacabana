#!/usr/bin/env python3
"""Whether copa_glob_unit leaves the phony targets a developer builds by hand.

A unit is reachable through every level of its name, so that one file, one directory or the whole suite is a target.
Ninja is the one that lists them, the names never appearing in any CMakeLists.

  python3 test/target-hierarchy.py <copacabana source directory>
"""
import pathlib
import tempfile

from checks import cli, expect, report, run

EXPECTED = ["unit.exe", "unit.types.exe", "unit.types.structure.exe",
            "unit.values.exe", "unit.values.value.exe", "unit.values.version.exe"]


def main(root: str = ".") -> int:
    root = pathlib.Path(root).resolve()

    with tempfile.TemporaryDirectory() as tmp:
        out = run("cmake", "-G", "Ninja", "-S", f"{root}/test/example", "-B", tmp,
                  f"-DCPM_COPACABANA_SOURCE={root}", "-DOPT_QUIET=ON")
        if not expect("the example configures", out.returncode == 0, out.stderr[-300:]):
            return report("What ninja knows how to build")

        listed = run("ninja", "-C", tmp, "-t", "targets").stdout
        names = {line.split(":", 1)[0] for line in listed.splitlines()}
        for target in EXPECTED:
            expect(f"ninja knows {target}", target in names)

    return report("What ninja knows how to build")


if __name__ == "__main__":
    cli(main)
