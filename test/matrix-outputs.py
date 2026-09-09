#!/usr/bin/env python3
"""What the matrix workflow makes of a matrix file, checked by running the reader the workflow carries.

The script is read out of the workflow rather than copied here, so the two cannot drift. Every output is a string
that the caller reads back with fromJSON, which is what lets a key hold a list: `runs-on: [self-hosted, cuda]` went
out as its Python repr once, a label no runner carries, and the jobs sat queued with nothing said.

  python3 test/matrix-outputs.py <copacabana source directory>
"""
import json
import pathlib
import sys
import tempfile

from checks import cli, expect, report, run

WORKFLOW = ".github/workflows/matrix.yml"

CASES = [
    ("a matrix naming no runner", {}, "runs-on", "ubuntu-latest"),
    ("one label", {"runs-on": "cuda"}, "runs-on", "cuda"),
    ("a list of labels", {"runs-on": ["self-hosted", "cuda"]}, "runs-on", ["self-hosted", "cuda"]),
    ("the configurations", {}, "configs", ["Debug", "Release"]),
]


def reader(workflow):
    """The python the Read it step feeds the matrix file, dedented out of its heredoc."""
    lines = pathlib.Path(workflow).read_text(encoding="utf-8").splitlines()
    start = next(i for i, line in enumerate(lines) if line.endswith("<<'EOF'")) + 1
    end = next(i for i, line in enumerate(lines[start:], start) if line.strip() == "EOF")
    return "\n".join(line[10:] for line in lines[start:end])


def outputs(script, spec):
    """What the step would write to GITHUB_OUTPUT, as a dictionary."""
    with tempfile.NamedTemporaryFile("w", suffix=".yml") as matrix:
        json.dump({"rows": [{"preset": "gcc"}], **spec}, matrix)
        matrix.flush()
        written = run(sys.executable, "-c", script, matrix.name)

    return dict(line.split("=", 1) for line in written.stdout.splitlines())


def main(root: str = ".") -> int:
    script = reader(pathlib.Path(root) / WORKFLOW)

    for what, spec, key, wanted in CASES:
        written = outputs(script, spec).get(key, "")
        try:
            read_back = json.loads(written)
        except json.JSONDecodeError:
            read_back = None

        expect(f"{what} reaches the job as {wanted!r}", read_back == wanted, written)

    return report("The matrix outputs")


if __name__ == "__main__":
    cli(main)
