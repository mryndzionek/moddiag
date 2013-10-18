cmake_minimum_required(VERSION 2.6)
project(moddiag)

set(PROGRAM_NAME moddiag)
set(VERSION_MAJOR 0)
set(VERSION_MINOR 0)
set(VERSION_PATCH 1)
set(VERSION_STRING "${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH}")

option(STATIC_LINK "Link statically" 0)

configure_file (
  "${CMAKE_CURRENT_SOURCE_DIR}/include/config.h.in"
  "${CMAKE_CURRENT_BINARY_DIR}/include/config.h"
  )

find_path(LIBMODBUS_INCLUDES NAMES modbus/modbus.h)

if(STATIC_LINK)
	find_library(LIBMODBUS_LIBRARY NAMES libmodbus.a)
else(STATIC_LINK)
	find_library(LIBMODBUS_LIBRARY NAMES modbus libmodbus)
endif(STATIC_LINK)

find_program(RAGEL "ragel")

function(ragel_gen in_rl)
  add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${in_rl}.c
    COMMAND ${RAGEL} -G2 -o ${CMAKE_CURRENT_BINARY_DIR}/${in_rl}.c ${CMAKE_CURRENT_SOURCE_DIR}/${in_rl}.rl -I ${CMAKE_CURRENT_SOURCE_DIR} ${ARGN}
    DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/${in_rl}.rl
    )
  add_custom_target(ragel_${in_rl} DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/${in_rl}.c)
endfunction(ragel_gen)

include_directories("${CMAKE_CURRENT_SOURCE_DIR}/include")
include_directories("${CMAKE_CURRENT_BINARY_DIR}/include")
include_directories("${LIBMODBUS_INCLUDES}")

ragel_gen(options)
add_executable(moddiag moddiag.c options.c)
target_link_libraries(moddiag ${LIBMODBUS_LIBRARY})
