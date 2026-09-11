#!/usr/bin/env python3
##======================================================================================================================
##  Copacabana - Common CMake Package Tools
##  Copyright : Copacabana Project Contributors
##  SPDX-License-Identifier: BSL-1.0
##======================================================================================================================
"""Check that what the template calls exists here, and that both of its pins say the same thing.

A scaffolded project follows main, so the file it names has to be on main: a workflow renamed or moved breaks every
project the scaffolder ever wrote, and nothing in this repository builds them. The second pin is the GIT_TAG that
brings in the cmake functions, which has to follow the workflows rather than drift behind them.

  python3 test/template-pin.py <copacabana source directory>
"""
import pathlib
import re

from checks import cli, expect, report

CALL = re.compile(r"uses:\s*jfalcou/copacabana/(\.github/[A-Za-z0-9._/-]+)@(\S+)")
GIT_TAG = re.compile(r"GIT_TAG\s+(\S+)")


def main(root: str = ".") -> int:
    root = pathlib.Path(root)
    workflows = sorted((root / "tools" / "template" / ".github" / "workflows").glob("*.yml"))
    print(f"{len(workflows)} template workflows read\n")

    refs = set()
    for workflow in workflows:
        for line, text in enumerate(workflow.read_text(encoding="utf-8").splitlines(), 1):
            found = CALL.search(text)
            if not found:
                continue

            called, ref = found.groups()
            refs.add(ref)
            where = f"{workflow.name}:{line}"
            expect(f"{where}: {called} is a file of this repository", (root / called).is_file())

    expect("the template's workflows all name one reference", len(refs) == 1, sorted(refs))

    dependencies = root / "tools" / "template" / "cmake" / "dependencies.cmake"
    found = GIT_TAG.search(dependencies.read_text(encoding="utf-8"))
    version = found.group(1).rstrip(")") if found else None
    expect("dependencies.cmake brings in the cmake functions from the same one",
           refs and version == next(iter(refs)), version)

    return report("The template's pins")


if __name__ == "__main__":
    cli(main)
