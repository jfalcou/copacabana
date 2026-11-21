#!/usr/bin/env python3
##======================================================================================================================
##  Copacabana - Common CMake Package Tools
##  Copyright : Copacabana Project Contributors
##  SPDX-License-Identifier: BSL-1.0
##======================================================================================================================
"""Check the references between the workflows, matrices, and presets of a scaffolded project.

- every `needs:` names a job of its workflow, and every `uses:` of copacabana a workflow of this checkout
- every `preset:`, and every preset a called shared workflow builds, is in CMakePresets.json
- every matrix file read exists, and holds a row

A broken `needs:` or `uses:` fails the run before any job starts, and an undeclared preset fails the configure.
"""
import json
import pathlib
import re

from checks import cli, expect, report

JOB = re.compile(r"^  ([A-Za-z0-9_-]+):$", re.M)
NEEDS = re.compile(r"needs:\s*\[([^\]]*)\]")
CALLS = re.compile(r"uses:\s*jfalcou/copacabana/\.github/workflows/([A-Za-z0-9._-]+)@")
READS = re.compile(r"file:\s*\.github/matrices/([A-Za-z0-9._-]+)")
ROW = re.compile(r"^\s*- \{.*preset:", re.M)
PRESET = re.compile(r"""preset:\s*["']?([A-Za-z0-9._-]+)""")

SHARED = pathlib.Path(__file__).resolve().parent.parent / ".github" / "workflows"

## Presets built by each shared workflow, to be declared in the CMakePresets.json of the caller.
BUILDS_WITH = { "sanitizers.yml": {"gcc-sanitize", "clang-sanitize"}
              , "coverage.yml":   {"gcc-coverage"}
              }


def main(root: str) -> int:
    directory = pathlib.Path(root) / ".github" / "workflows"
    matrices = pathlib.Path(root) / ".github" / "matrices"
    readable = {path.name for path in matrices.glob("*.yml")}
    declared_presets = {p["name"] for p in json.loads((pathlib.Path(root) / "CMakePresets.json").read_text(
                        encoding="utf-8"))["configurePresets"]}
    present = {path.name for path in directory.glob("*.yml")}
    print(f"{len(present)} workflows and {len(readable)} matrices read\n")

    # matrix.yml of copacabana fails on a matrix file without a row
    for matrix in sorted(matrices.glob("*.yml")):
        expect(f"{matrix.name} holds a row naming a preset", ROW.search(matrix.read_text(encoding="utf-8")))

    for workflow in sorted(directory.glob("*.yml")):
        text = workflow.read_text(encoding="utf-8")
        ## The keys of the triggers sit at the indent of the jobs, so the jobs are read after `jobs:` alone.
        declared = set(JOB.findall(text.split("\njobs:\n", 1)[-1]))

        for names in NEEDS.findall(text):
            for name in (n.strip() for n in names.split(",") if n.strip()):
                expect(f"{workflow.name} needs {name}, which a job declares", name in declared)

        for called in CALLS.findall(text):
            expect(f"{workflow.name} calls {called}, a workflow of copacabana", (SHARED / called).is_file())
            for preset in sorted(BUILDS_WITH.get(called, set())):
                expect(f"{preset}, built by {called} from {workflow.name}, is declared",
                       preset in declared_presets)

        if "coverage: true" in text:
            expect(f"{workflow.name} sets coverage: true, and gcc-coverage is declared",
                   "gcc-coverage" in declared_presets)

        for preset in sorted(set(PRESET.findall(text))):
            expect(f"{preset}, set in {workflow.name}, is declared", preset in declared_presets)

        for read in READS.findall(text):
            expect(f"{workflow.name} reads {read}, which was written", read in readable)

    return report("The scaffolded workflows")


if __name__ == "__main__":
    cli(main)
