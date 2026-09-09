#!/usr/bin/env python3
"""Whether the pre-commit banner reaches a runner, checked on a scaffolded project rather than on this repository.

Nothing here configures a tree that is both a git checkout and free of hooks, which is what makes the banner appear,
so the check scaffolds one. The option summary is read alongside it: silencing the banner through QUIET took the
summary with it, which is what the CI guard exists to avoid.

  python3 test/precommit-banner.py <copacabana source directory>
"""
import os
import pathlib
import subprocess
import sys
import tempfile

from checks import expect, report

BANNER = "ATTENTION: DEVELOPMENT ENVIRONMENT SETUP"
SUMMARY = "(via NARROW_BUILD_TEST)"


def run(command, cwd=None, env=None):
    return subprocess.run(command, cwd=cwd, env=env, capture_output=True, text=True)


def scaffold(root, where):
    """A project the scaffolder wrote, turned into a git checkout with no hook installed."""
    run([sys.executable, "tools/new-project.py", where, "--name", "narrow", "--brief", "A narrower library",
         "--remote", "https://github.com/someone/narrow", "--presets", "gcc", "--no-standalone"], cwd=root)
    run(["git", "init", "--quiet", "."], cwd=where)
    run(["git", "add", "--all"], cwd=where)
    run(["git", "-c", "user.email=ci@example.org", "-c", "user.name=CI", "commit", "--quiet", "-m", "init"], cwd=where)


def configure(root, where, build, ci):
    """Configure the scaffolded project against this checkout, with CI set or absent."""
    env = dict(os.environ)
    env.pop("CI", None)
    if ci:
        env["CI"] = "true"

    result = run(["cmake", "-S", where, "-B", build, f"-DCPM_COPACABANA_SOURCE={root}"], env=env)
    expect(f"the configure succeeds with CI {'set' if ci else 'unset'}", result.returncode == 0, result.stderr[-400:])
    return result.stdout


def main(root: str = ".") -> int:
    root = str(pathlib.Path(root).resolve())

    with tempfile.TemporaryDirectory() as tmp:
        where = str(pathlib.Path(tmp) / "narrow")
        scaffold(root, where)

        local = configure(root, where, str(pathlib.Path(tmp) / "local"), ci=False)
        expect("someone at a keyboard is told how to get the hooks", BANNER in local)
        expect("and reads the option summary", SUMMARY in local)

        runner = configure(root, where, str(pathlib.Path(tmp) / "runner"), ci=True)
        expect("a runner is not told anything about the hooks", BANNER not in runner)
        expect("and still reads the option summary", SUMMARY in runner)

    return report("The pre-commit banner")


if __name__ == "__main__":
    sys.exit(main(*sys.argv[1:]))
