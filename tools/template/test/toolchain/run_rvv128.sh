#!/bin/sh
##======================================================================================================================
##  SAMPLE - @brief@
##  Copyright : SAMPLE Project Contributors
##  SPDX-License-Identifier: BSL-1.0
##======================================================================================================================
## Runs a test the rvv128 preset built. Do not replace the rva23u64 model by rv64,v=true: on qemu 10 that enables no
## RVV, and the first vector instruction raises SIGILL.
exec qemu-riscv64 --cpu rva23u64,zfh=false,zfhmin=false,zvfh=false,zvfhmin=false,vlen=128 "$@"
