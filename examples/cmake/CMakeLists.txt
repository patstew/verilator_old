######################################################################
#
# DESCRIPTION: Verilator Example: Small CMakeLists.txt
#
# This is an example cmake script to build a verilog project using
# cmake and verilator.
#
# Copyright 2003-2019 by Wilson Snyder. This program is free software; you can
# redistribute it and/or modify it under the terms of either the GNU
# Lesser General Public License Version 3 or the Perl Artistic License
# Version 2.0.
#
######################################################################

# This example builds the hello_world_c example using CMake
# To use it, run the following:

# cd /path/to/verilator/examples/cmake
# rm -rf build && mkdir build && cd build
# cmake ..
# cmake --build .

cmake_minimum_required(VERSION 3.8)
cmake_policy(SET CMP0074 NEW)
project(cmake_example)

find_package(verilator HINTS $ENV{VERILATOR_ROOT})
if (NOT verilator_FOUND)
    message(FATAL_ERROR "Verilator was not found. Either install it, or set the VERILATOR_ROOT environment variable")
endif()

# Create a new executable target that will contain all your sources
add_executable(example ${CMAKE_CURRENT_SOURCE_DIR}/../tracing_c/sim_main.cpp)

# Add the verilated circuit to the target
verilate(example COVERAGE TRACE
    INCLUDE_DIRS "${CMAKE_CURRENT_SOURCE_DIR}/../tracing_c"
    VERILATOR_ARGS -f ${CMAKE_CURRENT_SOURCE_DIR}/../tracing_c/input.vc -O2 -x-assign 0
    SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/../tracing_c/top.v)
