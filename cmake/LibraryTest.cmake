get_filename_component(src ${CMAKE_CURRENT_SOURCE_DIR} DIRECTORY)
get_filename_component(libname ${src} NAME)
set(name "${libname}_test")

project(${name})

include(${CMAKE_CURRENT_LIST_DIR}/option.cmake)

add_executable(${name} ${src_list})

include_directories(${PROJECT_SOURCE_DIR}/../ "${PROJECT_SOURCE_DIR}/../include" "${PROJECT_SOURCE_DIR}/../../")

if(NOT DEFINED test_libs)
	message(FATAL_ERROR "[LibraryTest.cmake] test_libs is required!")
endif()

set(libs ${libname} ${libs} ${test_libs})
foreach(lib ${libs})
	target_link_libraries(${name} "${EXECUTABLE_OUTPUT_PATH}/${CMAKE_STATIC_LIBRARY_PREFIX}${lib}${CMAKE_STATIC_LIBRARY_SUFFIX}")
endforeach()

setup_result_library(${name})

if(link_flags)
	set_target_properties(${name} PROPERTIES LINK_FLAGS ${link_flags})
endif()