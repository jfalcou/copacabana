#!/usr/bin/env python3
##======================================================================================================================
##  Copacabana - Common CMake Package Tools
##  Copyright : Copacabana Project Contributors
##  SPDX-License-Identifier: BSL-1.0
##======================================================================================================================
"""Check the copacabana pins of the template and REMOTE_PRESETS of the scaffolder.

- every `uses: jfalcou/copacabana/<path>@<ref>` of the template names a file of this checkout
- every `uses:` and the GIT_TAG of cmake/dependencies.cmake carry one ref
- REMOTE_PRESETS equals the presets built by each shared workflow it lists

  python3 test/template-pin.py <copacabana source directory>
"""
import importlib.util
import pathlib
import re

from checks import cli, expect, report

CALL = re.compile(r"uses:\s*jfalcou/copacabana/(\.github/[A-Za-z0-9._/-]+)@(\S+)")
GIT_TAG = re.compile(r"GIT_TAG\s+(\S+)")
BUILT_WITH = re.compile(r"""(?:preset:\s*["']?|--preset\s+)([A-Za-z0-9._-]+)""")


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

    spec = importlib.util.spec_from_file_location("new_project", root / "tools" / "new-project.py")
    scaffolder = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(scaffolder)
    for workflow, presets in scaffolder.REMOTE_PRESETS.items():
        text = (root / ".github" / "workflows" / workflow).read_text(encoding="utf-8")
        built = {p for p in BUILT_WITH.findall(text) if not p.startswith("$")}
        expect(f"REMOTE_PRESETS lists the presets {workflow} builds", built == presets, sorted(built))

    return report("The template's pins")


if __name__ == "__main__":
    cli(main)
