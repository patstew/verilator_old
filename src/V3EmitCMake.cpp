// -*- mode: C++; c-file-style: "cc-mode" -*-
//*************************************************************************
// DESCRIPTION: Verilator: Emit CMake file list
//
// Code available from: http://www.veripool.org/verilator
//
//*************************************************************************
//
// Copyright 2004-2019 by Wilson Snyder.  This program is free software; you can
// redistribute it and/or modify it under the terms of either the GNU
// Lesser General Public License Version 3 or the Perl Artistic License
// Version 2.0.
//
// Verilator is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
//*************************************************************************

#include "config_build.h"
#include "verilatedos.h"
#include <cstdio>
#include <cstdarg>
#include <unistd.h>
#include <cmath>
#include <map>
#include <vector>
#include <algorithm>

#include "V3Global.h"
#include "V3Os.h"
#include "V3EmitCMake.h"
#include "V3EmitCBase.h"

#include <memory>

// Concatenate all strings in 'strs' with 'joint' between them.
template<typename List>
static string cmake_list(const List& strs, const string& joint=" ") {
    string s;
    if (strs.begin() != strs.end()) {
        s.append("\"");
        s.append(*strs.begin());
        s.append("\"");
        for (typename List::const_iterator i = ++strs.begin(); i != strs.end(); i++) {
            s.append(joint);
            s.append("\"");
            s.append(*i);
            s.append("\"");
        }
    }
    return s;
}

// Print CMake variable set command: output raw_value unmodified
// cache_type should be empty for a normal variable
// "BOOL", "FILEPATH", "PATH", "STRING" or "INTERNAL" for a CACHE variable
// See https://cmake.org/cmake/help/latest/command/set.html
static void cmake_set_raw(std::ofstream& of, const string& name, const string& raw_value,
                        const string& cache_type = "", const string& docstring = "") {
    of << "set(" << name << " " << raw_value;
    if (!cache_type.empty()) {
        of << " CACHE " << cache_type << " " << docstring;
    }
    of << ")\n";
}

static void cmake_set(std::ofstream& of, const string& name, const string& value,
                        const string& cache_type = "", const string& docstring = "") {
    string raw_value = "\"" + value + "\"";
    cmake_set_raw(of, name, raw_value, cache_type, docstring);
}

//Swap all backslashes for forward slashes, because of Windows
static string normalize(string s) {
    for (string::iterator i = s.begin(); i != s.end(); i++) {
        if (*i == '\\')
            *i = '/';
    }
    return s;
}

void V3EmitCMake::emit(AstNetlist* nodep) {
    const vl_unique_ptr<std::ofstream> of (V3File::new_ofstream(v3Global.opt.makeDir()+"/"+ v3Global.opt.prefix() + ".cmake.gen"));
    UINFO(2,__FUNCTION__<<": "<<endl);
    string name = v3Global.opt.prefix();
    *of << "# List generated files for CMake\n";

    *of << "\n### Constants...\n";
    cmake_set(*of, "PERL", normalize(V3Options::getenvPERL()), "FILEPATH", "\"Perl executable (from $PERL)\"");
    cmake_set(*of, "VERILATOR_ROOT", normalize(V3Options::getenvVERILATOR_ROOT()), "PATH" ,"\"Path to Verilator kit (from $VERILATOR_ROOT)\"");
    cmake_set(*of, "SYSTEMC_INCLUDE", normalize(V3Options::getenvSYSTEMC_INCLUDE()), "PATH", "\"SystemC include directory with systemc.h (from $SYSTEMC_INCLUDE)\"");
    cmake_set(*of, "SYSTEMC_LIBDIR", normalize(V3Options::getenvSYSTEMC_LIBDIR()), "PATH", "\"SystemC library directory with libsystemc.a (from $SYSTEMC_LIBDIR)\"");

    *of << "\n### Switches...\n";
    *of << "# SystemC output mode?  0/1 (from --sc)\n";
    cmake_set_raw(*of, "VM_SC", v3Global.opt.systemC() ? "1" : "0");

    *of << "# User CFLAGS (from -CFLAGS on Verilator command line)\n";
    cmake_set_raw(*of, "VM_USER_CFLAGS", cmake_list(v3Global.opt.cFlags()));

    *of << "# User LDLIBS (from -LDFLAGS on Verilator command line)\n";
    cmake_set(*of, "VM_USER_LDLIBS", cmake_list(v3Global.opt.ldLibs()));

    *of << "\n### Switches...\n";
    *of << "# Coverage output mode?  0/1 (from --coverage)\n";
    cmake_set(*of, name + "_COVERAGE", v3Global.opt.coverage()?"1":"0");
    *of << "# Threaded output mode?  0/1/N threads (from --threads)\n";
    cmake_set(*of, name + "_THREADS", cvtToStr(v3Global.opt.threads()));
    *of << "# Tracing output mode?  0/1 (from --trace)\n";
    cmake_set(*of, name + "_TRACE", v3Global.opt.trace()?"1":"0");

    *of << "\n### Object file lists...\n";
    std::vector<string> classes_fast, classes_slow, support_fast, support_slow, global;
    for (AstCFile* nodep = v3Global.rootp()->filesp(); nodep; nodep=VN_CAST(nodep->nextp(), CFile)) {
        if (nodep->source()) {
            if (nodep->support()) {
                if (nodep->slow()) {
                    support_slow.push_back(nodep->name());
                } else {
                    support_fast.push_back(nodep->name());
                }
            } else {
                if (nodep->slow()) {
                    classes_slow.push_back(nodep->name());
                } else {
                    classes_fast.push_back(nodep->name());
                }
            }
        }
    }

    global.push_back("${VERILATOR_ROOT}/include/verilated.cpp");
    if (v3Global.dpi()) {
        global.push_back("${VERILATOR_ROOT}/include/verilated_dpi.cpp");
    }
    if (v3Global.opt.vpi()) {
        global.push_back("${VERILATOR_ROOT}/include/verilated_vpi.cpp");
    }
    if (v3Global.opt.savable()) {
        global.push_back("${VERILATOR_ROOT}/include/verilated_save.cpp");
    }
    if (v3Global.opt.coverage()) {
        global.push_back("${VERILATOR_ROOT}/include/verilated_cov.cpp");
    }
    if (v3Global.opt.trace()) {
        global.push_back("${VERILATOR_ROOT}/include/" + v3Global.opt.traceSourceName()+"_c.cpp");
        if (v3Global.opt.systemC()) {
            if (v3Global.opt.traceFormat() != TraceFormat::VCD) {
                v3error("Unsupported: This trace format is not supported in SystemC, use VCD format.");
            } else {
                global.push_back("${VERILATOR_ROOT}/include/" + v3Global.opt.traceSourceName()+"_sc.cpp");
            }
        }
    }
    if (v3Global.opt.mtasks()) {
        global.push_back("${VERILATOR_ROOT}/include/verilated_threads.cpp");
    }

    *of << "# Global classes, need linked once per executable\n";
    cmake_set_raw(*of, name + "_GLOBAL", normalize(cmake_list(global)));
    *of << "# Generated module classes, non-fast-path, compile with low/medium optimization\n";
    cmake_set_raw(*of, name + "_CLASSES_SLOW", normalize(cmake_list(classes_slow)));
    *of << "# Generated module classes, fast-path, compile with highest optimization\n";
    cmake_set_raw(*of, name + "_CLASSES_FAST", normalize(cmake_list(classes_fast)));
    *of << "# Generated support classes, non-fast-path, compile with low/medium optimization\n";
    cmake_set_raw(*of, name + "_SUPPORT_SLOW", normalize(cmake_list(support_slow)));
    *of << "# Generated support classes, fast-path, compile with highest optimization\n";
    cmake_set_raw(*of, name + "_SUPPORT_FAST", normalize(cmake_list(support_fast)));

    *of << "# All dependencies\n";
    cmake_set_raw(*of, name + "_DEPS", normalize(cmake_list(V3File::getAllDeps())));

    *of << "# User .cpp files (from .cpp's on Verilator command line)\n";
    cmake_set_raw(*of, name + "_USER_CLASSES", normalize(cmake_list(v3Global.opt.cppFiles())));
}
