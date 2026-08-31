//======================================================================================================================
//  Copacabana - Common CMake Package Tools
//  Copyright : Copacabana Project Contributors
//  SPDX-License-Identifier: BSL-1.0
//======================================================================================================================
#ifndef EXAMPLE_HPP_INCLUDED
#define EXAMPLE_HPP_INCLUDED

#include <libexample/first.hpp>
#include <libexample/second.hpp>
#include <string>

namespace example
{
  inline const std::string version = "1.0.1";

  // Carries an actual branch, so the coverage report has something to measure
  template<typename T>
  constexpr T clamp_to_value(T x)
  {
    if(x > value<T>) return value<T>;
    return x;
  }
}

#endif
