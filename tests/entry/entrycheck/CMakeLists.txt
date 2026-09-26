cmake_minimum_required(VERSION 3.10)

# Static library built through cmake/Library.cmake, plus a small executable that
# proves the toolchain can link (and, on the host, run) it.
include(${CMAKE_CURRENT_LIST_DIR}/../../../cmake/Library.cmake)

add_executable(entrycheck_exe "${CMAKE_CURRENT_LIST_DIR}/main.c")
target_link_libraries(entrycheck_exe entrycheck)
