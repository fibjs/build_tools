cmake_minimum_required(VERSION 3.10)

# Assembly probe: cmake gives the .asm extension to the assembly language that
# was enabled last in the build tree, so a library whose assembly is written in
# another language has to be pinned (cmake/Library.cmake).  The library list of
# this repository states the language (asm_language_asmprobe), exactly like the
# vendored tree states it for v8, blst and openssl, and asmsteal/ enables a
# second assembly language after this one - the pin is what keeps the source in
# the assembler of its own language.
#
# The probe is only built where its source can be assembled: MASM on Windows
# x64/ia32, the clang driver (which accepts .asm) elsewhere.  The gcc drivers
# only know .s/.S and Windows arm64 has no MASM, so those targets skip it.
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

    enable_language(ASM_MASM)
    set(asmprobe_asm_source "${CMAKE_CURRENT_SOURCE_DIR}/src/asmprobe_masm.asm")
else()
    enable_language(ASM)

    if(NOT "${CMAKE_ASM_COMPILER}" MATCHES "clang")
        file(WRITE "${FIBJS_BIN_DIR}/asmprobe-skipped" "the assembler driver does not accept .asm\n")
        message(STATUS "asmprobe: skipped, the assembler driver does not accept .asm")
        return()
    endif()

    set(asmprobe_asm_source "${CMAKE_CURRENT_SOURCE_DIR}/src/asmprobe_gnu.asm")
endif()

set(src_list
    "${CMAKE_CURRENT_SOURCE_DIR}/src/asmprobe.c"
    "${asmprobe_asm_source}")

include(${CMAKE_CURRENT_LIST_DIR}/../../../cmake/Library.cmake)

# The language of the sources is checked after the build (tests/run.sh inspects
# the rule that assembled them): querying the LANGUAGE property here would
# determine and freeze the language of the file before asmsteal/ claims the
# extension, which is exactly what the check is about.
if(NOT DEFINED asm_language_asmprobe)
    message(FATAL_ERROR "asmprobe: libs.cmake does not state the language of this library")
endif()