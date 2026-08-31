@page examples Some Code Examples

@section injection Sample code with Godbolt.org injection

```c++
#include <fmt/core.h>

int main()
{
  fmt::print("Hello World! This is the number {}\n", 77);
  return 8;
}
```

@section error Sample code with compilation error

@code{cpp}
#include <fmt/core.h>

int main()
{
  fmt::print("Hello World! This is the number {}\n", 77);
  erturn 0;
}
@endcode

