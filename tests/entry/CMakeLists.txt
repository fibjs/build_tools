cmake_minimum_required(VERSION 3.10)

# Self test case C: a repository with its own entry script (tests/entry/build),
# built for whatever architecture/platform the entry point was asked for.  This
# is the case that the full architecture matrix runs, because it goes through
# build_env.sh (docker dispatch) exactly like vender and fibjs do.
#
# The layout mirrors the vender tree - a root CMakeLists.txt that configures the
# feature checks once, a libs.cmake with the library list, and one directory per
# library - so that the failures of a vender build show up here as well: see
# cxxprobe/src/cxxprobe.cpp.
#
# config.cmake comes first: it detects the platform/arch/type and the compiler.
include(${CMAKE_CURRENT_LIST_DIR}/../../cmake/config.cmake)

project(entrycheck C CXX)

include(${CMAKE_CURRENT_LIST_DIR}/../../cmake/option_config.cmake)
fibjs_config_target()

include(${CMAKE_CURRENT_LIST_DIR}/libs.cmake)

foreach(lib ${libs})
    if(EXISTS "${CMAKE_CURRENT_LIST_DIR}/${lib}/CMakeLists.txt")
        add_subdirectory(${lib})
    endif()
endforeach()

foreach(lib ${libs})
    if(EXISTS "${CMAKE_CURRENT_LIST_DIR}/${lib}/test/CMakeLists.txt")
        add_subdirectory(${lib}/test)
    endif()
endforeach()
