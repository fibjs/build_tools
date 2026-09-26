cmake_minimum_required(VERSION 3.10)

# ============================================================================
# Prebuilt vendored libraries (USE_VENDER_DIST / -DFIBJS_VENDER=dist)
#
# Downloads (or reuses) a release archive of the vendored libraries and declares
# every library as an IMPORTED target, so the rest of the build tree links the
# very same target names as in the in-tree build.  This is the CI path: it lets
# an application build without compiling vender.
#
# Inputs:
#   FIBJS_VENDER_DIR        the vendored sources (for libs.cmake and the tag),
#                           default <current source dir>/vender
#   FIBJS_VENDER_DIST_DIR   directory containing <OS>_<ARCH>_<TYPE>/lib*.a
#                           (skips the download; used for local testing)
#   FIBJS_VENDER_TAG / $VENDER_TAG   release tag to download
#
# Archive layout: <OS>_<ARCH>_<TYPE>/lib<name>.a, i.e. the repository's bin/
# directory with the leading component stripped by FetchContent.
# ============================================================================

if("${FIBJS_VENDER_DIR}" STREQUAL "")
    set(FIBJS_VENDER_DIR "${CMAKE_CURRENT_SOURCE_DIR}/vender")
endif()

if("${FIBJS_VENDER_TAG}" STREQUAL "")
    if(NOT "$ENV{VENDER_TAG}" STREQUAL "")
        message(NOTICE "env vender tag: $ENV{VENDER_TAG}\n")
        set(FIBJS_VENDER_TAG "$ENV{VENDER_TAG}")
    else()
        message(NOTICE "no vender tag specified, try to find the latest tag\n")
        file(READ ${FIBJS_VENDER_DIR}/.git GIT_DIR)
        string(REPLACE "gitdir: " "" GIT_DIR ${GIT_DIR})
        string(REPLACE "\n" "" GIT_DIR ${GIT_DIR})
        set(GIT_DIR "${FIBJS_VENDER_DIR}/${GIT_DIR}")

        file(READ "${GIT_DIR}/HEAD" REF_HEAD)

        if("${REF_HEAD}" MATCHES "ref: ([^\n\r]*)")
            file(READ "${GIT_DIR}/${CMAKE_MATCH_1}" REF_HEAD)
        endif()

        string(STRIP "${REF_HEAD}" REF_HEAD)

        file(READ ${GIT_DIR}/packed-refs GIT_TAGS)
        string(REGEX MATCH "${REF_HEAD} refs/tags/([^\n\r]+)" MATCHED_LINE ${GIT_TAGS})

        if(NOT "${MATCHED_LINE}" STREQUAL "")
            string(REGEX REPLACE "${REF_HEAD} refs/tags/([^\n\r]+)" "\\1" FIBJS_VENDER_TAG ${MATCHED_LINE})
        endif()

        file(GLOB ALL_TAGS "${GIT_DIR}/refs/tags/*")

        foreach(FILE ${ALL_TAGS})
            file(READ ${FILE} CONTENT)
            string(STRIP "${CONTENT}" CONTENT)

            if("${CONTENT}" STREQUAL "${REF_HEAD}")
                get_filename_component(FIBJS_VENDER_TAG ${FILE} NAME)
                break()
            endif()
        endforeach()
    endif()
endif()

if("${FIBJS_VENDER_DIST_DIR}" STREQUAL "")
    if("${FIBJS_VENDER_TAG}" STREQUAL "")
        message(FATAL_ERROR "cannot find vender tag")
    endif()

    message("using vender tag: ${FIBJS_VENDER_TAG}\n")

    if("${BUILD_OS}" STREQUAL "Linux")
        set(BUILD_TARGET "linux")
    elseif("${BUILD_OS}" STREQUAL "Alpine")
        set(BUILD_TARGET "alpine")
    elseif("${BUILD_OS}" STREQUAL "Darwin")
        set(BUILD_TARGET "darwin")
    elseif("${BUILD_OS}" STREQUAL "Windows")
        set(BUILD_TARGET "win32")
    elseif("${BUILD_OS}" STREQUAL "Android")
        set(BUILD_TARGET "android")
    elseif("${BUILD_OS}" STREQUAL "iPhone")
        set(BUILD_TARGET "iphone")
    elseif("${BUILD_OS}" STREQUAL "iPhoneSimulator")
        set(BUILD_TARGET "iphone-simulator")
    endif()

    message("downloading: ${FIBJS_VENDER_TAG}/fibjs_vender-${BUILD_TARGET}-${BUILD_ARCH}-${BUILD_TYPE}.tar.gz\n")

    include(FetchContent)

    FetchContent_Declare(
        vender
        URL "https://github.com/fibjs/fibjs_vender/releases/download/${FIBJS_VENDER_TAG}/fibjs_vender-${BUILD_TARGET}-${BUILD_ARCH}-${BUILD_TYPE}.tar.gz"
    )

    FetchContent_GetProperties(vender)

    if(NOT vender_POPULATED)
        FetchContent_Populate(vender)
    endif()

    set(FIBJS_VENDER_DIST_DIR "${vender_SOURCE_DIR}")
endif()

if(NOT EXISTS "${FIBJS_VENDER_DIST_DIR}/${DIST_DIRNAME}")
    message(FATAL_ERROR "vender dist not found: ${FIBJS_VENDER_DIST_DIR}/${DIST_DIRNAME}")
endif()

message("using vender dist: ${FIBJS_VENDER_DIST_DIR}/${DIST_DIRNAME}\n")

file(COPY "${FIBJS_VENDER_DIST_DIR}/${DIST_DIRNAME}/" DESTINATION "${FIBJS_BIN_DIR}")

include(${FIBJS_VENDER_DIR}/libs.cmake)

foreach(lib ${libs})
    if(NOT TARGET ${lib})
        add_library(${lib} STATIC IMPORTED GLOBAL)
        set_target_properties(${lib} PROPERTIES
            IMPORTED_LOCATION "${FIBJS_BIN_DIR}/${CMAKE_STATIC_LIBRARY_PREFIX}${lib}${CMAKE_STATIC_LIBRARY_SUFFIX}")
    endif()
endforeach()
