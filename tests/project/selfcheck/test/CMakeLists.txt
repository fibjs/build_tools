cmake_minimum_required(VERSION 3.10)

# Executable built through cmake/LibraryTest.cmake: it links the library under
# test by target name (the library lives in the parent directory).
include(${CMAKE_CURRENT_LIST_DIR}/../../../../cmake/LibraryTest.cmake)
