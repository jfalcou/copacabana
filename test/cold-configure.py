#!/usr/bin/env python3
"""Where a project option becomes readable, checked on a scaffolded project configured once.

cmake/dependencies.cmake runs before copa_add_option exists, so a package guarded there on an option sees nothing on
the first configure of a fresh clone and is silently skipped; the second configure reads the cache and hides it. A
preset hides it too, its cacheVariables landing before the CMakeLists is read, which is why no CI has ever caught it.
This configures once, in an empty tree, with no preset.

  python3 test/cold-configure.py <copacabana source directory>
"""
import pathlib
import sys
import tempfile

from checks import cli, expect, report, run

PROBE = 'file(APPEND "${{COLD_PROBE}}" "{where}=${{NARROW_BUILD_TEST}}\\n")\n'


def main(root: str = ".") -> int:
    root = pathlib.Path(root).resolve()

    with tempfile.TemporaryDirectory() as tmp:
        where, probe = str(pathlib.Path(tmp, "narrow")), pathlib.Path(tmp, "probe.txt")

        out = run(sys.executable, "tools/new-project.py", where, "--name", "narrow", "--brief", "A narrower library",
                  "--remote", "https://github.com/someone/narrow", "--presets", "gcc", "--no-standalone", cwd=root)
        if not expect("the scaffolder writes the project", out.returncode == 0, out.stderr[-300:]):
            return report("Where an option is readable")

        ## One probe where the dependencies are fetched, one where the options are declared: the file says what each
        ## read, and an unset option reads as empty.
        deps = pathlib.Path(where, "cmake/dependencies.cmake")
        deps.write_text(deps.read_text(encoding="utf-8") + PROBE.format(where="dependencies"), encoding="utf-8")

        lists = pathlib.Path(where, "CMakeLists.txt")
        anchor = "copa_show_options()"
        text = lists.read_text(encoding="utf-8")
        assert text.count(anchor) == 1
        lists.write_text(text.replace(anchor, PROBE.format(where="options") + anchor), encoding="utf-8")

        out = run("cmake", "-S", where, "-B", str(pathlib.Path(tmp, "build")), f"-DCPM_COPACABANA_SOURCE={root}",
                  f"-DCOLD_PROBE={probe}")
        if not expect("a fresh tree configures once, with no preset", out.returncode == 0, out.stderr[-400:]):
            return report("Where an option is readable")

        said = dict(line.split("=", 1) for line in probe.read_text(encoding="utf-8").splitlines())
        expect("dependencies.cmake cannot read a project option", said.get("dependencies") == "", said)
        expect("the option is set where copa_add_option put it", said.get("options") == "ON", said)

    return report("Where an option is readable")


if __name__ == "__main__":
    cli(main)
