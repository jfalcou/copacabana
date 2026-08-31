//======================================================================================================================
//  Copacabana - Common CMake Package Tools
//  Copyright : Copacabana Project Contributors
//  SPDX-License-Identifier: BSL-1.0
//======================================================================================================================
#include <libexample/example.hpp>
#include <cstdio>

int main()
{
  example::type<int> x = {};
  x.data.resize(10);

  std::printf("%zu\n", x.data.size());

  return 0;
}