# cmake/build_all.cmake
#
# Builds all Betaflight board configs (or base MCU targets) in three phases:
#   1. Configure  — cmake -S/-B -GNinja  (parallel, lightweight)
#   2. Compile    — ninja object files   (parallel, CPU-saturating)
#   3. Link       — ninja final link     (parallel, limited — LTO is memory-hungry)
#
# Invoke from the repo root:
#   cmake -P cmake/build_all.cmake
#
# Optional -D variables:
#   PARALLEL_TARGETS  Configure/compile slots   (default: logical core count)
#   JOBS_PER_TARGET   Compiler jobs per slot    (default: 1)
#   LINK_PARALLELISM  Simultaneous link jobs    (default: logical_cores / 4, min 1)
#   BUILD_CONFIGS     ON = board configs (default), OFF = base MCU targets
#   BUILD_DIR         Build output root  (default: build/all)
#   TARGETS_FILTER    Semicolon list to limit scope, e.g. "MATEKF405TE;KAKUTEH7"

cmake_minimum_required(VERSION 3.25)

# ---------------------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------------------
cmake_host_system_information(RESULT _NCPU QUERY NUMBER_OF_LOGICAL_CORES)
if(NOT _NCPU OR _NCPU LESS 1)
    set(_NCPU 4)
endif()

# One slot per logical core — no artificial cap.
# Total concurrent processes = PARALLEL_TARGETS * JOBS_PER_TARGET = _NCPU * 1 = _NCPU.
if(NOT DEFINED PARALLEL_TARGETS)
    set(PARALLEL_TARGETS ${_NCPU})
endif()

if(NOT DEFINED JOBS_PER_TARGET)
    set(JOBS_PER_TARGET 1)
endif()

# LTO linkers can use several GB each; throttle to avoid OOM.
if(NOT DEFINED LINK_PARALLELISM)
    math(EXPR LINK_PARALLELISM "${_NCPU} / 4")
    if(LINK_PARALLELISM LESS 1)
        set(LINK_PARALLELISM 1)
    endif()
endif()

if(NOT DEFINED BUILD_CONFIGS)
    set(BUILD_CONFIGS ON)
endif()

if(NOT DEFINED BUILD_DIR)
    set(BUILD_DIR "${CMAKE_CURRENT_LIST_DIR}/../build/all")
endif()

set(_TOOLCHAIN "${CMAKE_CURRENT_LIST_DIR}/arm-none-eabi-toolchain.cmake")
set(_ROOT      "${CMAKE_CURRENT_LIST_DIR}/..")
cmake_path(NORMAL_PATH _ROOT)
cmake_path(NORMAL_PATH BUILD_DIR)
cmake_path(NORMAL_PATH _TOOLCHAIN)

find_program(_NINJA_EXE ninja REQUIRED)

# ---------------------------------------------------------------------------
# Discover targets
# ---------------------------------------------------------------------------
if(BUILD_CONFIGS)
    file(GLOB _HDR_LIST "${_ROOT}/src/config/configs/*/config.h")
    if(NOT _HDR_LIST)
        message(FATAL_ERROR
            "No board configs found under src/config/configs/.\n"
            "Hydrate the submodule: git submodule update --init src/config")
    endif()
    set(_BUILD_TYPE "config")
    set(_BF_ARG_PREFIX "-DBF_CONFIG=")
    set(_ITEMS "")
    foreach(_hdr ${_HDR_LIST})
        get_filename_component(_dir "${_hdr}" DIRECTORY)
        get_filename_component(_name "${_dir}" NAME)
        list(APPEND _ITEMS "${_name}")
    endforeach()
else()
    file(GLOB_RECURSE _MK_LIST "${_ROOT}/src/platform/*/target/*/target.mk")
    set(_BUILD_TYPE "target")
    set(_BF_ARG_PREFIX "-DBF_TARGET=")
    set(_ITEMS "")
    foreach(_mk ${_MK_LIST})
        get_filename_component(_dir "${_mk}" DIRECTORY)
        get_filename_component(_name "${_dir}" NAME)
        list(APPEND _ITEMS "${_name}")
    endforeach()
endif()

list(SORT _ITEMS)

if(TARGETS_FILTER)
    set(_FILTERED "")
    foreach(_item ${_ITEMS})
        if(_item IN_LIST TARGETS_FILTER)
            list(APPEND _FILTERED "${_item}")
        endif()
    endforeach()
    set(_ITEMS "${_FILTERED}")
endif()

list(LENGTH _ITEMS _TOTAL)
message(STATUS "Building ${_TOTAL} ${_BUILD_TYPE}(s)")
message(STATUS "  Logical cores    : ${_NCPU}")
message(STATUS "  Parallel targets : ${PARALLEL_TARGETS}")
message(STATUS "  Jobs per target  : ${JOBS_PER_TARGET}")
message(STATUS "  Link parallelism : ${LINK_PARALLELISM}")
message(STATUS "  Build dir        : ${BUILD_DIR}")
message(STATUS "")

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
set(_STAMP_DIR   "${BUILD_DIR}/.stamps")
set(_SCRIPTS_DIR "${BUILD_DIR}/.scripts")
file(MAKE_DIRECTORY "${_STAMP_DIR}")
file(MAKE_DIRECTORY "${_SCRIPTS_DIR}")

# Write a Ninja file with a single rule and one build edge per item,
# then run it.  Sets _PHASE_FAILED to the list of items missing their stamp.
macro(bf_ninja_phase NF_VAR PARALLELISM STAMP_SUFFIX)
    execute_process(
        COMMAND "${_NINJA_EXE}" -j${PARALLELISM} -f "${${NF_VAR}}" -C "${BUILD_DIR}"
        WORKING_DIRECTORY "${BUILD_DIR}"
    )
    set(_PHASE_FAILED "")
    foreach(_pi ${_PHASE_ITEMS})
        if(NOT EXISTS "${_STAMP_DIR}/${_pi}.${STAMP_SUFFIX}")
            list(APPEND _PHASE_FAILED "${_pi}")
        endif()
    endforeach()
endmacro()

# ---------------------------------------------------------------------------
# Phase 1 — Configure
# ---------------------------------------------------------------------------
set(_PHASE_ITEMS ${_ITEMS})

foreach(_item ${_ITEMS})
    set(_bdir  "${BUILD_DIR}/${_item}")
    set(_stamp "${_STAMP_DIR}/${_item}.configured")
    set(_log   "${_bdir}/configure.log")
    file(WRITE "${_SCRIPTS_DIR}/${_item}_configure.cmake"
"file(MAKE_DIRECTORY \"${_bdir}\")
execute_process(
    COMMAND \"${CMAKE_COMMAND}\"
        -S \"${_ROOT}\" -B \"${_bdir}\"
        \"-DCMAKE_TOOLCHAIN_FILE=${_TOOLCHAIN}\"
        \"${_BF_ARG_PREFIX}${_item}\" -GNinja
    RESULT_VARIABLE _r OUTPUT_FILE \"${_log}\" ERROR_FILE \"${_log}\"
)
if(NOT _r EQUAL 0)
    message(FATAL_ERROR \"Configure failed for ${_item} — see ${_log}\")
endif()
file(TOUCH \"${_stamp}\")
message(STATUS \"CFG  ${_item}\")
")
endforeach()

set(_NF "${BUILD_DIR}/phase1_configure.ninja")
set(_nf_content "cmake_exe = ${CMAKE_COMMAND}\n\nrule r\n  command = \$cmake_exe -P \$s\n  description = [configure] \$t\n\n")
foreach(_item ${_ITEMS})
    string(APPEND _nf_content "build .stamps/${_item}.configured: r\n  s = ${_SCRIPTS_DIR}/${_item}_configure.cmake\n  t = ${_item}\n\n")
endforeach()
set(_all "")
foreach(_item ${_ITEMS})
    string(APPEND _all " .stamps/${_item}.configured")
endforeach()
string(APPEND _nf_content "build all: phony${_all}\ndefault all\n")
file(WRITE "${_NF}" "${_nf_content}")

message(STATUS "Phase 1: Configuring ${_TOTAL} target(s) ...")
bf_ninja_phase(_NF ${PARALLEL_TARGETS} "configured")

list(LENGTH _PHASE_FAILED _N_FAIL)
math(EXPR _N_PASS "${_TOTAL} - ${_N_FAIL}")
message(STATUS "Configure: ${_N_PASS} OK, ${_N_FAIL} failed")
if(_PHASE_FAILED)
    foreach(_f ${_PHASE_FAILED})
        message(STATUS "  FAIL  ${_f}  ->  ${BUILD_DIR}/${_f}/configure.log")
    endforeach()
    message(FATAL_ERROR "Configure phase failed — aborting.")
endif()
message(STATUS "")

# ---------------------------------------------------------------------------
# Phase 2 — Compile (object files only, no link)
#
# Each per-target script asks ninja for its object-file targets, writes a
# compile_only.ninja wrapper (avoids Windows cmd-line length limits when
# passing hundreds of .obj paths), then runs it.
# ---------------------------------------------------------------------------
set(_PHASE_ITEMS ${_ITEMS})   # all configured (no failures past this point)

foreach(_item ${_ITEMS})
    set(_bdir  "${BUILD_DIR}/${_item}")
    set(_stamp "${_STAMP_DIR}/${_item}.compiled")
    set(_log   "${_bdir}/compile.log")
    file(WRITE "${_SCRIPTS_DIR}/${_item}_compile.cmake"
"# Discover object targets from this target's build.ninja
execute_process(
    COMMAND \"${_NINJA_EXE}\" -C \"${_bdir}\" -t targets all
    OUTPUT_VARIABLE _t OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET
)
set(_deps \"\")
string(REPLACE \"\\n\" \";\" _lines \"\${_t}\")
foreach(_line \${_lines})
    if(_line MATCHES \"\\\\.(c|cc|cpp|cxx|s|S)\\\\.(o|obj):\")
        string(REGEX REPLACE \":.*\" \"\" _name \"\${_line}\")
        string(STRIP \"\${_name}\" _name)
        string(APPEND _deps \" \${_name}\")
    endif()
endforeach()
if(NOT _deps)
    message(FATAL_ERROR \"No object targets found in ${_bdir}\")
endif()
# Write a wrapper ninja file so the long dependency list stays on disk,
# not on the command line (avoids Windows 8 KB arg-list limit).
file(WRITE \"${_bdir}/compile_only.ninja\"
    \"include build.ninja\\n\"
    \"build _bf_compile_all: phony\${_deps}\\n\"
    \"default _bf_compile_all\\n\"
)
execute_process(
    COMMAND \"${_NINJA_EXE}\" -C \"${_bdir}\" -f compile_only.ninja -j${JOBS_PER_TARGET}
    RESULT_VARIABLE _r OUTPUT_FILE \"${_log}\" ERROR_FILE \"${_log}\"
)
if(NOT _r EQUAL 0)
    message(FATAL_ERROR \"Compile failed for ${_item} — see ${_log}\")
endif()
file(TOUCH \"${_stamp}\")
message(STATUS \"COMP ${_item}\")
")
endforeach()

set(_NF "${BUILD_DIR}/phase2_compile.ninja")
set(_nf_content "cmake_exe = ${CMAKE_COMMAND}\n\nrule r\n  command = \$cmake_exe -P \$s\n  description = [compile] \$t\n\n")
foreach(_item ${_ITEMS})
    string(APPEND _nf_content "build .stamps/${_item}.compiled: r\n  s = ${_SCRIPTS_DIR}/${_item}_compile.cmake\n  t = ${_item}\n\n")
endforeach()
set(_all "")
foreach(_item ${_ITEMS})
    string(APPEND _all " .stamps/${_item}.compiled")
endforeach()
string(APPEND _nf_content "build all: phony${_all}\ndefault all\n")
file(WRITE "${_NF}" "${_nf_content}")

message(STATUS "Phase 2: Compiling ${_TOTAL} target(s) ...")
message(STATUS "Per-target logs: ${BUILD_DIR}/<target>/compile.log")
bf_ninja_phase(_NF ${PARALLEL_TARGETS} "compiled")

set(_COMP_FAILED ${_PHASE_FAILED})
list(LENGTH _COMP_FAILED _N_FAIL)
math(EXPR _N_PASS "${_TOTAL} - ${_N_FAIL}")
message(STATUS "Compile: ${_N_PASS} OK, ${_N_FAIL} failed")
if(_COMP_FAILED)
    foreach(_f ${_COMP_FAILED})
        message(STATUS "  FAIL  ${_f}  ->  ${BUILD_DIR}/${_f}/compile.log")
    endforeach()
    message(FATAL_ERROR "Compile phase failed — aborting before link.")
endif()
message(STATUS "")

# ---------------------------------------------------------------------------
# Phase 3 — Link
#
# All object files are already built.  cmake --build just invokes the linker.
# Throttled to LINK_PARALLELISM to avoid running too many LTO linkers at once.
# ---------------------------------------------------------------------------
set(_PHASE_ITEMS ${_ITEMS})

foreach(_item ${_ITEMS})
    set(_bdir  "${BUILD_DIR}/${_item}")
    set(_stamp "${_STAMP_DIR}/${_item}.linked")
    set(_log   "${_bdir}/link.log")
    file(WRITE "${_SCRIPTS_DIR}/${_item}_link.cmake"
"execute_process(
    COMMAND \"${CMAKE_COMMAND}\" --build \"${_bdir}\" -- -j1
    RESULT_VARIABLE _r OUTPUT_FILE \"${_log}\" ERROR_FILE \"${_log}\"
)
if(NOT _r EQUAL 0)
    message(FATAL_ERROR \"Link failed for ${_item} — see ${_log}\")
endif()
file(TOUCH \"${_stamp}\")
message(STATUS \"LINK ${_item}\")
")
endforeach()

set(_NF "${BUILD_DIR}/phase3_link.ninja")
set(_nf_content "cmake_exe = ${CMAKE_COMMAND}\n\nrule r\n  command = \$cmake_exe -P \$s\n  description = [link] \$t\n\n")
foreach(_item ${_ITEMS})
    string(APPEND _nf_content "build .stamps/${_item}.linked: r\n  s = ${_SCRIPTS_DIR}/${_item}_link.cmake\n  t = ${_item}\n\n")
endforeach()
set(_all "")
foreach(_item ${_ITEMS})
    string(APPEND _all " .stamps/${_item}.linked")
endforeach()
string(APPEND _nf_content "build all: phony${_all}\ndefault all\n")
file(WRITE "${_NF}" "${_nf_content}")

message(STATUS "Phase 3: Linking ${_TOTAL} target(s) (parallelism: ${LINK_PARALLELISM}) ...")
message(STATUS "Per-target logs: ${BUILD_DIR}/<target>/link.log")
bf_ninja_phase(_NF ${LINK_PARALLELISM} "linked")

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
set(_PASSED "")
set(_FAILED "")
foreach(_item ${_ITEMS})
    if(EXISTS "${_STAMP_DIR}/${_item}.linked")
        list(APPEND _PASSED "${_item}")
    else()
        list(APPEND _FAILED "${_item}")
    endif()
endforeach()
list(LENGTH _PASSED _N_PASS)
list(LENGTH _FAILED _N_FAIL)

message(STATUS "")
message(STATUS "========================================")
message(STATUS "Build summary: ${_N_PASS} passed, ${_N_FAIL} failed / ${_TOTAL} total")
if(_FAILED)
    message(STATUS "Failed targets:")
    foreach(_f ${_FAILED})
        message(STATUS "  FAIL  ${_f}  ->  ${BUILD_DIR}/${_f}/link.log")
    endforeach()
endif()
message(STATUS "========================================")

if(_FAILED)
    message(SEND_ERROR "Build finished with failures.")
endif()
