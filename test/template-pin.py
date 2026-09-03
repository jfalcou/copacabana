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
"""
import pathlib
import re
import subprocess
import sys

PIN = re.compile(r"@([0-9a-f]{40})\s*#\s*(v[0-9]+)")
CALL = re.compile(r"uses:\s*jfalcou/copacabana/(\.github/[A-Za-z0-9._/-]+)@([0-9a-f]{40})")


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
    wrong = 0

    for workflow in workflows:
        for line, text in enumerate(workflow.read_text(encoding="utf-8").splitlines(), 1):
            found = PIN.search(text)
            if not found:
                continue

            pinned, tag = found.groups()
            actual = resolve(tag)

            if actual is None:
                print(f"{workflow}:{line}: {tag} is not a tag of this repository")
                wrong += 1
            elif actual != pinned:
                print(f"{workflow}:{line}: pinned at {pinned[:7]}, {tag} is {actual[:7]}")
                wrong += 1

            called = CALL.search(text)
            if called and not exists(called.group(2), called.group(1)):
                print(f"{workflow}:{line}: {called.group(1)} does not exist at {called.group(2)[:7]}, {tag} has no such file")
                wrong += 1

    print(f"[copacabana] - {len(workflows)} template workflows read, {wrong} pin(s) naming the wrong commit")
    return 1 if wrong else 0


if __name__ == "__main__":
    sys.exit(main(*sys.argv[1:]))
