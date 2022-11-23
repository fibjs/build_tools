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

if(${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Linux")
    message("[Linux] HOST_ARCH is ${HOST_ARCH}, TARGET_ARCH is ${ARCH}")

    execute_process(
        COMMAND gcc -dumpversion
        OUTPUT_VARIABLE GCC_VERSION
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    message("[Linux] GCC_VERSION is ${GCC_VERSION}")

    if(${ARCH} STREQUAL "amd64")
        set(BUILD_TARGET "x86_64-linux-gnu")
    elseif(${ARCH} STREQUAL "i386")
        set(BUILD_TARGET "i686-linux-gnu")
    elseif(${ARCH} STREQUAL "arm")
        set(BUILD_OPTION "${BUILD_OPTION} -march=armv7-a -mfpu=vfp3 -marm")
        set(BUILD_TARGET "arm-linux-gnueabihf")
    elseif(${ARCH} STREQUAL "arm64")
        set(BUILD_TARGET "aarch64-linux-gnu")
    elseif(${ARCH} STREQUAL "armv6")
        set(BUILD_OPTION "${BUILD_OPTION} -march=armv6 -mfpu=vfp -marm")
        set(BUILD_TARGET "arm-linux-gnueabihf")
    elseif(${ARCH} STREQUAL "mips")
        set(BUILD_TARGET "mips-linux-gnu")
    elseif(${ARCH} STREQUAL "mips64")
        set(BUILD_TARGET "mips64-linux-gnuabi64")
    elseif(${ARCH} STREQUAL "ppc")
        set(BUILD_TARGET "powerpc-linux-gnu")
    elseif(${ARCH} STREQUAL "ppc64")
        set(BUILD_TARGET "powerpc64-linux-gnu")
    endif()

    if(NOT ${HOST_ARCH} STREQUAL ${ARCH})
        if("${CMAKE_C_COMPILER}" STREQUAL "/usr/bin/clang")
            set(BUILD_OPTION "${BUILD_OPTION} --target=${BUILD_TARGET} -L/usr/lib/gcc-cross/${BUILD_TARGET}/${GCC_VERSION} -L/usr/${BUILD_TARGET}/lib -I/usr/${BUILD_TARGET}/include -I/usr/${BUILD_TARGET}/include/c++/${GCC_VERSION} -I/usr/${BUILD_TARGET}/include/c++/${GCC_VERSION}/${BUILD_TARGET}")
        endif()

        set(CMAKE_ASM_COMPILER_TARGET "${BUILD_TARGET}")
        set(CMAKE_ASM-ATT_TARGET "${BUILD_TARGET}")
        set(CMAKE_ASM-ATT_COMPILER "/usr/${BUILD_TARGET}/bin/as")
    endif()

elseif(${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Windows")
    clean_clang_flags()
    fixup_CMAKE_BUILD_TYPE()

    if(${ARCH} STREQUAL "amd64")
        set(BUILD_OPTION "${BUILD_OPTION} --target=x86_64-pc-windows-msvc")
    else()
        set(BUILD_OPTION "${BUILD_OPTION} --target=i686-pc-windows-msvc")
    endif()

    # keep same name format with Unix
    set(CMAKE_STATIC_LIBRARY_PREFIX "lib")

    set(CMAKE_CXX_STANDARD 14)

	add_definitions(-DWIN32 -D_LIB -D_CRT_SECURE_NO_WARNINGS -D_CRT_RAND_S -DNOMINMAX)
	set(flags "${flags} -fms-extensions -fmsc-version=1910 -frtti")

    if(${BUILD_TYPE} STREQUAL "debug")
        set(flags "${flags} -Xclang --dependent-lib=libcmtd")
    elseif(${BUILD_TYPE} STREQUAL "release")
        set(flags "${flags} -Xclang --dependent-lib=libcmt")
    endif()
elseif(${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Darwin")
	set(flags "${flags} -Wno-nullability-completeness -mmacosx-version-min=10.9 -DOBJC_OLD_DISPATCH_PROTOTYPES=1")
	set(link_flags "${link_flags} -framework WebKit -framework Cocoa -framework Carbon -framework IOKit -mmacosx-version-min=10.9")

    if(${ARCH} STREQUAL "amd64")
        set(CMAKE_OSX_ARCHITECTURES "x86_64")
        set(BUILD_TARGET "x86_64-apple-darwin")
    elseif(${ARCH} STREQUAL "arm64")
        set(BUILD_TARGET "aarch64-apple-darwin")
    elseif(${ARCH} STREQUAL "arm")
        set(BUILD_TARGET "aarch-apple-darwin")
    endif()

    if(NOT ${HOST_ARCH} STREQUAL ${ARCH})
        set(BUILD_OPTION "${BUILD_OPTION} --target=${BUILD_TARGET}")
        set(CMAKE_ASM_COMPILER_TARGET "${BUILD_TARGET}")
    endif()
	
    if(src_platform_list)
	    set_source_files_properties(${src_platform_list} PROPERTIES COMPILE_FLAGS "-x objective-c++")
    endif()
endif()

if("${CMAKE_CXX_STANDARD}" STREQUAL "")
    set(CMAKE_CXX_STANDARD 11)
endif()
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(flags "${flags} -fsigned-char -fmessage-length=0 -fdata-sections -ffunction-sections -D_FILE_OFFSET_BITS=64")

if(${BUILD_TYPE} STREQUAL "release")
	set(flags "${flags} -O3 -s ${BUILD_OPTION} -w -fomit-frame-pointer -fvisibility=hidden")

	if(${CMAKE_HOST_SYSTEM_NAME} STREQUAL "FreeBSD")
		set(flags "${flags} -fno-omit-frame-pointer")
	else()
		set(flags "${flags} -fomit-frame-pointer")
	endif()

	set(link_flags "${link_flags} ${BUILD_OPTION} -static-libstdc++")
	add_definitions(-DNDEBUG=1)

	if(${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Linux")
		set(link_flags "${link_flags} ${link_flags} -static-libgcc")
	endif()
elseif(${BUILD_TYPE} STREQUAL "debug")
	set(flags "${flags} -g -O0 ${BUILD_OPTION} -Wall -Wno-overloaded-virtual")
	set(link_flags "${link_flags} ${BUILD_OPTION}")
	add_definitions(-DDEBUG=1)

	if(${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Windows")
		add_definitions(-D_DEBUG)
	endif()
endif()