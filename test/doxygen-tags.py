#!/usr/bin/env python3
##======================================================================================================================
##  Copacabana - Common CMake Package Tools
##  Copyright : Copacabana Project Contributors
##  SPDX-License-Identifier: BSL-1.0
##======================================================================================================================
"""Check the tag files of copa_setup_doxygen, on a probe project whose two tag files sit in a directory with a space.

    python3 test/doxygen-tags.py <copacabana source directory>

The doxygen target has to run with two tag files and a space in their path, and a configure that cannot download a
tag file again has to keep the copy of the configure before, which doxygen reads, rather than an empty file.
"""
import pathlib
import shutil
import tempfile

from checks import cli, expect, report, run

PROJECT = """cmake_minimum_required(VERSION 3.24)
project(probe LANGUAGES CXX)
set(COPACABANA_SOURCE_DIR "{root}")
include({root}/copacabana/cmake/copacabana.cmake)
copa_project_version(MAJOR 1 MINOR 0 PATCH 0)
copa_setup_doxygen(QUIET DESTINATION "${{PROJECT_BINARY_DIR}}/site" TAGFILES "one={site}" "two={site}")
"""

DOXYFILE = """OUTPUT_DIRECTORY       = $(DOXYGEN_OUPUT)
HTML_OUTPUT            = ./
INPUT                  = .
@INCLUDE               = $(DOXYGEN_ASSETS)/base.doxyfile
"""

TAG = "<?xml version='1.0' encoding='UTF-8' standalone='yes' ?>\n<tagfile doxygen_version=\"1.16.1\">\n</tagfile>\n"


def main(root: str = ".") -> int:
    root = pathlib.Path(root).resolve()

    with tempfile.TemporaryDirectory() as tmp:
        site = pathlib.Path(tmp, "tag site")
        site.mkdir()
        for name in ("one", "two"):
            (site / f"{name}.tag").write_text(TAG, encoding="utf-8")

        project = pathlib.Path(tmp, "probe")
        (project / "doc").mkdir(parents=True)
        (project / "doc" / "Doxyfile").write_text(DOXYFILE, encoding="utf-8")
        (project / "doc" / "index.md").write_text("# Probe\n\nA page.\n", encoding="utf-8")
        (project / "CMakeLists.txt").write_text(PROJECT.format(root=root.as_posix(), site=site.as_uri()),
                                                encoding="utf-8")

        build = pathlib.Path(tmp, "build")
        out = run("cmake", "-G", "Ninja", "-S", str(project), "-B", str(build))
        if not expect("the probe configures with two tag files", out.returncode == 0, out.stderr[-400:]):
            return report("The tag files")

        out = run("cmake", "--build", str(build), "--target", "probe-doxygen")
        expect("doxygen runs with two tag files in a path holding a space", out.returncode == 0,
               (out.stdout + out.stderr)[-400:])

        ## The site goes away, as it does offline: the copies of the first configure have to survive the second.
        shutil.rmtree(site)
        out = run("cmake", "-S", str(project), "-B", str(build))
        tags = [pathlib.Path(build, "copa-doxygen", f"{name}.tag") for name in ("one", "two")]
        expect("a failed download keeps the tag file of the configure before",
               all(t.is_file() and t.read_text(encoding="utf-8") == TAG for t in tags),
               [t.stat().st_size if t.is_file() else None for t in tags])
        expect("the configure warns that a tag file could not be fetched", "could not be fetched" in out.stderr,
               out.stderr[-300:])

        out = run("cmake", "--build", str(build), "--target", "probe-doxygen")
        expect("doxygen still runs on the kept tag files", out.returncode == 0, (out.stdout + out.stderr)[-400:])

    return report("The tag files")


if __name__ == "__main__":
    cli(main)
