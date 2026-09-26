cmake_minimum_required(VERSION 3.10)

# Self test case B: a repository that drives its own build from a script-mode
# build.cmake (the addon layout, see fibjs/fib-addon).  build_tools/scripts/build
# takes the script-mode branch whenever build.cmake exists.
#
# The script below configures and builds this project in one pass.

include(${CMAKE_CURRENT_LIST_DIR}/../../cmake/config.cmake)

get_filename_component(name ${CMAKE_CURRENT_SOURCE_DIR} NAME)

if("${BT_BIN_DIR}" STREQUAL "")
    set(BT_BIN_DIR "${CMAKE_CURRENT_SOURCE_DIR}/bin/${DIST_DIRNAME}")
endif()

# bin/<OS>_<ARCH>_<TYPE> always lives at <work root>/bin/...; the driver passes
# BT_BIN_DIR, so the work root can be derived from it.
get_filename_component(WORK_ROOT "${BT_BIN_DIR}/../.." ABSOLUTE)

set(BUILD_DIR "${WORK_ROOT}/out/${DIST_DIRNAME}")
set(BIN_DIR "${BT_BIN_DIR}")

if("${CLEAN_BUILD}" STREQUAL "true")
    file(REMOVE_RECURSE "${WORK_ROOT}/out" "${WORK_ROOT}/bin")
endif()

file(MAKE_DIRECTORY "${BUILD_DIR}")

execute_process(WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
    COMMAND ${CMAKE_COMMAND}
        -DBUILD_ARCH=${BUILD_ARCH}
        -DBUILD_TYPE=${BUILD_TYPE}
        -DBUILD_OS=${BUILD_OS}
        -DBUILD_JOBS=${BUILD_JOBS}
        -DBUILD_WITH_MSVC=${BUILD_WITH_MSVC}
        -DBT_BIN_DIR=${BIN_DIR}
        -S "${CMAKE_CURRENT_SOURCE_DIR}"
        -B "${BUILD_DIR}"
    RESULT_VARIABLE STATUS)
if(NOT STATUS EQUAL 0)
    message(FATAL_ERROR "[scriptcheck] configure failed: ${STATUS}")
endif()

execute_process(COMMAND ${CMAKE_COMMAND} --build "${BUILD_DIR}" -- -j${BUILD_JOBS}
    RESULT_VARIABLE STATUS)
if(NOT STATUS EQUAL 0)
    message(FATAL_ERROR "[scriptcheck] build failed: ${STATUS}")
endif()

message("")
message("scriptcheck: built ${BIN_DIR}/${name}${CMAKE_SHARED_LIBRARY_SUFFIX}")
message("")
