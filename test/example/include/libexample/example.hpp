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
  namespace _
  {
    template<typename T> struct storage : std::vector<T> {};
  }
  template<typename T>
  struct type
  {
    _::storage<T> data;
  };
}
#include <string>
namespace example
{
  inline const std::string version = "1.0.1";
  template<typename T>
  constexpr T clamp_to_value(T x)
  {
    if(x > value<T>) return value<T>;
    return x;
  }
}
#endif
