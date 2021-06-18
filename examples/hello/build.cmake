include(../../cmake-scripts/get_env.cmake)

set(WORK_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/output")

set(BIN_ROOT "${WORK_ROOT}/bin")
set(OUT_ROOT "${WORK_ROOT}/out")
set(DIST_DIRNAME "${CMAKE_HOST_SYSTEM_NAME}_${BUILD_ARCH}_${BUILD_TYPE}")

if("${CLEAN_BUILD}" STREQUAL "true")
    rimraf(${BIN_ROOT}/${DIST_DIRNAME})
    rimraf(${OUT_ROOT}/${DIST_DIRNAME})
else()
    set(OUT_PATH "${OUT_ROOT}/${DIST_DIRNAME}")

    build("${CMAKE_CURRENT_SOURCE_DIR}" "${OUT_PATH}/hello")

    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/test")
        build("${CMAKE_CURRENT_SOURCE_DIR}/test" "${OUT_PATH}/hello_test")
    endif()
endif()
