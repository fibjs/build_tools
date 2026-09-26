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

# Note: the variable is intentionally local - "libs" holds the full vendored
# library list in the parent scope of the unified build, and inheriting it here
# would link every library into every test.
set(test_link_libs ${libname} ${test_libs})

foreach(lib ${test_link_libs})
	if(TARGET ${lib})
		target_link_libraries(${name} ${lib})
	else()
		target_link_libraries(${name} "${BIN_PATH}/${CMAKE_STATIC_LIBRARY_PREFIX}${lib}${CMAKE_STATIC_LIBRARY_SUFFIX}")
	endif()
endforeach()

setup_result_library(${name})
