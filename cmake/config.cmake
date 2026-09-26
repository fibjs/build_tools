cmake_minimum_required(VERSION 3.10)

# ============================================================================
# build configuration of the repositories that use this tool
#
# Single place that computes the build environment.  It is included by the
# top-level CMakeLists.txt (project mode) and by the build scripts through
# cmake-scripts/dist_dirname.cmake (script mode, only to learn DIST_DIRNAME),
# and it is idempotent, so a library may also include it directly.
#
# Inputs (cache entries / -D):
#   BUILD_OS       linux | alpine | android | win32 | darwin | iphone |
#                  iphone-simulator   (default: host system name)
#   BUILD_ARCH     x64 | ia32 | arm | arm64 | mips64 | ppc64 | riscv64 |
#                  loong64 | loong64ow | s390x  (default: host / compiler target)
#   BUILD_TYPE     release | debug               (default: release)
#   BUILD_JOBS     parallel jobs                 (default: host cpu count)
#   BT_BIN_DIR  output directory for libraries and executables
#                  (default: <build dir>/../bin/<OS>_<ARCH>_<TYPE>)
#
# Outputs:
#   BUILD_OS, BUILD_ARCH, BUILD_TYPE, HOST_ARCH, DIST_DIRNAME, BUILD_JOBS,
#   BT_BIN_DIR
# ============================================================================

if(NOT DEFINED BT_CONFIG_LOADED)
set(BT_CONFIG_LOADED 1)

# The environment has to be computed before the first project() call: project()
# is what detects the compiler, and get_compiler.cmake below selects it (clang-18
# on Linux, the cross compiler of the build image in a container).  A top-level
# CMakeLists.txt without a literal project() call gets an implicit
# project(Project) from CMake before anything else runs - which is the mistake
# reported here, because it would detect the compiler of the host instead.
if(DEFINED CMAKE_C_COMPILER_ID)
    message(FATAL_ERROR
        "config.cmake has to be included before the first project() call:\n"
        "  the top-level CMakeLists.txt includes cmake/config.cmake and then\n"
        "  calls project(), which detects the compiler selected here")
endif()

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
            # On Windows, when running under WoW64 (32-bit process on 64-bit OS),
            # PROCESSOR_ARCHITECTURE returns the emulated architecture (e.g., x86),
            # while PROCESSOR_ARCHITEW6432 returns the real host architecture.
            # We need to check PROCESSOR_ARCHITEW6432 first to get the true host arch.
            set(HOST_SYSTEM_PROCESSOR $ENV{PROCESSOR_ARCHITEW6432})
            if("${HOST_SYSTEM_PROCESSOR}" STREQUAL "")
                set(HOST_SYSTEM_PROCESSOR $ENV{PROCESSOR_ARCHITECTURE})
            endif()
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

            # Searched from the newest supported Visual Studio downwards:
            # 2022 (17) and 2026 (18) are both covered.
            find_vs(16, 21)

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

# ----------------------------------------------------------------------------
# platform / arch / type
# ----------------------------------------------------------------------------

gethostname()

include(ProcessorCount)

# prepare_platform() locates the Visual Studio toolchain so that project() can
# use clang-cl; a script-mode run (cmake -P, e.g. the dist directory helper) has
# no project and must not depend on vswhere.
if(NOT DEFINED CMAKE_SCRIPT_MODE_FILE)
    prepare_platform()
endif()

gethostarch(HOST_ARCH)

if("${BUILD_OS}" STREQUAL "iphone")
    set(BUILD_OS "iPhone")
elseif("${BUILD_OS}" STREQUAL "iphone-simulator")
    set(BUILD_OS "iPhoneSimulator")
else()
    set(BUILD_OS ${CMAKE_HOST_SYSTEM_NAME})
endif()

include(${CMAKE_CURRENT_LIST_DIR}/../cmake-scripts/get_compiler.cmake)

if("${BUILD_TYPE}" STREQUAL "")
    set(BUILD_TYPE release)
endif()

set(DIST_DIRNAME "${BUILD_OS}_${BUILD_ARCH}_${BUILD_TYPE}")

# The assembler of the NASM language slot for the Windows targets comes from
# this repository; the rule and the tool are described in option_asm.cmake.
include(${CMAKE_CURRENT_LIST_DIR}/option_asm.cmake)
asm_compilers()

if("${BUILD_JOBS}" STREQUAL "")
    ProcessorCount(CMAKE_HOST_SYSTEM_PROCESSOR_COUNT)
    set(BUILD_JOBS ${CMAKE_HOST_SYSTEM_PROCESSOR_COUNT})
endif()

set(ENV{CLICOLOR_FORCE} 1)

# ----------------------------------------------------------------------------
# output layout
#
# Everything (static libraries, executables, tests) is written to a single
# directory so that consumers can link by path as well as by target name:
#
#     <WORK_ROOT>/out/<DIST_DIRNAME>/   build tree (one subdirectory per target)
#     <WORK_ROOT>/bin/<DIST_DIRNAME>/   artifacts
#
# BT_BIN_DIR may be preset by the caller (the build driver or the top-level
# project) when the build tree lives outside of the default layout.
# ----------------------------------------------------------------------------

if("${BT_BIN_DIR}" STREQUAL "" AND NOT DEFINED CMAKE_SCRIPT_MODE_FILE)
    # project mode.  The default build tree is <work root>/out/<dist>, so the
    # artifacts belong to <work root>/bin/<dist>.  Callers that use a different
    # -B location pass -DBT_BIN_DIR explicitly (build_tools/scripts/build).
    set(BT_BIN_DIR "${CMAKE_BINARY_DIR}/../../bin/${DIST_DIRNAME}")
endif()

if(NOT "${BT_BIN_DIR}" STREQUAL "")
    get_filename_component(BT_BIN_DIR "${BT_BIN_DIR}" ABSOLUTE)
endif()

message("")
message("HOST_OS is ${CMAKE_HOST_SYSTEM_NAME}")
message("HOST_ARCH is ${HOST_ARCH}")
message("BUILD_OS is ${BUILD_OS}")
message("BUILD_ARCH is ${BUILD_ARCH}")
message("BUILD_TYPE is ${BUILD_TYPE}")
message("BUILD_JOBS is ${BUILD_JOBS}")
if(NOT "${BT_BIN_DIR}" STREQUAL "")
    message("BT_BIN_DIR is ${BT_BIN_DIR}")
endif()
message("")

endif()
