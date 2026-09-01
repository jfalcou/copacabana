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
  //! @cond
  namespace _
  {
    template<typename T> struct storage : std::vector<T> {};
  }
  //! @endcond

  //! @brief A value and the storage the implementation picked for it
  template<typename T>
  struct type
  {
    //! The storage, whose type is not part of the public interface
    _::storage<T> data;
  };
}

#endif
