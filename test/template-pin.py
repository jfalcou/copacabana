#!/usr/bin/env python3
##======================================================================================================================
##  Copacabana - Common CMake Package Tools
##  Copyright : Copacabana Project Contributors
##  SPDX-License-Identifier: BSL-1.0
##======================================================================================================================
"""Check that every pin the template carries points at the tag written beside it, and at a file that tag has.

A workflow reference is a commit followed by the tag it is meant to be, as `@<sha> # <tag>`. Nothing moves the first
half when the second is retagged, so a scaffolded project is born on a version it only claims to be. And a workflow
added here is not at any earlier tag: a template calling it through the previous pin scaffolds a project whose call
GitHub refuses, without anything in this repository building it. This reads the tags and the trees of the checkout
it runs in, so the CI step calling it needs them fetched.

The template carries a second pin, the GIT_TAG that brings in the cmake functions, which a move to a new version has
to take along: it sat two versions behind the workflows once.
"""
import pathlib
import re
import subprocess
import sys

from checks import expect, report

PIN = re.compile(r"@([0-9a-f]{40})\s*#\s*(v[0-9]+)")
CALL = re.compile(r"uses:\s*jfalcou/copacabana/(\.github/[A-Za-z0-9._/-]+)@([0-9a-f]{40})")
GIT_TAG = re.compile(r"GIT_TAG\s+(v[0-9]+)")


def resolve(tag: str) -> str | None:
    result = subprocess.run(["git", "rev-parse", f"{tag}^{{commit}}"], capture_output=True, text=True)
    return result.stdout.strip() if result.returncode == 0 else None


def exists(sha: str, path: str) -> bool:
    """Whether the commit carries the file, a composite action being its directory's action.yml."""
    for candidate in (path, f"{path}/action.yml"):
        if subprocess.run(["git", "cat-file", "-e", f"{sha}:{candidate}"], capture_output=True).returncode == 0:
            return True
    return False


def main(root: str = ".") -> int:
    workflows = sorted((pathlib.Path(root) / "tools" / "template" / ".github" / "workflows").glob("*.yml"))
    print(f"{len(workflows)} template workflows read\n")

    tags = set()
    for workflow in workflows:
        for line, text in enumerate(workflow.read_text(encoding="utf-8").splitlines(), 1):
            found = PIN.search(text)
            if not found:
                continue

            pinned, tag = found.groups()
            tags.add(tag)
            actual = resolve(tag)
            where = f"{workflow.name}:{line}"

            if actual is None:
                expect(f"{where}: {tag} is a tag of this repository", False)
            else:
                expect(f"{where}: the pin names the commit {tag} points at", actual == pinned,
                       f"{pinned[:7]} rather than {actual[:7]}")

            called = CALL.search(text)
            if called:
                expect(f"{where}: {called.group(1)} exists at {called.group(2)[:7]}",
                       exists(called.group(2), called.group(1)))

    dependencies = pathlib.Path(root) / "tools" / "template" / "cmake" / "dependencies.cmake"
    found = GIT_TAG.search(dependencies.read_text(encoding="utf-8"))
    version = found.group(1) if found else None

    if expect("the template's workflows name one version", len(tags) == 1, sorted(tags)):
        wanted = tags.pop()
        expect(f"dependencies.cmake brings in the cmake functions of {wanted}", version == wanted, version)

    return report("The template's pins")


if __name__ == "__main__":
    sys.exit(main(*sys.argv[1:]))
