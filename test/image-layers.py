#!/usr/bin/env python3
##======================================================================================================================
##  Copacabana - Common CMake Package Tools
##  Copyright : Copacabana Project Contributors
##  SPDX-License-Identifier: BSL-1.0
##======================================================================================================================
"""Check the layers the image action adds to its base, read from an archive of `docker save`.

    python3 test/image-layers.py <image.tar> <project>

The layers after the LABEL step of the Dockerfile are those of the action: none may hold a source, the setup script,
or a .git, which the mounts keep out, and one holds the headers the install wrote. The base image has a .git of its
own, so its layers are left out.
"""
import json
import pathlib
import re
import sys
import tarfile
import tempfile

from checks import expect, report

LEAK = re.compile(r"^(\./)?(src|tmp/setup)/.|(^|/)\.git(/|$)")


def blob(root, digest):
    algorithm, value = digest.split(":")
    return root / "blobs" / algorithm / value


def added_layers(root):
    """The layers the steps after the LABEL of the Dockerfile wrote, in order."""
    manifest = json.loads(blob(root, json.loads((root / "index.json").read_text())["manifests"][0]["digest"])
                          .read_text())
    if "manifests" in manifest:
        manifest = json.loads(blob(root, manifest["manifests"][0]["digest"]).read_text())
    history = json.loads(blob(root, manifest["config"]["digest"]).read_text())["history"]

    label = max((i for i, step in enumerate(history)
                 if "org.opencontainers.image.source" in step.get("created_by", "")), default=None)
    if label is None:
        return []
    before = sum(not step.get("empty_layer") for step in history[:label])
    return [blob(root, layer["digest"]) for layer in manifest["layers"][before:]]


def main(archive, project):
    with tempfile.TemporaryDirectory() as tmp:
        root = pathlib.Path(tmp)
        with tarfile.open(archive) as image:
            image.extractall(root, filter="data")

        layers = added_layers(root)
        expect("the archive holds the layers the action adds", len(layers) >= 3, len(layers))

        entries = [name for layer in layers for name in tarfile.open(layer).getnames()]
        expect("the install writes the headers of the project", any(f"include/{project}/" in e for e in entries))
        leaks = [e for e in entries if LEAK.search(e)]
        expect("no layer the action adds holds a source, the setup script, or a .git", not leaks, leaks[:10])

    return report("The layers of the image")


if __name__ == "__main__":
    sys.exit(main(*sys.argv[1:3]))
