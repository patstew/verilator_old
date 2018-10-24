cmake_minimum_required(VERSION 3.8)

#Prefer VERILATOR_ROOT from environment
if (DEFINED ENV{VERILATOR_ROOT})
    set(VERILATOR_ROOT "$ENV{VERILATOR_ROOT}" CACHE PATH "VERILATOR_ROOT")
endif()

set(VERILATOR_ROOT "${CMAKE_CURRENT_LIST_DIR}" CACHE PATH "VERILATOR_ROOT")

find_file(VERILATOR_BIN NAMES verilator_bin verilator_bin.exe HINTS ${VERILATOR_ROOT}/bin NO_CMAKE_PATH NO_CMAKE_ENVIRONMENT_PATH NO_CMAKE_SYSTEM_PATH)

if (NOT VERILATOR_ROOT)
    message(FATAL_ERROR "VERILATOR_ROOT cannot be detected. Set it to the appropriate directory (e.g. /usr/share/verilator) as an environment variable or CMake define.")
endif()

if (NOT VERILATOR_BIN)
    message(FATAL_ERROR "Cannot find verilator_bin excecutable.")
endif()

set(verilator_FOUND 1)

#Check flag support. Skip on MSVC, these are all GCC flags.
if (NOT (DEFINED VERILATOR_CFLAGS OR CMAKE_CXX_COMPILER_ID MATCHES MSVC))
    include(CheckCXXCompilerFlag)
    foreach (FLAG -faligned-new -fbracket-depth=4096 -Qunused-arguments -Wno-bool-operation -Wno-parentheses-equality
                  -Wno-sign-compare -Wno-uninitialized -Wno-unused-but-set-variable -Wno-unused-parameter
                  -Wno-unused-variable -Wno-shadow)
        string(MAKE_C_IDENTIFIER ${FLAG} FLAGNAME)
        check_cxx_compiler_flag(${FLAG} ${FLAGNAME})
        if (${FLAGNAME})
            list(APPEND VERILATOR_CFLAGS ${FLAG})
        endif()
    endforeach()
endif()

define_property(TARGET
    PROPERTY VERILATOR_COVERAGE
    BRIEF_DOCS "Verilator coverage enabled"
    FULL_DOCS "Verilator coverage enabled"
)

define_property(TARGET
    PROPERTY VERILATOR_TRACE
    BRIEF_DOCS "Verilator trace enabled"
    FULL_DOCS "Verilator trace enabled"
)

define_property(TARGET
    PROPERTY VERILATOR_SYSTEMC
    BRIEF_DOCS "Verilator systemc enabled"
    FULL_DOCS "Verilator systemc enabled"
)

define_property(TARGET
    PROPERTY VERILATOR_THREADED
    BRIEF_DOCS "Verilator multithreading enabled"
    FULL_DOCS "Verilator multithreading enabled"
)

function(verilate TARGET)
    cmake_parse_arguments(VERILATE "MAIN;COVERAGE;TRACE;SYSTEMC" "PREFIX;TOP_MODULE" "SOURCES;VERILATOR_ARGS;INCLUDE_DIRS;SLOW_FLAGS;FAST_FLAGS" ${ARGN})
    if (NOT VERILATE_SOURCES)
        message(FATAL_ERROR "Need at least one source")
    endif()

    if (NOT VERILATE_PREFIX)
        list(GET VERILATE_SOURCES 0 TOPSRC)
        get_filename_component(_SRC_NAME ${TOPSRC} NAME_WE)
        set(VERILATE_PREFIX V${_SRC_NAME})
    endif()

    if (VERILATE_TOP_MODULE)
        list(APPEND VERILATE_TOP_MODULE --top-module ${VERILATE_TOP_MODULE})
    endif()

    if (VERILATE_COVERAGE)
        list(APPEND VERILATOR_ARGS --coverage)
    endif()

    if (VERILATE_TRACE)
        list(APPEND VERILATOR_ARGS --trace)
    endif()

    if (VERILATE_SYSTEMC)
        list(APPEND VERILATOR_ARGS --sc)
    else()
        list(APPEND VERILATOR_ARGS --cc)
    endif()

    if (VERILATE_MAIN)
        list(APPEND VERILATOR_SOURCES "${VERILATOR_ROOT}/include/verilated.cpp")
    endif()

    foreach(INC ${VERILATE_INCLUDE_DIRS})
        list(APPEND VERILATOR_ARGS -y "${INC}")
    endforeach()

    string(TOLOWER ${CMAKE_CXX_COMPILER_ID} COMPILER)
    if (NOT COMPILER MATCHES "msvc|clang")
        set(COMPILER gcc)
    endif()

    set(DIR "${CMAKE_CURRENT_BINARY_DIR}/${VERILATE_PREFIX}.dir")
    file(MAKE_DIRECTORY ${DIR})

    set(VERILATOR_COMMAND "${VERILATOR_BIN}" -Wall -Wno-fatal --compiler ${COMPILER} --top-module ${VERILATE_TOP_MODULE} --prefix ${VERILATE_PREFIX} --Mdir ${DIR} --make cmake ${VERILATOR_ARGS} ${VERILATE_VERILATOR_ARGS} ${VERILATE_SOURCES})

    set(VCMAKE ${DIR}/${VERILATE_PREFIX}.cmake)
    if (NOT EXISTS ${VCMAKE})
        message(VERBOSE "Verilator command: \"${VERILATOR_COMMAND_READABLE}\"")
        execute_process(
            COMMAND ${VERILATOR_COMMAND}
            WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
            RESULT_VARIABLE _VERILATOR_RC
            OUTPUT_VARIABLE _VERILATOR_OUTPUT
            ERROR_VARIABLE _VERILATOR_OUTPUT)
        if (_VERILATOR_RC)
            message("Output:\n${_VERILATOR_OUTPUT}")
            string(REPLACE ";" " " VERILATOR_COMMAND_READABLE "${VERILATOR_COMMAND}")
            message(FATAL_ERROR "Verilator command failed (return code=${_VERILATOR_RC})")
        endif()
        execute_process(COMMAND "${CMAKE_COMMAND}" -E copy "${VCMAKE}.gen" "${VCMAKE}")
    endif()

    include(${VCMAKE})

    add_custom_command(OUTPUT ${OUTPUTS} ${VCMAKE}.gen ${${VERILATE_PREFIX}_CLASSES_SLOW} ${${VERILATE_PREFIX}_SUPPORT_SLOW} ${${VERILATE_PREFIX}_CLASSES_FAST} ${${VERILATE_PREFIX}_SUPPORT_FAST}
                       COMMAND ${VERILATOR_COMMAND}
                       WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
                       DEPENDS ${${VERILATE_PREFIX}_DEPS} VERBATIM)
    # Reconfigure if file list has changed (check contents rather than modified time to avoid unnecessary reconfiguration)
    add_custom_command(OUTPUT ${VCMAKE}
                       COMMAND ${CMAKE_COMMAND} -E copy_if_different "${VCMAKE}.gen" "${VCMAKE}"
                       DEPENDS ${VCMAKE}.gen)

    if (${VERILATE_PREFIX}_COVERAGE)
        #If any verilate() call specifies --coverage, define VM_COVERAGE in the final build
        set_property(TARGET ${TARGET} PROPERTY VERILATOR_COVERAGE ON)
    endif()
    get_property(_PROP TARGET ${TARGET} PROPERTY VERILATOR_COVERAGE SET)

    if (${VERILATE_PREFIX}_TRACE)
        #If any verilate() call specifies --trace, define VM_TRACE in the final build
        set_property(TARGET ${TARGET} PROPERTY VERILATOR_TRACE ON)
    endif()
    get_property(_PROP TARGET ${TARGET} PROPERTY VERILATOR_TRACE SET)

    if (VM_SC)
        #If any verilate() call specifies --sc, define VM_SC in the final build
        set_property(TARGET ${TARGET} PROPERTY VERILATOR_SYSTEMC ON)
    endif()
    get_property(_PROP TARGET ${TARGET} PROPERTY VERILATOR_SYSTEMC SET)

    if (${VERILATE_PREFIX}_THREADS)
        #If any verilate() call specifies --threads, define VM_THREADED in the final build
        set_property(TARGET ${TARGET} PROPERTY VERILATOR_THREADED ON)
    endif()
    get_property(_PROP TARGET ${TARGET} PROPERTY VERILATOR_THREADED SET)

    set(OUTPUTS ${${VERILATE_PREFIX}_CLASSES_FAST} ${${VERILATE_PREFIX}_CLASSES_SLOW} ${${VERILATE_PREFIX}_SUPPORT_FAST} ${${VERILATE_PREFIX}_SUPPORT_SLOW})

    target_sources(${TARGET} PRIVATE ${OUTPUTS} ${${VERILATE_PREFIX}_GLOBAL})
    target_include_directories(${TARGET} PRIVATE ${VERILATOR_ROOT}/include ${VERILATOR_ROOT}/include/vltstd "${DIR}")
    target_compile_definitions(${TARGET} PRIVATE VL_PRINTF=printf
        VM_COVERAGE=$<BOOL:$<TARGET_PROPERTY:VERILATOR_COVERAGE>>  VM_SC=$<BOOL:$<TARGET_PROPERTY:VERILATOR_SYSTEMC>>
        VM_TRACE=$<BOOL:$<TARGET_PROPERTY:VERILATOR_TRACE>> $<$<BOOL:$<TARGET_PROPERTY:VERILATOR_THREADED>>:VL_THREADED>)
    target_compile_options(${TARGET} PRIVATE ${VERILATOR_CFLAGS} ${VM_USER_CFLAGS})
    set_source_files_properties(${${VERILATE_PREFIX}_CLASSES_SLOW} ${${VERILATE_PREFIX}_SUPPORT_SLOW} PROPERTIES COMPILE_FLAGS "${VERILATE_SLOW_FLAGS}")
    set_source_files_properties(${${VERILATE_PREFIX}_CLASSES_FAST} ${${VERILATE_PREFIX}_SUPPORT_FAST} PROPERTIES COMPILE_FLAGS "${VERILATE_FAST_FLAGS}")
endfunction()
