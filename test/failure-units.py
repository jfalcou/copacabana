#!/usr/bin/env python3
"""What copa_glob_failure_unit answers, checked by breaking the source it watches.

A check that only asks "did the build fail" goes green on a typo, a missing header or a renamed
include, and proves nothing about the diagnostic it exists to pin. This edits the example's
failure test three ways and reads the verdict each time.

  python3 test/failure-units.py <copacabana source directory>
"""
import pathlib
import re
import subprocess
import sys
import tempfile

SOURCE = "test/example/test/failure/clamp_needs_ordering.cpp"

failures = []


def ctest(build):
    out = subprocess.run(["ctest", "--test-dir", str(build), "-R", "failure", "--output-on-failure"],
                         capture_output=True, text=True)
    return out.returncode == 0, out.stdout + out.stderr


def main(source):
    source = pathlib.Path(source).resolve()
    watched = source / SOURCE
    original = watched.read_text(encoding="utf-8")

    with tempfile.TemporaryDirectory() as tmp:
        build = pathlib.Path(tmp, "build")
        out = subprocess.run(["cmake", "-S", f"{source}/test/example", "-B", str(build), "-G", "Ninja",
                              f"-DCPM_COPACABANA_SOURCE={source}"], capture_output=True, text=True)
        if out.returncode:
            print(f"  FAIL  the example does not configure\n{out.stderr}")
            return 1

        try:
            # As written, it must pass: the source does not compile, and says what it fails with.
            passed, _ = ctest(build)
            if not passed:
                failures.append("the failure test does not pass on the source as written")

            # Made to compile. The point of the check is that this is a failure, not a success.
            watched.write_text(original.replace("== 0", "!= 0"), encoding="utf-8")
            passed, log = ctest(build)
            if passed:
                failures.append("a source that compiles is accepted, and it must not be")
            elif "written to be rejected" not in log:
                failures.append("a source that compiles fails for an unclear reason")

            # Still fails, for the wrong reason. This is the case a bare WILL_FAIL would let through.
            watched.write_text(original.replace("libexample/example.hpp", "libexample/nowhere.hpp"),
                               encoding="utf-8")
            passed, log = ctest(build)
            if passed:
                failures.append("a source failing for another reason is accepted, and it must not be")
            elif "not for what it says" not in log:
                failures.append("a source failing for another reason fails for an unclear reason")

            # A source naming nothing cannot be checked, and saying so beats passing.
            watched.write_text(re.sub(r"^// build error:.*\n", "", original, flags=re.M), encoding="utf-8")
            passed, log = ctest(build)
            if passed:
                failures.append("a source naming no diagnostic is accepted, and it must not be")
            elif "says nothing it should fail with" not in log:
                failures.append("a source naming no diagnostic fails for an unclear reason")
        finally:
            watched.write_text(original, encoding="utf-8")

    for f in failures:
        print(f"  FAIL  {f}")
    print(f"{len(failures)} failure(s)")
    return 1 if failures else 0


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(2)
    sys.exit(main(sys.argv[1]))
