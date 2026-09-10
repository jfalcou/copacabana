#!/usr/bin/env python3
"""What base.doxyfile and base.html are supposed to have produced, checked against a site it generates.

Read the output rather than the configuration: a setting can be right and still not reach the page, and what ships is
the page.

  python3 test/doxygen-setup.py <copacabana source directory>
"""
import collections
import colorsys
import pathlib
import re
import shutil
import tempfile

from checks import cli, expect, report, run


def inspect(out):
    out = pathlib.Path(out)
    index = (out / "index.html").read_text(encoding="utf-8")

    # The navigation menu is built at load time by doxygen's own menu.js, and it is what carries the button that
    # replaces the sidebar on a narrow screen. No menu.js, no way to navigate below 768px.
    expect("menu.js is generated", (out / "menu.js").is_file())
    expect("index.html loads menu.js", 'src="menu.js"' in index)
    expect("menu.js builds the hamburger", "main-menu-btn" in (out / "menu.js").read_text(encoding="utf-8")
           if (out / "menu.js").is_file() else False)

    # doxygen-awesome-sidebar-only overrides doxygen-awesome, so it only works after it. Reversed, the header renders
    # broken and nothing reports it.
    # head.html is copied into the generated head, and nothing is emitted without it. What has to hold either way
    # is that the placeholder never reaches the page: an unsubstituted @VAR@ in a <head> is invisible until someone
    # views the source, which is how the corner went two months pointing at a literal.
    expect("no placeholder survives into the head", "@COPA_" not in index)

    # The corner is the only link on the page that has to carry a value from outside doxygen, and doxygen expands
    # $(VAR) in a Doxyfile but never in a header. It read as a literal on every published site for two months.
    # There is no corner at all when the project said nowhere it lives, which is deliberate. What must not happen is
    # a corner carrying something other than a URL.
    corner = re.search(r'<a href="([^"]*)"[^>]*class="github-corner"', index)
    if corner:
        expect("the github corner links somewhere", corner.group(1).startswith("http"), corner.group(1))

    sheets = [pathlib.Path(h).name for h in re.findall(r'<link[^>]*href="([^"]+\.css)"', index)]
    awesome = [s for s in sheets if s.startswith("doxygen-awesome")]
    expect("both awesome stylesheets are linked", len(awesome) == 2, str(awesome))
    expect("sidebar-only comes after doxygen-awesome",
           awesome == ["doxygen-awesome.css", "doxygen-awesome-sidebar-only.css"], str(awesome))

    # The godbolt button reads what copa_setup_doxygen declared rather than what a header hard-coded.
    config = out / "godbolt-config.js"
    expect("godbolt-config.js is generated", config.is_file())
    if config.is_file():
        text = config.read_text(encoding="utf-8")
        for name in ("GODBOLT_LIBRARIES", "GODBOLT_COMPILER", "GODBOLT_OPTIONS"):
            expect(f"{name} is defined", re.search(rf"const {name}\s*=", text) is not None)
    expect("index.html loads it before godbolt.js",
           index.find("godbolt-config.js") < index.find('src="godbolt.js"') if "godbolt.js" in index else False)

    # filter.py rewrites the detail namespace before doxygen parses it, so none of it can reach a page. A leak here
    # means the filter did not run at all.
    pages = list(out.glob("*.html"))
    expect("pages were generated", len(pages) > 1, f"{len(pages)} page(s)")
    leaks = [p.name for p in pages if re.search(r"\b_::\w", p.read_text(encoding="utf-8"))]
    expect("no detail namespace reaches a page", not leaks, ", ".join(leaks))

    # doxygen tints the widgets it generates, doxygen-awesome reads its own hsl() variables, and the two used to be
    # written by hand in two files they drift, and the stylesheet is what the reader sees.
    css = (out / "color.css").read_text(encoding="utf-8") if (out / "color.css").is_file() else ""
    declared = re.search(r"hsl\(\s*(\d+)", css)
    expect("color.css is generated and names a hue", declared is not None)
    if declared:
        wanted = int(declared.group(1))
        hues = collections.Counter()
        for hex6 in re.findall(r"#([0-9a-fA-F]{6})", (out / "doxygen.css").read_text(encoding="utf-8")):
            r, g, b = (int(hex6[i:i + 2], 16) for i in (0, 2, 4))
            hue, _, sat = colorsys.rgb_to_hls(r / 255, g / 255, b / 255)
            if sat > 0.05:
                hues[round(hue * 360)] += 1
        seen = hues.most_common(1)[0][0] if hues else None
        expect(f"doxygen is tinted the hue color.css asks for ({wanted})",
               seen is not None and abs(seen - wanted) <= 2, f"{seen}")

    # The panel doxygen puts on the right of every page, which this fleet does not want.
    expect("no page outline panel", "PageOutline" not in index and 'id="page-nav"' not in index)


def main(root: str = ".") -> int:
    """Generate the example documentation, then read what came out."""
    root = pathlib.Path(root).resolve()

    with tempfile.TemporaryDirectory() as tmp:
        out = run("cmake", "-S", f"{root}/test/example", "-B", tmp, "-G", "Ninja",
                  f"-DCPM_COPACABANA_SOURCE={root}", "-DEXAMPLE_BUILD_TEST=OFF",
                  "-DEXAMPLE_BUILD_DOCUMENTATION=ON")
        if not expect("the example configures for documentation", out.returncode == 0, out.stderr[-300:]):
            return report("What the shared Doxygen setup produced")

        out = run("cmake", "--build", tmp, "--target", "example-doxygen")
        if not expect("doxygen runs", out.returncode == 0, out.stderr[-300:]):
            return report("What the shared Doxygen setup produced")

        site = pathlib.Path(tmp, "doxygen-output")
        inspect(site)
        expect("the godbolt configuration reaches the pages", (site / "godbolt-config.js").exists())

        ## Everything a page loads has to come back from a build alone: what only generate time writes is lost the
        ## first time the output is cleaned, and the button disappears with nothing saying so.
        shutil.rmtree(site)
        out = run("cmake", "--build", tmp, "--target", "example-doxygen")
        expect("doxygen runs again on a cleaned output", out.returncode == 0, out.stderr[-300:])
        expect("the godbolt configuration comes back", (site / "godbolt-config.js").exists())

    return report("What the shared Doxygen setup produced")


if __name__ == "__main__":
    cli(main)
