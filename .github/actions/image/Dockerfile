##======================================================================================================================
##  Copacabana - Common CMake Package Tools
##  Copyright : Copacabana Project Contributors
##  SPDX-License-Identifier: BSL-1.0
##======================================================================================================================
## The image of a project: a base image, what the setup script of the project adds to it, the project installed from
## the checkout, and what its finish script does before the sources go. The action beside this file builds it.
##======================================================================================================================
ARG BASE=ghcr.io/jfalcou/compilers:v11
FROM ${BASE}

ARG PROJECT
ARG SOURCE
LABEL org.opencontainers.image.source="${SOURCE}"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

## Do not move this step after the COPY of the sources: its layer would be rebuilt at every commit.
COPY --from=setup . /tmp/setup/
RUN   if [ -f /tmp/setup/setup.sh ]; then bash /tmp/setup/setup.sh; fi                                       \
  &&  rm -rf /tmp/setup

RUN   useradd --user-group --create-home --no-log-init --shell /bin/bash "${PROJECT}"

COPY . /src

ARG CMAKE_ARGS=""
ARG FINISH=""

RUN   NAME="${PROJECT^^}"                                                                                     \
  &&  cmake -S /src -B /tmp/build -G Ninja "-D${NAME}_BUILD_TEST=OFF" "-D${NAME}_BUILD_DOCUMENTATION=OFF"     \
            ${CMAKE_ARGS}                                                                                     \
  &&  cmake --install /tmp/build                                                                              \
  &&  if [ -n "${FINISH}" ]; then cd /src && COPA_HOME="/home/${PROJECT}" bash "${FINISH}"; fi              \
  &&  chown -R "${PROJECT}:${PROJECT}" "/home/${PROJECT}"                                                     \
  &&  rm -rf /tmp/build /src

USER ${PROJECT}
WORKDIR /home/${PROJECT}
