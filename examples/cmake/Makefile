######################################################################
#
# DESCRIPTION: Verilator CMake example usage
#
# This file shows usage of the cmake script.
# This makefile is mainly here for testing the examples and should
# generally not be added a cmake project.
#
# Copyright 2003-2019 by Wilson Snyder. This program is free software; you can
# redistribute it and/or modify it under the terms of either the GNU
# Lesser General Public License Version 3 or the Perl Artistic License
# Version 2.0.
#
######################################################################

######################################################################
# Set up variables

# If $VERILATOR_ROOT isn't in the environment, we assume it is part of a
# package inatall, and verilator is in your path. Otherwise find the
# binary relative to $VERILATOR_ROOT (such as when inside the git sources).
ifeq ($(VERILATOR_ROOT),)
VERILATOR = verilator
VERILATOR_COVERAGE = verilator_coverage
else
export VERILATOR_ROOT
VERILATOR = $(VERILATOR_ROOT)/bin/verilator
VERILATOR_COVERAGE = $(VERILATOR_ROOT)/bin/verilator_coverage
endif
######################################################################

default: run

run:
	@echo
	@echo "-- Verilator cmake hello-world simple example"

	@echo
	@echo "-- CMake ----------------"
	rm -rf build && mkdir build
	cmake -S . -B build

	@echo
	@echo "-- COMPILE -----------------"
	cmake --build build

	@echo
	@echo "-- RUN ---------------------"
	@mkdir -p logs
	build/example +trace

	@echo
	@echo "-- COVERAGE ----------------"
	$(VERILATOR_COVERAGE) --annotate logs/annotated logs/coverage.dat

	@echo
	@echo "-- DONE --------------------"
	@echo "To see waveforms, open vlt_dump.vcd in a waveform viewer"
	@echo
