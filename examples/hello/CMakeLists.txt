cmake_minimum_required(VERSION 3.10)

# One CMake project per repository: config.cmake detects the platform, the
# architecture, the build type and the compiler that project() is about to use.
include(${CMAKE_CURRENT_LIST_DIR}/../../cmake/config.cmake)

get_filename_component(name ${CMAKE_CURRENT_SOURCE_DIR} NAME)
project(${name})

include(${CMAKE_CURRENT_LIST_DIR}/../../cmake/Library.cmake)

add_subdirectory(test)
