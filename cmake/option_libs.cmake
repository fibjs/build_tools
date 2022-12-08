function(setup_result_library name)
    if("${BUILD_OS}" STREQUAL "Windows")
        target_link_libraries(${name} winmm ws2_32 psapi dbghelp shlwapi urlmon
            userenv advapi32 kernel32 iphlpapi)

        set_target_properties(${name} PROPERTIES
            ARCHIVE_OUTPUT_DIRECTORY_RELEASE "${LIBRARY_OUTPUT_PATH}"
            ARCHIVE_OUTPUT_DIRECTORY_DEBUG "${LIBRARY_OUTPUT_PATH}"
            RUNTIME_OUTPUT_DIRECTORY_RELEASE "${EXECUTABLE_OUTPUT_PATH}"
            RUNTIME_OUTPUT_DIRECTORY_DEBUG "${EXECUTABLE_OUTPUT_PATH}"
        )
    else()
        if("${BUILD_OS}" STREQUAL "Darwin")
            target_link_libraries(${name} dl iconv stdc++)
        elseif("${BUILD_OS}" STREQUAL "Linux")
            target_link_libraries(${name} dl)
            if(NOT ANDROID)
                target_link_libraries(${name} rt util)
            endif()
        elseif("${BUILD_OS}" STREQUAL "FreeBSD")
            find_library(execinfo execinfo "/usr/local/lib" "/usr/lib")
            target_link_libraries(${name} ${execinfo})
        endif()

        if(NOT ANDROID)
            target_link_libraries(${name} pthread)
        endif()

        if(NOT HAVE_GLIB_C_ATOMIC_H AND NOT ${ARCH} STREQUAL "i386")
            target_link_libraries(${name} atomic)
        endif()
    endif()
endfunction()
