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
import subprocess
import sys
from pathlib import Path
from urllib.parse import urlparse

TEMPLATE = Path(__file__).resolve().parent / "template"

## Copied byte for byte: vendored upstream code has no business carrying our names.
VERBATIM = {"cmake/CPM.cmake"}

## Written only when the flag is on: the publisher of the standalone branch has nothing to publish otherwise.
FLAG_ONLY = { "standalone": [r"^\.github/workflows/package-standalone\.yml$"] }

## What a preset group holds, so that a new project ships the handful it will use rather than the fleet's whole matrix.
PRESET_GROUPS = { "native": [ "gcc", "clang", "clang-macos", "msvc", "clangcl"
                            , "gcc-sanitize", "gcc-coverage", "clang-sanitize", "clang-coverage", "clang-compile-cost"
                            ]
                , "cross":  ["gcc-aarch64", "gcc-aarch64-sve", "gcc-aarch64-sve2", "gcc-ppc64", "wasm", "rvv128"]
                , "cuda":   ["nvcc", "clang-cuda"]
                , "intel":  ["icpx", "icpx-sycl"]
                }

## The shared workflows a job of ci.yml calls from copacabana, and the presets each builds with: a job goes when one of
## its presets was left out, as a job calling a workflow that was not written does.
REMOTE_PRESETS = { "sanitizers.yml": {"gcc-sanitize", "clang-sanitize"}
                 , "coverage.yml":   {"gcc-coverage"}
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
    """The presets file with only the groups asked for, and every preset they inherit from."""
    document = json.loads(text)
    keep = {name for group in wanted for name in PRESET_GROUPS.get(group, [group])}

    by_name = {p["name"]: p for p in document.get("configurePresets", [])}
    pending = list(keep)
    while pending:
        parents = by_name.get(pending.pop(), {}).get("inherits", [])
        for parent in [parents] if isinstance(parents, str) else parents:
            if parent not in keep:
                keep.add(parent)
                pending.append(parent)

    for section in ("configurePresets", "buildPresets", "testPresets"):
        if section not in document:
            continue
        document[section] = [p for p in document[section] if p.get("hidden") or p["name"] in keep]

    return json.dumps(document, indent=2) + "\n"


def toolchains_of(presets: str) -> set[str]:
    """The toolchain files a preset document still points at, by name."""
    return set(re.findall(r"toolchain/([A-Za-z0-9._]+\.cmake)", presets))


def preset_names(presets: str) -> set[str]:
    """The presets a document declares, hidden ones aside, since nothing is ever asked for by their name."""
    document = json.loads(presets)
    return {p["name"] for p in document.get("configurePresets", []) if not p.get("hidden")}


def presets_of(workflow: str) -> set[str]:
    """The presets a workflow asks to be built with. Quoted or not, both spellings appear in the template."""
    return set(re.findall(r"""preset:\s*["']?([A-Za-z0-9._-]+)["']?""", workflow))


def prune_matrix(workflow: str, alive: set[str]) -> str:
    """Drop the matrix rows naming a preset the caller left out.

    A workflow keeps its file as long as one of its presets survived, and the rows for the others would each ask to be
    built with a preset the project does not declare.
    """
    kept = [line for line in workflow.split("\n")
            if not (line.lstrip().startswith("- {") and (named := presets_of(line)) and not (named & alive))]
    return "\n".join(kept)


def prune_jobs(workflow: str, gone: set[str]) -> str:
    """Drop the jobs calling a workflow, or reading a matrix, that was not written, then the needs entries naming a
    job that is gone.

    A job removed by a conditional block leaves its name behind in every needs list that mentions it, and a
    workflow whose jobs depend on one that does not exist is refused before a single job starts.
    """
    kept, dropped = [], set()

    for block in re.split(r"\n(?=  [A-Za-z0-9_-]+:\n)", workflow):
        called = re.findall(r"(?:uses:\s*(?:\.|jfalcou/copacabana)/\.github/workflows/|file:\s*\.github/matrices/)"
                            r"([A-Za-z0-9._-]+)", block)
        if set(called) & gone:
            name = re.match(r"\n?  ([A-Za-z0-9_-]+):", block)
            dropped.add(name.group(1) if name else "")
            continue
        kept.append(block)

    text = "\n".join(kept)
    # The keys of the triggers sit at the same indent as the jobs, so the jobs are read after `jobs:` alone.
    jobs = text.split("\njobs:\n", 1)[-1]
    declared = set(re.findall(r"^  ([A-Za-z0-9_-]+):$", jobs, re.M)) - dropped

    def needs(match: re.Match) -> str:
        names = [n.strip() for n in match.group(1).split(",")]
        alive = [n for n in names if n in declared]
        return f"needs: [{', '.join(alive)}]" if alive else ""

    return re.sub(r"needs:\s*\[([^\]]*)\]", needs, text)


def pin_copacabana(text: str, ref: str) -> str:
    """Both pins of copacabana on one commit: every `uses:` of a shared workflow, and the GIT_TAG of its fetch."""
    text = re.sub(r"(jfalcou/copacabana/\S+)@main\b", rf"\1@{ref}", text)
    return re.sub(r"(CPMAddPackage\(NAME COPACABANA [^)]*GIT_TAG )main\)", rf"\g<1>{ref})", text)


def is_script(path: Path) -> bool:
    return path.suffix == ".sh"


def template_files() -> list[Path]:
    """The files of the template git knows, untracked ones included and ignored ones left out, so that a build tree
    under the template never reaches a project. Outside a checkout, every file under it."""
    listed = subprocess.run(["git", "-C", str(TEMPLATE), "ls-files", "-z", "--cached", "--others",
                             "--exclude-standard"], capture_output=True, text=True)
    if listed.returncode == 0 and listed.stdout:
        return sorted(p for p in (TEMPLATE / name for name in set(listed.stdout.split("\0")) if name) if p.is_file())
    return sorted(p for p in TEMPLATE.rglob("*") if p.is_file())


def create(directory: Path, fields: dict[str, str], flags: dict[str, bool], presets: list[str], forge: str) -> int:
    if directory.exists() and any(directory.iterdir()):
        print(f"[copacabana] - {directory} exists and is not empty", file=sys.stderr)
        return 1

    # Written beside the directory and renamed once complete, so that a failure leaves nothing a second run refuses.
    partial = directory.parent / f".{directory.name}.partial"
    shutil.rmtree(partial, ignore_errors=True)
    try:
        written = write(partial, fields, flags, presets, forge)
    except BaseException:
        shutil.rmtree(partial, ignore_errors=True)
        raise

    if directory.exists():
        directory.rmdir()
    partial.rename(directory)
    reformat(directory)
    return 0 if written else 1


def write(directory: Path, fields: dict[str, str], flags: dict[str, bool], presets: list[str], forge: str) -> int:
    """Write the project into directory, and give back how many files it holds."""
    directory.mkdir(parents=True)

    dropped = [p for name, patterns in FORGE_ONLY.items() if name != forge for p in patterns]
    # A file that only makes sense with a flag on goes with the flag, whole: a conditional block would leave an
    # empty workflow behind, which GitHub refuses as it does a job that needs a name nothing declares.
    dropped += [p for flag, patterns in FLAG_ONLY.items() if not flags.get(flag, False) for p in patterns]
    selected = select_presets((TEMPLATE / "CMakePresets.json").read_text(encoding="utf-8"), presets)
    kept_toolchains = toolchains_of(selected)
    alive = preset_names(selected)

    # A workflow, or a matrix file, whose every preset was left out has nothing left to build, so it goes the way of
    # the toolchain files above, and prune_jobs takes the job that called it out of ci.yml.
    gone = { candidate.name
             for folder in ("workflows", "matrices")
             for candidate in (TEMPLATE / ".github" / folder).glob("*.yml")
             if (named := presets_of(candidate.read_text(encoding="utf-8"))) and not (named & alive)
           }
    unmet = {name for name, needed in REMOTE_PRESETS.items() if not needed <= alive}
    written, text_written = 0, None

    # A script goes with the file that names it, the runner of a toolchain with its toolchain file and the setup of a
    # matrix row with its row, so the scripts come last.
    for source in sorted(template_files(), key=is_script):
        relative = str(source.relative_to(TEMPLATE))

        if any(re.search(p, relative) for p in dropped):
            continue

        if is_script(source):
            if text_written is None:
                text_written = "\n".join(p.read_text(encoding="utf-8", errors="ignore")
                                         for p in directory.rglob("*") if p.is_file())
            if source.name not in text_written:
                continue

        # A preset the caller left out takes its toolchain file with it, rather than leaving a cross-compile
        # description behind for a target nothing in the project can be built for.
        if not is_script(source) and "test/toolchain/" in relative.replace("\\", "/") \
           and source.name not in kept_toolchains:
            continue

        if source.name in gone and re.search(r"\.github/(workflows|matrices)", relative.replace("\\", "/")):
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
        elif re.search(r"\.github/(workflows|matrices)", relative.replace("\\", "/")):
            content = prune_matrix(substitute(content, fields), alive)
            if source.name == "ci.yml":
                content = prune_jobs(content, gone | unmet)
            if source.name == "documentation.yml" and "coverage.yml" in unmet:
                content = content.replace("coverage: true", "coverage: false")
        else:
            content = substitute(content, fields)

        content = pin_copacabana(content, fields["copacabana"])

        # Dropping a conditional block leaves the blank line that followed it, which end-of-file-fixer then rewrites
        # on the first commit. Settle every file on exactly one trailing newline here, and none at all when it is
        # empty - a marker file like .nojekyll is meant to have no content.
        content = content.rstrip("\n")
        target.write_text(content + "\n" if content else "", encoding="utf-8")
        shutil.copymode(source, target)
        written += 1

    return written


def reformat(directory: Path) -> None:
    """Lay out the CMake that was written the way the hooks the project ships would.

    The name reaches nearly every line, so what fits in the width for one project overflows for the next, and no
    hand-written template can be right for every name. Done here when cmake-format is on the path, and left for the
    first `pre-commit run` when it is not, since asking for it to be installed to make a project would be steep.
    """
    if not shutil.which("cmake-format"):
        return

    written = [str(p) for p in directory.rglob("*.cmake")] + [str(p) for p in directory.rglob("CMakeLists.txt")]
    written = [p for p in written if "CPM.cmake" not in p]

    if written:
        subprocess.run(["cmake-format", "-i", *written], check=False, capture_output=True)


def copacabana_head() -> str:
    """The head of copacabana's main, or of the checkout this script runs from when the remote cannot be read."""
    listed = subprocess.run(["git", "ls-remote", "https://github.com/jfalcou/copacabana", "refs/heads/main"],
                            capture_output=True, text=True, timeout=60)
    if listed.returncode == 0 and listed.stdout.split():
        return listed.stdout.split()[0]
    local = subprocess.run(["git", "-C", str(TEMPLATE), "rev-parse", "HEAD"], capture_output=True, text=True)
    print("[copacabana] - the head of copacabana could not be read, the pins name this checkout's commit",
          file=sys.stderr)
    return local.stdout.strip()


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
    parser.add_argument("--presets",
                        help=f"Comma-separated groups or names ({', '.join(PRESET_GROUPS)}, default native)")
    parser.add_argument("--standalone", action="store_true", default=None, help="Ship the standalone header target")
    parser.add_argument("--no-standalone", dest="standalone", action="store_false", help="Leave the standalone out")
    parser.add_argument("--copacabana-ref",
                        help="Commit of copacabana both pins name, the head of its main by default")

    # The file only sets defaults, so that whatever the command line says wins.
    config = parser.parse_known_args(argv)[0].config
    if config:
        known = {action.dest for action in parser._actions} - {"help", "config"}
        defaults = {}
        for key, value in json.loads(Path(config).read_text(encoding="utf-8")).items():
            dest = key.replace("-", "_")
            if dest not in known:
                parser.error(f"{config}: unknown key {key!r}")
            if dest == "standalone" and not isinstance(value, bool):
                parser.error(f"{config}: standalone takes true or false, not {value!r}")
            defaults[dest] = ",".join(value) if isinstance(value, list) else value
        parser.set_defaults(**defaults)

    args = parser.parse_args(argv)

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

    ## The integration tests clone <remote>.git, and a runner holds no key for an ssh address.
    remote = args.remote.rstrip("/").removesuffix(".git")
    if urlparse(remote).scheme != "https":
        print(f"[copacabana] - --remote takes an https url, not {args.remote}", file=sys.stderr)
        return 1

    forge = forge_of(remote)
    presets = [p.strip() for p in (args.presets or "native").split(",") if p.strip()]
    standalone = True if args.standalone is None else args.standalone

    known = set(PRESET_GROUPS) | preset_names((TEMPLATE / "CMakePresets.json").read_text(encoding="utf-8"))
    unknown = [p for p in presets if p not in known]
    if unknown:
        print(f"[copacabana] - unknown preset {', '.join(unknown)}", file=sys.stderr)
        return 1

    ref = args.copacabana_ref or copacabana_head()
    if not re.fullmatch(r"[0-9a-f]{40}", ref):
        print(f"[copacabana] - '{ref}' is not a full commit of copacabana: pass --copacabana-ref", file=sys.stderr)
        return 1

    fields = { "project":    name
             , "PROJECT":    name.upper()
             , "remote":     remote
             , "brief":      args.brief or "A C++20 library"
             , "copacabana": ref
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
