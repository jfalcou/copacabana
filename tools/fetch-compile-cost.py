#!/usr/bin/env python3
##======================================================================================================================
##  Copacabana - Common CMake Package Tools
##  Copyright : Copacabana Project Contributors
##  SPDX-License-Identifier: BSL-1.0
##======================================================================================================================
"""Bring back the compile cost measured at a commit, for the reader to open beside another.

Every run of compile-cost.yml attaches its CSV, and the artifact carries the commit it was measured at. Listing them
needs no token; downloading one does, which is what gh holds, so this asks gh rather than curl.

    python3 tools/fetch-compile-cost.py HEAD~5 main       # two commits, to compare
    python3 tools/fetch-compile-cost.py v8                # one, to read on its own
    python3 tools/fetch-compile-cost.py --list            # what is still there to ask for

A measurement lives 90 days when it was taken on main, 14 on a pull request, so an older commit answers nothing.
"""
import argparse
import io
import pathlib
import subprocess
import sys
import zipfile


def gh(*args, binary=False):
    """Run gh and hand back what it wrote, or None when it refused."""
    out = subprocess.run(["gh", *args], capture_output=True)
    if out.returncode:
        return None
    return out.stdout if binary else out.stdout.decode()


def repository():
    """owner/name of the repository the working directory belongs to."""
    said = gh("repo", "view", "--json", "nameWithOwner", "-q", ".nameWithOwner")
    return said.strip() if said else None


def measurements(repo):
    """Every compile cost artifact still downloadable, newest first."""
    said = gh("api", f"repos/{repo}/actions/artifacts?per_page=100", "--paginate",
              "-q", ".artifacts[] | select(.expired == false) | select(.name | test(\"compile-cost\")) |"
                    " [.id, .name, .workflow_run.head_sha, .workflow_run.head_branch, .created_at] | @tsv")
    if not said:
        return []
    return [line.split("\t") for line in said.splitlines() if line]


def resolve(ref):
    """The full SHA a reference names, or the reference itself when git does not know it."""
    out = subprocess.run(["git", "rev-parse", ref], capture_output=True, text=True)
    return out.stdout.strip() if out.returncode == 0 else ref


def fetch(repo, artifact_id, into):
    """Unpack the CSV of one artifact, and say where it landed."""
    blob = gh("api", f"repos/{repo}/actions/artifacts/{artifact_id}/zip", binary=True)
    if not blob:
        return None
    with zipfile.ZipFile(io.BytesIO(blob)) as z:
        names = [n for n in z.namelist() if n.endswith(".csv")]
        if not names:
            return None
        into.parent.mkdir(parents=True, exist_ok=True)
        into.write_bytes(z.read(names[0]))
    return into


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("refs", nargs="*", help="commits, branches or tags, one or two")
    ap.add_argument("--repo", help="owner/name, when not asking about the repository you are in")
    ap.add_argument("--into", default="compile-cost", help="where the CSV files are written")
    ap.add_argument("--list", action="store_true", help="show what is still downloadable")
    args = ap.parse_args()

    repo = args.repo or repository()
    if not repo:
        print("no repository: run this inside a clone, or name one with --repo", file=sys.stderr)
        return 2

    taken = measurements(repo)
    if not taken:
        print(f"{repo} has no compile cost measurement left to download", file=sys.stderr)
        return 1

    if args.list or not args.refs:
        print(f"{len(taken)} measurement(s) still there in {repo}\n")
        for _, name, sha, branch, when in taken:
            print(f"  {sha[:7]}  {when[:10]}  {branch or '?':24} {name}")
        return 0

    known = {sha: artifact for artifact, _, sha, _, _ in taken}
    written = []
    for ref in args.refs:
        sha = resolve(ref)
        ## A reference git does not know is still worth trying as the prefix it looks like, which is what --list
        ## prints and what someone reads off a run page.
        if sha not in known:
            near = [k for k in known if k.startswith(sha)]
            sha = near[0] if len(near) == 1 else sha
        if sha not in known:
            print(f"{ref} ({sha[:7]}) has no measurement left: it expired, or no run measured it", file=sys.stderr)
            continue
        into = pathlib.Path(args.into, f"{sha[:7]}.csv")
        if fetch(repo, known[sha], into):
            written.append(into)
            print(f"{ref} ({sha[:7]}) → {into}")

    if len(written) == 2:
        print(f"\nOpen compile-cost.html and drop {written[0]} as the measurement, {written[1]} as the baseline.")
    return 0 if written else 1


if __name__ == "__main__":
    sys.exit(main())
