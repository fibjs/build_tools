cmake_minimum_required(VERSION 3.10)

# Self test case B: the project that tests/script/build.cmake configures.
# It does not call project() itself - the driver script provides the build
# environment (BUILD_OS/BUILD_ARCH/BUILD_TYPE, BT_BIN_DIR).
project(scriptcheck C)

add_library(scriptcheck SHARED src/scriptcheck.c)

set_target_properties(scriptcheck PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY "${BT_BIN_DIR}"
    RUNTIME_OUTPUT_DIRECTORY "${BT_BIN_DIR}")
