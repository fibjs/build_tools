
# run c code to get some library information(like iconv/glibc) from env
function(check_env c_flags)
	include(CheckIncludeFiles)
	include(CheckCSourceCompiles)

	set(CMAKE_C_FLAGS "${c_flags}")

	check_include_files(iconv.h HAVE_ICONV_H)
    set(HAVE_ICONV_H "${HAVE_ICONV_H}" PARENT_SCOPE)

    if(${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Darwin")
        check_c_source_compiles("#include <stdatomic.h>
            atomic_int a;
            int main(void){atomic_load(&a);return 0;}" HAVE_GLIB_C_ATOMIC_H)
    else()
        check_c_source_compiles("#include <atomic>
            int main(void){std::atomic<int64_t> a;std::atomic_load(&a);return 0;}" HAVE_GLIB_C_ATOMIC_H)
    endif()
    set(HAVE_GLIB_C_ATOMIC_H ${HAVE_GLIB_C_ATOMIC_H} PARENT_SCOPE)

    if(${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Linux")
        check_c_source_compiles("void posix_spawnp();
            __asm__(\".symver posix_spawnp,posix_spawnp@GLIBC_2.2.5\");
            int main(void){posix_spawnp();return 0;}" HAVE_GLIB_C_225_H)
        set(HAVE_GLIB_C_225_H ${HAVE_GLIB_C_225_H} PARENT_SCOPE)

        check_c_source_compiles("void posix_spawnp();
            __asm__(\".symver posix_spawnp,posix_spawnp@GLIBC_2.2\");
            int main(void){posix_spawnp();return 0;}" HAVE_GLIB_C_22_H)
        set(HAVE_GLIB_C_22_H ${HAVE_GLIB_C_22_H} PARENT_SCOPE)

        check_c_source_compiles("void fcntl();
            __asm__(\".symver fcntl,fcntl@GLIBC_2.2.5\");
            int main(void){fcntl();return 0;}" HAVE_GLIB_C_FCNTL_225_H)
        set(HAVE_GLIB_C_FCNTL_225_H ${HAVE_GLIB_C_FCNTL_225_H} PARENT_SCOPE)

        check_c_source_compiles("void fcntl();
            __asm__(\".symver fcntl,fcntl@GLIBC_2.0\");
            int main(void){fcntl();return 0;}" HAVE_GLIB_C_FCNTL_2_H)
        set(HAVE_GLIB_C_FCNTL_2_H ${HAVE_GLIB_C_FCNTL_2_H} PARENT_SCOPE)

        check_c_source_compiles("void fcntl();
            __asm__(\".symver fcntl,fcntl@GLIBC_2.4\");
            int main(void){fcntl();return 0;}" HAVE_GLIB_C_FCNTL_24_H)
        set(HAVE_GLIB_C_FCNTL_24_H ${HAVE_GLIB_C_FCNTL_24_H} PARENT_SCOPE)

        check_c_source_compiles("void fcntl();
            __asm__(\".symver fcntl,fcntl@GLIBC_2.17\");
            int main(void){fcntl();return 0;}" HAVE_GLIB_C_FCNTL_217_H)
        set(HAVE_GLIB_C_FCNTL_217_H ${HAVE_GLIB_C_FCNTL_217_H} PARENT_SCOPE)
    endif()
endfunction()

check_env("${BUILD_OPTION}")
if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/tools/config.h.in)
	configure_file(${CMAKE_CURRENT_SOURCE_DIR}/tools/config.h.in ${CMAKE_CURRENT_BINARY_DIR}/config.h)
endif()

if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/tools/config.h.in)
	execute_process(WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
		COMMAND git describe --tags --always
		OUTPUT_VARIABLE GIT_INFO
		OUTPUT_STRIP_TRAILING_WHITESPACE
	)
	configure_file(${CMAKE_CURRENT_SOURCE_DIR}/tools/gitinfo.h.in ${CMAKE_CURRENT_BINARY_DIR}/gitinfo.h)
endif()