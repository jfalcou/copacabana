#!/usr/bin/env python3
"""What the scaffolder writes, checked by scaffolding twice and building what comes out.

The second project asks for less, neither the standalone nor a Windows preset, which is what turns a job into a name
nothing declares and a workflow into a call to a file that was never written.

  python3 test/scaffolder.py <copacabana source directory>
"""
import pathlib
import sys
import tempfile

from checks import cli, expect, report, run


def scaffold(root, where, *options):
    return run(sys.executable, "tools/new-project.py", where, "--brief", "A scaffolded library",
               "--remote", "https://github.com/someone/mylib", *options, cwd=root)


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

        for gone in (".github/matrices/windows.yml", ".github/workflows/standalone.yml"):
            expect(f"what it left out is absent: {gone}", not pathlib.Path(narrow, gone).exists())

        ## Two rows survive out of ten: a matrix keeps its file while one preset holds, not its every row.
        rows = pathlib.Path(narrow, ".github/matrices/linux.yml").read_text(encoding="utf-8").count("- {")
        expect("the linux matrix keeps the two rows asked for", rows == 2, rows)

    return report("What the scaffolder writes")


if __name__ == "__main__":
    cli(main)
