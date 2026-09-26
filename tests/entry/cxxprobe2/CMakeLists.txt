cmake_minimum_required(VERSION 3.10)

# The second C++ library of the tree.
#
# The base flags of the tree are applied in the directory scope of each library
# (cmake/option_flags.cmake), so this library only compiles when they reach
# every library of libs.cmake and not just the first one.
include(${CMAKE_CURRENT_LIST_DIR}/../../../cmake/Library.cmake)
