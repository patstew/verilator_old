cmake_minimum_required(VERSION 3.8)
set(TEST_REQUIRED_VARS NAME CSOURCES VERILATOR_ROOT VERILATOR_ARGS VERILATOR_SOURCES)
foreach(var ${TEST_REQUIRED_VARS})
    if (NOT TEST_${var})
        message(FATAL_ERROR "TEST_${var} not defined. This CMakeLists.txt file is meant to be run by driver.pl.")
    endif()
endforeach()

project("${TEST_NAME}")

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

set(TEST_TOP_MODULE t)

# Remove --top-module <top-module>
list(FIND TEST_VERILATOR_ARGS "--top-module" _INDEX)
if(NOT _INDEX EQUAL -1)
    list(REMOVE_AT TEST_VERILATOR_ARGS ${_INDEX})
    list(GET TEST_VERILATOR_ARGS ${_INDEX} TEST_TOP_MODULE)
    list(REMOVE_AT TEST_VERILATOR_ARGS ${_INDEX})
endif()

separate_arguments(TEST_VERILATOR_SOURCES)
# filter out empty sources
list(FILTER TEST_VERILATOR_SOURCES EXCLUDE REGEX "$^")

find_package(verilator REQUIRED HINTS ${TEST_VERILATOR_ROOT})


set(verilate_ARGS MAIN)
if(TEST_TOP_MODULE)
    list(APPEND verilate_ARGS TOP_MODULE ${TEST_TOP_MODULE})
endif()
if(TEST_PREFIX)
    list(APPEND verilate_ARGS PREFIX ${TEST_PREFIX})
endif()

set(TARGET_NAME "V${TEST_NAME}")

add_executable(${TARGET_NAME} ${TEST_CSOURCES})
verilate(${TARGET_NAME} ${verilate_ARGS} VERILATOR_ARGS ${TEST_VERILATOR_ARGS} SOURCES ${TEST_VERILATOR_SOURCES})
