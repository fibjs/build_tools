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
            set(HOST_SYSTEM_PROCESSOR amd64)
        else()
            execute_process(
                COMMAND uname -m
                OUTPUT_VARIABLE HOST_SYSTEM_PROCESSOR
                OUTPUT_STRIP_TRAILING_WHITESPACE
            )
        endif()

        if(${HOST_SYSTEM_PROCESSOR} MATCHES "^(i386)|(i686)|(x86)$")
            set(${RETVAL} i386 PARENT_SCOPE)
        elseif(${HOST_SYSTEM_PROCESSOR} MATCHES "^(x86_64)|(amd64)|(AMD64)$")
            set(${RETVAL} amd64 PARENT_SCOPE)
        elseif(${HOST_SYSTEM_PROCESSOR} MATCHES "^(armv6)$")
            set(${RETVAL} armv6 PARENT_SCOPE)
        elseif(${HOST_SYSTEM_PROCESSOR} MATCHES "^(armv7)|(armv7s)|(armv7l)$")
            set(${RETVAL} arm PARENT_SCOPE)
        elseif(${HOST_SYSTEM_PROCESSOR} MATCHES "^(aarch64)|(arm64)$")
            set(${RETVAL} arm64 PARENT_SCOPE)
        elseif(${HOST_SYSTEM_PROCESSOR} MATCHES "^(mips)|(mipsel)$")
            set(${RETVAL} mips PARENT_SCOPE)
        elseif(${HOST_SYSTEM_PROCESSOR} MATCHES "^mips64$")
            set(${RETVAL} mips64 PARENT_SCOPE)
        elseif(${HOST_SYSTEM_PROCESSOR} MATCHES "^powerpc$")
            set(${RETVAL} ppc PARENT_SCOPE)
        elseif(${HOST_SYSTEM_PROCESSOR} MATCHES "^ppc64$")
            set(${RETVAL} ppc64 PARENT_SCOPE)
        endif()
    endif()
endfunction()

function(build src out name)
    set(OUT_PATH "${out}/out/${DIST_DIRNAME}/${name}")
    set(BIN_PATH "${out}/bin/${DIST_DIRNAME}")

    file(MAKE_DIRECTORY "${OUT_PATH}")

    if(NOT DEFINED BUILD_TYPE)
        message(FATAL_ERROR "[get_env::build] BUILD_TYPE haven't been set, check your input.")
    endif()

    if((${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Windows") AND (NOT "${BUILD_USE_CLANG}" STREQUAL "true"))
        if(${BUILD_ARCH} STREQUAL "amd64")
            set(TargetArch "x64")
        elseif(${BUILD_ARCH} STREQUAL "i386")
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
                -DARCH=${BUILD_ARCH}
                -DBUILD_TYPE=${BUILD_TYPE}
                -DLIBRARY_OUTPUT_PATH=${BIN_PATH}
                -DEXECUTABLE_OUTPUT_PATH=${BIN_PATH}
                -A ${TargetArch}
                "${src}"
            ENCODING UTF8
            RESULT_VARIABLE STATUS
            ERROR_VARIABLE BUILD_ERROR
        )

        if(STATUS AND NOT STATUS EQUAL 0)
            message("[get_env::build::error::cmake] for '${OUT_PATH}'")
            message(FATAL_ERROR "${BUILD_ERROR}")
        endif()

        execute_process(WORKING_DIRECTORY "${OUT_PATH}"
            COMMAND ${CMAKE_COMMAND} 
            --build ./
            --config ${BUILD_TYPE}
            -- /nologo /verbosity:minimal
            /p:CL_MPcount=${BUILD_JOBS}
            ENCODING UTF8
            RESULT_VARIABLE STATUS
            ERROR_VARIABLE BUILD_ERROR
        )
    else()
        execute_process(WORKING_DIRECTORY "${OUT_PATH}"
            OUTPUT_FILE CMake.log 
            COMMAND ${CMAKE_COMMAND}
                -Wno-dev
                -DCMAKE_MAKE_PROGRAM=make
                -G "Unix Makefiles"
                -DCMAKE_C_COMPILER=$ENV{CC}
                -DCMAKE_CXX_COMPILER=$ENV{CXX}
                -DARCH=${BUILD_ARCH}
                -DBUILD_TYPE=${BUILD_TYPE}
                -DLIBRARY_OUTPUT_PATH=${BIN_PATH}
                -DEXECUTABLE_OUTPUT_PATH=${BIN_PATH}
                "${src}"
            RESULT_VARIABLE STATUS
            ERROR_VARIABLE BUILD_ERROR
        )

        if(STATUS AND NOT STATUS EQUAL 0)
            message("[get_env::build::error::cmake] for '${OUT_PATH}'")
            message(FATAL_ERROR "${BUILD_ERROR}")
        endif()
        
        execute_process(WORKING_DIRECTORY "${OUT_PATH}"
            COMMAND ${CMAKE_COMMAND} --build . -- -j${BUILD_JOBS}
            RESULT_VARIABLE STATUS
            ERROR_VARIABLE BUILD_ERROR
        )
    endif()

    if(STATUS AND NOT STATUS EQUAL 0)
        message("[get_env::build::error::make] for '${OUT_PATH}'")
        message(FATAL_ERROR "${BUILD_ERROR}")
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
            
            find_vs(15, 18)

            if("${VS_INSTALLPATH}" STREQUAL "")
                chalklog("error" "make sure you have installed vs.net with vcruntime headers/libraries" "[win32]")
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

set(BUILD_OS ${CMAKE_HOST_SYSTEM_NAME})

if(NOT DEFINED BUILD_ARCH OR "${BUILD_ARCH}" STREQUAL "")
    set(BUILD_ARCH ${HOST_ARCH})
endif()

if("$ENV{CC}" STREQUAL "")
    set(ENV{CC} "clang")
    set(ENV{CXX} "clang++")
else()
    execute_process(
        COMMAND bash -c "$ENV{CC} -dM -E - </dev/null"
        OUTPUT_VARIABLE GCC_DEFINES
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )

    if(${GCC_DEFINES} MATCHES "__aarch64__")
        set(BUILD_ARCH "arm64")
    endif()

    if(${GCC_DEFINES} MATCHES "__ANDROID__")
        set(BUILD_OS "Android")
    endif()
endif()

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
