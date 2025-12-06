cmake_minimum_required(VERSION 3.10)

macro(clean_clang_flags)
    set(variables
        CMAKE_C_FLAGS_DEBUG
        CMAKE_C_FLAGS_RELEASE
        CMAKE_C_FLAGS_RELWITHDEBINFO
        CMAKE_C_FLAGS_MINSIZEREL
        CMAKE_CXX_FLAGS_DEBUG
        CMAKE_CXX_FLAGS_RELEASE
        CMAKE_CXX_FLAGS_RELWITHDEBINFO
        CMAKE_CXX_FLAGS_MINSIZEREL)

    foreach(variable ${variables})
        # To use static c runtime from libcmt(d).lib, we could:
        # 1.remove '-D_DLL' from those CMAKE predefined flags
        # 2. pass '-D_LIB' instead of '-D_DLL' to clang
        string(REGEX REPLACE
            "-D_DLL" ""
            ${variable} "${${variable}}")

        string(REGEX REPLACE
            "-Xclang --dependent-lib=msvcrt" "-Xclang --dependent-lib=libcmt"
            ${variable} "${${variable}}")

        if(${variable} MATCHES "/MD")
            string(REGEX REPLACE "/MD" "/MT" ${variable} "${${variable}}")
        endif()

        set(${variable} "${${variable}}" CACHE STRING "CLANG_${variable}" FORCE)
    endforeach()
endmacro()

macro(fixup_CMAKE_BUILD_TYPE)
    # @warning: for cmake/clang on windows, you should always make CMAKE_BUILD_TYPE available, never leave it. Otherwise you would get one library for 'DEBUG'
    if(${BUILD_TYPE} STREQUAL "debug")
        set(CMAKE_BUILD_TYPE Debug)
    elseif(${BUILD_TYPE} STREQUAL "release")
        set(CMAKE_BUILD_TYPE Release)
    endif()
endmacro()

macro(configure_clang_cl_mp)
    set(variables
        CMAKE_C_FLAGS
        CMAKE_C_FLAGS_RELEASE
        CMAKE_CXX_FLAGS
        CMAKE_CXX_FLAGS_RELEASE)

    if("$ENV{COMMIT_ID}" STREQUAL "")
        foreach(variable ${variables})
            # enforce multiple core processing
            if(NOT ${variable} MATCHES "/MD" AND NOT ${variable} MATCHES "/MP")
                set(${variable} "${${variable}} /MP" CACHE STRING "CLANGCL_${variable}" FORCE)
            endif()
        endforeach()
    endif()
endmacro()

if("${BUILD_OS}" STREQUAL "Alpine")
    if(${BUILD_ARCH} STREQUAL "arm")
        set(flags "${flags} -march=armv7-a -mfpu=vfp3 -marm")
    endif()
elseif("${BUILD_OS}" STREQUAL "Linux")
    if(NOT ${HOST_ARCH} STREQUAL ${BUILD_ARCH} AND "${CMAKE_C_COMPILER}" MATCHES "clang")
        if(${BUILD_ARCH} STREQUAL "x64")
            set(BUILD_TARGET "x86_64-linux-gnu")
        elseif(${BUILD_ARCH} STREQUAL "ia32")
            set(BUILD_TARGET "i686-linux-gnu")
        elseif(${BUILD_ARCH} STREQUAL "arm")
            set(flags "${flags} -march=armv7-a -mfpu=vfp3 -marm")
            set(BUILD_TARGET "arm-linux-gnueabihf")
        elseif(${BUILD_ARCH} STREQUAL "arm64")
            set(BUILD_TARGET "aarch64-linux-gnu")
        elseif(${BUILD_ARCH} STREQUAL "mips64")
            set(BUILD_TARGET "mips64el-linux-gnuabi64")
        elseif(${BUILD_ARCH} STREQUAL "ppc64")
            set(BUILD_TARGET "powerpc64le-linux-gnu")
            set(link_flags "${link_flags} -Wl,--no-tls-get-addr-optimize")
        elseif(${BUILD_ARCH} STREQUAL "s390x")
            set(BUILD_TARGET "s390x-linux-gnu")
        elseif(${BUILD_ARCH} STREQUAL "riscv64")
            set(BUILD_TARGET "riscv64-linux-gnu")
        else()
            message(FATAL_ERROR "Unsupported target architecture {${BUILD_ARCH}}.")
        endif()

        execute_process(
            COMMAND gcc -dumpversion
            OUTPUT_VARIABLE GCC_VERSION
            OUTPUT_STRIP_TRAILING_WHITESPACE
        )

        set(flags "${flags} --target=${BUILD_TARGET} -I/usr/${BUILD_TARGET}/include -I/usr/${BUILD_TARGET}/include/c++/${GCC_VERSION}/${BUILD_TARGET}")
        set(link_flags "${link_flags} -L/usr/${BUILD_TARGET}/lib")

        set(CMAKE_ASM_COMPILER_TARGET "${BUILD_TARGET}")
        set(CMAKE_ASM-ATT_TARGET "${BUILD_TARGET}")
        set(CMAKE_ASM-ATT_COMPILER "/usr/${BUILD_TARGET}/bin/as")
    endif()
elseif("${BUILD_OS}" STREQUAL "Windows")
    clean_clang_flags()
    fixup_CMAKE_BUILD_TYPE()
    configure_clang_cl_mp()

    # it's not necessary to set target for clang-cl,
    # but we leave here for convenience if v8 switch back to clang.exe in the future
    #
    # if(${BUILD_ARCH} STREQUAL "x64") # x64
    # set(flags "${flags} --target=x86_64-pc-windows-msvc")
    # elseif(${BUILD_ARCH} STREQUAL "arm64") # arm64
    # set(flags "${flags} --target=aarch64-pc-windows-msvc")
    # else() # ia32
    # set(flags "${flags} --target=i686-pc-windows-msvc")
    # endif()

    # keep same name format with Unix
    set(CMAKE_STATIC_LIBRARY_PREFIX "lib")

    add_definitions(-DWIN32 -D_LIB -D_CRT_SECURE_NO_WARNINGS -D_CRT_RAND_S -DNOMINMAX -DUNICODE -D_UNICODE)
    set(flags "${flags} /showFilenames /EHsc /utf-8 -fms-extensions -fmsc-version=1910 -frtti")
    set(link_flags "${link_flags} /SAFESEH:NO")

    if(${BUILD_TYPE} STREQUAL "debug")
        set(flags "${flags} -Xclang --dependent-lib=libcmtd")
    elseif(${BUILD_TYPE} STREQUAL "release")
        set(flags "${flags} -Xclang --dependent-lib=libcmt")
    endif()
elseif("${BUILD_OS}" MATCHES "iPhone")
    set(flags "${flags} -Wno-nullability-completeness -miphoneos-version-min=12.0")
    set(link_flags "${link_flags} -miphoneos-version-min=12.0 -framework Foundation -framework UIKit -framework WebKit")

    if("${BUILD_OS}" STREQUAL "iPhoneSimulator")
        execute_process(
            COMMAND xcrun --sdk iphonesimulator --show-sdk-path
            OUTPUT_VARIABLE CMAKE_OSX_SYSROOT
            OUTPUT_STRIP_TRAILING_WHITESPACE
        )

        if(${BUILD_ARCH} STREQUAL "x64")
            set(CMAKE_OSX_ARCHITECTURES "x86_64")
            set(BUILD_TARGET "x86_64-apple-ios-simulator")
        elseif(${BUILD_ARCH} STREQUAL "arm64")
            set(CMAKE_OSX_ARCHITECTURES "arm64")
            set(BUILD_TARGET "aarch64-apple-ios-simulator")
        else()
            message(FATAL_ERROR "Unsupported target architecture {${BUILD_ARCH}}.")
        endif()
    else()
        execute_process(
            COMMAND xcrun --sdk iphoneos --show-sdk-path
            OUTPUT_VARIABLE CMAKE_OSX_SYSROOT
            OUTPUT_STRIP_TRAILING_WHITESPACE
        )

        if(${BUILD_ARCH} STREQUAL "arm64")
            set(CMAKE_OSX_ARCHITECTURES "arm64")
            set(BUILD_TARGET "aarch64-apple-ios")
        else()
            message(FATAL_ERROR "Unsupported target architecture {${BUILD_ARCH}}.")
        endif()
    endif()


    set(CMAKE_OSX_DEPLOYMENT_TARGET "" CACHE STRING "Force unset of the deployment target for iOS" FORCE)

    set(flags "${flags} --target=${BUILD_TARGET}")
    set(CMAKE_ASM_COMPILER_TARGET "${BUILD_TARGET}")

    set(CMAKE_ASM_FLAGS "-miphoneos-version-min=12.0")

    if(src_platform_list)
        set_source_files_properties(${src_platform_list} PROPERTIES COMPILE_FLAGS "-x objective-c++")
    endif()
elseif("${BUILD_OS}" STREQUAL "Darwin")
    set(flags "${flags} -Wno-nullability-completeness -mmacosx-version-min=10.13")
    set(link_flags "${link_flags} -framework WebKit -framework Cocoa -mmacosx-version-min=10.13")

    if(${BUILD_ARCH} STREQUAL "x64")
        set(CMAKE_OSX_ARCHITECTURES "x86_64")
        set(BUILD_TARGET "x86_64-apple-darwin")
    elseif(${BUILD_ARCH} STREQUAL "arm64")
        set(CMAKE_OSX_ARCHITECTURES "arm64")
        set(BUILD_TARGET "aarch64-apple-darwin")
    else()
        message(FATAL_ERROR "Unsupported target architecture {${BUILD_ARCH}}.")
    endif()

    set(flags "${flags} --target=${BUILD_TARGET}")
    set(CMAKE_ASM_COMPILER_TARGET "${BUILD_TARGET}")

    set(CMAKE_ASM_FLAGS "-mmacosx-version-min=10.13")

    if(src_platform_list)
        enable_language(OBJCXX)
        set(CMAKE_OBJCXX_COMPILER /usr/bin/clang++)
    endif()
endif()

set(flags "${flags} -fPIC -fsigned-char -fmessage-length=0 -fdata-sections -ffunction-sections")
set(CMAKE_ASM_FLAGS "${CMAKE_ASM_FLAGS} -Wno-unused-command-line-argument")

if(${BUILD_TYPE} STREQUAL "release")
    set(flags "${flags} -O3 -s -w -fvisibility=hidden")
    add_definitions(-DNDEBUG=1)

    if(NOT "${BUILD_OS}" STREQUAL "Windows")
        set(link_flags "${link_flags} -static-libstdc++")

        if("${CMAKE_HOST_SYSTEM_NAME}" STREQUAL "Darwin")
            set(link_flags "${link_flags} -Wl,-dead_strip")
        else()
            set(link_flags "${link_flags} -static-libgcc -Wl,--gc-sections")
        endif()
    endif()
elseif(${BUILD_TYPE} STREQUAL "debug")
    set(flags "${flags} -g1 -O0")

    if(${BUILD_ARCH} STREQUAL "mips64")
        set(flags "${flags} -mxgot")
        set(link_flags "${link_flags} -mxgot")
    endif()

    set(flags "${flags} -Wall -Wno-unused-function")

    add_definitions(-DDEBUG=1)

    if("${BUILD_OS}" STREQUAL "Windows")
        add_definitions(-D_DEBUG)
        set(flags "${flags} -w")
    endif()
endif()

if(NOT "${BUILD_OS}" STREQUAL "Windows")
    include(CheckIncludeFileCXX)
    set(CMAKE_REQUIRED_FLAGS "${flags}")
    unset(HAS_COMPARE CACHE)
    CHECK_INCLUDE_FILE_CXX(compare HAS_COMPARE)
    unset(CMAKE_REQUIRED_FLAGS)
    if(NOT HAS_COMPARE)
        include_directories("${CMAKE_CURRENT_LIST_DIR}/../patch/cxx20/10")
    endif()
endif()