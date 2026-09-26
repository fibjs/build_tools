cmake_minimum_required(VERSION 3.10)

# Static library built through cmake/Library.cmake, carrying the checks that the
# vender build failures were about (see src/cxxprobe.cpp).
#
# The two assertions below are the cmake half of them: they stop the configure
# step before the compiler is even started, and they fail with the values that
# are actually in scope, which is what the raw job log would be needed for
# otherwise.
include(${CMAKE_CURRENT_LIST_DIR}/../../../cmake/Library.cmake)

# The base flags - the C++ standard among them - are applied in the directory
# scope of every library (cmake/option_flags.cmake), not once per build tree.
# Without them v8 stops with "C++20 or later required".
if("${CMAKE_CXX_STANDARD}" STREQUAL "" OR CMAKE_CXX_STANDARD LESS 20)
    message(FATAL_ERROR
        "cxxprobe: the C++ standard of the tree did not reach this library "
        "(CMAKE_CXX_STANDARD='${CMAKE_CXX_STANDARD}')")
endif()

# cmake/option_libs.cmake copies `link_flags` of this scope onto the target, and
# the platform file fills it with the static C++ runtime, the target library
# path and (on macOS) the frameworks.  Losing it produced test binaries that
# could not find libstdc++ inside the build images, and links that could not
# find the libraries of the target.
get_target_property(cxxprobe_link_flags cxxprobe LINK_FLAGS)
if("${cxxprobe_link_flags}" STREQUAL "" OR "${cxxprobe_link_flags}" MATCHES "NOTFOUND")
    message(FATAL_ERROR
        "cxxprobe: the platform link flags did not reach this library "
        "(LINK_FLAGS='${cxxprobe_link_flags}')")
endif()

# The architecture this build was asked for, as an id the source compares with
# the architecture the compiler actually emits for.  The target triple and the
# sysroot of a cross build are part of the base flags, and without them the
# compiler silently emits code for the host (see src/cxxprobe.cpp).
if("${BUILD_ARCH}" STREQUAL "x64")
    set(cxxprobe_arch_id 1)
elseif("${BUILD_ARCH}" STREQUAL "ia32")
    set(cxxprobe_arch_id 2)
elseif("${BUILD_ARCH}" STREQUAL "arm64")
    set(cxxprobe_arch_id 3)
elseif("${BUILD_ARCH}" STREQUAL "arm")
    set(cxxprobe_arch_id 4)
elseif("${BUILD_ARCH}" STREQUAL "mips64")
    set(cxxprobe_arch_id 5)
elseif("${BUILD_ARCH}" STREQUAL "ppc64")
    set(cxxprobe_arch_id 6)
elseif("${BUILD_ARCH}" STREQUAL "riscv64")
    set(cxxprobe_arch_id 7)
elseif("${BUILD_ARCH}" MATCHES "^loong64")
    # loong64ow is the Loongson toolchain of the same architecture.
    set(cxxprobe_arch_id 8)
else()
    message(FATAL_ERROR "cxxprobe: unknown architecture '${BUILD_ARCH}'")
endif()

target_compile_definitions(cxxprobe PRIVATE
    SELFTEST_ARCH_ID_EXPECTED=${cxxprobe_arch_id})
