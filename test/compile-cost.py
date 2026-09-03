#!/usr/bin/env python3
##======================================================================================================================
##  Copacabana - Common CMake Package Tools
##  Copyright : Copacabana Project Contributors
##  SPDX-License-Identifier: BSL-1.0
##======================================================================================================================
"""Check what copa_setup_compile_cost and copa_setup_time_trace left in a build tree of the example.

    compile-cost.py <build-dir> <example-dir>

The CSV has to hold one line per unit the aggregate builds, the summary and the full table have to be
written and say so, and the trace has to have been aggregated. Reading the numbers themselves is the
report's job; this only says whether every piece of the chain ran.
"""
import pathlib
import sys

broken = 0


def expect(what, ok):
    global broken
    print(("  ok    " if ok else "  FAIL  ") + what)
    if not ok:
        broken += 1


def main():
    build = pathlib.Path(sys.argv[1])
    example = pathlib.Path(sys.argv[2])
    cost = build / "compile-cost"

    units = sorted(p.relative_to(example / "test") for p in (example / "test" / "unit").rglob("*.cpp"))

    ## Named after the project, so that what a run attaches says whose it is
    found = sorted(cost.glob("*-compile-cost.csv"))
    csv = found[0] if found else cost / "example-compile-cost.csv"
    expect("%s is written" % csv.name, csv.is_file())
    lines = [line for line in csv.read_text().splitlines() if line.strip()] if csv.is_file() else []

    ## clang appends, and any build after the measurement adds its lines: the time trace target rebuilds the units
    ## and lands here too. What has to hold is that every unit is in, once at least, and that the report read one
    ## row per object, not per line.
    objects = {line.split(",")[1] for line in lines}
    expect("one object per unit at least, %d units, %d objects" % (len(units), len(objects)), len(objects) >= len(units))
    for unit in units:
        expect("%s is measured" % unit, any(str(unit) in obj for obj in objects))

    summary = cost / "summary.md"
    expect("summary.md is written", summary.is_file())
    if summary.is_file():
        text = summary.read_text()
        expect("the summary counts the units", "translation units" in text)
        expect("the summary names the project", "EXAMPLE compile cost" in text or "example compile cost" in text.lower())

    full = cost / "example-compile-cost.md"
    expect("example-compile-cost.md is written", full.is_file())
    if full.is_file():
        rows = [line for line in full.read_text().splitlines() if line.startswith("| `")]
        expect("the full table has a row per object, %d rows" % len(rows), len(rows) == len(objects))

    trace = build / "time-trace" / "capture.bin"
    expect("time-trace/capture.bin is aggregated", trace.is_file() and trace.stat().st_size > 0)

    print("\n%d broken" % broken if broken else "\nall good")
    return 1 if broken else 0


if __name__ == "__main__":
    sys.exit(main())
