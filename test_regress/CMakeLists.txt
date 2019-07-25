######################################################################
#
# DESCRIPTION: CMake script for regression tests
#
# This CMake file is meant to be consumed by regression tests.
#
# Copyright 2003-2019 by Wilson Snyder. This program is free software; you can
# redistribute it and/or modify it under the terms of either the GNU
# Lesser General Public License Version 3 or the Perl Artistic License
# Version 2.0.
#
######################################################################

cmake_minimum_required(VERSION 3.8)
set(TEST_REQUIRED_VARS NAME CSOURCES OPT_FAST VERILATOR_ROOT VERILATOR_ARGS VERILATOR_SOURCES SYSTEMC VERBOSE VERILATION)
foreach(var ${TEST_REQUIRED_VARS})
    if (NOT DEFINED TEST_${var})
        message(FATAL_ERROR "TEST_${var} not defined. This CMakeLists.txt file is meant to be run by driver.pl.")
    endif()
endforeach()

project("${TEST_NAME}")

if(TEST_VERBOSE)
    add_definitions(-DTEST_VERBOSE=1)
endif()

separate_arguments(TEST_VERILATOR_ARGS)
# filter out empty arguments
list(FILTER TEST_VERILATOR_ARGS EXCLUDE REGEX "$^")

# Remove -Mdir "<path>"
list(FIND TEST_VERILATOR_ARGS "-Mdir" _INDEX)
if(NOT _INDEX EQUAL -1)
    list(REMOVE_AT TEST_VERILATOR_ARGS ${_INDEX})
    list(REMOVE_AT TEST_VERILATOR_ARGS ${_INDEX})
endif()

# Remove -make <build-system>
list(FIND TEST_VERILATOR_ARGS "--make" _INDEX)
if(NOT _INDEX EQUAL -1)
    list(REMOVE_AT TEST_VERILATOR_ARGS ${_INDEX})
    list(REMOVE_AT TEST_VERILATOR_ARGS ${_INDEX})
endif()

set(TEST_PREFIX ${TEST_NAME})

# Remove --prefix <prefix>
list(FIND TEST_VERILATOR_ARGS "--prefix" _INDEX)
if(NOT _INDEX EQUAL -1)
    list(REMOVE_AT TEST_VERILATOR_ARGS ${_INDEX})
    list(GET TEST_VERILATOR_ARGS ${_INDEX} TEST_PREFIX)
    list(REMOVE_AT TEST_VERILATOR_ARGS ${_INDEX})
endif()

# Remove --top-module <top-module>
list(FIND TEST_VERILATOR_ARGS "--top-module" _INDEX)
if(NOT _INDEX EQUAL -1)
    list(REMOVE_AT TEST_VERILATOR_ARGS ${_INDEX})
    list(GET TEST_VERILATOR_ARGS ${_INDEX} TEST_TOP_MODULE)
    list(REMOVE_AT TEST_VERILATOR_ARGS ${_INDEX})
endif()

# Remove --make <make-system>
list(FIND TEST_VERILATOR_ARGS "--make" _INDEX)
if(NOT _INDEX EQUAL -1)
    list(REMOVE_AT TEST_VERILATOR_ARGS ${_INDEX})
    list(REMOVE_AT TEST_VERILATOR_ARGS ${_INDEX})
endif()

# Remove --threads <nbthreads>
list(FIND TEST_VERILATOR_ARGS "--threads" _INDEX)
if(NOT _INDEX EQUAL -1)
    list(REMOVE_AT TEST_VERILATOR_ARGS ${_INDEX})
    list(GET TEST_VERILATOR_ARGS ${_INDEX} TEST_THREADS)
    list(REMOVE_AT TEST_VERILATOR_ARGS ${_INDEX})
endif()

# Remove -cc
list(FIND TEST_VERILATOR_ARGS "-cc" _INDEX)
if(NOT _INDEX EQUAL -1)
    list(REMOVE_AT TEST_VERILATOR_ARGS ${_INDEX})
endif()
list(FIND TEST_VERILATOR_ARGS "--cc" _INDEX)
if(NOT _INDEX EQUAL -1)
    list(REMOVE_AT TEST_VERILATOR_ARGS ${_INDEX})
endif()

# Remove -sc
list(FIND TEST_VERILATOR_ARGS "-sc" _INDEX)
if(NOT _INDEX EQUAL -1)
    set(TEST_SYSTEMC 1)
    list(REMOVE_AT TEST_VERILATOR_ARGS ${_INDEX})
endif()
list(FIND TEST_VERILATOR_ARGS "--sc" _INDEX)
if(NOT _INDEX EQUAL -1)
    set(TEST_SYSTEMC 1)
    list(REMOVE_AT TEST_VERILATOR_ARGS ${_INDEX})
endif()

separate_arguments(TEST_VERILATOR_SOURCES)
# filter out empty sources
list(FILTER TEST_VERILATOR_SOURCES EXCLUDE REGEX "$^")

find_package(verilator REQUIRED HINTS ${TEST_VERILATOR_ROOT})

set(verilate_ARGS MAIN)
if(NOT TEST_TOP_MODULE)
    set(TEST_TOP_MODULE t)
endif()
list(APPEND verilate_ARGS TOP_MODULE ${TEST_TOP_MODULE})
if(TEST_PREFIX)
    list(APPEND verilate_ARGS PREFIX ${TEST_PREFIX})
endif()
if(TEST_OPT_FAST)
    list(APPEND verilate_ARGS OPT_FAST ${TEST_OPT_FAST})
endif()
if(TEST_THREADS)
    list(APPEND verilate_ARGS THREADS ${TEST_THREADS})
endif()
if(TEST_SYSTEMC)
    list(APPEND verilate_ARGS SYSTEMC)
endif()

set(TARGET_NAME "V${TEST_NAME}")

add_executable(${TARGET_NAME} ${TEST_CSOURCES})

if(TEST_VERILATION)
    verilate(${TARGET_NAME} ${verilate_ARGS} VERILATOR_ARGS ${TEST_VERILATOR_ARGS} SOURCES ${TEST_VERILATOR_SOURCES})
endif()

if(TEST_SYSTEMC)
    verilator_link_systemc("${TARGET_NAME}")
endif()
