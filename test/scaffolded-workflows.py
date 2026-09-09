#!/usr/bin/env python3
##======================================================================================================================
##  Copacabana - Common CMake Package Tools
##  Copyright : Copacabana Project Contributors
##  SPDX-License-Identifier: BSL-1.0
##======================================================================================================================
"""Check that the workflows of a scaffolded project hold together.

Dropping something the caller did not ask for leaves references behind: a job that names one the conditional blocks
removed, or a call to a workflow whose presets were all left out. GitHub refuses such a file before a single job
starts, and reports it as a run with no jobs and no logs, so it is worth catching here instead.
"""
import pathlib
import re

from checks import cli, expect, report

JOB = re.compile(r"^  ([A-Za-z0-9_-]+):$", re.M)
NEEDS = re.compile(r"needs:\s*\[([^\]]*)\]")
CALLS = re.compile(r"uses:\s*\./\.github/workflows/([A-Za-z0-9._-]+)")
READS = re.compile(r"file:\s*\.github/matrices/([A-Za-z0-9._-]+)")
ROW = re.compile(r"^\s*- \{.*preset:", re.M)


def main(root: str) -> int:
    directory = pathlib.Path(root) / ".github" / "workflows"
    matrices = pathlib.Path(root) / ".github" / "matrices"
    present = {path.name for path in directory.glob("*.yml")}
    readable = {path.name for path in matrices.glob("*.yml")}
    print(f"{len(present)} workflows and {len(readable)} matrices read\n")

    # A matrix file is read by copacabana's matrix.yml, which refuses one with no row to build
    for matrix in sorted(matrices.glob("*.yml")):
        expect(f"{matrix.name} holds a row naming a preset", ROW.search(matrix.read_text(encoding="utf-8")))

    for workflow in sorted(directory.glob("*.yml")):
        text = workflow.read_text(encoding="utf-8")
        declared = set(JOB.findall(text))

        for names in NEEDS.findall(text):
            for name in (n.strip() for n in names.split(",") if n.strip()):
                expect(f"{workflow.name} needs {name}, which a job declares", name in declared)

        for called in CALLS.findall(text):
            expect(f"{workflow.name} calls {called}, which was written", called in present)

        for read in READS.findall(text):
            expect(f"{workflow.name} reads {read}, which was written", read in readable)

    return report("The scaffolded workflows")


if __name__ == "__main__":
    cli(main)
