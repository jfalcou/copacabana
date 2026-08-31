# Copacabana's own shape, for both cmake-format and cmake-lint.
#
# Written in python rather than yaml: cmakelang does not depend on pyyaml, so a yaml config cannot be read from the
# isolated environment pre-commit builds for it.

with section("parse"):
  # CPMAddPackage is not a CMake command, so the formatter has no signature for it and treats every token as a
  # standalone positional argument - one per line, keyword and value split apart. Declaring the signature is what
  # lets it keep a keyword next to the value it introduces.
  additional_commands = {
      "cpmaddpackage": {
          "pargs": {"nargs": "*"},
          "kwargs": {
              "NAME": 1,
              "VERSION": 1,
              "GIT_TAG": 1,
              "GIT_REPOSITORY": 1,
              "GITHUB_REPOSITORY": 1,
              "GITLAB_REPOSITORY": 1,
              "BITBUCKET_REPOSITORY": 1,
              "SOURCE_DIR": 1,
              "SOURCE_SUBDIR": 1,
              "DOWNLOAD_ONLY": 1,
              "DOWNLOAD_COMMAND": 1,
              "FIND_PACKAGE_ARGUMENTS": 1,
              "NO_CACHE": 1,
              "SYSTEM": 1,
              "GIT_SHALLOW": 1,
              "EXCLUDE_FROM_ALL": 1,
              "CUSTOM_CACHE_KEY": 1,
              "URL": 1,
              "URL_HASH": 1,
              "OPTIONS": "*",
              "PATCHES": "*",
          },
      }
  }
  additional_commands["cpmfindpackage"] = additional_commands["cpmaddpackage"]
  additional_commands["cpmdeclarepackage"] = additional_commands["cpmaddpackage"]

with section("format"):
  # The formatter lowercases every command it emits, which would rename the calls to COPA_SETUP_COVERAGE and friends
  # while leaving the function() declaring them untouched - an API documented in one case and invoked in another.
  # CPMAddPackage has the same problem, in CPM's spelling rather than ours.
  command_case = "unchanged"

  line_width = 120
  tab_size = 2

with section("markup"):
  # The formatter reflows a comment block into a paragraph, which would run the three lines of the licence header
  # into one and take SPDX-License-Identifier out of the first column, where the scanners look for it.
  enable_markup = False
  canonicalize_hashrulers = False

with section("lint"):
  # The naming C0103 checks against, widened to what this project does rather than turned off: functions are declared
  # COPA_UPPERCASE and called copa_lowercase, and a local is uppercase like the directory-scope names around it. The
  # patterns left alone still hold - a macro and a CACHE variable have to be uppercase - and no name may open on a
  # digit.
  function_pattern = "[A-Za-z_][0-9A-Za-z_]*"
  local_var_pattern = "[A-Za-z_][0-9A-Za-z_]*"
  argument_var_pattern = "[A-Za-z_][0-9A-Za-z_]*"
