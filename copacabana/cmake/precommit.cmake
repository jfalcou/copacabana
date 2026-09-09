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

  ## A tree with no .git is a tarball, which is how the package managers build: there is no hook to install there and
  ## nothing to say about it.
  if(EXISTS "${CMAKE_SOURCE_DIR}/.git")
    find_program(PRE_COMMIT_CMD NAMES pre-commit)

    ## Named whether or not the target gets created, the advice below spelling it out either way.
    string(TOLOWER "${PROJECT_NAME}" PROJECT_NAME_LOWER)
    set(HOOK_TARGET "${PROJECT_NAME_LOWER}-setup-hooks")

    if(PRE_COMMIT_CMD)
      add_custom_target(
        "${HOOK_TARGET}"
        COMMAND ${PRE_COMMIT_CMD} install
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        COMMENT "Installing pre-commit git hooks to ${CMAKE_SOURCE_DIR}/.git/hooks"
        VERBATIM)
    endif()

    if(EXISTS "${CMAKE_SOURCE_DIR}/.git/hooks/pre-commit")
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
