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
import sys

JOB = re.compile(r"^  ([A-Za-z0-9_-]+):$", re.M)
NEEDS = re.compile(r"needs:\s*\[([^\]]*)\]")
CALLS = re.compile(r"uses:\s*\./\.github/workflows/([A-Za-z0-9._-]+)")


def main(root: str) -> int:
    directory = pathlib.Path(root) / ".github" / "workflows"
    present = {path.name for path in directory.glob("*.yml")}
    broken = 0

    for workflow in sorted(directory.glob("*.yml")):
        text = workflow.read_text(encoding="utf-8")
        declared = set(JOB.findall(text))

        for names in NEEDS.findall(text):
            for name in (n.strip() for n in names.split(",") if n.strip()):
                if name not in declared:
                    print(f"{workflow}: needs {name}, which no job declares")
                    broken += 1

        for called in CALLS.findall(text):
            if called not in present:
                print(f"{workflow}: calls {called}, which was not written")
                broken += 1

    print(f"[copacabana] - {len(present)} workflows read, {broken} dangling reference(s)")
    return 1 if broken else 0


if __name__ == "__main__":
    sys.exit(main(*sys.argv[1:]))
