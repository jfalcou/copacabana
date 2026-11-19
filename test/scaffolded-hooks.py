#!/usr/bin/env python3
"""Whether the hooks a scaffolded project ships pass on what was scaffolded.

They need the Python the shared gate runs under: the container the builds use carries neither pip nor a venv, so this
is precommit.yml's own setup, same Python, same pinned release, pointed at a tree the scaffolder just wrote.

  python3 test/scaffolded-hooks.py <copacabana source directory>
"""
import pathlib
import sys
import tempfile

from checks import cli, expect, report, run


def main(root: str = ".") -> int:
    root = pathlib.Path(root).resolve()

    with tempfile.TemporaryDirectory() as tmp:
        where = str(pathlib.Path(tmp, "narrow"))

        out = run(sys.executable, "tools/new-project.py", where, "--name", "narrow", "--brief", "A narrower library",
                  "--remote", "https://github.com/someone/narrow", "--presets", "gcc,clang", "--no-standalone",
                  cwd=root)
        expect("the scaffolder writes the project", out.returncode == 0, out.stderr[-300:])

        run("git", "init", "--quiet", ".", cwd=where)
        run("git", "add", "--all", cwd=where)
        run("git", "-c", "user.email=ci@example.org", "-c", "user.name=CI", "commit", "--quiet", "-m", "init",
            cwd=where)

        out = run("pre-commit", "run", "--all-files", "--show-diff-on-failure", "--color=always", cwd=where)
        expect("its own hooks pass on it", out.returncode == 0, out.stdout[-600:])

        # A long name lengthens the CMake lines, which the first run lays out when the scaffolder could not.
        long = "a_library_with_a_much_longer_name"
        where = str(pathlib.Path(tmp, long))
        out = run(sys.executable, "tools/new-project.py", where, "--name", long, "--brief", "A library",
                  "--remote", f"https://github.com/someone/{long}", "--presets", "gcc,clang", "--no-standalone",
                  cwd=root)
        expect("the scaffolder writes a project with a long name", out.returncode == 0, out.stderr[-300:])

        run("git", "init", "--quiet", ".", cwd=where)
        run("git", "add", "--all", cwd=where)
        run("git", "-c", "user.email=ci@example.org", "-c", "user.name=CI", "commit", "--quiet", "-m", "init",
            cwd=where)
        run("pre-commit", "run", "--all-files", cwd=where)
        # Staged, since pre-commit stashes what is not and would check the files as scaffolded again.
        run("git", "add", "--all", cwd=where)
        out = run("pre-commit", "run", "--all-files", "--show-diff-on-failure", "--color=always", cwd=where)
        expect("its hooks pass on it once a first run laid it out", out.returncode == 0, out.stdout[-600:])

    return report("What the scaffolded hooks say")


if __name__ == "__main__":
    cli(main)
