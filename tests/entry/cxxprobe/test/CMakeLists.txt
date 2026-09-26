cmake_minimum_required(VERSION 3.10)

# Executable built through cmake/LibraryTest.cmake: it links the library under
# test (and cxxprobe2) by target name.  The libraries live in the parent
# directory, the second one is named by test_libs.
set(test_libs cxxprobe2)

include(${CMAKE_CURRENT_LIST_DIR}/../../../../cmake/LibraryTest.cmake)

# The executable is its own directory scope: it has to be compiled with the base
# flags as well, and it is checked the same way as the library (see
# ../../cxxprobe/src/cxxprobe.cpp).  tests/run.sh also checks that it links the
# C++ runtime statically.
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
    set(cxxprobe_arch_id 8)
else()
    message(FATAL_ERROR "cxxprobe_test: unknown architecture '${BUILD_ARCH}'")
endif()

target_compile_definitions(cxxprobe_test PRIVATE
    SELFTEST_ARCH_ID_EXPECTED=${cxxprobe_arch_id})
