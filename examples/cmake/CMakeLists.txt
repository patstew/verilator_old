#This example builds the hello_world_c example using CMake
#To use it, run the following:

#cd /path/to/verilator/examples/cmake
#mkdir build
#cd build
#cmake ..
#cmake --build .

cmake_minimum_required(VERSION 3.8)
cmake_policy(SET CMP0074 NEW)
project(cmake_example)

find_package(verilator HINTS $ENV{VERILATOR_ROOT})
if (NOT verilator_FOUND)
    message(FATAL_ERROR "Verilator was not found. Either install it, or set the VERILATOR_ROOT environment variable")
endif()

add_executable(example ${CMAKE_CURRENT_SOURCE_DIR}/../hello_world_c/sim_main.cpp)
verilate(example SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/../hello_world_c/top.v)
