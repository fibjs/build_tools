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
# build tree, and the library that owns assembly states its language itself (see
# tests/entry/asmprobe/CMakeLists.txt).  Targets without an assembler for it
# skip the probe and leave a marker, so it is listed here unconditionally.
list(APPEND libs
    asmprobe
    asmsteal
)
