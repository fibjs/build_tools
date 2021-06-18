# build_tools

fibjs's build_tools based on .cmake

# Getting Started

To use build_tools for fibjs, you need install:

- CMake >= 3.0
- C/Cpp Compiler
    - Windows: clang/VC++
    - Linux: clang
    - MacOS: clang

To explain how to use built_tools, we try to compile [examples/hello](./examples/hello/build.cmake).

All `<built_tool_path>` in codes refers to this project's root path.

### Workflow on CMake ccripts

We recommend CMake script-mode as build workflow, that is, instead of bash/sh/cmd/powershell, just use CMake script to 
drive your build.

```CMake
include(<built_tool_path>/cmake-scripts/get_env.cmake)

set(WORK_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/output")

set(BIN_ROOT "${WORK_ROOT}/bin")
set(OUT_ROOT "${WORK_ROOT}/out")
set(DIST_DIRNAME "${CMAKE_HOST_SYSTEM_NAME}_${BUILD_ARCH}_${BUILD_TYPE}")

if("${CLEAN_BUILD}" STREQUAL "true")
    rimraf(${BIN_ROOT}/${DIST_DIRNAME})
    rimraf(${OUT_ROOT}/${DIST_DIRNAME})
else()
    set(OUT_PATH "${OUT_ROOT}/${DIST_DIRNAME}")

    build("${CMAKE_CURRENT_SOURCE_DIR}" "${OUT_PATH}/hello")

    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/test")
        build("${CMAKE_CURRENT_SOURCE_DIR}/test" "${OUT_PATH}/hello_test")
    endif()
endif()
```

As of this script, `build` funciton is defined in  `<built_tool_path>/cmake-scripts/get_env.cmake`.

```CMake
build(src_dirname, outputpath)
```

It tried to find `<src_dirname>/CMakeLists.txt` and run do cmake build against it. That is, you can customize by writing your own CMakeList.txt

### Create CMakeLists.txt

Add one CMakeLists.txt on your project. like [examples/hello/CMakeLists.txt](./examples/hello/CMakeLists.txt).

To build one **static** Library, include `cmake/Library.cmake`

```CMake
cmake_minimum_required(VERSION 2.6)

include(<built_tool_path>/cmake/Library.cmake)
```

Or put one CMakeLists.txt on project_root's test directory, like [examples/hello/test/CMakeLists.txt](./examples/hello/test/CMakeLists.txt).

To build one **test** executation, include `cmake/LibraryTest.cmake`

```CMake
cmake_minimum_required(VERSION 2.6)

include(<built_tool_path>/cmake/LibraryTest.cmake)
```

### Run CMake

```bash
cmake -DBUILD_ARCH=amd64\
    -DBUILD_TYPE=release\
    -DCLEAN_BUILD=""\
    -DBUILD_JOBS=4\
    -DBUILD_USE_CLANG=1\
    -P build.cmake
```

see more configuration on 

- [examples/hello/build](./examples/hello/build) for bash
- [examples/hello/build.cmd](./examples/hello/build.cmd) for windows cmd

## Copyright

[MIT](./LICENSE) License