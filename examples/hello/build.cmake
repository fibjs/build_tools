cmake_minimum_required(VERSION 3.10)

# Single-project build: configure and build the example in one pass.
#
#   cmake -DBUILD_ARCH=x64 -DBUILD_TYPE=release -DBUILD_JOBS=4 -P build.cmake
#
# Artifacts land in output/bin/<OS>_<ARCH>_<TYPE> (BT_BIN_DIR).

include(ProcessorCount)

if("${BUILD_TYPE}" STREQUAL "")
    set(BUILD_TYPE release)
endif()

if("${BUILD_JOBS}" STREQUAL "")
    ProcessorCount(BUILD_JOBS)
endif()

set(EXAMPLE_DIR "${CMAKE_CURRENT_LIST_DIR}")
set(WORK_ROOT "${EXAMPLE_DIR}/output")
set(BUILD_DIR "${WORK_ROOT}/out")
set(BIN_DIR "${WORK_ROOT}/bin")

if("${CLEAN_BUILD}" STREQUAL "true")
    file(REMOVE_RECURSE "${WORK_ROOT}")
endif()

file(MAKE_DIRECTORY "${BUILD_DIR}")

# The library and its test are two projects; both write into the same BIN_DIR.
foreach(target "${EXAMPLE_DIR}" "${EXAMPLE_DIR}/test")
    if(NOT EXISTS "${target}/CMakeLists.txt")
        continue()
    endif()

    get_filename_component(target_name "${target}" NAME)
    set(target_build_dir "${BUILD_DIR}/${target_name}")

    execute_process(WORKING_DIRECTORY "${target}"
        COMMAND ${CMAKE_COMMAND}
            -DBUILD_ARCH=${BUILD_ARCH}
            -DBUILD_TYPE=${BUILD_TYPE}
            -DBUILD_JOBS=${BUILD_JOBS}
            -DBUILD_WITH_MSVC=${BUILD_WITH_MSVC}
            -DBT_BIN_DIR=${BIN_DIR}
            -S "${target}"
            -B "${target_build_dir}"
        RESULT_VARIABLE STATUS
    )

    if(NOT STATUS EQUAL 0)
        message(FATAL_ERROR "[hello] configure failed for ${target}: ${STATUS}")
    endif()

    execute_process(
        COMMAND ${CMAKE_COMMAND} --build "${target_build_dir}" -- -j${BUILD_JOBS}
        RESULT_VARIABLE STATUS
    )

    if(NOT STATUS EQUAL 0)
        message(FATAL_ERROR "[hello] build failed for ${target}: ${STATUS}")
    endif()
endforeach()
