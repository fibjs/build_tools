
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

    if(NOT ANDROID)
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

    configure_file(${CMAKE_CURRENT_LIST_DIR}/../tools/glibc_config.h.in ${CMAKE_CURRENT_BINARY_DIR}/glibc_config.h)
endfunction()

config()

execute_process(WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
    COMMAND git describe --tags --always
    OUTPUT_VARIABLE GIT_INFO
    OUTPUT_STRIP_TRAILING_WHITESPACE
)
configure_file(${CMAKE_CURRENT_LIST_DIR}/../tools/gitinfo.h.in ${CMAKE_CURRENT_BINARY_DIR}/gitinfo.h)
