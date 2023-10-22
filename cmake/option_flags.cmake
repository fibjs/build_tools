# get host's architecture in cmake script mode
function(gethostarch RETVAL)
    if("${${RETVAL}}" STREQUAL "")
        if("${BUILD_OS}" STREQUAL "Windows")
            set(HOST_SYSTEM_PROCESSOR x64)
        else()
            execute_process(
                COMMAND uname -m
                OUTPUT_VARIABLE HOST_SYSTEM_PROCESSOR
                OUTPUT_STRIP_TRAILING_WHITESPACE
            )
        endif()

        if(${HOST_SYSTEM_PROCESSOR} MATCHES "^(i386)|(i686)|(x86)$")
            set(${RETVAL} x86 PARENT_SCOPE)
        elseif(${HOST_SYSTEM_PROCESSOR} MATCHES "^(x86_64)|(amd64)|(AMD64)$")
            set(${RETVAL} x64 PARENT_SCOPE)
        elseif(${HOST_SYSTEM_PROCESSOR} MATCHES "^(armv7)|(armv7s)|(armv7l)$")
            set(${RETVAL} arm PARENT_SCOPE)
        elseif(${HOST_SYSTEM_PROCESSOR} MATCHES "^(aarch64)|(arm64)$")
            set(${RETVAL} arm64 PARENT_SCOPE)
        elseif(${HOST_SYSTEM_PROCESSOR} MATCHES "mips64")
            set(${RETVAL} mips64 PARENT_SCOPE)
        elseif(${HOST_SYSTEM_PROCESSOR} MATCHES "ppc64")
            set(${RETVAL} ppc64 PARENT_SCOPE)
        elseif(${HOST_SYSTEM_PROCESSOR} MATCHES "s390x")
            set(${RETVAL} s390x PARENT_SCOPE)
        elseif(${HOST_SYSTEM_PROCESSOR} MATCHES "riscv64")
            set(${RETVAL} riscv64 PARENT_SCOPE)
        elseif(${HOST_SYSTEM_PROCESSOR} MATCHES "loongarch64")
            set(${RETVAL} loong64 PARENT_SCOPE)
        endif()
    endif()
endfunction()

gethostarch(HOST_ARCH)

if(NOT DEFINED flags)
    set(flags "")
endif()

if(NOT DEFINED ccflags)
    set(ccflags "")
endif()

if(NOT DEFINED link_flags)
    set(link_flags "")
endif()

if("${ARCH}" STREQUAL "")
    message(FATAL_ERROR "Unsupported target architecture {${ARCH}}.")
endif()

if(MSVC)
	include(${CMAKE_CURRENT_LIST_DIR}/option_flags_vc.cmake)
else()
	include(${CMAKE_CURRENT_LIST_DIR}/option_flags_clang.cmake)
endif()

if("${CMAKE_CXX_STANDARD}" STREQUAL "")
    set(CMAKE_CXX_STANDARD 20)
endif()
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${flags}")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${flags} ${ccflags}")
set(CMAKE_OBJCXX_FLAGS "${CMAKE_OBJCXX_FLAGS} ${flags} ${ccflags}")
