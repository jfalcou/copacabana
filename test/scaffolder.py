#!/usr/bin/env python3
"""What the scaffolder writes, checked by scaffolding twice and building what comes out.

The second project asks for less, neither the standalone nor a Windows preset, which is what turns a job into a name
nothing declares and a workflow into a call to a file that was never written.

  python3 test/scaffolder.py <copacabana source directory>
"""
import json
import os
import pathlib
import re
import sys
import tempfile

from checks import cli, expect, report, run

## The commit both pins of a scaffold name, fixed here so that the check reads no remote and no git: a CI container
## refuses git on a checkout owned by another user, and the configures below take copacabana from the checkout anyway.
PIN = "0123456789abcdef0123456789abcdef01234567"


def scaffold(root, where, *options, remote="https://github.com/someone/mylib"):
    return run(sys.executable, "tools/new-project.py", where, "--brief", "A scaffolded library",
               "--remote", remote, "--copacabana-ref", PIN, *options, cwd=root)


def pins(project):
    """Every commit a project names copacabana at, in its workflows and in its fetch."""
    found = set()
    for path in pathlib.Path(project).rglob("*"):
        if path.is_file() and path.suffix in (".yml", ".cmake"):
            text = path.read_text(encoding="utf-8")
            found |= set(re.findall(r"jfalcou/copacabana/\S+@(\S+)", text))
            found |= set(re.findall(r"NAME COPACABANA [^)]*GIT_TAG (\S+)\)", text))
    return found


def main(root: str = ".") -> int:
    root = pathlib.Path(root).resolve()

    with tempfile.TemporaryDirectory() as tmp:
        full, narrow = str(pathlib.Path(tmp, "mylib")), str(pathlib.Path(tmp, "narrow"))

        out = scaffold(root, full, "--name", "mylib")
        expect("the scaffolder writes a whole project", out.returncode == 0, out.stderr[-300:])

        out = run("cmake", "-S", full, "-B", f"{full}/build", "-G", "Ninja",
                  f"-DCPM_COPACABANA_SOURCE={root}", "-DMYLIB_BUILD_DOCUMENTATION=ON")
        expect("what it wrote configures", out.returncode == 0, out.stderr[-300:])

        out = run("cmake", "--build", f"{full}/build", "--target", "mylib-test", "mylib-doxygen", "--parallel", "2")
        expect("what it declares builds", out.returncode == 0, out.stderr[-300:])

        out = scaffold(root, narrow, "--name", "narrow", "--presets", "gcc,clang", "--no-standalone")
        expect("the scaffolder writes a narrower one", out.returncode == 0, out.stderr[-300:])

        out = run(sys.executable, "test/scaffolded-workflows.py", narrow, cwd=root)
        expect("its workflows call only what it has", out.returncode == 0, out.stdout[-400:])

        for gone in (".github/matrices/windows.yml", ".github/workflows/package-standalone.yml"):
            expect(f"what it left out is absent: {gone}", not pathlib.Path(narrow, gone).exists())

        ## Three rows survive out of eleven, gcc16 building with the gcc preset: a matrix keeps its file while one
        ## preset holds, not its every row.
        linux = pathlib.Path(narrow, ".github/matrices/linux.yml").read_text(encoding="utf-8")
        expect("the linux matrix keeps the three rows of its two presets", linux.count("- {") == 3, linux[-400:])
        expect("the setup script of the gcc16 row is written with it",
               pathlib.Path(narrow, ".github/scripts/g++-16.sh").is_file())

        presets = json.loads(pathlib.Path(narrow, "CMakePresets.json").read_text(encoding="utf-8"))
        compilers = {p["name"]: p for p in presets["configurePresets"] if p["name"] in ("gcc", "clang")}
        expect("the gcc and clang presets name their compiler rather than a toolchain file",
               all("toolchainFile" not in p and p.get("cacheVariables", {}).get("CMAKE_CXX_COMPILER")
                   for p in compilers.values()) and len(compilers) == 2, compilers)

        ## The shared sanitizer and coverage workflows build with presets the narrow project left out.
        ci = pathlib.Path(narrow, ".github/workflows/ci.yml").read_text(encoding="utf-8")
        expect("its CI calls no shared workflow needing a preset it lacks",
               "sanitizers.yml" not in ci and "coverage.yml" not in ci, ci[-400:])
        documentation = pathlib.Path(narrow, ".github/workflows/documentation.yml").read_text(encoding="utf-8")
        expect("its documentation builds no coverage", "coverage: false" in documentation)

        expect("both pins of copacabana name one commit, the one asked for", pins(narrow) == {PIN}, pins(narrow))

        derived = str(pathlib.Path(tmp, "derived"))
        out = scaffold(root, derived, "--name", "derived", "--presets", "gcc-sanitize,clang-compile-cost")
        listed = run("cmake", "--list-presets", cwd=derived)
        expect("a derived preset keeps the presets it inherits from",
               out.returncode == 0 and listed.returncode == 0, (out.stderr + listed.stderr)[-300:])

        typo = pathlib.Path(tmp, "typo")
        out = scaffold(root, str(typo), "--name", "typo", "--presets", "gcc,gc")
        expect("an unknown preset stops the scaffold and leaves no directory",
               out.returncode != 0 and not typo.exists(), out.stderr[-300:])

        ## A project hosted elsewhere than GitHub keeps the runner its wasm toolchain names, and drops the one of a
        ## preset it left out.
        runner = pathlib.Path(tmp, "runner").resolve()
        out = scaffold(root, str(runner), "--name", "runner", "--presets", "clang,wasm",
                       remote="https://gitlab.example.org/team/runner")
        toolchains = runner / "test/toolchain"
        command = re.search(r"CMAKE_CROSSCOMPILING_CMD \$\{CMAKE_CURRENT_LIST_DIR\}/(\S+)\)",
                            (toolchains / "clang.wasm.cmake").read_text(encoding="utf-8"))
        script = toolchains / command.group(1) if command else toolchains / "missing"
        expect("the wasm toolchain runs its tests through a script that is written, executable",
               out.returncode == 0 and script.is_file() and os.access(script, os.X_OK), (out.stderr[-300:], script))
        expect("the runner of a preset left out is not written", not (toolchains / "run_rvv128.sh").exists())
        expect("nothing of GitHub's is written", not (runner / ".github").exists())

        cpm_test = runner / "test/integration/cpm-test"
        included = re.search(r"include\(\$\{CMAKE_CURRENT_LIST_DIR\}/(\S+)\)",
                             (cpm_test / "CMakeLists.txt").read_text(encoding="utf-8"))
        expect("the CPM test includes the CPM of the project, its one copy",
               included is not None and (cpm_test / included.group(1)).resolve() == runner / "cmake/CPM.cmake"
               and not (cpm_test / "cpm.cmake").exists(), included)

        dotgit = str(pathlib.Path(tmp, "dotgit"))
        scaffold(root, dotgit, "--name", "dotgit", remote="https://github.com/someone/dotgit.git/")
        fetch = pathlib.Path(dotgit, "test/integration/fetch-test/CMakeLists.txt").read_text(encoding="utf-8")
        expect("a remote ending in .git is cloned once with it",
               "dotgit.git.git" not in fetch and "dotgit.git" in fetch)

    return report("What the scaffolder writes")


if __name__ == "__main__":
    cli(main)
