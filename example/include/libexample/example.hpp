//======================================================================================================================
//  Copacabana - Common CMake Package Tools
//  Copyright : Copacabana Project Contributors
//  SPDX-License-Identifier: BSL-1.0
//======================================================================================================================
#ifndef EXAMPLE_HPP_INCLUDED
#define EXAMPLE_HPP_INCLUDED
namespace example
{
  template<typename T>
  inline constexpr auto value = T(1337.42);
}
#include <vector>
namespace example
{
  template<typename T>
  struct type
  {
    std::vector<T*> data;
  };
}
#include <string>
namespace example
{
  inline const std::string version = "1.0.1";
}
#endif
