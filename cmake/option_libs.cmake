get_filename_component(BIN_PATH ${CMAKE_CURRENT_BINARY_DIR} DIRECTORY)
get_filename_component(BIN_PATH ${BIN_PATH} DIRECTORY)
get_filename_component(BIN_PATH ${BIN_PATH} DIRECTORY)
set(BIN_PATH "${BIN_PATH}/bin/${BUILD_OS}_${BUILD_ARCH}_${BUILD_TYPE}")

set(LIBRARY_OUTPUT_PATH "${BIN_PATH}")
set(EXECUTABLE_OUTPUT_PATH "${BIN_PATH}")

function(setup_result_library name)
    if("${BUILD_OS}" STREQUAL "Windows")
        target_link_libraries(${name} winmm ws2_32 psapi dbghelp shlwapi urlmon
            userenv advapi32 kernel32 iphlpapi comctl32)

        set_target_properties(${name} PROPERTIES
            ARCHIVE_OUTPUT_DIRECTORY_RELEASE "${LIBRARY_OUTPUT_PATH}"
            ARCHIVE_OUTPUT_DIRECTORY_DEBUG "${LIBRARY_OUTPUT_PATH}"
            RUNTIME_OUTPUT_DIRECTORY_RELEASE "${EXECUTABLE_OUTPUT_PATH}"
            RUNTIME_OUTPUT_DIRECTORY_DEBUG "${EXECUTABLE_OUTPUT_PATH}"
        )
    elseif("${CMAKE_HOST_SYSTEM_NAME}" STREQUAL "Darwin")
        target_link_libraries(${name} dl iconv pthread)
    elseif("${BUILD_OS}" STREQUAL "FreeBSD")
        find_library(execinfo execinfo "/usr/local/lib" "/usr/lib")
        target_link_libraries(${name} ${execinfo} pthread)
    elseif("${BUILD_OS}" STREQUAL "Android")
        target_link_libraries(${name} dl)
    else()
        target_link_libraries(${name} dl rt util pthread)

        if(NOT HAVE_GLIB_C_ATOMIC_H AND NOT ${BUILD_ARCH} STREQUAL "ia32")
            target_link_libraries(${name} atomic)
        endif()
    endif()

	set_target_properties(${name} PROPERTIES LINK_FLAGS "${link_flags}")
endfunction()
