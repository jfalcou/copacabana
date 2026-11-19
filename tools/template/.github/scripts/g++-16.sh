#!/bin/sh
##======================================================================================================================
##  SAMPLE - @brief@
##  Copyright : SAMPLE Project Contributors
##  SPDX-License-Identifier: BSL-1.0
##======================================================================================================================
## Sourced by the gcc16 row of the Linux matrix, so that the g++ of the gcc preset is GCC 16 rather than the default of
## the image.
mkdir -p /tmp/gcc16
ln -sf "$(command -v g++-16)" /tmp/gcc16/g++
export PATH="/tmp/gcc16:$PATH"
