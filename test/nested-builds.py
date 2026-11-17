#!/usr/bin/env python3
"""What copa_setup_install and copa_setup_precommit_hooks do in a project nested in another one.

The outer project adds the inner one as CPM adds a dependency, a git checkout of its own added as a subdirectory, and
both call the two functions. The outer one is then checked out a second time as a git worktree, whose .git is a file.

  python3 test/nested-builds.py <copacabana source directory>
"""
import os
import pathlib
import re
import tempfile

from checks import cli, expect, report, run

PROJECT = """cmake_minimum_required(VERSION 3.24)
project({name} VERSION 1.0 LANGUAGES CXX)
set(COPACABANA_SOURCE_DIR {source})
include(${{COPACABANA_SOURCE_DIR}}/copacabana/cmake/copacabana.cmake)
copa_setup_precommit_hooks()
copa_setup_install(LIBRARY {name} DOC ${{PROJECT_SOURCE_DIR}}/{doc})
{more}"""

BANNER = "ATTENTION: DEVELOPMENT ENVIRONMENT SETUP"


def git(where, *args):
    return run("git", "-c", "user.email=ci@example.org", "-c", "user.name=CI", *args, cwd=where)


def checkout(root, name, doc, source, more=""):
    """A project committed to a git repository of its own, with a file of documentation."""
    root.mkdir()
    (root / "CMakeLists.txt").write_text(PROJECT.format(name=name, source=source, doc=doc, more=more),
                                         encoding="utf-8")
    (root / doc).write_text(f"{name}\n", encoding="utf-8")
    git(root, "init", "--quiet", ".")
    git(root, "add", "--all")
    git(root, "commit", "--quiet", "-m", "init")


def configure(source, build, *args):
    """Configure with CI unset, so that the banner shows, and a pre-commit that is never run.

    CMake runs outside both checkouts, where a path to a hook left relative finds nothing.
    """
    env = dict(os.environ)
    env.pop("CI", None)
    return run("cmake", "-S", str(source), "-B", str(build), "-G", "Ninja", "-DPRE_COMMIT_CMD=/bin/true", *args,
               env=env, cwd=build.parent)


def installed(build, prefix):
    out = run("cmake", "--install", str(build), "--prefix", str(prefix))
    if not expect("the projects install", out.returncode == 0, out.stderr[-300:]):
        return set()
    return {str(p.relative_to(prefix)) for p in prefix.rglob("*") if p.is_file() and p.suffix != ".cmake"}


def targets(build):
    out = run("ninja", "-C", str(build), "-t", "targets", "all")
    return {line.split(":")[0] for line in out.stdout.splitlines()}


def main(source):
    source = pathlib.Path(source).resolve()

    with tempfile.TemporaryDirectory() as tmp:
        tmp = pathlib.Path(tmp)
        outer = tmp / "outer"
        checkout(tmp / "inner", "inner", "NOTICE", source)
        checkout(outer, "outer", "LICENSE", source, more=f"add_subdirectory({tmp / 'inner'} inner)\n")

        out = configure(outer, tmp / "build")
        if expect("the nested projects configure", out.returncode == 0, out.stderr[-300:]):
            files = installed(tmp / "build", tmp / "prefix")
            expect("the outer file of documentation installs under its project",
                   "share/doc/outer/LICENSE" in files, sorted(files))
            expect("the inner file of documentation installs under its project",
                   "share/doc/inner/NOTICE" in files, sorted(files))

            expect("the outer project creates its hooks target", "outer-setup-hooks" in targets(tmp / "build"))
            expect("the inner project creates none", "inner-setup-hooks" not in targets(tmp / "build"))
            expect("the outer project reports its missing hooks", re.search(rf"\[outer\] - +{BANNER}", out.stdout))
            expect("the inner project reports nothing", "[inner] -" not in out.stdout, out.stdout[-300:])

        # The top level keeps the documentation directory given on the command line.
        out = configure(outer, tmp / "docdir", "-DCMAKE_INSTALL_DOCDIR=doc/custom")
        if expect("the projects configure with CMAKE_INSTALL_DOCDIR set", out.returncode == 0, out.stderr[-300:]):
            files = installed(tmp / "docdir", tmp / "docdir-prefix")
            expect("the outer file of documentation installs into CMAKE_INSTALL_DOCDIR",
                   "doc/custom/LICENSE" in files, sorted(files))
            expect("the inner file of documentation stays under its project",
                   "share/doc/inner/NOTICE" in files, sorted(files))

        # One hook installed in the main checkout, read from it and from a worktree, which shares it.
        hook = outer / ".git" / "hooks" / "pre-commit"
        hook.write_text("#!/bin/sh\n", encoding="utf-8")
        out = configure(outer, tmp / "hooked")
        if expect("the checkout configures with its hook", out.returncode == 0, out.stderr[-300:]):
            expect("the checkout reads its hook as installed", BANNER not in out.stdout, out.stdout[-300:])

        out = git(outer, "worktree", "add", "--quiet", str(tmp / "worktree"))
        if expect("the worktree is created", out.returncode == 0, out.stderr[-300:]):
            out = configure(tmp / "worktree", tmp / "worktree-build")
            if expect("the worktree configures", out.returncode == 0, out.stderr[-300:]):
                expect("the worktree reads the hooks of the main checkout as installed", BANNER not in out.stdout,
                       out.stdout[-300:])

    return report("Nested builds")


if __name__ == "__main__":
    cli(main)
