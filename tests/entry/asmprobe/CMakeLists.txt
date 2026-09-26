cmake_minimum_required(VERSION 3.10)

# Assembly probe: cmake gives the .asm extension to the assembly language that
# was enabled last in the build tree, so a library whose assembly is written in
# another language has to be pinned (cmake/Library.cmake).  The library list of
# this repository states the language (asm_language_asmprobe), exactly like the
# vendored tree states it for v8, blst and openssl, and the check below fails
# the configure step when the pin did not reach the sources - asmsteal/ enables
# a second assembly language after this one, so the pin is what keeps the source
# out of that assembler.
if("${BUILD_OS}" STREQUAL "Windows")
    enable_language(ASM_MASM)
    set(asmprobe_asm_source "${CMAKE_CURRENT_SOURCE_DIR}/src/asmprobe_masm.asm")
else()
    enable_language(ASM)
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