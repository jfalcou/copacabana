# Copacabana's own shape, for both cmake-format and cmake-lint.
#
# Written in python rather than yaml: cmakelang does not depend on pyyaml, so a yaml config cannot be read from the
# isolated environment pre-commit builds for it.

with section("format"):
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
