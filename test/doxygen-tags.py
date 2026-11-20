#!/usr/bin/env python3
##======================================================================================================================
##  Copacabana - Common CMake Package Tools
##  Copyright : Copacabana Project Contributors
##  SPDX-License-Identifier: BSL-1.0
##======================================================================================================================
"""Check the tag files and the paths of copa_setup_doxygen, on a probe project where every path holds a space.

    python3 test/doxygen-tags.py <copacabana source directory>

Copacabana, the probe, its build tree, and the site of its two tag files each sit in a directory whose name holds a
space. Doxygen skips a path it splits at the space and still exits 0, so the checks read what the site holds: the
links the tag files resolve, the text the input filter rewrites, and the files the extra lists copy. A configure that
cannot download a tag file again has to keep the copy of the configure before.
"""
import pathlib
import shutil
import tempfile

from checks import cli, expect, report, run

PROJECT = """cmake_minimum_required(VERSION 3.24)
project(probe LANGUAGES CXX)
set(COPACABANA_SOURCE_DIR "{root}")
include("{root}/copacabana/cmake/copacabana.cmake")
copa_project_version(MAJOR 1 MINOR 0 PATCH 0)
copa_setup_doxygen(QUIET DESTINATION "${{PROJECT_BINARY_DIR}}/site" TAGFILES "one={site}" "two={site}")
"""

DOXYFILE = """OUTPUT_DIRECTORY       = $(DOXYGEN_OUPUT)
HTML_OUTPUT            = ./
INPUT                  = .
@INCLUDE               = $(DOXYGEN_ASSETS)/base.doxyfile
"""

PAGE = "# Probe\n\nSee \\ref one::Widget and \\ref two::Widget.\n"

HEADER = """/// \\file
/// The interface of the probe.

/// The namespace of the probe.
namespace probe
{
  /// A function whose return type the filter hides.
  _::hidden made();
}
"""

## What HTML_EXTRA_STYLESHEET and HTML_EXTRA_FILES of the shared Doxyfile copy into the site, from the three
## directories they name: copacabana's assets, the downloaded theme, and the files of the configure.
EXTRAS = [ "custom.css", "doxygen-awesome.css", "color.css", "godbolt.js", "copacabana.js", "doxygen-awesome-tabs.js"
         , "godbolt-config.js", "compile-cost.html"
         ]


def tag(name):
    """A tag file declaring one class, which a page of the probe links to."""
    return ("<?xml version='1.0' encoding='UTF-8' standalone='yes' ?>\n<tagfile doxygen_version=\"1.16.1\">\n"
            f"  <compound kind=\"class\"><name>{name}::Widget</name>"
            f"<filename>class{name}_1_1Widget.html</filename></compound>\n</tagfile>\n")


def linked(site):
    """Whether the pages of the site link to the class of each tag file."""
    html = "".join(p.read_text(encoding="utf-8", errors="ignore") for p in pathlib.Path(site).glob("*.html"))
    return all(f"class{name}_1_1Widget.html" in html for name in ("one", "two")), html


def main(root: str = ".") -> int:
    root = pathlib.Path(root).resolve()

    with tempfile.TemporaryDirectory() as tmp:
        copacabana = pathlib.Path(tmp, "copa dir")
        shutil.copytree(root / "copacabana", copacabana / "copacabana")

        site = pathlib.Path(tmp, "tag site")
        site.mkdir()
        for name in ("one", "two"):
            (site / f"{name}.tag").write_text(tag(name), encoding="utf-8")

        project = pathlib.Path(tmp, "probe dir")
        (project / "doc").mkdir(parents=True)
        (project / "doc" / "Doxyfile").write_text(DOXYFILE, encoding="utf-8")
        (project / "doc" / "index.md").write_text(PAGE, encoding="utf-8")
        (project / "doc" / "probe.hpp").write_text(HEADER, encoding="utf-8")
        (project / "CMakeLists.txt").write_text(PROJECT.format(root=copacabana.as_posix(), site=site.as_uri()),
                                                encoding="utf-8")

        build = pathlib.Path(tmp, "build dir")
        out = run("cmake", "-G", "Ninja", "-S", str(project), "-B", str(build))
        if not expect("the probe configures with two tag files", out.returncode == 0, out.stderr[-400:]):
            return report("The tag files")

        out = run("cmake", "--build", str(build), "--target", "probe-doxygen")
        expect("the doxygen target builds", out.returncode == 0, (out.stdout + out.stderr)[-400:])
        links, html = linked(build / "site")
        expect("the links of both tag files resolve", links, (out.stdout + out.stderr)[-400:])
        expect("the input filter rewrites the hidden type", "probe_implementation_defined" in html,
               (out.stdout + out.stderr)[-400:])
        missing = [name for name in EXTRAS if not (build / "site" / name).is_file()]
        expect("the extra stylesheets and files reach the site", not missing, missing)

        ## The site goes away, as it does offline: the copies of the first configure have to survive the second.
        shutil.rmtree(site)
        out = run("cmake", "-S", str(project), "-B", str(build))
        tags = [pathlib.Path(build, "copa-doxygen", f"{name}.tag") for name in ("one", "two")]
        expect("a failed download keeps the tag file of the configure before",
               all(t.is_file() and t.read_text(encoding="utf-8") == tag(t.stem) for t in tags),
               [t.stat().st_size if t.is_file() else None for t in tags])
        expect("the configure warns that a tag file could not be fetched", "could not be fetched" in out.stderr,
               out.stderr[-300:])

        shutil.rmtree(build / "site")
        out = run("cmake", "--build", str(build), "--target", "probe-doxygen")
        links, _ = linked(build / "site")
        expect("the links still resolve on the kept tag files", out.returncode == 0 and links,
               (out.stdout + out.stderr)[-400:])

    return report("The tag files")


if __name__ == "__main__":
    cli(main)
