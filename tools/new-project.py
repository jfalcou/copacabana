#!/usr/bin/env python3
##======================================================================================================================
##  Copacabana - Common CMake Package Tools
##  Copyright : Copacabana Project Contributors
##  SPDX-License-Identifier: BSL-1.0
##======================================================================================================================
"""Create a repository that copacabana can build, test, document and package.

The tree under template/ is a working project called sample: it configures, builds, tests and documents, and the
hooks check it like any other tree, so it cannot rot unnoticed. Making a project from it renames sample to the name
asked for, in file contents and in path names alike.

What is not a name stays a placeholder - @brief@ and @remote@ - since a placeholder inside a comment or a string
leaves the file valid. A block between @if <flag>@ and @endif@, optionally with an @else@, is kept or dropped
according to that flag; the marker lines never reach the output.

Every option can come from a json file instead, so a project template of your own is one file rather than a command
line to remember:

    { "name": "mylib", "remote": "https://gitlab.example.org/team/mylib", "standalone": false, "presets": ["native"] }
"""

import argparse
import json
import re
import shutil
import sys
from pathlib import Path
from urllib.parse import urlparse

TEMPLATE = Path(__file__).resolve().parent / "template"

## Copied byte for byte: vendored upstream code has no business carrying our names.
VERBATIM = {"cmake/CPM.cmake"}

## What a preset group holds, so that a new project ships the handful it will use rather than the fleet's whole matrix.
PRESET_GROUPS = { "native": [ "gcc", "clang", "clang-macos", "msvc", "clangcl"
                            , "gcc-sanitize", "gcc-coverage", "clang-sanitize", "clang-coverage"
                            ]
                , "cross":  ["gcc-aarch64", "gcc-aarch64-sve", "gcc-aarch64-sve2", "gcc-ppc64", "wasm", "rvv128"]
                , "cuda":   ["nvcc", "clang-cuda"]
                , "intel":  ["icpx", "icpx-sycl"]
                }

## Only meaningful where the repository will actually live: GitHub Actions on GitHub, nothing on a plain git remote.
FORGE_ONLY = { "github": ["\\.github/"]
             , "gitlab": ["\\.gitlab-ci\\.yml$"]
             }


## The template is a working project named sample: it configures, it builds, and the hooks check it like any other
## tree, so it cannot rot unnoticed. Making one from it is a rename rather than a substitution.
SAMPLE = "sample"


def substitute(text: str, fields: dict[str, str]) -> str:
    text = text.replace(SAMPLE.upper(), fields["PROJECT"]).replace(SAMPLE, fields["project"])

    for key, value in fields.items():
        text = text.replace(f"@{key}@", value)

    return text


def resolve_blocks(text: str, flags: dict[str, bool]) -> str:
    """Keep or drop every @if <flag>@ ... [@else@ ...] @endif@ block, marker lines included."""
    pattern = re.compile(
        r"^[^\n]*@if (\w+)@[^\n]*\n(.*?)(?:^[^\n]*@else@[^\n]*\n(.*?))?^[^\n]*@endif@[^\n]*\n",
        re.S | re.M,
    )

    def choose(match: re.Match) -> str:
        flag, taken, otherwise = match.group(1), match.group(2), match.group(3) or ""
        return taken if flags.get(flag, False) else otherwise

    return pattern.sub(choose, text)


def select_presets(text: str, wanted: list[str]) -> str:
    """The presets file with only the groups asked for, the hidden ones they inherit from always kept."""
    document = json.loads(text)
    keep = {name for group in wanted for name in PRESET_GROUPS.get(group, [group])}

    for section in ("configurePresets", "buildPresets", "testPresets"):
        if section not in document:
            continue
        document[section] = [p for p in document[section] if p.get("hidden") or p["name"] in keep]

    return json.dumps(document, indent=2) + "\n"


def toolchains_of(presets: str) -> set[str]:
    """The toolchain files a preset document still points at, by name."""
    return set(re.findall(r"toolchain/([A-Za-z0-9._]+\.cmake)", presets))


def create(directory: Path, fields: dict[str, str], flags: dict[str, bool], presets: list[str], forge: str) -> int:
    if directory.exists() and any(directory.iterdir()):
        print(f"[copacabana] - {directory} exists and is not empty", file=sys.stderr)
        return 1

    dropped = [p for name, patterns in FORGE_ONLY.items() if name != forge for p in patterns]
    kept_toolchains = toolchains_of(select_presets((TEMPLATE / "CMakePresets.json").read_text(encoding="utf-8"), presets))
    written = 0

    for source in sorted(p for p in TEMPLATE.rglob("*") if p.is_file()):
        relative = str(source.relative_to(TEMPLATE))

        if any(re.search(p, relative) for p in dropped):
            continue

        # A preset the caller left out takes its toolchain file with it, rather than leaving a cross-compile
        # description behind for a target nothing in the project can be built for.
        if "test/toolchain/" in relative.replace("\\", "/") and source.name not in kept_toolchains:
            continue

        target = directory / substitute(relative, fields)
        target.parent.mkdir(parents=True, exist_ok=True)

        if relative in VERBATIM:
            shutil.copy(source, target)
            written += 1
            continue

        content = resolve_blocks(source.read_text(encoding="utf-8"), flags)

        if relative == "CMakePresets.json":
            content = select_presets(substitute(content, fields), presets)
        else:
            content = substitute(content, fields)

        # Dropping a conditional block leaves the blank line that followed it, which end-of-file-fixer then rewrites
        # on the first commit. Settle every file on exactly one trailing newline here, and none at all when it is
        # empty - a marker file like .nojekyll is meant to have no content.
        content = content.rstrip("\n")
        target.write_text(content + "\n" if content else "", encoding="utf-8")
        written += 1

    return 0 if written else 1


def forge_of(remote: str) -> str:
    host = urlparse(remote).netloc or remote
    return "github" if "github.com" in host else "gitlab" if "gitlab" in host else "none"


def settings(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("directory", nargs="?", help="Directory to create; its name is the project name by default")
    parser.add_argument("--config", help="Json file holding any of the options below")
    parser.add_argument("--name", help="Project name, when it differs from the directory name")
    parser.add_argument("--brief", help="One line describing what the project is")
    parser.add_argument("--remote", help="Required. Where the repository will live, as a url")
    parser.add_argument("--presets", help=f"Comma-separated groups or names ({', '.join(PRESET_GROUPS)}, default native)")
    parser.add_argument("--standalone", action="store_true", default=None, help="Ship the standalone header target")
    parser.add_argument("--no-standalone", dest="standalone", action="store_false", help="Leave the standalone out")
    args = parser.parse_args(argv)

    if args.config:
        stored = json.loads(Path(args.config).read_text(encoding="utf-8"))
        for key, value in stored.items():
            key = key.replace("-", "_")
            if getattr(args, key, None) in (None, False) or key == "presets":
                setattr(args, key, ",".join(value) if isinstance(value, list) else value)

    if not args.directory:
        parser.error("a directory is required, on the command line or as \"directory\" in the config")

    return args


def main(argv: list[str] | None = None) -> int:
    args = settings(argv if argv is not None else sys.argv[1:])

    directory = Path(args.directory)
    name = (args.name or directory.name).strip()

    ## The name reaches a namespace, a CMake target and an option prefix, so it has to be an identifier everywhere.
    if not re.fullmatch(r"[a-z][a-z0-9_]*", name):
        print(f"[copacabana] - '{name}' is not a usable name: lowercase, starting with a letter", file=sys.stderr)
        return 1

    ## No default: where a repository will live is not something this script can know, and a guess would put
    ## someone else's account in a generated project's documentation, CI and README.
    if not args.remote:
        print("[copacabana] - --remote is required: the url the repository will live at", file=sys.stderr)
        return 1

    remote = args.remote
    forge = forge_of(remote)
    presets = [p.strip() for p in (args.presets or "native").split(",") if p.strip()]
    standalone = True if args.standalone is None else args.standalone

    unknown = [p for p in presets if p not in PRESET_GROUPS]
    if unknown:
        print(f"[copacabana] - unknown preset group {', '.join(unknown)}", file=sys.stderr)

    path = urlparse(remote).path.strip("/")
    fields = { "project": name
             , "PROJECT": name.upper()
             , "owner":   path.rsplit("/", 1)[0] if "/" in path else name
             , "remote":  remote
             , "brief":   args.brief or "A C++20 library"
             , "standalone-needs": "standalone-generation, " if standalone else ""
             }

    if create(directory, fields, {"standalone": standalone}, presets, forge):
        return 1

    print(f"[copacabana] - {name} written to {directory}")
    print(f"[copacabana] -   remote {remote} ({forge})")
    print(f"[copacabana] -   presets {', '.join(presets)}, standalone {'on' if standalone else 'off'}")

    if forge == "none":
        print(f"[copacabana] -   no continuous integration written: {remote} is neither GitHub nor GitLab")

    return 0


if __name__ == "__main__":
    sys.exit(main())
