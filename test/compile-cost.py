#!/usr/bin/env python3
##======================================================================================================================
##  Copacabana - Common CMake Package Tools
##  Copyright : Copacabana Project Contributors
##  SPDX-License-Identifier: BSL-1.0
##======================================================================================================================
"""Check what copa_setup_compile_cost and copa_setup_time_trace left in a build tree of the example.

    compile-cost.py <build-dir> <example-dir> [<exclude>]

The CSV has to hold one line per unit the aggregate builds, the summary and the full table have to be
written and say so, and the trace has to have been aggregated. Reading the numbers themselves is the
report's job; this only says whether every piece of the chain ran.

With <exclude>, the units whose target it matches must be absent from the CSV, and the trace is not checked.
"""
import pathlib
import re

from checks import cli, expect, report


def target_of(unit):
    """unit/a/b.cpp is built by unit.a.b.exe, as copa_source_to_target names it."""
    return unit.with_suffix(".exe").as_posix().replace("/", ".")


def main(build, example, exclude=""):
    build = pathlib.Path(build)
    example = pathlib.Path(example)
    cost = build / "compile-cost"

    units = sorted(p.relative_to(example / "test") for p in (example / "test" / "unit").rglob("*.cpp"))
    left_out = [u for u in units if exclude and re.search(exclude, target_of(u))]
    measured = [u for u in units if u not in left_out]

    if exclude:
        expect("'%s' leaves out %d of the %d units" % (exclude, len(left_out), len(units)),
               0 < len(left_out) < len(units))

    ## Named after the project, so that what a run attaches says whose it is
    found = sorted(cost.glob("*-compile-cost.csv"))
    csv = found[0] if found else cost / "example-compile-cost.csv"
    expect("%s is written" % csv.name, csv.is_file())
    lines = [line for line in csv.read_text().splitlines() if line.strip()] if csv.is_file() else []

    ## clang appends, and any build after the measurement adds its lines: the time trace target rebuilds the units
    ## and lands here too. What has to hold is that every unit is in, once at least, and that the report read one
    ## row per object, not per line.
    ## The first column is the program the driver spawned: the linker's lines measure an executable, not a unit.
    objects = {line.split(",")[1] for line in lines if "clang" in line.split(",")[0]}
    linked = {line.split(",")[1] for line in lines if "clang" not in line.split(",")[0]}
    expect("one object per unit at least, %d units, %d objects" % (len(measured), len(objects)),
           len(objects) >= len(measured))
    for unit in measured:
        expect("%s is measured" % unit, any(str(unit) in obj for obj in objects))
    for unit in left_out:
        expect("%s is left out" % unit,
               not any(str(unit) in obj for obj in objects) and not any(target_of(unit) in exe for exe in linked))

    expect("the executables are measured too, %d of them" % len(linked), len(linked) > 0)

    summary = cost / "summary.md"
    expect("summary.md is written", summary.is_file())
    if summary.is_file():
        text = summary.read_text()
        expect("the summary counts the units", "translation units" in text)
        expect("the summary names the project",
               "EXAMPLE compile cost" in text or "example compile cost" in text.lower())
        expect("the summary counts the links", "link" in text and "### Linking" in text)

    full = cost / "example-compile-cost.md"
    expect("example-compile-cost.md is written", full.is_file())
    if full.is_file():
        rows = [line for line in full.read_text().splitlines() if line.startswith("| `")]
        expect("the full table has a row per object, %d rows" % len(rows), len(rows) == len(objects))

    if not exclude:
        trace = build / "time-trace" / "capture.bin"
        expect("time-trace/capture.bin is aggregated", trace.is_file() and trace.stat().st_size > 0)

    return report("The compile cost report")


if __name__ == "__main__":
    cli(main)
