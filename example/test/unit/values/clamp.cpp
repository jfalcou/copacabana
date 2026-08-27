//======================================================================================================================
//  Copacabana - Common CMake Package Tools
//  Copyright : Copacabana Project Contributors
//  SPDX-License-Identifier: BSL-1.0
//======================================================================================================================
#include <libexample/example.hpp>

int main()
{
  return !(example::clamp_to_value(2000) == 1337 && example::clamp_to_value(12) == 12);
}
