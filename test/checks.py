#!/usr/bin/env python3
"""One shape for what the meta checks print, how they run a command, and how they read their command line.

A check that says nothing when it passes leaves a reader with a green square and no idea what was looked at, which is
how a check that stopped looking goes unnoticed. Every check names itself, whether it holds or not, and the run ends
on a count plus a table in the job summary when GitHub is watching.
"""
import inspect
import os
import pathlib
import subprocess
import sys

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


def run(*command, **kwargs):
    """Run a command and hand back its result, with the output captured as text.

    The scripts read the return code themselves, so nothing here raises on a failure.
    """
    return subprocess.run(command, capture_output=True, text=True, **kwargs)


def cli(main):
    """Hand the command line to main and leave on what it gives back.

    How many arguments a script takes is read off main itself, and the module docstring is the usage message.
    """
    wanted = inspect.signature(main).parameters
    least = sum(1 for p in wanted.values() if p.default is p.empty)
    given = sys.argv[1:]

    if not least <= len(given) <= len(wanted):
        print(sys.modules["__main__"].__doc__ or "")
        sys.exit(2)

    sys.exit(main(*given))
