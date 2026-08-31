//======================================================================================================================
/*
  SAMPLE - @brief@
  Copyright : SAMPLE Project Contributors
  SPDX-License-Identifier: BSL-1.0
*/
//======================================================================================================================
#include <iostream>

//@if standalone@
#if defined SAMPLE_STANDALONE
#include "sample.hpp"
#else
#include <sample/sample.hpp>
#endif
//@else@
#include <sample/sample.hpp>
//@endif@

int main()
{
  std::cout << "sample " << sample::version << "\n";

  return sample::version.empty() ? 1 : 0;
}
