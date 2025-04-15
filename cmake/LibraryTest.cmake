cmake_minimum_required(VERSION 3.10)

get_filename_component(src ${CMAKE_CURRENT_SOURCE_DIR} DIRECTORY)
get_filename_component(libname ${src} NAME)
set(name "${libname}_test")

project(${name})

include(${CMAKE_CURRENT_LIST_DIR}/option.cmake)

add_executable(${name} ${src_list})

include_directories(${PROJECT_SOURCE_DIR}/../ "${PROJECT_SOURCE_DIR}/../include" "${PROJECT_SOURCE_DIR}/../../")

if(NOT DEFINED test_libs)
	set(test_libs "")
endif()

set(libs ${libname} ${libs} ${test_libs})

foreach(lib ${libs})
	target_link_libraries(${name} "${BIN_PATH}/${CMAKE_STATIC_LIBRARY_PREFIX}${lib}${CMAKE_STATIC_LIBRARY_SUFFIX}")
endforeach()

setup_result_library(${name})
