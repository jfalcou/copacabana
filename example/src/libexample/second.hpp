//======================================================================================================================
//  Copacabana - Common CMake Package Tools
//  Copyright : Copacabana Project Contributors
//  SPDX-License-Identifier: BSL-1.0
//======================================================================================================================
#ifndef SECOND_HPP_INCLUDED
#define SECOND_HPP_INCLUDED

#include <vector>

namespace example
{
  template<typename T>
  struct type
  {
    std::vector<T*> data;
  };
}

#endif
