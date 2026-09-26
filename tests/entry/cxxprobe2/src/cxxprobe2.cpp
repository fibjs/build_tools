/*
 * Second C++ library of the self test tree: the same standard check as the
 * first one, because a regression in the flag handling can leave every library
 * behind the first entry of libs.cmake compiled with the compiler defaults.
 */

#include <compare>
#include <string>

#if defined(_MSVC_LANG)
#define FIBJS_SELFTEST_STANDARD _MSVC_LANG
#else
#define FIBJS_SELFTEST_STANDARD __cplusplus
#endif

#if FIBJS_SELFTEST_STANDARD < 202002L
#error "the C++20 standard of the tree did not reach this library (the base flags must reach every library of libs.cmake)"
#endif

int cxxprobe2_value()
{
    std::string text("cxxprobe2");

    return text.size() == 9 ? 7 : -1;
}
