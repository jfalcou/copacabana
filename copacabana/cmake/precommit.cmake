##======================================================================================================================
##  Copacabana - Common CMake Package Tools
##  Copyright : Copacabana Project Contributors
##  SPDX-License-Identifier: BSL-1.0
##======================================================================================================================

##======================================================================================================================
## Setup pre-commit hooks setup targets
##======================================================================================================================
function(COPA_SETUP_PRECOMMIT_HOOKS)
  set(options QUIET)
  cmake_parse_arguments(OPT "${options}" "" "" ${ARGN} )

  if(EXISTS "${CMAKE_SOURCE_DIR}/.git")
    find_program(PRE_COMMIT_CMD NAMES pre-commit)

    if(PRE_COMMIT_CMD)
      add_custom_target ( setup-hooks
                          COMMAND ${PRE_COMMIT_CMD} install
                          WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
                          COMMENT "Installing pre-commit git hooks to ${CMAKE_SOURCE_DIR}/.git/hooks"
                          VERBATIM
                        )
    endif()

    if(EXISTS "${CMAKE_SOURCE_DIR}/.git/hooks/pre-commit")
      set(PRE_COMMIT_HOOKS_INSTALLED TRUE)
    else()
      set(PRE_COMMIT_HOOKS_INSTALLED FALSE)
    endif()

    if(NOT ${OPT_QUIET})
      if(NOT PRE_COMMIT_CMD OR NOT PRE_COMMIT_HOOKS_INSTALLED)
        message(STATUS "[${PROJECT_NAME}] -")
        message(STATUS "[${PROJECT_NAME}] - ==================================================================")
        message(STATUS "[${PROJECT_NAME}] -              ATTENTION: DEVELOPMENT ENVIRONMENT SETUP             ")
        message(STATUS "[${PROJECT_NAME}] - ==================================================================")

        if(NOT PRE_COMMIT_CMD)
          message(STATUS "[${PROJECT_NAME}] -   1. 'pre-commit' tool is NOT found on your system.")
          message(STATUS "[${PROJECT_NAME}] -     Please install it: 'pip install pre-commit' or 'brew install pre-commit'")
        else()
          message(STATUS "[${PROJECT_NAME}] -   1. 'pre-commit' tool is found.")
        endif()

        if(NOT PRE_COMMIT_HOOKS_INSTALLED)
          message(STATUS "[${PROJECT_NAME}] -   2. Git hooks are NOT active for this repo.")
          message(STATUS "[${PROJECT_NAME}] -     Run this command to fix it:")
          message(STATUS "[${PROJECT_NAME}] -     --------------------------------------------------")
          message(STATUS "[${PROJECT_NAME}] -     cmake --build . --target setup-hooks")
          message(STATUS "[${PROJECT_NAME}] -     --------------------------------------------------")
        endif()

        message(STATUS "[${PROJECT_NAME}] - ==================================================================")
        message(STATUS "[${PROJECT_NAME}] - ")
      endif()
    endif()
  endif()
endfunction()
