#!/usr/bin/env python3
##======================================================================================================================
##  Copacabana - Common CMake Package Tools
##  Copyright : Copacabana Project Contributors
##  SPDX-License-Identifier: BSL-1.0
##======================================================================================================================
"""Draw the social card a link to a documentation site unfurls into.

The card is the project's logo with its name beside it, written in the dark shade of the theme, the colour
copa_setup_doxygen derives for --primary-dark-color. Pass the COLOR_HUE, COLOR_SATURATION and COLOR_LIGHTNESS
the CMakeLists.txt declares and the card comes out the colour of the pages.

Writing the SVG needs nothing installed. The PNG that unfurlers want comes from a converter, run here when one
is on the path:

    rsvg-convert card.svg -o card.png       # librsvg2-bin
    resvg card.svg card.png                 # resvg
    npx @resvg/resvg-js-cli card.svg card.png

Commit that PNG beside the Doxyfile, publish it with

    HTML_EXTRA_FILES      += card.png

and point head.html at it. Nothing reads it at build time, so the card changes when you ask for it.
"""
import argparse
import base64
import colorsys
import pathlib
import re
import shutil
import subprocess
import sys

WIDTH, HEIGHT, PADDING, GUTTER = 730, 382, 36, 48

## Below this, a dark theme writes its name in something too close to black to read as a colour.
MIN_LIGHTNESS = 25

## No text metrics without a font library, so the size comes from the widest a capital can be and still fit.
WIDEST_CAPITAL = 0.80
MAX_SIZE = 128

CONVERTERS = [
    ("rsvg-convert", lambda svg, png: ["rsvg-convert", str(svg), "-o", str(png)]),
    ("resvg", lambda svg, png: ["resvg", str(svg), str(png)]),
    ("inkscape", lambda svg, png: ["inkscape", str(svg), "--export-filename", str(png)]),
]


def dark_shade(hue, saturation, lightness):
    """The theme's --primary-dark-color, which is where the name is written."""
    red, green, blue = colorsys.hls_to_rgb(hue / 360, max(lightness - 20, MIN_LIGHTNESS) / 100, saturation / 100)
    return "#%02X%02X%02X" % (round(red * 255), round(green * 255), round(blue * 255))


def viewbox(text):
    """What the logo draws itself in, from its viewBox or, failing that, its width and height."""
    box = re.search(r'viewBox\s*=\s*"([\d.\-\s]+)"', text)
    if box:
        return tuple(float(value) for value in box.group(1).split())

    width = re.search(r'width\s*=\s*"([\d.]+)', text)
    height = re.search(r'height\s*=\s*"([\d.]+)', text)
    if not (width and height):
        raise SystemExit("the logo declares neither a viewBox nor a width and height")
    return 0.0, 0.0, float(width.group(1)), float(height.group(1))


def logo_of(path, side):
    """The logo, scaled into a square of that side at the card's padding, as something the card can carry."""
    data = path.read_bytes()

    if path.suffix.lower() != ".svg":
        return (f'<image x="{PADDING}" y="{PADDING}" width="{side}" height="{side}" '
                f'preserveAspectRatio="xMidYMid meet" '
                f'href="data:image/{path.suffix.lstrip(".")};base64,{base64.b64encode(data).decode()}"/>')

    text = data.decode()
    origin_x, origin_y, width, height = viewbox(text)
    scale = min(side / width, side / height)
    offset_x = PADDING + (side - width * scale) / 2
    offset_y = PADDING + (side - height * scale) / 2

    ## Its own <svg> element carries a size this card decides instead, so only what it draws is kept.
    inner = re.sub(r"^.*?<svg[^>]*>", "", text, count=1, flags=re.S)
    inner = re.sub(r"</svg>\s*$", "", inner, flags=re.S)
    return (f'<g transform="translate({offset_x:.2f},{offset_y:.2f}) scale({scale:.4f}) '
            f'translate({-origin_x:.2f},{-origin_y:.2f})">{inner}</g>')


def card(logo, name, hue, saturation, lightness):
    side = HEIGHT - 2 * PADDING
    text_x = PADDING + side + GUTTER
    size = min(int((WIDTH - text_x - PADDING) / (WIDEST_CAPITAL * len(name))), MAX_SIZE)

    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="{WIDTH}" height="{HEIGHT}"
     viewBox="0 0 {WIDTH} {HEIGHT}">
  <rect width="{WIDTH}" height="{HEIGHT}" fill="#FFFFFF"/>
  {logo_of(logo, side)}
  <text x="{text_x}" y="{HEIGHT // 2}" fill="{dark_shade(hue, saturation, lightness)}"
        font-family="DejaVu Sans, Verdana, sans-serif" font-weight="bold" font-size="{size}"
        letter-spacing="{size * 0.06:.1f}" dominant-baseline="central">{name}</text>
</svg>
'''


def rasterize(svg, png):
    """The PNG the unfurlers want, when something here can draw one."""
    for tool, command in CONVERTERS:
        if shutil.which(tool):
            subprocess.run(command(svg, png), check=True)
            return tool
    return None


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("logo", type=pathlib.Path, help="the project's logo, SVG or raster")
    parser.add_argument("name", help="what to write beside it, usually the project in capitals")
    parser.add_argument("--hue", type=int, default=220, help="COLOR_HUE, as declared to copa_setup_doxygen")
    parser.add_argument("--saturation", type=int, default=39, help="COLOR_SATURATION, likewise")
    parser.add_argument("--lightness", type=int, default=45, help="COLOR_LIGHTNESS, likewise")
    parser.add_argument("--output", type=pathlib.Path, default=pathlib.Path("card.svg"), help="where to write it")

    options = parser.parse_args()
    if not options.logo.exists():
        raise SystemExit(f"no logo at {options.logo}")

    options.output.write_text(card(options.logo, options.name, options.hue, options.saturation, options.lightness))
    print(f"{options.output} written")

    png = options.output.with_suffix(".png")
    tool = rasterize(options.output, png)
    if tool:
        print(f"{png} written, through {tool}")
    else:
        print(f"no converter found, so {png} is yours to make: see this script's header for the three that fit")


if __name__ == "__main__":
    sys.exit(main())
