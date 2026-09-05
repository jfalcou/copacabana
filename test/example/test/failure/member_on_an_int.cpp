//======================================================================================================================
//  Copacabana - Common CMake Package Tools
//  Copyright : Copacabana Project Contributors
//  SPDX-License-Identifier: BSL-1.0
//======================================================================================================================
// build error-gcc: which is of non-class type
// build error-clang: is not a structure or union
// build error-msvc: left of '.clear' must have class/struct/union

int main()
{
  int i = 1;
  i.clear();
}
