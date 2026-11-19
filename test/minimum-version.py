#!/usr/bin/env python3
"""Every check that drives CMake, run under the oldest CMake the modules support.

Every other row takes the latest release, so this one is where a command or a behavior newer than the floor shows.

  python3 test/minimum-version.py <copacabana source directory>
"""
import os
import pathlib
import sys
import tarfile
import tempfile
import urllib.request

from checks import cli, expect, report, run

## The floor the modules declare with cmake_minimum_required.
VERSION = "3.24.3"
ARCHIVE = f"https://github.com/Kitware/CMake/releases/download/v{VERSION}/cmake-{VERSION}-linux-x86_64.tar.gz"

## The checks that configure, build or install with CMake. The spack consumption reads an installed tree instead, and
## the system installers need the rpmbuild the image lacks.
CHECKS = [ "cold-configure", "doxygen-setup", "doxygen-tags", "failure-units", "heavy-pool", "install-layout"
         , "nested-builds", "precommit-banner", "scaffolder", "target-hierarchy", "unit-targets"
         ]


def main(source):
    source = pathlib.Path(source).resolve()

    with tempfile.TemporaryDirectory() as tmp:
        with urllib.request.urlopen(ARCHIVE, timeout=120) as answer, tarfile.open(fileobj=answer, mode="r|gz") as tar:
            tar.extractall(tmp, filter="data")

        env = dict(os.environ)
        env["PATH"] = f"{tmp}/cmake-{VERSION}-linux-x86_64/bin{os.pathsep}{env['PATH']}"
        out = run("cmake", "--version", env=env)
        if not expect(f"cmake on the path is {VERSION}", f"cmake version {VERSION}" in out.stdout, out.stdout[:80]):
            return report(f"Checks under CMake {VERSION}")

        for check in CHECKS:
            out = run(sys.executable, f"test/{check}.py", str(source), env=env, cwd=source)
            expect(f"{check} passes", out.returncode == 0, out.stdout[-600:])

        out = run("cmake", "-S", "test/guard", "-B", f"{tmp}/guard", f"-DCOPACABANA_SOURCE_DIR={source}", env=env,
                  cwd=source)
        expect("two consumers configure in one build", out.returncode == 0, out.stderr[-400:])

    return report(f"Checks under CMake {VERSION}")


if __name__ == "__main__":
    cli(main)
