//======================================================================================================================
//  Copacabana - Common CMake Package Tools
//  Copyright : Copacabana Project Contributors
//  SPDX-License-Identifier: BSL-1.0
//======================================================================================================================
#include <libexample/example.hpp>
#include <iostream>

int main()
{
  example::type<int> x;
  x.data.resize(10);

  std::cout << x.data.size() << "\n";
  return 0;
}
