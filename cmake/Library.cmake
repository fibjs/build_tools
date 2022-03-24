get_filename_component(name ${CMAKE_CURRENT_SOURCE_DIR} NAME)
project(${name})

include(${CMAKE_CURRENT_LIST_DIR}/option.cmake)

add_library(${name} ${src_list})

include_directories(${PROJECT_SOURCE_DIR} "${PROJECT_SOURCE_DIR}/include" "${PROJECT_SOURCE_DIR}/../")

setup_result_library(${name})