#!/usr/bin/env python3
##======================================================================================================================
##  Copacabana - Common CMake Package Tools
##  Copyright : Copacabana Project Contributors
##  SPDX-License-Identifier: BSL-1.0
##======================================================================================================================
"""Check the heavy pool, from the list compile_cost.py --heavy writes to the edges Ninja holds back.

    python3 test/heavy-pool.py <copacabana source directory>

The list comes from a measurement written here, and the pool from the example configured twice: with a depth of 2,
the two units of its heavy-units.txt that it declares compile in the pool and no other does, and with the default
depth of 0, Ninja declares no pool at all.
"""
import pathlib
import sys
import tempfile

from checks import cli, expect, report, run

GIB = 1024 * 1024

## What clang writes: program, object, total and user microseconds, peak KiB. The link line is not a compiler line.
MEASURE = [
    ("clang++", "test/CMakeFiles/unit.big.exe.dir/unit/big.cpp.o", 9, 9, 2 * GIB),
    ("clang++", "test/CMakeFiles/unit.small.exe.dir/unit/small.cpp.o", 9, 9, GIB // 2),
    ("clang++", "test/CMakeFiles/unit.pair.exe.dir/unit/pair_a.cpp.o", 9, 9, GIB // 2),
    ("clang++", "test/CMakeFiles/unit.pair.exe.dir/unit/pair_b.cpp.o", 9, 9, 3 * GIB // 2),
    ("/usr/bin/ld", "unit.huge.exe", 9, 9, 4 * GIB),
]


def pooled(build):
    """The objects whose compile edge carries `pool = heavy`, by the build line above it."""
    edges, last = [], ""
    for line in pathlib.Path(build, "build.ninja").read_text(encoding="utf-8").splitlines():
        if line.startswith("build "):
            last = line
        elif line.strip() == "pool = heavy":
            edges.append(last.split(":", 1)[0])
    return edges


def main(root: str = ".") -> int:
    root = pathlib.Path(root).resolve()
    script = root / "copacabana/cmake/asset/compile_cost.py"

    with tempfile.TemporaryDirectory() as tmp:
        csv = pathlib.Path(tmp, "measure.csv")
        csv.write_text("".join('"%s","%s",%d,%d,%d\n' % row for row in MEASURE), encoding="utf-8")
        listed = pathlib.Path(tmp, "heavy-units.txt")
        out = run(sys.executable, str(script), str(csv), "--heavy", str(listed),
                  "--summary", str(pathlib.Path(tmp, "summary.md")))
        expect("compile_cost.py writes the list", out.returncode == 0 and listed.exists(), out.stderr[-300:])
        if listed.exists():
            lines = listed.read_text(encoding="utf-8").splitlines()
            names = [line for line in lines if not line.startswith("#")]
            expect("the list holds the targets from 1.5 GiB, a target taking the peak of its heaviest unit",
                   names == ["unit.big.exe", "unit.pair.exe"], names)

        for depth in (2, 0):
            build = pathlib.Path(tmp, f"depth-{depth}")
            out = run("cmake", "-G", "Ninja", "-S", f"{root}/test/example", "-B", str(build),
                      f"-DCPM_COPACABANA_SOURCE={root}", f"-DEXAMPLE_HEAVY_POOL={depth}")
            if not expect(f"the example configures with a depth of {depth}", out.returncode == 0, out.stderr[-300:]):
                continue
            ## CMake writes the pools among the rules, not in build.ninja.
            ninja = pathlib.Path(build, "CMakeFiles/rules.ninja").read_text(encoding="utf-8")
            edges = pooled(build)
            if depth:
                expect("Ninja declares the pool with its depth", "pool heavy\n  depth = 2" in ninja)
                expect("the two declared units of the list compile in the pool, and no other",
                       sorted(e.rsplit("/", 1)[-1] for e in edges) == ["clamp.cpp.o", "value.cpp.o"], edges)
            else:
                expect("a depth of 0 declares no pool", "pool heavy" not in ninja and not edges, edges)

    return report("The heavy pool")


if __name__ == "__main__":
    cli(main)
