# build_tools

fibjs's build_tools based on .cmake

# Getting Started

To use build_tools for fibjs, you need install:

- CMake >= 3.0
- C/Cpp Compiler
  - Windows: clang/VC++
  - Linux: clang
  - MacOS: clang

To explain how to use built_tools, we try to compile [examples/hello](./examples/hello/CMakeLists.txt).

All `<built_tool_path>` in codes refers to this project's root path.

### Workflow

One CMake project per repository, configured and built in one pass:

```bash
cmake -DBUILD_ARCH=x64 -DBUILD_TYPE=release -DFIBJS_BIN_DIR=$PWD/bin \
      -S . -B out/Linux_x64_release
cmake --build out/Linux_x64_release -- -j8
```

`cmake/config.cmake` detects the platform/architecture/type (overridable with
`-DBUILD_OS`, `-DBUILD_ARCH`, `-DBUILD_TYPE`, `-DBUILD_JOBS`) and computes the
artifact directory `FIBJS_BIN_DIR` (`bin/<OS>_<ARCH>_<TYPE>`).

A top-level CMakeLists.txt adds the projects with `add_subdirectory` and calls
`fibjs_config_target()` once for the whole tree (feature checks and the
generated `glibc_config.h` / `std_config.h` / `gitinfo.h`).

> The historical script-mode driver (`cmake-scripts/get_env.cmake` with the
> `build()` function) was removed; builds are plain CMake projects now.

### Create CMakeLists.txt

Add one CMakeLists.txt on your project. like [examples/hello/CMakeLists.txt](./examples/hello/CMakeLists.txt).

To build one **static** Library, include `cmake/Library.cmake`

```CMake
cmake_minimum_required(VERSION 3.10)

include(<built_tool_path>/cmake/Library.cmake)
```

Or put one CMakeLists.txt on project_root's test directory, like [examples/hello/test/CMakeLists.txt](./examples/hello/test/CMakeLists.txt).

To build one **test** executation, include `cmake/LibraryTest.cmake`

```CMake
cmake_minimum_required(VERSION 3.10)

include(<built_tool_path>/cmake/LibraryTest.cmake)
```

### Run CMake

The example driver configures and builds the project in one pass:

```bash
cd examples/hello
bash build x64 release -j4
```

see more configuration on

- [examples/hello/build](./examples/hello/build) for bash
- [examples/hello/build.cmd](./examples/hello/build.cmd) for windows cmd

### Assembly sources

CMake keeps one "extension -> language" map per configure, and it gives an
extension to the language that was enabled last.  A build tree that enables more
than one assembly language (for example `ASM_MASM` and `ASM_NASM`, as the
vendored tree does on Windows) would therefore assemble the sources of a library
with the assembler of another one.

A library states the language its `.asm` sources are written in, and
`cmake/Library.cmake` pins those sources with the `LANGUAGE` source property:

- the library list of the repository (its `libs.cmake`) sets
  `asm_language_<library>`, which keeps the statement with the library list
  itself, or
- a library sets `asm_language` for itself, before including
  `cmake/Library.cmake`.

Libraries that are not listed are assembled with the language of the extension,
which is what a build tree with a single assembly language needs.

## Copyright

[MIT](./LICENSE) License
