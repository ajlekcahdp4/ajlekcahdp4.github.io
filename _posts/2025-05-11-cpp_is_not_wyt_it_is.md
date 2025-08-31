---
icon: fas fa-info-circle
title: C++ is not what you think it is
description: >-
  All hail C++ (or not)
author: alexander
date: 2025-07-28 11:05:00 +0300
categories: [C++, languages]
tags: [cpp, languages]
toc: true
---

I started my path as a C++ developer several years ago and for
a while I was living in the "C++ bubble" as one could say.  Primarily talking to other people
learning and doing C++ daily. But lately I started talking more and more to non-C++
developers and was shocked by the general consensus about what type of language C++ is. I am
not just saying that common stereotypes are wrong. I am saying that modern C++ is a completely
different language than others consider it to be. And the problems C++ programmers have might
be not what you think they are.

# History
C++ started as C with classes giving its users capability for better encapsulation and
abstraction while remaining backwards compatible with C. The possibility of writing classes
and templates allowed programmers to think at a higher level of abstraction and still know
what kind of machine code will be generated. The things programmers were often worried about however
generally remained the same: allocate memory, do the thing, deallocate. During the next 20 years
language was gradually evolving. People started to understand
template metaprogramming, and an amazing standard library was developed during that time.

Since 2011 C++'s speed of evolution drastically increased and the way a C++ program
looks and feels started to change. Since 2011 C++ standard committee started a
regular 3-year release process. Which means that every 3 years users were getting newer useful
features in both the language itself and its standard library. Over the past 14 years and through 5
(soon to be 6) new C++ standards accumulated changes truly transformed the language. With
introduction of lambdas, constexpr functions, ranges, smart pointers (about which I'll talk
later) and many other features the way a tipical C++ program looks changed drastically. Instead
of generic C with a higher level of abstractions programmers now have a powerful language with
great explicitness and safety. Yes, I am saying that C++ is indeed safe (dangerous but safe).
Let's discuss some of the most powerful features of the modern C++.

# Standard containers and smart pointers
In any discussion about C++ it is inevitable to hear about memory safety issues and why "you
should use rust" (great language btw). The common issues that public (as well as US
[Government](https://www.cisa.gov/resources-tools/resources/product-security-bad-practices))
has with C++ is that it is "easy" to get memory vulnerabilities such as memory leaks or uninitialized
value reads/writes. However I argue that this relates to the old C++ and much less to the
modern one. I am sure that you've probably already heard this argument but here were are.

## Smart pointers
Let's say you want to allocate a variable of type `Widget` on the heap (e.g. you are writing
a factory function). This is how you would do it in C:

```cpp
struct Widget *factory() {
  struct Widget *w = (struct Widget *)malloc(sizeof(struct Widget));
  assert(w);
  // Initialize w here
  return w;
}
```
{% include alert.html type="note" content="My friend asked me to mention that you'd also use typedef on Widget. Thank you, Alex." %}

Returning a raw pointer has obvious downsides. For the user of this function it is unclear,
who owns this object, should he call free later and whether he can get a `NULL` pointer from it. If he should free the object, he might forget to do so. The problem here arises from pointers being too generic types. They can be used for every type of storage and ownership. C++ solves this problem since C++11 standard by introducing smart pointers. In an unlikely case you never heard of them, I'll give two examples. Let us again consider our factory function. If one were to write an API that gives exclusive ownership of widgets to the caller, it would have a signature containing `std::unique_ptr`:

```cpp
std::unique_ptr<Widget> factory();
```

Now user can clearly see that this function returns a pointer with exclusive ownership of the underlying object (it can be destroyed when not needed) and he doesn't have to worry much about its lifetime as it will live as long as `unique_ptr` exists. Now he also doesn't have to worry about deallocating memory as the smart pointer will take care of it.

Now let's consider the case where our factory is a class that internally stores pointers to all created widgets (for internal access and management) and discards them later. In C such a data structure would return the same pointer to the widget making it hard for users of the API to reason about ownership. Now let's see how it can be done in C++:

```cpp
class Application {
  std::vector<std::shared_ptr<Widget>> Widgets;
 public:
  std::shared_ptr<Widget> factory();
};
```

And from this signature users will see that the ownership of the widget is not exclusive, so they shouldn't destroy the object when not needed. Users still have no worries about the lifetime as the widget will live at least as long as their `shared_ptr` does. And, as a bonus, users still won't worry about memory deallocation as `shared_ptr` will take care of that when both client and `Application` class won't need it anymore.

## Containers
Let's now say that you want to allocate an array on the heap (because the size of it is unknown at compile time) and initialize it with value 1. Let's see how one would do it in C:

```cpp
  int *arr = (int *)malloc(size * sizeof(int));
  assert(arr);
  for (unsigned i = 0; i < size; ++i)
    arr[i] = 1;
```

Here you have the same problems with memory allocation and deallocation that we discussed above but also we now have to worry about out-of-bounds accesses and initialization. As I showed before, memory management aspects of this problem can be solved with smart pointers. But that's not all. I'd say that with how good standard containers are and how many third-party library exist you don't even have to use smart pointers that often. Memory handling is usually already done for you by standard and third-party libraries. Situations where you have to use smart pointers other than having a container full of `unique_ptr`s (for dynamic polymorphism or pimpl pattern) are very rare. I've only seen a handful of really good applications for `shared_ptr`. For 90% of the tasks containers are enough. And that means that as a modern C++ developer you only worry about memory management about 5-10% of the time (and even then smart pointers handle most of the tasks): mostly when you are writing dynamically polymorphic code with inheritance, some kind of pimpl pattern or when you are writing your own containers. Let's see how we can solve our case with a dynamic array using a standard container. For this trivial example `std::vector` is enough:

```cpp
  std::vector<int> arr (size, 1);
```

This line will both, allocate enough memory and initialize it with value 1.

All of the examples above were a very simple demonstration of how C++ allows you to think less about memory management and more about business logic, which is what most of us want.

# Lifetime management
Object lifetime is something many beginners struggle with. It's not hard
to get a dangling reference or pointer. C++ compilers have a limited number of warnings that
can help you find the most obvious bugs. However that clearly isn't enough to catch most of
them. Object lifetime is a very important topic to learn for every C++ developer. And I cannot
say that you don't have to think about it because you do. However not all the time. I'd say
that in 95% of situations, the objects you are working with have very clear lifetime scope and
anyone who has somewhat decent C++ experience will understand object's lifetime and won't make bugs. Of
course 95% is not enough. And there we can talk about an excellent set of tools that check
lifetime-based UB for you in a very efficient way. Tools like valgrind and sanitizers
are great at their job and won't allow you to leak some memory or access freed memory.

Let's take a look at the example. If as a beginner C++ programmer you heard that lifetime of a temporary object can be extended by binding to a constant reference and take this phrase literally, you might write something like this:

```cpp
#include <iostream>

struct A {
    int value;
    A(int v) : value(v) {}
};

const A &create_a(int x) {
    A a (x);
    return a;
}

int main() {
    auto &ref = create_a(5);
    std::cout << ref.value << '\n';
}
```

Here `create_a` function returns a reference to a local variable, which is destroyed during return so this reference is dangling and the behaviour of the program is undefined. However in such a trivial UB case every compiler I [tried](https://godbolt.org/z/9G7j5MnnE) (Including gcc, clang and MSVC) caught this error and produced a nice warning. But let's say you are a weird person who does not use `-Werror` flag to treat warnings as errors and doesn't even read his warnings, redirecting all of the compiler output to `/dev/null`. By executing this program you can get any result printed on the screen or none at all, get a Segmentation fault or no error at all. With clang I got zero printed on the screen and everything seemed fine:

```sh
❯ ./main
0
```
Let's now use some of the tools available for C++ developers to debug and diagnose the problem. First, we will use a sanitizer, which is a library you link with to diagnose memory access issues, UB or multithread issues. Sanitizers are great tools that you should ideally use in your regular builds (perhaps nightly or weekly) to catch problems in the first place, other than use them for debugging. First, we recompile our executable with address and UB sanitizers. Then, after launching it we will get a crash report:

```
❯ clang++ main.cpp -o main -fsanitize=address,undefined
main.cpp:11:12: warning: reference to stack memory associated with local variable 'a' returned [-Wreturn-stack-address]
   11 |     return a;
❯ ./main
=================================================================
==8365==ERROR: AddressSanitizer: stack-use-after-return on address 0x7f6b91900020 at pc 0x5634c25d2229 bp 0x7ffe45a1e580 sp 0x7ffe45a1e578
READ of size 4 at 0x7f6b91900020 thread T0
    #0 0x5634c25d2228  (/tmp/lifetime/main+0x16f228)
    #1 0x7f6b9382a4d7  (/nix/store/q4wq65gl3r8fy746v9bbwgx4gzn0r2kl-glibc-2.40-66/lib/libc.so.6+0x2a4d7) (BuildId: 3938ea5fdb2ce18cf9de6ebbd07b2ed43407cf53)
    #2 0x7f6b9382a59a  (/nix/store/q4wq65gl3r8fy746v9bbwgx4gzn0r2kl-glibc-2.40-66/lib/libc.so.6+0x2a59a) (BuildId: 3938ea5fdb2ce18cf9de6ebbd07b2ed43407cf53)
    #3 0x5634c248f344  (/tmp/lifetime/main+0x2c344)

Address 0x7f6b91900020 is located in stack of thread T0 at offset 32 in frame
    #0 0x5634c25d1fc7  (/tmp/lifetime/main+0x16efc7)

  This frame has 1 object(s):
    [32, 36) 'a' <== Memory access at offset 32 is inside this variable
HINT: this may be a false positive if your program uses some custom stack unwind mechanism, swapcontext or vfork
      (longjmp and C++ exceptions *are* supported)
SUMMARY: AddressSanitizer: stack-use-after-return (/tmp/lifetime/main+0x16f228)
Shadow bytes around the buggy address:
  0x7f6b918ffd80: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
  0x7f6b918ffe00: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
  0x7f6b918ffe80: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
  0x7f6b918fff00: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
  0x7f6b918fff80: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
=>0x7f6b91900000: f5 f5 f5 f5[f5]f5 f5 f5 00 00 00 00 00 00 00 00
  0x7f6b91900080: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
  0x7f6b91900100: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
  0x7f6b91900180: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
  0x7f6b91900200: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
  0x7f6b91900280: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
Shadow byte legend (one shadow byte represents 8 application bytes):
  Addressable:           00
  Partially addressable: 01 02 03 04 05 06 07
  Heap left redzone:       fa
  Freed heap region:       fd
  Stack left redzone:      f1
  Stack mid redzone:       f2
  Stack right redzone:     f3
  Stack after return:      f5
  Stack use after scope:   f8
  Global redzone:          f9
  Global init order:       f6
  Poisoned by user:        f7
  Container overflow:      fc
  Array cookie:            ac
  Intra object redzone:    bb
  ASan internal:           fe
  Left alloca redzone:     ca
  Right alloca redzone:    cb
==8365==ABORTING
```

Now it is clear that we have a problem. Diagnostincs point to stack use after return in `main` function with variable 'a' that was created at line 10.

# Ranges
Indices and iterators are both great ways to iterate over containers. However, they do
lack in expressiveness. That's one of the reasons why C++ now has standard ranges which allow you
to safely iterate, filter and modify over container without thinking about out-of-bounds accesses
and indirections. You can easily combine them with each other without performance loss (due to
their lazy nature). With ranges modern C++ programmers have a great power of explicitness and
highly reduced probavility of out-of-bounds access or dereferencing past the end iterator.

To demonstrate my point I want to take a look at the task of iterating over every 2 consecutive elements of std::vector which values are positive. Below is the best solution I could write that does not include ranges.


```cpp
#include <vector>
#include <algorithm>
#include <iostream>
#include <iterator>

void do_the_thing(int first, int second) {
  std::cout << first << " " << second << '\n';
}

int main() {
  std::vector<int> arr {1, 2, -3, 4, 5, 6, -7, -8, 9, -10, -11};
  auto is_positive = [](int e) { return e > 0; };
  auto first = std::find_if(arr.begin(), arr.end(), is_positive);
  for (;first != arr.end();) {
    auto second = std::find_if(std::next(first), arr.end(), is_positive);
    if (second == arr.end()) break;
    do_the_thing(*first, *second);
    first = std::find_if(std::next(second), arr.end(), is_positive);
  }
}
```

This works ([as far as I know](https://godbolt.org/z/EvKorG64f)). But the code is a mess. It becomes hard to reason about iterators even in such small example. I myself in fact got an out-of-bounds access the first time I wrote it. Let's not imagine more complex cases (such as iterating over each 5 or more elements). Let's now take a look at how you might do it with C++23 ranges:

```cpp
#include <iostream>
#include <iterator>
#include <vector>
#include <ranges>

void do_the_thing(int first, int second) {
  std::cout << first << " " << second << '\n';
}

namespace views = std::views;
namespace ranges = std::ranges;
int main() {
  std::vector<int> arr {1, 2, -3, 4, 5, 6, -7, -8, 9, -10, -11};
  auto is_positive = [](int e) { return e > 0; };
  for (auto &&chunk : arr | views::filter(is_positive) | views::chunk(2)) {
    auto first = std::next(chunk.begin());
    if (first == chunk.end()) break;
    do_the_thing(*chunk.begin(), *first);
  }
}
```

This still [works](https://godbolt.org/z/8oTK1PGYr). And now the code is easy to understand. Here we first filter our array for positive numbers and then view each elements by the chunks of size 2. Next we check for the last chunk that might have less than 2 elements and handle every other chunk. It is now effortless to reason about this code and change it as we wish.

# Error handling
Since the creation of the language exceptions are the primary error handling method in C++. They
are easy to throw and it is impossible to forget to check them. However, I do get people who
prefer error values to exceptions. And sometime you don't have a choice. You might be working
on LLVM or any other codebase with disabled exceptions. You might be writing a C API that should
never throw an exception. If you meet any of these criteria, don't worry, you don't have to fall
back to integer return codes or errno. C++ has a nice std::expected for you. It is both easy to
use and memory efficient.

Let's return to the factory example. We've already established that it will return `unique_ptr` on success. Now we will handle possible errors. For that we will use `std::expected` with errors represented by `std::string`:

```cpp
#include <iostream>
#include <expected>
#include <utility>
#include <memory>
#include <string>
#include <cassert>

class widget {};

void add_widget_to_app(std::unique_ptr<widget> w) {
    // Some implementation
}

std::expected<std::unique_ptr<widget>, std::string> factory(int x, int y) {
    if (x < 0) return std::unexpected("x should be greater than or equal to zero");
    if (y < 0) return std::unexpected("y should be greater than or equal to zero");
    return std::make_unique<widget>();
}

int main() {
    auto r = factory(1, 1);
    assert(r.has_value());
    add_widget_to_app(std::move(*r));
    r = factory(-1, 1);
    if (!r.has_value())
        std::cerr << "error: " << r.error() << '\n';
    else
        ass_widget_to_app(std::move(*r));
}
```

This example [works great](https://godbolt.org/z/cnsea11e9), code looks clean and can be used in environments without exceptions or anywhere you see fit.

# Conclusion
In all of those paragraphs I truly hope I managed to convince you that C++ is
very rapidly changing language and some of your assumptions might be wrong. So
you might consider to learn and use this wonderful language in your future
projects if it fits.
