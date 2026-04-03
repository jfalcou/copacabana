@page examples Some Code Examples

## Sample code with Godbolt.org injection

@code
#include <fmt/core.h>

int main()
{
  fmt::print("Hello World! This is the number {}\n", 77);
  return 8;
}
@endcode

## Sample code with compilation error

@code
#include <fmt/core.h>

int main()
{
  fmt::print("Hello World! This is the number {}\n", 77);
  erturn 0;
}
@endcode

