//======================================================================================================================
//  Copacabana - Common CMake Package Tools
//  Copyright : Copacabana Project Contributors
//  SPDX-License-Identifier: BSL-1.0
//======================================================================================================================
// build error: example::type holds its values, it does not order them

#include <libexample/example.hpp>

static_assert(sizeof(example::type<int>) == 0, "example::type holds its values, it does not order them");

int main() { return 0; }
