//======================================================================================================================
//  Copacabana - Common CMake Package Tools
//  Copyright : Copacabana Project Contributors
//  SPDX-License-Identifier: BSL-1.0
//======================================================================================================================
#if !defined( EXAMPLE_HPP_INCLUDED )
#define       EXAMPLE_HPP_INCLUDED
#endif
namespace example
{
  template<typename T>
  inline constexpr auto value = T{1337.42};
}
#if !defined( SECOND_HPP_INCLUDED )
#define       SECOND_HPP_INCLUDED
#endif
#include <vector>
namespace example
{
  template<typename T>
  struct type
  {
    std::vector<T*> data;
  };
}
namespace example
{
  inline constexpr auto version = "1.0.1";
}
