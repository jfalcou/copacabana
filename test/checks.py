#!/usr/bin/env python3
"""One shape for what the meta checks print.

A check that says nothing when it passes leaves a reader with a green square and no idea what was looked at, which is
how a check that stopped looking goes unnoticed. Every check names itself, whether it holds or not, and the run ends
on a count plus a table in the job summary when GitHub is watching.
"""
import os
import pathlib

_results = []


def expect(what, condition, saw=""):
    """Record and print one check. `saw` is what was found, shown only when the check fails."""
    ok = bool(condition)
    _results.append((what, ok, "" if ok else str(saw)))
    print(("  ok    " if ok else "  FAIL  ") + what + (f" - saw {saw}" if not ok and saw else ""))
    return ok


def failed():
    return [(what, saw) for what, ok, saw in _results if not ok]


def report(title):
    """Print the tally, write the summary GitHub renders, and give back the exit code to leave on."""
    bad = failed()
    print(f"\n{len(_results)} check(s), {len(bad)} failure(s)")

    summary = os.environ.get("GITHUB_STEP_SUMMARY")
    if summary:
        lines = [f"### {title}", "", "| | Check | Saw |", "|---|---|---|"]
        for what, ok, saw in _results:
            lines.append(f"| {'✅' if ok else '❌'} | {what} | {saw} |")
        lines.append("")
        lines.append(f"**{len(_results)} check(s), {len(bad)} failure(s)**")
        with pathlib.Path(summary).open("a", encoding="utf-8") as out:
            out.write("\n".join(lines) + "\n")

    return 1 if bad else 0
