cmake_minimum_required(VERSION 3.10)

# Script-mode helper: print the distribution directory name
# (<OS>_<ARCH>_<TYPE>) that the build scripts use for out/ and bin/.
#
#   cmake -DBUILD_OS=linux -DBUILD_ARCH=x64 -DBUILD_TYPE=release \
#         -P build_tools/cmake-scripts/dist_dirname.cmake
#
# The name is computed by build_tools/cmake/config.cmake, which is the single
# source of truth for platform/arch/type detection in script and project mode.

include(${CMAKE_CURRENT_LIST_DIR}/../cmake/config.cmake)

# STATUS goes to stdout (plain message() goes to stderr), so the caller can do:
#   DIST_DIRNAME=$(cmake -P dist_dirname.cmake 2>/dev/null | tail -n 1 | sed 's/^-- //')
message(STATUS "${DIST_DIRNAME}")
