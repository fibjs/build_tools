cmake_minimum_required(VERSION 3.10)

# Executable built through cmake/LibraryTest.cmake: it links the library under
# test, so the assembly source has to have been assembled into it.
include(${CMAKE_CURRENT_LIST_DIR}/../../../../cmake/LibraryTest.cmake)
