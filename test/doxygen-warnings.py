#!/usr/bin/env python3
"""What the documentation workflow counts as a Doxygen warning, checked against what Doxygen writes.

The pattern is read out of the workflow rather than copied here, so the two cannot drift: a test holding
its own copy would keep passing after someone narrowed the real one.

  python3 test/doxygen-warnings.py <copacabana source directory>
"""
import pathlib
import re

from checks import cli, expect, report, run

WORKFLOW = ".github/workflows/documentation.yml"

# What doxygen actually writes, and whether the job has to count it. The first shape names a file and a line;
# the second is what it says about the configuration itself, with nothing in front of it.
LINES = [
    (True,  "/src/lib/thing.hpp:42: warning: Found unknown command '@tab_begin'"),
    (True,  "/src/lib/other.hpp:150: warning: Illegal command '@someone' found as part of a <a>..</a> block"),
    (True,  "/src/lib/third.hpp:7: error: Unexpected end of comment"),
    (True,  "warning: ignoring unsupported tag 'COPY_CLIPBOARD' at line 35, file doc/Doxyfile"),
    (True,  "warning: source '../nowhere' is not a readable file or directory... skipping."),
    (True,  "error: could not copy file build/doc/color.css to build/doc/.//color.css"),
    # Doxygen interleaves its progress output, so a message can arrive glued to the line before it.
    (True,  "Preprocessing /src/lib/error: could not copy file a to b"),
    (False, "Parsing file /src/lib/thing.hpp..."),
    (False, "Generating docs for compound lib::thing..."),
    (False, "Searching for documented variables..."),
    # A page may legitimately talk about warnings and errors without doxygen having emitted one.
    (False, "  * `is_error`: reports whether the operation failed"),
    (False, "Generating docs for page error_handling..."),
]
def pattern_from(workflow):
    """The grep -E pattern the job feeds doxygen.log, taken from the workflow itself."""
    text = pathlib.Path(workflow).read_text(encoding="utf-8")
    m = re.search(r"grep -E '([^']+)' doxygen\.log", text)
    if not m:
        raise SystemExit(f"  FAIL  no grep over doxygen.log found in {workflow}")
    return m.group(1)


def main(source):
    source = pathlib.Path(source).resolve()
    pattern = pattern_from(source / WORKFLOW)

    # Through grep itself rather than through python's re: what ships is a grep -E, and the two dialects differ.
    print(f"The pattern read from {WORKFLOW}: {pattern}\n")

    for wanted, line in LINES:
        found = run("grep", "-E", pattern, input=line + "\n").returncode == 0
        expect(f"{'counts' if wanted else 'ignores'}: {line}", found == wanted)

    return report("What the documentation job counts as a warning")


if __name__ == "__main__":
    cli(main)
