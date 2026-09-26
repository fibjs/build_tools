cmake_minimum_required(VERSION 3.10)

# Assembly probe: the library turns on the language of its .asm sources with
# enable_asm_language(), which states it at the same time - the vendored
# libraries do the same (v8 and blst assemble MASM syntax, openssl assembles
# NASM).  cmake gives the .asm extension to the assembly language that was
# enabled last in the tree, and asmsteal/ enables a second one after this
# library - the statement is what keeps the source in the assembler of its own
# language (option_asm.cmake pins it).
#
# The probe is only built where its source can be assembled: MASM on Windows
# x64/ia32, the clang driver (which accepts .asm) elsewhere.  The gcc drivers
# only know .s/.S and Windows arm64 has no MASM, so those targets skip it.
include(${CMAKE_CURRENT_LIST_DIR}/../../../cmake/option_asm.cmake)

if("${BUILD_OS}" STREQUAL "Windows")
    # MASM assembles the x64 sources of the tree.  The ia32 targets name C
    # symbols with a leading underscore (which a MASM source does not add) and
    # arm64 has no MASM at all, so the probe stays out of both.
    if(NOT "${BUILD_ARCH}" STREQUAL "x64")
        # The report of the runner reads this marker (tests/run.sh): a skipped
        # probe must not be reported as a missing artifact.  It lands next to
        # the artifacts, which is the directory the runner already knows.
        file(WRITE "${FIBJS_BIN_DIR}/asmprobe-skipped" "no MASM for the ${BUILD_ARCH} target\n")
        message(STATUS "asmprobe: skipped, no MASM for the ${BUILD_ARCH} target")
        return()
    endif()

    enable_asm_language(ASM_MASM)
    set(asmprobe_asm_source "${CMAKE_CURRENT_SOURCE_DIR}/src/asmprobe_masm.asm")
else()
    enable_language(ASM)

    if(NOT "${CMAKE_ASM_COMPILER}" MATCHES "clang")
        file(WRITE "${FIBJS_BIN_DIR}/asmprobe-skipped" "the assembler driver does not accept .asm\n")
        message(STATUS "asmprobe: skipped, the assembler driver does not accept .asm")
        return()
    endif()

    enable_asm_language(ASM)
    set(asmprobe_asm_source "${CMAKE_CURRENT_SOURCE_DIR}/src/asmprobe_gnu.asm")
endif()

set(src_list
    "${CMAKE_CURRENT_SOURCE_DIR}/src/asmprobe.c"
    "${asmprobe_asm_source}")

include(${CMAKE_CURRENT_LIST_DIR}/../../../cmake/Library.cmake)

# The language of the sources is checked after the build (tests/run.sh reports
# the failure of the assembler): querying the LANGUAGE property here would
# determine and freeze the language of the file before asmsteal/ claims the
# extension, which is exactly what the statement is about.