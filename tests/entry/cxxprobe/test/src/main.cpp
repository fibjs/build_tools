/*
 * Payload of the C++ self test executable: it links the library under test and
 * reports what the build actually compiled for, which is what the CI log is
 * needed for otherwise (see ../../cxxprobe/src/cxxprobe.cpp).
 */

#include <cstdio>
#include <string>

#if defined(_MSVC_LANG)
#define FIBJS_SELFTEST_STANDARD _MSVC_LANG
#else
#define FIBJS_SELFTEST_STANDARD __cplusplus
#endif

#if FIBJS_SELFTEST_STANDARD < 202002L
#error "the C++20 standard of the tree did not reach this test executable"
#endif

/* The architecture check of the library, applied to this directory as well. */
#if defined(_M_X64) || defined(__x86_64__)
#define FIBJS_SELFTEST_ARCH_ID 1
#elif defined(_M_IX86) || defined(__i386__)
#define FIBJS_SELFTEST_ARCH_ID 2
#elif defined(_M_ARM64) || defined(__aarch64__)
#define FIBJS_SELFTEST_ARCH_ID 3
#elif defined(_M_ARM) || defined(__arm__)
#define FIBJS_SELFTEST_ARCH_ID 4
#elif defined(__mips64)
#define FIBJS_SELFTEST_ARCH_ID 5
#elif defined(__powerpc64__) || defined(__ppc64__)
#define FIBJS_SELFTEST_ARCH_ID 6
#elif defined(__riscv) && __riscv_xlen == 64
#define FIBJS_SELFTEST_ARCH_ID 7
#elif defined(__loongarch64) || defined(__loongarch__)
#define FIBJS_SELFTEST_ARCH_ID 8
#else
#define FIBJS_SELFTEST_ARCH_ID 0
#endif

#if !defined(FIBJS_SELFTEST_ARCH_ID_EXPECTED)
#error "cxxprobe/test/CMakeLists.txt did not pass the architecture of this build"
#endif

#if FIBJS_SELFTEST_ARCH_ID != FIBJS_SELFTEST_ARCH_ID_EXPECTED
#error "the build was asked for another architecture: the base flags, the target triple among them, did not reach this test executable"
#endif

std::string cxxprobe_arch();
std::string cxxprobe_expected_arch();
std::string cxxprobe_standard();
int cxxprobe_value();

int cxxprobe2_value();

int main()
{
    int value = cxxprobe_value();
    int value2 = cxxprobe2_value();
    std::string arch = cxxprobe_arch();
    std::string expected = cxxprobe_expected_arch();

    std::printf("cxxprobe: value = %d/%d, arch = %s (expected %s), standard = %s\n",
        value, value2, arch.c_str(), expected.c_str(),
        cxxprobe_standard().c_str());

    if (value != 42) {
        std::printf("cxxprobe: FAILED (cxxprobe_value)\n");
        return 1;
    }

    if (value2 != 7) {
        std::printf("cxxprobe: FAILED (cxxprobe2_value)\n");
        return 1;
    }

    if (arch != expected) {
        std::printf("cxxprobe: FAILED (arch: the base flags, the target triple "
                    "among them, did not reach this build)\n");
        return 1;
    }

    std::printf("cxxprobe: OK\n");
    return 0;
}
