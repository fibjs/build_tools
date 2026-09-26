cmake_minimum_required(VERSION 3.10)

get_filename_component(name ${CMAKE_CURRENT_SOURCE_DIR} NAME)
project(${name})

include(${CMAKE_CURRENT_LIST_DIR}/option.cmake)

# --- assembly sources ---------------------------------------------------------
# cmake keeps one "extension -> language" map per configure and gives an
# extension to the language that was enabled last, so a library whose assembly
# is written in another language than that winner would be assembled by the
# assembler of another library - one that is not even set in this scope (the
# vender Windows build failed with an empty nasm command line that way).
#
# The library list of the repository states the language of a library with
# `asm_language_<library>`, or a library states it for itself with
# `asm_language`, set before including this file like src_list/flags/ccflags.
# The sources are then pinned with the LANGUAGE source property.  The historical
# build configured every library in its own build tree, where the extension was
# never ambiguous; this restores that isolation.
if(DEFINED asm_language_${name})
    set(fibjs_asm_language "${asm_language_${name}}")
elseif(DEFINED asm_language)
    set(fibjs_asm_language "${asm_language}")
else()
    set(fibjs_asm_language "")
endif()

if(NOT "${fibjs_asm_language}" STREQUAL "")
    set(fibjs_asm_src_list ${src_list})
    list(FILTER fibjs_asm_src_list INCLUDE REGEX "\\.[aA][sS][mM]$")

    if(fibjs_asm_src_list)
        set_source_files_properties(${fibjs_asm_src_list} PROPERTIES LANGUAGE ${fibjs_asm_language})
    endif()
endif()

add_library(${name} ${src_list})

if(TARGET fibjs_config)
	target_link_libraries(${name} fibjs_config)
endif()

include_directories(${PROJECT_SOURCE_DIR} "${PROJECT_SOURCE_DIR}/include" "${PROJECT_SOURCE_DIR}/../")

setup_result_library(${name})