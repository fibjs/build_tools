# dirty code for replace compilation options of MSVC
macro(configure_msvc_runtime)
    set(variables
        CMAKE_C_FLAGS
        CMAKE_C_FLAGS_RELEASE
        CMAKE_CXX_FLAGS
        CMAKE_CXX_FLAGS_RELEASE)

    foreach(variable ${variables})
        if(${variable} MATCHES "/MD")
            string(REGEX REPLACE "/MD" "/MT" ${variable} "${${variable}}")
            set(${variable} "${${variable}}" CACHE STRING "MSVC_MP_${variable}" FORCE)
        endif()
    endforeach()
endmacro()

macro(configure_msvc_mp)
    set(variables
        CMAKE_C_FLAGS
        CMAKE_C_FLAGS_RELEASE
        CMAKE_CXX_FLAGS
        CMAKE_CXX_FLAGS_RELEASE)

    foreach(variable ${variables})
        # enforce multiple core processing
        if(NOT ${variable} MATCHES "/MD")
            set(${variable} "${${variable}} /MP" CACHE STRING "MSVC_${variable}" FORCE)
        endif()
    endforeach()
endmacro()

# keep same name format with Unix
set(CMAKE_STATIC_LIBRARY_PREFIX "lib")

add_definitions(-DWIN32 -D_LIB -D_CRT_SECURE_NO_WARNINGS -D_CRT_RAND_S -DNOMINMAX)

if("${CMAKE_CXX_STANDARD}" STREQUAL "")
    set(CMAKE_CXX_STANDARD 17)
endif()
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(flags "${flags} /utf-8")

configure_msvc_mp()
if(${BUILD_TYPE} STREQUAL "release")
	set(flags "${flags} -W0")

    configure_msvc_runtime()

	add_definitions(-DNDEBUG=1)
elseif(${BUILD_TYPE} STREQUAL "debug")
	add_definitions(-DDEBUG=1 -D_DEBUG)
endif()

set(link_flags "${link_flags} /SAFESEH:NO")
