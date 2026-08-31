//======================================================================================================================
/*
  SAMPLE - @brief@
  Copyright : SAMPLE Project Contributors
  SPDX-License-Identifier: BSL-1.0
*/
//======================================================================================================================
#include <sample/sample.hpp>

#include <iostream>

int main()
{
  std::cout << "sample " << sample::version << "\n";

  return sample::version.empty() ? 1 : 0;
}
