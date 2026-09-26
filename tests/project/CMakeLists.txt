cmake_minimum_required(VERSION 3.10)

# Self test case A: a repository that is a single CMake project at its root
# (the vender / fibjs layout).
#
#   cmake -S . -B out/<OS>_<ARCH>_<TYPE> -DFIBJS_BIN_DIR=bin/<OS>_<ARCH>_<TYPE>
#
# config.cmake comes first: it detects the platform/arch/type and the compiler
# that project() is about to use.
include(${CMAKE_CURRENT_LIST_DIR}/../../cmake/config.cmake)

project(selfcheck C CXX)

# Feature checks and the generated configuration headers, once for the tree.
include(${CMAKE_CURRENT_LIST_DIR}/../../cmake/option_config.cmake)
fibjs_config_target()

add_subdirectory(selfcheck)
add_subdirectory(selfcheck/test)
