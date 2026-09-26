cmake_minimum_required(VERSION 3.10)

find_program(CCACHE_FOUND ccache)
if(CCACHE_FOUND)
	set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE ccache)
	set_property(GLOBAL PROPERTY RULE_LAUNCH_LINK ccache)
endif(CCACHE_FOUND)

include(${CMAKE_CURRENT_LIST_DIR}/option_src.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/option_asm.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/option_flags.cmake)
if(TARGET bt_config)
	# The feature checks and the generated configuration headers are provided
	# once by the top-level project (option_config.cmake: bt_config_target).
else()
	include(${CMAKE_CURRENT_LIST_DIR}/option_config.cmake)
	bt_config_headers()
endif()
include(${CMAKE_CURRENT_LIST_DIR}/option_libs.cmake)
