##======================================================================================================================
##  Copacabana - Common CMake Package Tools
##  Copyright : Copacabana Project Contributors
##  SPDX-License-Identifier: BSL-1.0
##======================================================================================================================

##======================================================================================================================
## Setup pre-commit hooks setup targets
##======================================================================================================================
function(copa_setup_precommit_hooks)
  set(options QUIET)
  cmake_parse_arguments(OPT "${options}" "" "" ${ARGN})

  copa_check_arguments()

  ## Do not go on in a nested project: it is a dependency, and the banner and the target belong to the project being
  ## worked on.
  if(NOT PROJECT_IS_TOP_LEVEL)
    return()
  endif()

  ## A tree with no .git is a tarball, which is how the package managers build: there is no hook to install there and
  ## nothing to say about it.
  if(EXISTS "${PROJECT_SOURCE_DIR}/.git")
    find_program(PRE_COMMIT_CMD NAMES pre-commit)

    ## Named whether or not the target gets created, the advice below spelling it out either way.
    string(TOLOWER "${PROJECT_NAME}" PROJECT_NAME_LOWER)
    set(HOOK_TARGET "${PROJECT_NAME_LOWER}-setup-hooks")

    if(PRE_COMMIT_CMD)
      add_custom_target(
        "${HOOK_TARGET}"
        COMMAND ${PRE_COMMIT_CMD} install
        WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
        COMMENT "Installing the pre-commit git hooks of ${PROJECT_SOURCE_DIR}"
        VERBATIM)
    endif()

    ## Do not look under .git/hooks: in a worktree .git is a file, and the hooks are in the main checkout, or in the
    ## directory core.hooksPath names.
    execute_process(
      COMMAND git rev-parse --path-format=absolute --git-path hooks/pre-commit
      WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}"
      OUTPUT_VARIABLE HOOK_FILE
      OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)

    if(EXISTS "${HOOK_FILE}")
      set(PRE_COMMIT_HOOKS_INSTALLED TRUE)
    else()
      set(PRE_COMMIT_HOOKS_INSTALLED FALSE)
    endif()

    ## The banner is advice for someone at a keyboard: a runner has no reader and starts the next job from a
    ## clean machine. GitHub sets CI on every runner.
    if(NOT OPT_QUIET AND NOT DEFINED ENV{CI})
      if(NOT PRE_COMMIT_CMD OR NOT PRE_COMMIT_HOOKS_INSTALLED)
        message(STATUS "[${PROJECT_NAME}] -")
        message(STATUS "[${PROJECT_NAME}] - ==================================================================")
        message(STATUS "[${PROJECT_NAME}] -              ATTENTION: DEVELOPMENT ENVIRONMENT SETUP             ")
        message(STATUS "[${PROJECT_NAME}] - ==================================================================")

        if(NOT PRE_COMMIT_CMD)
          message(STATUS "[${PROJECT_NAME}] -   1. 'pre-commit' tool is NOT found on your system.")
          message(STATUS "[${PROJECT_NAME}] -     Install it: 'pip install pre-commit' or 'brew install pre-commit'")
        else()
          message(STATUS "[${PROJECT_NAME}] -   1. 'pre-commit' tool is found.")
        endif()

        if(NOT PRE_COMMIT_HOOKS_INSTALLED)
          message(STATUS "[${PROJECT_NAME}] -   2. Git hooks are NOT active for this repo.")

          if(PRE_COMMIT_CMD)
            message(STATUS "[${PROJECT_NAME}] -     Run this command to fix it:")
            message(STATUS "[${PROJECT_NAME}] -     --------------------------------------------------")
            message(STATUS "[${PROJECT_NAME}] -     cmake --build . --target ${HOOK_TARGET}")
            message(STATUS "[${PROJECT_NAME}] -     --------------------------------------------------")
          else()
            message(STATUS "[${PROJECT_NAME}] -     Install pre-commit, configure again, and the target")
            message(STATUS "[${PROJECT_NAME}] -     '${HOOK_TARGET}' will be there to run.")
          endif()
        endif()

        message(STATUS "[${PROJECT_NAME}] - ==================================================================")
        message(STATUS "[${PROJECT_NAME}] - ")
      endif()
    endif()
  endif()
endfunction()
