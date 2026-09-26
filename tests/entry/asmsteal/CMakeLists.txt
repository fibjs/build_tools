cmake_minimum_required(VERSION 3.10)

# The library that takes the .asm extension away from the assembly probe: cmake
# gives an extension to the assembly language that was enabled last, so this
# library - which is added after asmprobe - decides how the .asm sources of the
# tree are assembled.  asmprobe states its own language (libs.cmake:
# asm_language_asmprobe), which is what keeps its source in its own assembler.
#
# The language here is the one that is not used by the probe:
#   Windows        ASM_NASM (nasm, tools/asm/nasm.exe of build_tools)
#   Linux, macOS   ASM-ATT (gas/as, which claims .asm as well)
if("${BUILD_OS}" STREQUAL "Windows")
    if("${CMAKE_ASM_NASM_COMPILER}" STREQUAL "" OR NOT EXISTS "${CMAKE_ASM_NASM_COMPILER}")
        message(STATUS "asmsteal: no NASM assembler, the .asm extension stays with the probe")
        return()
    endif()

    enable_language(ASM_NASM OPTIONAL)
else()
    # gas/as, which claims .asm as well; targets that have no such assembler
    # (the android toolchain for example) simply keep the extension with the
    # probe library.
    enable_language(ASM-ATT OPTIONAL)
endif()

set(src_list "${CMAKE_CURRENT_SOURCE_DIR}/src/asmsteal.c")

include(${CMAKE_CURRENT_LIST_DIR}/../../../cmake/Library.cmake)
