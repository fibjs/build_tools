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

    if(${BUILD_ARCH} STREQUAL "x64")
        set(flags "${flags} --target=x86_64-pc-windows-msvc")
    else()
        set(flags "${flags} --target=i686-pc-windows-msvc")
    endif()

    # keep same name format with Unix
    set(CMAKE_STATIC_LIBRARY_PREFIX "lib")

	add_definitions(-DWIN32 -D_LIB -D_CRT_SECURE_NO_WARNINGS -D_CRT_RAND_S -DNOMINMAX)
	set(flags "${flags} -fms-extensions -fmsc-version=1910 -frtti")

    if(${BUILD_TYPE} STREQUAL "debug")
        set(flags "${flags} -Xclang --dependent-lib=libcmtd")
    elseif(${BUILD_TYPE} STREQUAL "release")
        set(flags "${flags} -Xclang --dependent-lib=libcmt")
    endif()
elseif("${BUILD_OS}" STREQUAL "iPhone")
    set(flags "${flags} -Wno-nullability-completeness -miphoneos-version-min=12.0")
    set(link_flags "${link_flags} -miphoneos-version-min=12.0")

    if(${BUILD_ARCH} STREQUAL "x64")
        execute_process(
            COMMAND xcrun --sdk iphonesimulator --show-sdk-path
            OUTPUT_VARIABLE CMAKE_OSX_SYSROOT
            OUTPUT_STRIP_TRAILING_WHITESPACE
        )

        set(CMAKE_OSX_ARCHITECTURES "x86_64")
        set(BUILD_TARGET "x86_64-apple-ios-simulator")
    elseif(${BUILD_ARCH} STREQUAL "arm64")
        execute_process(
            COMMAND xcrun --sdk iphoneos --show-sdk-path
            OUTPUT_VARIABLE CMAKE_OSX_SYSROOT
            OUTPUT_STRIP_TRAILING_WHITESPACE
        )

        set(CMAKE_OSX_ARCHITECTURES "arm64")
        set(BUILD_TARGET "aarch64-apple-ios")
    else()
        message(FATAL_ERROR "Unsupported target architecture {${BUILD_ARCH}}.")
    endif()

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

	set(link_flags "${link_flags} -static-libstdc++")
	add_definitions(-DNDEBUG=1)

    if("${CMAKE_HOST_SYSTEM_NAME}" STREQUAL "Darwin")
        set(link_flags "${link_flags} -Wl,-dead_strip")
    else()
		set(link_flags "${link_flags} -static-libgcc -Wl,--gc-sections")
	endif()
elseif(${BUILD_TYPE} STREQUAL "debug")
	set(flags "${flags} -g1 -O0")

    if(${BUILD_ARCH} STREQUAL "mips64")
        set(flags "${flags} -mxgot")
    endif()

    set(flags "${flags} -Wall -Wno-unused-function")

	add_definitions(-DDEBUG=1)

	if("${BUILD_OS}" STREQUAL "Windows")
		add_definitions(-D_DEBUG)
	endif()
endif()