cmake_minimum_required(VERSION 3.10)

# Executable built through cmake/LibraryTest.cmake: it links the library under
# test, so the assembly source has to have been assembled into it.  Targets
# without an assembler for the probe do not build the library at all.
if(NOT TARGET asmprobe)
    message(STATUS "asmprobe_test: skipped, the probe library is not built")
    return()
endif()

include(${CMAKE_CURRENT_LIST_DIR}/../../../../cmake/LibraryTest.cmake)
