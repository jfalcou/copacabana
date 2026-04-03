##======================================================================================================================
##  Copacabana - Common CMake Package Tools
##  Copyright : Copacabana Project Contributors
##  SPDX-License-Identifier: BSL-1.0
##======================================================================================================================

##======================================================================================================================
## Setup Sanitizers for a given target
##======================================================================================================================
function(COPA_SETUP_SANITIZERS target)
  set(options ENABLE_ASAN ENABLE_UBSAN ENABLE_TSAN ENABLE_MSAN)
  cmake_parse_arguments(OPT "${options}" "" "" ${ARGN})

  set(SANITIZER_FLAGS "")

  if(CMAKE_CXX_COMPILER_ID MATCHES "Clang" OR CMAKE_CXX_COMPILER_ID MATCHES "GNU")
    if(${OPT_ENABLE_ASAN})
      list(APPEND SANITIZER_FLAGS "-fsanitize=address")
    endif()

    if(${OPT_ENABLE_UBSAN})
      list(APPEND SANITIZER_FLAGS "-fsanitize=undefined")
    endif()

    if(${OPT_ENABLE_TSAN})
      if(${OPT_ENABLE_ASAN})
        message(FATAL_ERROR "[${PROJECT_NAME}] - ThreadSanitizer (TSan) cannot be combined with AddressSanitizer (ASan)")
      endif()
      list(APPEND SANITIZER_FLAGS "-fsanitize=thread")
    endif()

    if(${OPT_ENABLE_MSAN})
      if(CMAKE_CXX_COMPILER_ID MATCHES "GNU")
        message(WARNING "[${PROJECT_NAME}] - MemorySanitizer (MSan) is only fully supported by Clang")
      endif()
      if(${OPT_ENABLE_ASAN})
        message(FATAL_ERROR "[${PROJECT_NAME}] - MemorySanitizer (MSan) cannot be combined with AddressSanitizer (ASan)")
      endif()
      list(APPEND SANITIZER_FLAGS "-fsanitize=memory")
    endif()
  elseif(CMAKE_CXX_COMPILER_ID MATCHES "MSVC")
    if(${OPT_ENABLE_ASAN})
      list(APPEND SANITIZER_FLAGS "/fsanitize=address")
    endif()
    if(${OPT_ENABLE_UBSAN} OR ${OPT_ENABLE_TSAN} OR ${OPT_ENABLE_MSAN})
      message(WARNING "[${PROJECT_NAME}] - MSVC currently only supports AddressSanitizer (ASan)")
    endif()
  endif()

  if(SANITIZER_FLAGS)
    target_compile_options(${target} INTERFACE ${SANITIZER_FLAGS})
    target_link_options(${target} INTERFACE ${SANITIZER_FLAGS})
    message(STATUS "[${PROJECT_NAME}] - Enabled sanitizers for target '${target}': ${SANITIZER_FLAGS}")
  endif()

endfunction()