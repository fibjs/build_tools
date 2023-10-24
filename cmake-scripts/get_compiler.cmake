if(NOT WIN32)
    if("$ENV{CC}" STREQUAL "")
        if(${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Linux")
            find_path(C_PATH "clang-12")
            if(NOT ${C_PATH} STREQUAL "C_PATH-NOTFOUND")
                set(ENV{CC} "${C_PATH}/clang-12")
                set(ENV{CPP} "${C_PATH}/clang++-12")
                set(ENV{CXX} "${C_PATH}/clang++-12")
            else()
                find_path(C_PATH "gcc")
                if(NOT ${C_PATH} STREQUAL "C_PATH-NOTFOUND")
                    set(ENV{CC} "${C_PATH}/gcc")
                    set(ENV{CPP} "${C_PATH}/cpp")
                    set(ENV{CXX} "${C_PATH}/g++")
                else()
                    message(FATAL_ERROR "no compiler found")
                endif()
            endif()
        else()
            find_path(C_PATH "clang")
            if(NOT ${C_PATH} STREQUAL "C_PATH-NOTFOUND")
                set(ENV{CC} "${C_PATH}/clang")
                set(ENV{CPP} "${C_PATH}/clang++")
                set(ENV{CXX} "${C_PATH}/clang++")
            else()
                message(FATAL_ERROR "no compiler found")
            endif()
        endif()
    endif()

    execute_process(
        COMMAND $ENV{CC} $ENV{CFLAGS} -dumpmachine
        OUTPUT_VARIABLE CC_TARGET
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )

    if("${BUILD_ARCH}" STREQUAL "")
        if(${CC_TARGET} MATCHES "(x86_64)|(amd64)")
            set(BUILD_ARCH "x64")
        elseif(${CC_TARGET} MATCHES "(i386)|(i686)")
            set(BUILD_ARCH "ia32")
        elseif(${CC_TARGET} MATCHES "(aarch64)|(arm64)")
            set(BUILD_ARCH "arm64")
        elseif(${CC_TARGET} MATCHES "arm")
            set(BUILD_ARCH "arm")
        elseif(${CC_TARGET} MATCHES "mips64")
            set(BUILD_ARCH "mips64")
        elseif(${CC_TARGET} MATCHES "ppc64")
            set(BUILD_ARCH "ppc64")
        elseif(${CC_TARGET} MATCHES "s390x")
            set(BUILD_ARCH "s390x")
        elseif(${CC_TARGET} MATCHES "riscv64")
            set(BUILD_ARCH "riscv64")
        elseif(${CC_TARGET} MATCHES "loongarch64")
            set(BUILD_ARCH "loong64")
        else()
            set(BUILD_ARCH ${HOST_ARCH})
        endif()
    endif()

    if(${CC_TARGET} MATCHES "android")
        set(BUILD_OS "Android")
    elseif(${CC_TARGET} MATCHES "musl")
        set(BUILD_OS "Alpine")
    endif()
else()
    if("${BUILD_ARCH}" STREQUAL "")
        set(BUILD_ARCH ${HOST_ARCH})
    endif()
endif()