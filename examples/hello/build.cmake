
include(../../cmake-scripts/get_env.cmake)
set(WORK_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/output")

set(BIN_ROOT "${WORK_ROOT}/bin")
set(OUT_ROOT "${WORK_ROOT}/out")

if("${CLEAN_BUILD}" STREQUAL "true")
    rimraf(${BIN_ROOT})
    rimraf(${OUT_ROOT})
else()
    build("${CMAKE_CURRENT_SOURCE_DIR}" "${WORK_ROOT}", "hello")

    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/test")
        build("${CMAKE_CURRENT_SOURCE_DIR}/test" "${WORK_ROOT}" "hello_test")
    endif()
endif()
