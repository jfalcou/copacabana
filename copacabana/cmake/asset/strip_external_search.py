#!/usr/bin/env python3
##======================================================================================================================
##  Copacabana - Common CMake Package Tools
##  Copyright : Copacabana Project Contributors
##  SPDX-License-Identifier: BSL-1.0
##======================================================================================================================
"""Drop another project's symbols from the generated search index.

Reading a tagfile hands doxygen every symbol the other project documents, and they land in the search box.
No doxygen setting removes them: ALLEXTERNALS, EXTERNAL_GROUPS and EXTERNAL_PAGES leave the index alone.

  python3 strip_external_search.py <the generated search directory>
"""

import re
import sys
from pathlib import Path

## ['id',['name',['target',N,'context'],['target',N]]], context optional. operator[] carries brackets of its own,
## so targets are matched rather than brackets counted.
ENTRY = re.compile(r"^(\s*\['[^']*',\['[^']*',)(.*?)(\]\],?)$")
TARGET = re.compile(r"\['([^']*)',\s*\d+\s*(?:,\s*'[^']*')?,?\]")


def external(target: str) -> bool:
    return target.startswith("http://") or target.startswith("https://")


def strip(line: str) -> str | None:
    """The line without its external targets, or None when only external ones were in it."""
    match = ENTRY.match(line)
    if not match:
        return line

    head, body, tail = match.groups()
    targets = TARGET.findall(body)

    if not targets:
        return line
    if not any(external(t) for t in targets):
        return line
    if all(external(t) for t in targets):
        return None

    kept = [m.group(0) for m in TARGET.finditer(body) if not external(m.group(1))]

    return head + ",".join(kept) + tail


def main(directory: str) -> int:
    files = sorted(Path(directory).glob("*.js"))
    if not files:
        print(f"[copacabana] - no search index under {directory}", file=sys.stderr)
        return 1

    expunged = isolated = 0

    for path in files:
        out = []
        for line in path.read_text(encoding="utf-8").split("\n"):
            stripped = strip(line)
            if stripped is None:
                expunged += 1
            else:
                isolated += stripped != line
                out.append(stripped)

        ## Kept even when emptied: the search javascript loads every file by name.
        path.write_text("\n".join(out), encoding="utf-8")

    print(f"[copacabana] - search index: {expunged} entries expunged, {isolated} isolated")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1] if len(sys.argv) > 1 else "."))
