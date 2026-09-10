#!/usr/bin/env python3
"""What cpack puts in a system package, checked on the ones the example produces.

The job this replaces printed dpkg-deb and rpm output and passed on whatever they said, so a package
that had lost its headers or its cmake config went through green. This reads the two archives and
says what is inside them.

  python3 test/system-installers.py <copacabana source directory>
"""
import pathlib
import tempfile

from checks import cli, expect, report, run

VERSION = "1.2.3a"
INSTALLED = ["include/libexample/example.hpp", "include/libexample/first.hpp",
             "include/libexample/second.hpp", "share/example/example-config.cmake"]


def build_packages(source, build):
    """Configure the example without its tests and run the package target."""
    out = run("cmake", "-S", f"{source}/test/example", "-B", str(build), "-G", "Ninja",
              f"-DCPM_COPACABANA_SOURCE={source}", "-DEXAMPLE_BUILD_TEST=OFF")
    if out.returncode:
        return out.stderr
    out = run("cmake", "--build", str(build), "--target", "package")
    return out.stderr if out.returncode else ""


def one(build, suffix):
    found = sorted(build.glob(f"*{suffix}"))
    return found[0] if found else None


def main(source: str = ".") -> int:
    source = pathlib.Path(source).resolve()

    with tempfile.TemporaryDirectory() as tmp:
        build = pathlib.Path(tmp, "build")
        failed = build_packages(source, build)
        if not expect("the example packages itself", not failed, failed[-400:]):
            return report("What cpack put in the packages")

        deb, rpm, tgz = one(build, ".deb"), one(build, ".rpm"), one(build, ".tar.gz")
        for what, package in (("a deb", deb), ("an rpm", rpm), ("a tarball", tgz)):
            expect(f"cpack writes {what}", package is not None)
        if not (deb and rpm):
            return report("What cpack put in the packages")

        fields = run("dpkg-deb", "-f", str(deb), "Package", "Version", "Maintainer", "Depends").stdout
        expect("the deb names the project", "Package: example" in fields, fields)
        expect(f"the deb carries {VERSION}", f"Version: {VERSION}" in fields, fields)
        expect("the deb keeps the declared dependencies", "libfmt-dev (>= 10.1.1)" in fields, fields)

        listed = run("dpkg-deb", "-c", str(deb)).stdout
        for path in INSTALLED:
            expect(f"the deb holds {path}", path in listed)

        described = run("rpm", "-qpi", str(rpm)).stdout
        expect("the rpm names the project", "Name        : example" in described, described[:200])
        expect(f"the rpm carries {VERSION}", VERSION in described, described[:200])

        needs = run("rpm", "-qpR", str(rpm)).stdout
        expect("the rpm keeps the declared dependencies", "fmt-devel >= 10.1.1" in needs, needs)

        listed = run("rpm", "-qpl", str(rpm)).stdout
        for path in INSTALLED:
            expect(f"the rpm holds {path}", path in listed)

    return report("What cpack put in the packages")


if __name__ == "__main__":
    cli(main)
