# Copacabana's own shape, so that the linter reports what is wrong rather than what is deliberate.
#
# Written in python rather than yaml: cmakelang does not depend on pyyaml, so a yaml config cannot be read from the
# isolated environment pre-commit builds for it.

with section("format"):
  line_width = 120
  tab_size = 2

with section("lint"):
  # C0103 - functions are declared COPA_UPPERCASE and called copa_lowercase throughout, on purpose.
  # C0111 - a COMMENT on a property says nothing its name does not.
  # C0113 - same, for a custom target or command.
  # C0307 - arguments are aligned under the opening parenthesis, which is the shape of every module here.
  disabled_codes = ["C0103", "C0111", "C0113", "C0307"]
  max_statements = 70
  max_branches = 20
