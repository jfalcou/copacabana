#!/usr/bin/env python3
##======================================================================================================================
##  Copacabana - Common CMake Package Tools
##  Copyright : Copacabana Project Contributors
##  SPDX-License-Identifier: BSL-1.0
##======================================================================================================================
"""Check the standalone header embed.py writes, on a tree of two headers.

    python3 test/standalone.py <copacabana source directory>

The main header holds its license, its guard, and a doxygen block before its first include. The included one holds
comments of every form, and the literals a comment marker can sit in: strings, a raw string, a character, digit
separators, and the /**/ that ends a multi-line macro.
"""
import pathlib
import subprocess
import sys
import tempfile

from checks import cli, expect, report, run

MAIN = """//==========
/*
  LIB - the license
*/
//==========
#ifndef LIB_HPP_INCLUDED
#define LIB_HPP_INCLUDED
//==========
//! @namespace lib
//! @brief The namespace of the library
//==========
#include <lib/detail.hpp>
#endif
"""

DETAIL = """// The detail header
#ifndef LIB_DETAIL_HPP_INCLUDED
#define LIB_DETAIL_HPP_INCLUDED
#define LIB_TWICE(X) X + X                                                        \\
/**/
namespace lib
{
  /* a block comment
     on two lines */
  inline constexpr auto url    = "https://example.org/a//b"; // a trailing comment
  inline constexpr auto opener = "/* no comment here */";
  inline constexpr auto quoted = R"(<a href="//x">//</a>)";
  inline constexpr char slash  = '/';
  inline constexpr auto big    = 1'000; /* a short block */ inline constexpr int after = 1;
  inline constexpr int  twice  = LIB_TWICE(2);
}
#endif
"""

KEPT = ['"https://example.org/a//b"', '"/* no comment here */"', 'R"(<a href="//x">//</a>)"', "'/'", "1'000;",
        "after = 1", "LIB - the license"]

GONE = ["@namespace", "The detail header", "a block comment", "on two lines", "a trailing comment", "a short block",
        "LIB_DETAIL_HPP_INCLUDED"]


def main(root: str = ".") -> int:
    root = pathlib.Path(root).resolve()

    with tempfile.TemporaryDirectory() as tmp:
        include = pathlib.Path(tmp, "include")
        (include / "lib").mkdir(parents=True)
        (include / "lib" / "lib.hpp").write_text(MAIN, encoding="utf-8")
        (include / "lib" / "detail.hpp").write_text(DETAIL, encoding="utf-8")
        header = pathlib.Path(tmp, "standalone.hpp")

        out = run(sys.executable, str(root / "copacabana/cmake/asset/embed.py"), str(include / "lib" / "lib.hpp"),
                  "-I", str(include), "-o", str(header), "--include-match", "lib/.*")
        if not expect("embed.py writes the header", out.returncode == 0, out.stderr[-300:]):
            return report("The standalone header")

        text = header.read_text(encoding="utf-8")
        for kept in KEPT:
            expect(f"the header keeps {kept}", kept in text, text[-400:])
        for gone in GONE:
            expect(f"the header drops {gone}", gone not in text, text[-400:])

        unit = pathlib.Path(tmp, "use.cpp")
        unit.write_text('#include "standalone.hpp"\nstatic_assert(lib::twice == 4 && lib::after == 1);\n',
                        encoding="utf-8")
        compiled = subprocess.run(["c++", "-std=c++20", "-fsyntax-only", str(unit)], capture_output=True, text=True,
                                  cwd=tmp)
        expect("a unit including the header compiles", compiled.returncode == 0, compiled.stderr[-400:])

    return report("The standalone header")


if __name__ == "__main__":
    cli(main)
