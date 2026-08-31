#!/usr/bin/env python3
"""What base.doxyfile and base.html are supposed to have produced, checked against a generated site.

Read the output rather than the configuration: a setting can be right and still not reach the page, and what ships is
the page. Run it on the directory copa_setup_doxygen wrote:

  python3 test/doxygen-setup.py <doxygen output directory>
"""
import pathlib
import re
import sys

failures = []


def expect(what, condition, saw=""):
    if not condition:
        failures.append(f"{what}{' - saw ' + saw if saw else ''}")


def main(out):
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

    # The panel doxygen puts on the right of every page, which this fleet does not want.
    expect("no page outline panel", "PageOutline" not in index and 'id="page-nav"' not in index)

    for f in failures:
        print(f"  FAIL  {f}")
    print(f"{len(failures)} failure(s)")
    return 1 if failures else 0


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(2)
    sys.exit(main(sys.argv[1]))
