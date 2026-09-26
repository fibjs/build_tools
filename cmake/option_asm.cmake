cmake_minimum_required(VERSION 3.10)

# ============================================================================
# assembly sources
#
# A library turns on the language of its .asm sources with
# enable_asm_language(<language>) instead of enable_language(): the call
# enables the language and states that the .asm sources of that library are
# written in it, so the two cannot drift apart.  The library owns that fact, the
# build system only applies it - which is what the historical build got for free,
# because every library had its own build tree and its assembly language was
# never ambiguous there.
#
# In one build tree cmake keeps a single "extension -> language" map and gives an
# extension to the language that was enabled last, so without the statement the
# .asm sources of a library are assembled by the assembler of another library -
# one that is not even set in its scope.  That is how the vender Windows build
# failed with an empty nasm command line: v8 and blst assemble MASM syntax,
# openssl assembles NASM, and all three share one configure.
#
# The statement is applied below: the .asm sources of the library that is being
# configured are pinned to that language with the LANGUAGE source property.
#
# The one piece of tooling that lives here is the assembler of the NASM slot for
# the Windows targets (tools/asm/nasm.exe of this repository); the libraries do
# not carry copies of it.
# ============================================================================

# Enable an assembly language and state that the .asm sources of the calling
# library are written in it.  A macro, not a function: enable_language() has to
# run in file scope (cmake 3.16, which the build images ship, rejects it from a
# function), and the statement has to land in the caller's directory scope,
# which is where the pin below reads it.
macro(enable_asm_language language)
    enable_language(${language})
    set(ASM_LANGUAGE "${language}")
endmacro()

# The NASM assembler of the Windows targets.  Called by config.cmake, before any
# library enables ASM_NASM; a caller may override the cache entry with
# -DCMAKE_ASM_NASM_COMPILER.  The arm64 targets are not covered: v8 drives its
# own armasm wrapper there and states it itself.
function(asm_compilers)
    if(NOT "${BUILD_OS}" STREQUAL "Windows")
        return()
    endif()

    if(DEFINED CMAKE_ASM_NASM_COMPILER)
        return()
    endif()

    if("${BUILD_ARCH}" STREQUAL "arm64")
        return()
    endif()

    set(CMAKE_ASM_NASM_COMPILER "${CMAKE_CURRENT_LIST_DIR}/../tools/asm/nasm.exe"
        CACHE FILEPATH "assembler of the NASM language")
endfunction()

# Pin the .asm sources of the library that is being configured (included from
# option.cmake, after the library stated its assembly language and before its
# target is created).
if(DEFINED ASM_LANGUAGE AND NOT "${ASM_LANGUAGE}" STREQUAL "")
    set(asm_src_list ${src_list})
    list(FILTER asm_src_list INCLUDE REGEX "\\.[aA][sS][mM]$")

    if(asm_src_list)
        message(STATUS "${name}: .asm sources are assembled as ${ASM_LANGUAGE}")
        set_source_files_properties(${asm_src_list} PROPERTIES LANGUAGE ${ASM_LANGUAGE})
    endif()
endif()
