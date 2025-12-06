cmake_minimum_required(VERSION 3.10)

function(check_glibc func next flag)
    set(vers 2.29 2.28 2.27 2.17 2.14 2.4 2.2.5 2.2 2.0)

    foreach(ver ${vers})
        unset(HAVE_GLIB_C_${func} CACHE)
        check_c_source_compiles("void ${func}();
            __asm__(\".symver ${func},${func}@GLIBC_${ver}\");
            int main(void){${func}();return 0;}" HAVE_GLIB_C_${func})

        if(${HAVE_GLIB_C_${func}})
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

    configure_file(${CMAKE_CURRENT_LIST_DIR}/../tools/glibc_config.h.in ${CMAKE_CURRENT_BINARY_DIR}/glibc_config.h)
    configure_file(${CMAKE_CURRENT_LIST_DIR}/../tools/std_config.h.in ${CMAKE_CURRENT_BINARY_DIR}/std_config.h)
    include_directories(${CMAKE_CURRENT_BINARY_DIR})
endfunction()

config()

execute_process(WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
    COMMAND git describe --tags --always
    OUTPUT_VARIABLE GIT_INFO
    OUTPUT_STRIP_TRAILING_WHITESPACE
)
configure_file(${CMAKE_CURRENT_LIST_DIR}/../tools/gitinfo.h.in ${CMAKE_CURRENT_BINARY_DIR}/gitinfo.h)
