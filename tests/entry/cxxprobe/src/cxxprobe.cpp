/*
 * Payload of the C++ self test library.
 *
 * Everything below encodes a failure that a build of the vender tree hits when
 * the base flags of the tree (build_tools/cmake/option_flags.cmake) do not
 * reach every library:
 *
 *   * v8 refuses to compile without C++20 ("C++20 or later required"), and the
 *     C++20 headers of an older libstdc++ (10) fail on their own as well
 *     ("no member named '__bit_width' in namespace 'std'" from <charconv>), so
 *     the standard is checked first;
 *   * a cross build has to be compiled for the architecture it was asked for -
 *     the target triple and the sysroot are part of the base flags, and without
 *     them the compiler silently emits code for the host;
 *   * <compare>/<span>/<bit> are the headers the bundled fallback
 *     (patch/cxx20/10) provides for toolchains that lack them, and the fallback
 *     must not shadow the headers of a toolchain that has them (the fallback
 *     <concepts> redefines what libstdc++ 10 already has in C++20 mode).
 *
 * The executable in test/ checks the values at run time, tests/run.sh reports
 * the architecture and the standard that were compiled in.
 */

#include <charconv>
#include <compare>
#include <string>

#if defined(_MSVC_LANG)
#define SELFTEST_STANDARD _MSVC_LANG
#else
#define SELFTEST_STANDARD __cplusplus
#endif

#if SELFTEST_STANDARD < 202002L
#error "the C++20 standard of the tree did not reach this library"
#endif

#if defined(__has_include)
#if __has_include(<version>)
#include <version>
#endif
#if defined(__cpp_lib_span) && __has_include(<span>)
#include <span>
#define SELFTEST_HAVE_SPAN 1
#endif
#endif

/* The architecture the compiler emits code for.  The ids have to match the ones
 * cxxprobe/CMakeLists.txt assigns to BUILD_ARCH. */
#if defined(_M_X64) || defined(__x86_64__)
#define SELFTEST_ARCH_ID 1
#elif defined(_M_IX86) || defined(__i386__)
#define SELFTEST_ARCH_ID 2
#elif defined(_M_ARM64) || defined(__aarch64__)
#define SELFTEST_ARCH_ID 3
#elif defined(_M_ARM) || defined(__arm__)
#define SELFTEST_ARCH_ID 4
#elif defined(__mips64)
#define SELFTEST_ARCH_ID 5
#elif defined(__powerpc64__) || defined(__ppc64__)
#define SELFTEST_ARCH_ID 6
#elif defined(__riscv) && __riscv_xlen == 64
#define SELFTEST_ARCH_ID 7
#elif defined(__loongarch64) || defined(__loongarch__)
#define SELFTEST_ARCH_ID 8
#else
#define SELFTEST_ARCH_ID 0
#endif

#if !defined(SELFTEST_ARCH_ID_EXPECTED)
#error "cxxprobe/CMakeLists.txt did not pass the architecture of this build"
#endif

#if SELFTEST_ARCH_ID != SELFTEST_ARCH_ID_EXPECTED
#error "the build was asked for another architecture: the base flags, the target triple among them, did not reach this library"
#endif

namespace {

struct probe_pair
{
    int a;
    int b;

    auto operator<=>(const probe_pair&) const = default;
};

} // namespace

const char* cxxprobe_arch_name(int id)
{
    switch (id) {
    case 1:
        return "x64";
    case 2:
        return "ia32";
    case 3:
        return "arm64";
    case 4:
        return "arm";
    case 5:
        return "mips64";
    case 6:
        return "ppc64";
    case 7:
        return "riscv64";
    case 8:
        return "loong64";
    default:
        return "unknown";
    }
}

std::string cxxprobe_arch()
{
    return cxxprobe_arch_name(SELFTEST_ARCH_ID);
}

std::string cxxprobe_expected_arch()
{
    return cxxprobe_arch_name(SELFTEST_ARCH_ID_EXPECTED);
}

std::string cxxprobe_standard()
{
    return std::to_string(SELFTEST_STANDARD);
}

int cxxprobe_value()
{
    probe_pair low { 1, 2 };
    probe_pair high { 3, 4 };

    if (!(low < high) || (low <=> high) != std::strong_ordering::less)
        return -1;

#if defined(SELFTEST_HAVE_SPAN)
    int values[] = { 1, 2, 3 };
    /* The (iterator, count) constructor is the one the bundled fallback header
     * has as well. */
    std::span<int> view(values, 3);

    if (view.size() != 3)
        return -2;
#endif

    char buffer[8] = { 0 };
    auto result = std::to_chars(buffer, buffer + sizeof(buffer), 42);

    if (result.ec != std::errc() || std::string(buffer, result.ptr) != "42")
        return -3;

    return 42;
}
