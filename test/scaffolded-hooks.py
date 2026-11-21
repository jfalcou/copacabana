#!/usr/bin/env python3
"""Run the pre-commit hooks of a scaffold on that scaffold, and on one with a 50-character name.

Runs under the Python and the pinned pre-commit of precommit.yml, since the build container has neither pip nor venv.

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

        # With a 50-character name, CMake lines exceed 120 columns until cmake-format wraps them, at the scaffold if
        # installed, else at the first pre-commit run.
        long = "a_library_with_a_name_of_fifty_characters_in_total"
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
