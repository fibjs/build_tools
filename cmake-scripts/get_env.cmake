function(usechalk)
    string(ASCII 27 Esc)
    set(ChalkColorReset     "${Esc}[m"      PARENT_SCOPE)
    set(ChalkColorBold      "${Esc}[1m"     PARENT_SCOPE)
    set(ChalkRed            "${Esc}[31m"    PARENT_SCOPE)
    set(ChalkGreen          "${Esc}[32m"    PARENT_SCOPE)
    set(ChalkYellow         "${Esc}[33m"    PARENT_SCOPE)
    set(ChalkBlue           "${Esc}[34m"    PARENT_SCOPE)
    set(ChalkMagenta        "${Esc}[35m"    PARENT_SCOPE)
    set(ChalkCyan           "${Esc}[36m"    PARENT_SCOPE)
    set(ChalkWhite          "${Esc}[37m"    PARENT_SCOPE)
    set(ChalkBoldRed        "${Esc}[1;31m"  PARENT_SCOPE)
    set(ChalkBoldGreen      "${Esc}[1;32m"  PARENT_SCOPE)
    set(ChalkBoldYellow     "${Esc}[1;33m"  PARENT_SCOPE)
    set(ChalkBoldBlue       "${Esc}[1;34m"  PARENT_SCOPE)
    set(ChalkBoldMagenta    "${Esc}[1;35m"  PARENT_SCOPE)
    set(ChalkBoldCyan       "${Esc}[1;36m"  PARENT_SCOPE)
    set(ChalkBoldWhite      "${Esc}[1;37m"  PARENT_SCOPE)
endfunction()

# log function, use like this:
# chalklog("msg...")
# chalklog("info", "msg")
# chalklog("info", "msg", "prefix")
# chalklog("success", "msg", "prefix")
# chalklog("warn", "msg", "prefix")
# chalklog("error", "msg", "prefix")
function(chalklog)
    if("${ChalkColorReset}" STREQUAL "")
        usechalk()
    endif()
    
    if(${ARGC} EQUAL 3)
        set(type "${ARGV0}")
        set(msg "${ARGV1}")
        set(prefix "${ARGV2}")
    elseif(${ARGC} EQUAL 2)
        set(type "info")
        set(msg "${ARGV0}")
        set(prefix "${ARGV1}")
    else()
        set(type "info")
        set(msg "${ARG0}")
        set(prefix "")
    endif()

    if("${type}" STREQUAL "")
        set(type "info")
    endif()
    
    if("${type}" STREQUAL "info")
        set(coloredPrefix "${prefix}")
    elseif("${type}" STREQUAL "success")
        set(coloredPrefix "${ChalkGreen}${prefix}${ChalkColorReset}")
    elseif("${type}" STREQUAL "warn")
        set(coloredPrefix "${ChalkYellow}${prefix}${ChalkColorReset}")
    elseif("${type}" STREQUAL "error")
        set(coloredPrefix "${ChalkRed}${prefix}${ChalkColorReset}")
    endif()

    if("${type}" STREQUAL "error")
        message(FATAL_ERROR "${coloredPrefix} ${msg}")
    else()
        message("${coloredPrefix} ${msg}")
    endif()
endfunction()

# get host's name in cmake script mode
function(gethostname)
    if(WIN32)
        set(CMAKE_HOST_SYSTEM_NAME "Windows" PARENT_SCOPE)
    else()
        execute_process(
            COMMAND uname
            OUTPUT_VARIABLE CMAKE_HOST_SYSTEM_NAME
            OUTPUT_STRIP_TRAILING_WHITESPACE
        )
        set(CMAKE_HOST_SYSTEM_NAME ${CMAKE_HOST_SYSTEM_NAME} PARENT_SCOPE)
    endif()
endfunction()

# get host's architecture in cmake script mode
function(gethostarch RETVAL)
    if("${${RETVAL}}" STREQUAL "")
        if(WIN32)
            set(HOST_SYSTEM_PROCESSOR $ENV{PROCESSOR_ARCHITECTURE})
        else()
            execute_process(
                COMMAND uname -m
                OUTPUT_VARIABLE HOST_SYSTEM_PROCESSOR
                OUTPUT_STRIP_TRAILING_WHITESPACE
            )
        endif()

        if(${HOST_SYSTEM_PROCESSOR} MATCHES "^(i386)|(i686)|(x86)$")
            set(${RETVAL} ia32 PARENT_SCOPE)
        elseif(${HOST_SYSTEM_PROCESSOR} MATCHES "^(x86_64)|(amd64)|(AMD64)$")
            set(${RETVAL} x64 PARENT_SCOPE)
        elseif(${HOST_SYSTEM_PROCESSOR} MATCHES "^(armv6)$")
            set(${RETVAL} armv6 PARENT_SCOPE)
        elseif(${HOST_SYSTEM_PROCESSOR} MATCHES "^(armv7)|(armv7s)|(armv7l)$")
            set(${RETVAL} arm PARENT_SCOPE)
        elseif(${HOST_SYSTEM_PROCESSOR} MATCHES "^(aarch64)|(arm64)|(ARM64)$")
            set(${RETVAL} arm64 PARENT_SCOPE)
        elseif(${HOST_SYSTEM_PROCESSOR} MATCHES "mips64")
            set(${RETVAL} mips64 PARENT_SCOPE)
        elseif(${HOST_SYSTEM_PROCESSOR} MATCHES "ppc64")
            set(${RETVAL} ppc64 PARENT_SCOPE)
        elseif(${HOST_SYSTEM_PROCESSOR} MATCHES "s390x")
            set(${RETVAL} s390x PARENT_SCOPE)
        elseif(${HOST_SYSTEM_PROCESSOR} MATCHES "riscv")
            set(${RETVAL} riscv64 PARENT_SCOPE)
        elseif(${HOST_SYSTEM_PROCESSOR} MATCHES "loongarch64")
            set(${RETVAL} loong64 PARENT_SCOPE)
        endif()
    endif()
endfunction()

function(build src out name)
    set(OUT_PATH "${out}/out/${DIST_DIRNAME}/${name}")
    file(MAKE_DIRECTORY "${OUT_PATH}")

    if(NOT DEFINED BUILD_TYPE)
        message(FATAL_ERROR "[get_env::build] BUILD_TYPE haven't been set, check your input.")
    endif()

    if(("${BUILD_OS}" STREQUAL "Windows") AND (NOT "${BUILD_USE_CLANG}" STREQUAL "true"))
        if(${BUILD_ARCH} STREQUAL "x64")
            set(TargetArch "x64")
        elseif(${BUILD_ARCH} STREQUAL "ia32")
            set(TargetArch "Win32")
        elseif(${BUILD_ARCH} STREQUAL "arm64")
            set(TargetArch "ARM64")
        elseif(${BUILD_ARCH} STREQUAL "arm")
            set(TargetArch "ARM")
        endif()

        execute_process(WORKING_DIRECTORY "${OUT_PATH}"
            OUTPUT_FILE CMake.log 
            COMMAND ${CMAKE_COMMAND}
                -Wno-dev
                -DBUILD_OS=${BUILD_OS}
                -DBUILD_ARCH=${BUILD_ARCH}
                -DBUILD_TYPE=${BUILD_TYPE}
                -A ${TargetArch}
                "${src}"
            RESULT_VARIABLE STATUS
        )

        if(NOT STATUS EQUAL 0)
            message(FATAL_ERROR "[build] exit code: ${STATUS}")
        endif()

        execute_process(WORKING_DIRECTORY "${OUT_PATH}"
            COMMAND ${CMAKE_COMMAND} 
            --build ./
            --config ${BUILD_TYPE}
            -- /nologo /verbosity:minimal
            /p:CL_MPcount=${BUILD_JOBS}
            RESULT_VARIABLE STATUS
        )
    else()
        execute_process(WORKING_DIRECTORY "${OUT_PATH}"
            OUTPUT_FILE CMake.log 
            COMMAND ${CMAKE_COMMAND}
                -Wno-dev
                -DBUILD_OS=${BUILD_OS}
                -DBUILD_ARCH=${BUILD_ARCH}
                -DBUILD_TYPE=${BUILD_TYPE}
                "${src}"
            RESULT_VARIABLE STATUS
        )

        if(NOT STATUS EQUAL 0)
            message(FATAL_ERROR "[build] exit code: ${STATUS}")
        endif()
        
        execute_process(WORKING_DIRECTORY "${OUT_PATH}"
            COMMAND ${CMAKE_COMMAND} --build . -- -j${BUILD_JOBS}
            RESULT_VARIABLE STATUS
        )
    endif()

    if(NOT STATUS EQUAL 0)
        message(FATAL_ERROR "[build] exit code: ${STATUS}")
    endif()
endfunction()

function(find_vs v1 v2)
    while(v1 LESS v2 AND "${VS_INSTALLPATH}" STREQUAL "")
        MATH(EXPR v3 "${v2}-1")

        execute_process(
            WORKING_DIRECTORY "${out}"
            COMMAND "${PROGRAM_FILES_X86}\\Microsoft\ Visual\ Studio\\Installer\\vswhere.exe" -property installationPath -version "[${v3}.0, ${v2}.0)"
            OUTPUT_VARIABLE VS_INSTALLPATH
            OUTPUT_STRIP_TRAILING_WHITESPACE
        )

        set(v2 "${v3}")
    endwhile()
    set(VS_INSTALLPATH ${VS_INSTALLPATH} PARENT_SCOPE)
endfunction()

function(prepare_platform)
    if(${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Windows")
        # @todo set EnvVar to tell clang use VS2017 rather than newest one if it's not VS2019
        if("$ENV{VCToolsInstallDir}" STREQUAL "")
            if("$ENV{ProgramW6432}" STREQUAL "")
                set(PROGRAM_FILES_X86 "$ENV{ProgramFiles\(x86\)}")
            else()
                set(PROGRAM_FILES_X86 "$ENV{ProgramW6432} (x86)")
            endif()

            chalklog("success" "PROGRAM_FILES_X86 is ${PROGRAM_FILES_X86}" "[win32]")
            
            find_vs(16, 18)

            if("${VS_INSTALLPATH}" STREQUAL "" OR NOT EXISTS "${VS_INSTALLPATH}\\VC")
                chalklog("error" "make sure you have installed vs.net with vc runtime\n" "[win32]")
            endif()

            file(STRINGS "${VS_INSTALLPATH}\\VC\\Auxiliary\\Build\\Microsoft.VCToolsVersion.default.txt" CUR_MSVC_VER)
            chalklog("success" "CUR_MSVC_VER is ${CUR_MSVC_VER}" "[win32]")

            set(ENV{VCToolsInstallDir} "${VS_INSTALLPATH}\\VC\\Tools\\MSVC\\${CUR_MSVC_VER}")
            chalklog("success" "ENV{VCToolsInstallDir} is $ENV{VCToolsInstallDir}" "[win32]")
        endif()
    endif()
endfunction()

function(rimraf TARGET)
    if(EXISTS "${TARGET}")
        file(REMOVE_RECURSE ${TARGET})
        message("removed ${TARGET}")
    else()
        message("path '${TARGET}' didn't existed, no removal required.")
    endif()
endfunction()

gethostname()

include(ProcessorCount)

prepare_platform()
gethostarch(HOST_ARCH)

if("${BUILD_OS}" STREQUAL "iphone")
    set(BUILD_OS "iPhone")
else()
    set(BUILD_OS ${CMAKE_HOST_SYSTEM_NAME})
endif()

include(${CMAKE_CURRENT_LIST_DIR}/get_compiler.cmake)

if("${BUILD_TYPE}" STREQUAL "")
    set(BUILD_TYPE release)
endif()

set(DIST_DIRNAME "${BUILD_OS}_${BUILD_ARCH}_${BUILD_TYPE}")

if("${BUILD_JOBS}" STREQUAL "")
    ProcessorCount(CMAKE_HOST_SYSTEM_PROCESSOR_COUNT)
    set(BUILD_JOBS ${CMAKE_HOST_SYSTEM_PROCESSOR_COUNT})
endif()

set(ENV{CLICOLOR_FORCE} 1)

message("")
message("HOST_OS is ${CMAKE_HOST_SYSTEM_NAME}")
message("HOST_ARCH is ${HOST_ARCH}")
message("BUILD_OS is ${BUILD_OS}")
message("BUILD_ARCH is ${BUILD_ARCH}")
message("BUILD_TYPE is ${BUILD_TYPE}")
message("BUILD_JOBS is ${BUILD_JOBS}")
message("")
