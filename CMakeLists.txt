cmake_minimum_required(VERSION 3.25)

# ---------------------------------------------------------------------------
# Toolchain must be set before project().
# Pass it on the command line:
#   cmake -B build \
#         -DCMAKE_TOOLCHAIN_FILE=cmake/arm-none-eabi-toolchain.cmake \
#         -DBF_TARGET=STM32F405
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# User-facing cache variables
# ---------------------------------------------------------------------------
set(BF_TARGET  ""    CACHE STRING "MCU target to build  (e.g. STM32F405, STM32H743)")
set(BF_CONFIG  ""    CACHE STRING "Board config to build (e.g. MATEKF405TE) — sets BF_TARGET automatically")
set(BF_DEBUG   ""    CACHE STRING "Debug mode: empty=release, INFO=debug-symbols, GDB=full-debug")
set(BF_EXST    FALSE CACHE BOOL   "Build for External-Storage-Bootloader (EXST)")
set(BF_RAM_BASED FALSE CACHE BOOL "Build firmware to run from RAM")
set(BF_HSE_VALUE 8000000 CACHE STRING "External oscillator frequency in Hz")
set(BF_EXTRA_FLAGS "" CACHE STRING "Extra compiler flags appended to CFLAGS")
set(BF_FLASH_SIZE   "" CACHE STRING "Override flash size in KB")

project(betaflight C ASM)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)         # Generate compile_commands.json for language servers

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
set(BF_ROOT         "${CMAKE_SOURCE_DIR}")
set(BF_SRC_DIR      "${BF_ROOT}/src/main")
set(BF_LIB_DIR      "${BF_ROOT}/lib/main")
set(BF_PLATFORM_DIR "${BF_ROOT}/src/platform")
set(BF_CONFIG_DIR   "${BF_ROOT}/src/config")
set(BF_CMAKE_DIR    "${BF_ROOT}/cmake")

# ---------------------------------------------------------------------------
# If BF_CONFIG is given, extract the MCU target from config.h
# ---------------------------------------------------------------------------
if(BF_CONFIG)
    if(BF_TARGET)
        message(FATAL_ERROR "Specify either BF_TARGET or BF_CONFIG, not both.")
    endif()

    set(_CONFIG_HDR "${BF_CONFIG_DIR}/configs/${BF_CONFIG}/config.h")
    if(NOT EXISTS "${_CONFIG_HDR}")
        message(FATAL_ERROR
            "Config header not found: ${_CONFIG_HDR}\n"
            "Have you initialised the config submodule? (git submodule update --init src/config)")
    endif()

    # Extract FC_TARGET_MCU token from config.h
    file(STRINGS "${_CONFIG_HDR}" _TARGET_LINE REGEX "#define[ \t]+FC_TARGET_MCU[ \t]+")
    if(NOT _TARGET_LINE)
        message(FATAL_ERROR "FC_TARGET_MCU not found in ${_CONFIG_HDR}")
    endif()
    string(REGEX REPLACE ".*FC_TARGET_MCU[ \t]+([A-Za-z0-9_]+).*" "\\1" BF_TARGET "${_TARGET_LINE}")

    # Optional: extract SYSTEM_HSE_MHZ and convert to Hz
    file(STRINGS "${_CONFIG_HDR}" _HSE_LINE REGEX "#define[ \t]+SYSTEM_HSE_MHZ[ \t]+")
    if(_HSE_LINE)
        string(REGEX REPLACE ".*SYSTEM_HSE_MHZ[ \t]+([0-9]+).*" "\\1" _HSE_MHZ "${_HSE_LINE}")
        math(EXPR BF_HSE_VALUE "${_HSE_MHZ} * 1000000")
    endif()

    message(STATUS "BF_CONFIG=${BF_CONFIG} → BF_TARGET=${BF_TARGET}, HSE=${BF_HSE_VALUE} Hz")
endif()

if(NOT BF_TARGET)
    message(FATAL_ERROR
        "No target specified. Pass -DBF_TARGET=<MCU> or -DBF_CONFIG=<board>.\n"
        "Example: cmake -B build -DCMAKE_TOOLCHAIN_FILE=cmake/arm-none-eabi-toolchain.cmake -DBF_TARGET=STM32F405")
endif()

# ---------------------------------------------------------------------------
# Locate target.mk to determine MCU and MCU family
# ---------------------------------------------------------------------------
file(GLOB _TARGET_MK_CANDIDATES
    "${BF_PLATFORM_DIR}/*/target/${BF_TARGET}/target.mk")

if(NOT _TARGET_MK_CANDIDATES)
    message(FATAL_ERROR "target.mk not found for target '${BF_TARGET}' under ${BF_PLATFORM_DIR}")
endif()
list(GET _TARGET_MK_CANDIDATES 0 _TARGET_MK)

# Parse TARGET_MCU and TARGET_MCU_FAMILY from target.mk
file(STRINGS "${_TARGET_MK}" _TARGET_MK_LINES)
foreach(_line ${_TARGET_MK_LINES})
    if(_line MATCHES "TARGET_MCU[ \t]*:=[ \t]*(.+)")
        string(STRIP "${CMAKE_MATCH_1}" BF_TARGET_MCU)
    endif()
    if(_line MATCHES "TARGET_MCU_FAMILY[ \t]*:=[ \t]*(.+)")
        string(STRIP "${CMAKE_MATCH_1}" BF_TARGET_MCU_FAMILY)
    endif()
endforeach()

if(NOT BF_TARGET_MCU OR NOT BF_TARGET_MCU_FAMILY)
    message(FATAL_ERROR "Could not parse TARGET_MCU / TARGET_MCU_FAMILY from ${_TARGET_MK}")
endif()

# Derive platform (e.g. STM32, AT32, APM32, PICO, SIMULATOR)
get_filename_component(_TGTMK_DIR "${_TARGET_MK}" DIRECTORY)  # .../target/STM32F405
get_filename_component(_TGTMK_DIR "${_TGTMK_DIR}" DIRECTORY)  # .../target
get_filename_component(_TGTMK_DIR "${_TGTMK_DIR}" DIRECTORY)  # .../STM32
get_filename_component(BF_TARGET_PLATFORM "${_TGTMK_DIR}" NAME)

message(STATUS "Building: TARGET=${BF_TARGET}  MCU=${BF_TARGET_MCU}  FAMILY=${BF_TARGET_MCU_FAMILY}  PLATFORM=${BF_TARGET_PLATFORM}")

# ---------------------------------------------------------------------------
# Platform-specific cmake — sets BF_ARCH_FLAGS, BF_DEVICE_FLAGS,
# BF_LD_SCRIPT, BF_STARTUP_SRCS, BF_MCU_SRCS, BF_VCP_SRCS, BF_MSC_SRCS,
# BF_DEVICE_LIB_SRCS, BF_PLATFORM_INCLUDE_DIRS, BF_MCU_FLASH_SIZE,
# BF_DSP_LIB_DIR, BF_SPEED_OPTIMISED_SRCS, BF_SIZE_OPTIMISED_SRCS
# ---------------------------------------------------------------------------
set(BF_OPTIMISE_DEFAULT "" CACHE INTERNAL "")
set(BF_OPTIMISE_SPEED   "" CACHE INTERNAL "")
set(BF_OPTIMISE_SIZE    "" CACHE INTERNAL "")

if(BF_TARGET_MCU_FAMILY STREQUAL "STM32F4")
    include("${BF_CMAKE_DIR}/stm32f4.cmake")
elseif(BF_TARGET_MCU_FAMILY STREQUAL "STM32F7")
    include("${BF_CMAKE_DIR}/stm32f7.cmake")
elseif(BF_TARGET_MCU_FAMILY STREQUAL "STM32G4")
    include("${BF_CMAKE_DIR}/stm32g4.cmake")
elseif(BF_TARGET_MCU_FAMILY STREQUAL "STM32H5")
    include("${BF_CMAKE_DIR}/stm32h5.cmake")
elseif(BF_TARGET_MCU_FAMILY STREQUAL "STM32H7")
    include("${BF_CMAKE_DIR}/stm32h7.cmake")
else()
    message(FATAL_ERROR "Unsupported MCU family: ${BF_TARGET_MCU_FAMILY}")
endif()

# Determine flash size (command-line override takes precedence)
if(BF_FLASH_SIZE)
    set(BF_TARGET_FLASH_SIZE ${BF_FLASH_SIZE})
else()
    set(BF_TARGET_FLASH_SIZE ${BF_MCU_FLASH_SIZE})
endif()

# ---------------------------------------------------------------------------
# Common source lists
# ---------------------------------------------------------------------------
include("${BF_CMAKE_DIR}/sources.cmake")

# ---------------------------------------------------------------------------
# Build the full source list
# ---------------------------------------------------------------------------
set(BF_ALL_SRCS
    ${BF_STARTUP_SRCS}
    ${BF_MCU_SRCS}
    ${BF_VCP_SRCS}
    ${BF_MSC_SRCS}
    ${BF_DEVICE_LIB_SRCS}
    ${BF_COMMON_SRCS}
    ${BF_PG_SRCS}
    ${BF_RX_SRCS}
    ${BF_FLASH_SRCS}
    ${BF_SDCARD_SRCS}
    ${BF_OLC_SRCS}
)

# Board config source (optional config.c)
if(BF_CONFIG)
    set(_CONFIG_SRC "${BF_CONFIG_DIR}/configs/${BF_CONFIG}/config.c")
    if(EXISTS "${_CONFIG_SRC}")
        list(APPEND BF_ALL_SRCS "${_CONFIG_SRC}")
        list(APPEND BF_CONFIG_COMPILE_DEFS USE_CONFIG_SOURCE)
    endif()
endif()

# DSP assembly sources (ARM CMSIS-DSP)
if(BF_DSP_LIB_DIR AND EXISTS "${BF_DSP_LIB_DIR}/Source")
    file(GLOB_RECURSE _DSP_ASM_SRCS "${BF_DSP_LIB_DIR}/Source/*/*.S")
    list(APPEND BF_ALL_SRCS ${_DSP_ASM_SRCS})
endif()

# Remove duplicates that come from including the same file in multiple lists
list(REMOVE_DUPLICATES BF_ALL_SRCS)

# ---------------------------------------------------------------------------
# Firmware version string (extracted from src/main/build/version.h)
# ---------------------------------------------------------------------------
set(_VERSION_HDR "${BF_SRC_DIR}/build/version.h")
set(BF_FC_VERSION "unknown")
if(EXISTS "${_VERSION_HDR}")
    file(STRINGS "${_VERSION_HDR}" _VER_LINE REGEX "FC_VERSION_STRING")
    if(_VER_LINE)
        string(REGEX REPLACE ".*\"([^\"]+)\".*" "\\1" BF_FC_VERSION "${_VER_LINE}")
    endif()
endif()

# Git revision
execute_process(
    COMMAND git rev-parse --short=9 HEAD
    WORKING_DIRECTORY "${BF_ROOT}"
    OUTPUT_VARIABLE BF_REVISION
    OUTPUT_STRIP_TRAILING_WHITESPACE
    ERROR_QUIET
)
if(NOT BF_REVISION)
    set(BF_REVISION "norevision")
endif()

# ---------------------------------------------------------------------------
# Optimisation flags — defined as CMake lists (semicolon-separated internally)
# ---------------------------------------------------------------------------
# Allow platform cmake to override these by setting BF_OPTIMISE_* before
# we resolve the final values.
if(BF_DEBUG STREQUAL "GDB")
    set(_CC_DEFAULT -Og)
    set(_CC_SPEED   -Og)
    set(_CC_SIZE    -Og)
    set(_DEBUG_FLAGS -ggdb2 -gdwarf-5 -DDEBUG)
    set(_LTO_FLAGS   "")
else()
    # LTO base as a proper CMake list (each flag is a separate item)
    set(_LTO_BASE
        -flto=auto
        -fuse-linker-plugin
        -ffast-math
        -fmerge-all-constants
    )
    # Use platform overrides if set, otherwise defaults
    if(BF_OPTIMISE_DEFAULT)
        separate_arguments(_OPT_DEFAULT UNIX_COMMAND "${BF_OPTIMISE_DEFAULT}")
    else()
        set(_OPT_DEFAULT -O2)
    endif()
    if(BF_OPTIMISE_SPEED)
        separate_arguments(_OPT_SPEED UNIX_COMMAND "${BF_OPTIMISE_SPEED}")
    else()
        set(_OPT_SPEED -Ofast)
    endif()
    if(BF_OPTIMISE_SIZE)
        separate_arguments(_OPT_SIZE UNIX_COMMAND "${BF_OPTIMISE_SIZE}")
    else()
        set(_OPT_SIZE -Os)
    endif()
    if(BF_DEBUG STREQUAL "INFO")
        set(_DEBUG_FLAGS -ggdb2)
    else()
        set(_DEBUG_FLAGS "")
    endif()
    set(_LTO_FLAGS  ${_LTO_BASE} ${_OPT_SPEED})
    set(_CC_DEFAULT ${_LTO_BASE} ${_OPT_DEFAULT})
    set(_CC_SPEED   ${_LTO_BASE} ${_OPT_SPEED})
    set(_CC_SIZE    ${_LTO_BASE} ${_OPT_SIZE})
endif()

# ---------------------------------------------------------------------------
# Create the firmware executable
# ---------------------------------------------------------------------------
# Strip dots/slashes from version for a valid target name
string(REPLACE "." "_" _VER_CLEAN "${BF_FC_VERSION}")
set(_ELF_NAME "betaflight_${_VER_CLEAN}_${BF_TARGET}")
if(BF_CONFIG)
    string(APPEND _ELF_NAME "_${BF_CONFIG}")
endif()

add_executable(${_ELF_NAME} ${BF_ALL_SRCS})

set_target_properties(${_ELF_NAME} PROPERTIES
    OUTPUT_NAME "${_ELF_NAME}"
    SUFFIX ".elf"
)

# ---------------------------------------------------------------------------
# Include directories
# ---------------------------------------------------------------------------
set(_INCLUDE_DIRS
    "${BF_SRC_DIR}"
    "${BF_LIB_DIR}/MAVLink"
    "${BF_PLATFORM_DIR}/common/stm32"
    "${BF_PLATFORM_DIR}/${BF_TARGET_PLATFORM}/target/${BF_TARGET}"
    "${BF_OLC_DIR}"
    ${BF_PLATFORM_INCLUDE_DIRS}
)

if(BF_CONFIG)
    list(APPEND _INCLUDE_DIRS "${BF_CONFIG_DIR}/configs/${BF_CONFIG}")
endif()

if(BF_DSP_LIB_DIR AND EXISTS "${BF_DSP_LIB_DIR}/Include")
    list(APPEND _INCLUDE_DIRS "${BF_DSP_LIB_DIR}/Include")
endif()

target_include_directories(${_ELF_NAME} PRIVATE ${_INCLUDE_DIRS})

# ---------------------------------------------------------------------------
# Compile definitions
# ---------------------------------------------------------------------------
set(_COMPILE_DEFS
    ${BF_DEVICE_FLAGS}
    "-DTARGET_FLASH_SIZE=${BF_TARGET_FLASH_SIZE}"
    "-D${BF_TARGET}"
    "-D${BF_TARGET_PLATFORM}"
    "-D${BF_TARGET_MCU_FAMILY}"
    "-D__FORKNAME__=\"betaflight\""
    "-D__TARGET__=\"${BF_TARGET}\""
    "-D__REVISION__=\"${BF_REVISION}\""
    "-D__FC_VERSION__=\"${BF_FC_VERSION}\""
    "-D_GNU_SOURCE"
    ${BF_CONFIG_COMPILE_DEFS}
)

if(BF_CONFIG)
    list(APPEND _COMPILE_DEFS "USE_CONFIG")
endif()
if(BF_EXST)
    list(APPEND _COMPILE_DEFS "USE_EXST")
endif()
if(BF_RAM_BASED)
    list(APPEND _COMPILE_DEFS "USE_EXST" "CONFIG_IN_RAM" "RAMBASED")
endif()

# ---------------------------------------------------------------------------
# Compile options (applied to target, then per-file overrides below)
# ---------------------------------------------------------------------------

# Suppress GCC 15+ warnings for code written against GCC 13 semantics
set(_GCC15_COMPAT_FLAGS "")
if(CMAKE_C_COMPILER_VERSION VERSION_GREATER_EQUAL "15.0.0")
    list(APPEND _GCC15_COMPAT_FLAGS
        # GCC 15 added stricter unterminated-string-initialization check
        -Wno-unterminated-string-initialization
    )
endif()

target_compile_options(${_ELF_NAME} PRIVATE
    ${BF_ARCH_FLAGS}
    -std=gnu17
    -Wall -Wextra -Werror
    -Wunsafe-loop-optimizations
    -Wdouble-promotion
    -Wold-style-definition
    ${_GCC15_COMPAT_FLAGS}
    -ffunction-sections
    -fdata-sections
    -fno-common
    -pipe
    -MMD -MP
    ${_DEBUG_FLAGS}
    ${BF_EXTRA_FLAGS}
    # NOTE: optimisation is set per-source-file below, not here
)

target_compile_definitions(${_ELF_NAME} PRIVATE ${_COMPILE_DEFS})

# ---------------------------------------------------------------------------
# Per-file optimisation
# ---------------------------------------------------------------------------
# Since COMPILE_OPTIONS on a source file are placed BEFORE the target's
# compile options on the command line, and GCC takes the last -O flag,
# we must NOT set optimisation at target level (done above) and instead
# assign it explicitly to every source file.
#
# Priority: size > speed > default  (size wins when a file is in both lists)
# Device library files also get -w to suppress third-party warnings.

set(_ALL_SPEED_SRCS ${BF_SPEED_OPT_SRCS} ${BF_SPEED_OPTIMISED_SRCS})
set(_ALL_SIZE_SRCS  ${BF_SIZE_OPT_SRCS}  ${BF_SIZE_OPTIMISED_SRCS})
list(REMOVE_DUPLICATES _ALL_SPEED_SRCS)
list(REMOVE_DUPLICATES _ALL_SIZE_SRCS)

# Build a set for fast lookup
set(_DEVLIB_SET "${BF_DEVICE_LIB_SRCS}")

foreach(_src ${BF_ALL_SRCS})
    # Determine optimisation tier
    if(_src IN_LIST _ALL_SIZE_SRCS)
        set(_opt_flags ${_CC_SIZE})
    elseif(_src IN_LIST _ALL_SPEED_SRCS)
        set(_opt_flags ${_CC_SPEED})
    else()
        set(_opt_flags ${_CC_DEFAULT})
    endif()

    # Suppress warnings for device library files
    if(_src IN_LIST _DEVLIB_SET)
        set_source_files_properties("${_src}" PROPERTIES
            COMPILE_OPTIONS "${_opt_flags};-w")
    else()
        set_source_files_properties("${_src}" PROPERTIES
            COMPILE_OPTIONS "${_opt_flags}")
    endif()
endforeach()

# ---------------------------------------------------------------------------
# Linker configuration
# ---------------------------------------------------------------------------
set(_MAP_FILE "${CMAKE_BINARY_DIR}/${_ELF_NAME}.map")

target_link_options(${_ELF_NAME} PRIVATE
    ${BF_ARCH_FLAGS}
    ${_LTO_FLAGS}
    ${_DEBUG_FLAGS}
    -nostartfiles
    "SHELL:--specs=nano.specs"
    -static
    "SHELL:-Wl,-gc-sections,--Map=${_MAP_FILE}"
    "SHELL:-Wl,-L${BF_PLATFORM_DIR}/${BF_TARGET_PLATFORM}/link"
    "SHELL:-Wl,--cref"
    "SHELL:-Wl,--no-wchar-size-warning"
    "SHELL:-Wl,--print-memory-usage"
    "-T${BF_LD_SCRIPT}"
)

# -lm / -lc / -lnosys must come AFTER object files so the linker can resolve
# _sbrk (from -lnosys) when nano.specs pulls in libc_nano at the very end.
# target_link_libraries() places these after @rsp; target_link_options() would not.
target_link_libraries(${_ELF_NAME} PRIVATE -lm -lc -lnosys)

# Additional linker scripts (e.g. EXST common/post scripts for H7)
foreach(_ld ${BF_LD_SCRIPTS})
    target_link_options(${_ELF_NAME} PRIVATE "-T${_ld}")
endforeach()

# ---------------------------------------------------------------------------
# Post-build: print size
# ---------------------------------------------------------------------------
add_custom_command(TARGET ${_ELF_NAME} POST_BUILD
    COMMAND "${ARM_SIZE}" "$<TARGET_FILE:${_ELF_NAME}>"
    COMMENT "Firmware size:"
)

# ---------------------------------------------------------------------------
# Binary output targets
# ---------------------------------------------------------------------------
set(_ELF_FILE "$<TARGET_FILE:${_ELF_NAME}>")
set(_HEX_FILE "${CMAKE_BINARY_DIR}/${_ELF_NAME}.hex")
set(_BIN_FILE "${CMAKE_BINARY_DIR}/${_ELF_NAME}.bin")

add_custom_command(OUTPUT "${_HEX_FILE}"
    COMMAND "${ARM_OBJCOPY}" -O ihex --set-start 0x8000000
            "${_ELF_FILE}" "${_HEX_FILE}"
    DEPENDS ${_ELF_NAME}
    COMMENT "Generating HEX: ${_HEX_FILE}"
)

add_custom_command(OUTPUT "${_BIN_FILE}"
    COMMAND "${ARM_OBJCOPY}" -O binary
            "${_ELF_FILE}" "${_BIN_FILE}"
    DEPENDS ${_ELF_NAME}
    COMMENT "Generating BIN: ${_BIN_FILE}"
)

add_custom_target(hex ALL DEPENDS "${_HEX_FILE}")
add_custom_target(bin      DEPENDS "${_BIN_FILE}")
