# The libraries of the self test repository, in the same shape as vender's
# libs.cmake: the tree root configures the feature checks once, then every
# library calls project() and cmake/Library.cmake on its own.
#
# The order is part of the test: the base flags of the tree are applied in the
# directory scope of each library (cmake/option_flags.cmake), so a regression
# that only reaches the first library of the list is caught by the libraries
# behind it.
set(libs
    entrycheck
    cxxprobe
    cxxprobe2
)

# The assembly probe: two assembly languages claim the .asm extension in one
# build tree and the library list pins the language of the probe, which is what
# the vendored tree does for v8, blst and openssl (see
# tests/entry/asmprobe/CMakeLists.txt).  Targets without an assembler for it
# skip the probe and leave a marker, so it is listed here unconditionally.
list(APPEND libs
    asmprobe
    asmsteal
)

if("${BUILD_OS}" STREQUAL "Windows")
    set(asm_language_asmprobe ASM_MASM)
else()
    set(asm_language_asmprobe ASM)
endif()
