cmake_minimum_required(VERSION 3.10)

# Directory of this file, captured at include time.  Inside the functions below
# CMAKE_CURRENT_LIST_DIR refers to the *caller* (which is the top-level
# CMakeLists.txt in the unified build), and CMAKE_CURRENT_FUNCTION_LIST_DIR
# needs CMake 3.17 while this tree supports 3.10.
set(FIBJS_BUILD_TOOLS_CMAKE_DIR "${CMAKE_CURRENT_LIST_DIR}")

function(check_glibc func next flag)
    set(vers 2.29 2.28 2.27 2.17 2.14 2.4 2.2.5 2.2 2.0)

    foreach(ver ${vers})
        # One cache entry per (function, version): the descending probe has to
        # look at every version, but repeated configures reuse the results
        # instead of re-running the checks.
        check_c_source_compiles("void ${func}();
            __asm__(\".symver ${func},${func}@GLIBC_${ver}\");
            int main(void){${func}();return 0;}" HAVE_GLIB_C_${func}_${ver})

        if(${HAVE_GLIB_C_${func}_${ver}})
            if("${next}" STREQUAL "no")
                set(next yes)
            else()
                set(found "${ver}")
            endif()
        endif()
    endforeach()

    if(NOT "${found}" STREQUAL "")
        set(${flag} "${found}" PARENT_SCOPE)
    endif()
endfunction()

# run c code to get some library information(like iconv/glibc) from env
function(config)
	include(CheckIncludeFiles)
	include(CheckCSourceCompiles)
    include(CheckCXXSourceCompiles)

    # The probes are expected (and cached); keep the configure log readable.
    set(CMAKE_REQUIRED_QUIET ON)

	set(CMAKE_C_FLAGS "${flags} -lm")

    check_cxx_source_compiles("#include <atomic>
        int main(void){std::atomic<double> a;std::atomic_load(&a);return 0;}"
        HAVE_GLIB_C_ATOMIC_H)
    set(HAVE_GLIB_C_ATOMIC_H ${HAVE_GLIB_C_ATOMIC_H} PARENT_SCOPE)

    if(NOT "${BUILD_OS}" STREQUAL "Android")
        check_include_files(iconv.h HAVE_ICONV_H)
        set(HAVE_ICONV_H "${HAVE_ICONV_H}")
    endif()

    if("${BUILD_OS}" STREQUAL "Linux")
        check_glibc(memcpy no GLIB_C_MEMCPY)
        check_glibc(clock_gettime no GLIB_C_TIME)
        check_glibc(pow no GLIB_C_MATH)
        check_glibc(log2 no GLIB_C_MATH2)

        check_glibc(fcntl yes GLIB_C_FCNTL)
    endif()

    # <compare> (C++20 three-way comparison) is missing on older libstdc++ /
    # libc++; the libraries then get the bundled fallback header
    # (see option_flags_clang.cmake).  Probed once here, not once per library.
    #
    # The directory is added *after* the probe on purpose: the fallback headers
    # shadow the system ones, so a probe that ran with them in the include path
    # would answer for the patch instead of the toolchain.  This directory (the
    # tree root in the single project layout, the library directory when a
    # library is configured on its own) is inherited by everything built below
    # it.
    if(NOT "${BUILD_OS}" STREQUAL "Windows")
        include(CheckIncludeFileCXX)
        set(CMAKE_REQUIRED_FLAGS "-std=gnu++20")
        check_include_file_cxx(compare HAS_COMPARE)
        unset(CMAKE_REQUIRED_FLAGS)

        if(NOT HAS_COMPARE)
            include_directories("${FIBJS_BUILD_TOOLS_CMAKE_DIR}/../patch/cxx20/10")
        endif()
    endif()

    # Check C++20 standard library features using project configured flags
    # Need to explicitly add -std=gnu++20 since CMAKE_CXX_STANDARD is not
    # automatically used by check_cxx_source_compiles
    set(CMAKE_REQUIRED_FLAGS "${flags} ${ccflags} -std=gnu++20")

    # Check for std::ranges
    # Note: need <algorithm> header for ranges algorithms like find_if
    check_cxx_source_compiles("#include <algorithm>
        #include <ranges>
        #include <vector>
        int main(void){std::vector<int> v{1,2,3};auto it=std::ranges::find_if(v,[](int x){return x>1;});return 0;}"
        HAVE_STD_RANGES)

    # Check for std::bit_cast
    check_cxx_source_compiles("#include <bit>
        int main(void){float f=1.0f;int i=std::bit_cast<int>(f);return 0;}"
        HAVE_STD_BIT_CAST)

    # Check for std::make_unique_for_overwrite
    check_cxx_source_compiles("#include <memory>
        int main(void){auto p=std::make_unique_for_overwrite<int>();return 0;}"
        HAVE_STD_MAKE_UNIQUE_FOR_OVERWRITE)

    # Check for std::to_array
    check_cxx_source_compiles("#include <array>
        int main(void){int a[]={1,2,3};auto arr=std::to_array(a);return 0;}"
        HAVE_STD_TO_ARRAY)

    configure_file(${FIBJS_BUILD_TOOLS_CMAKE_DIR}/../tools/glibc_config.h.in ${CMAKE_CURRENT_BINARY_DIR}/glibc_config.h)
    configure_file(${FIBJS_BUILD_TOOLS_CMAKE_DIR}/../tools/std_config.h.in ${CMAKE_CURRENT_BINARY_DIR}/std_config.h)
    include_directories(${CMAKE_CURRENT_BINARY_DIR})
endfunction()

# Feature checks plus the generated configuration headers of this directory.
function(fibjs_config_headers)
    # The checks have to see the toolchain the libraries will be compiled with:
    # a cross build carries its target triple and sysroot in these flags, and
    # without them the probes would answer for the host toolchain (e.g. a
    # <compare> that exists in the container's libstdc++ but not in the target's).
    include(${FIBJS_BUILD_TOOLS_CMAKE_DIR}/option_flags.cmake)

    config()

    execute_process(WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
        COMMAND git describe --tags --always
        OUTPUT_VARIABLE GIT_INFO
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    configure_file(${FIBJS_BUILD_TOOLS_CMAKE_DIR}/../tools/gitinfo.h.in ${CMAKE_CURRENT_BINARY_DIR}/gitinfo.h)
endfunction()

# Once per build tree: run the feature checks, generate glibc_config.h /
# std_config.h / gitinfo.h and publish them through the fibjs_config interface
# target.  Every library links fibjs_config (see Library.cmake), so the checks
# and the git describe call happen once instead of once per library.
#
# A library configured on its own (no top-level project) falls back to its own
# checks, see option.cmake.
function(fibjs_config_target)
    if(TARGET fibjs_config)
        return()
    endif()

    fibjs_config_headers()

    add_library(fibjs_config INTERFACE)
    target_include_directories(fibjs_config INTERFACE "${CMAKE_CURRENT_BINARY_DIR}")
endfunction()
