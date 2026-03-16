# cmake/arm-none-eabi-toolchain.cmake
#
# CMake toolchain file for ARM Cortex-M bare-metal targets.
# Automatically downloads the ARM GNU toolchain into <project_root>/.tools/
# if it is not already present.
#
# Usage:
#   cmake -B build -DCMAKE_TOOLCHAIN_FILE=cmake/arm-none-eabi-toolchain.cmake

set(TOOLCHAIN_VERSION "13.3.rel1")
set(TOOLCHAIN_PREFIX  "arm-none-eabi")

# Resolve .tools/ relative to this file's location (cmake/../.tools)
set(TOOLCHAIN_ROOT "${CMAKE_CURRENT_LIST_DIR}/../.tools")
cmake_path(NORMAL_PATH TOOLCHAIN_ROOT)

# Platform-specific archive name and extracted directory
if(CMAKE_HOST_WIN32)
    set(_ARCH_STEM "arm-gnu-toolchain-${TOOLCHAIN_VERSION}-mingw-w64-i686-${TOOLCHAIN_PREFIX}")
    set(_ARCHIVE   "${_ARCH_STEM}.zip")
elseif(CMAKE_HOST_APPLE AND CMAKE_HOST_SYSTEM_PROCESSOR MATCHES "arm64|aarch64")
    set(_ARCH_STEM "arm-gnu-toolchain-${TOOLCHAIN_VERSION}-darwin-arm64-${TOOLCHAIN_PREFIX}")
    set(_ARCHIVE   "${_ARCH_STEM}.tar.xz")
elseif(CMAKE_HOST_APPLE)
    set(_ARCH_STEM "arm-gnu-toolchain-${TOOLCHAIN_VERSION}-darwin-x86_64-${TOOLCHAIN_PREFIX}")
    set(_ARCHIVE   "${_ARCH_STEM}.tar.xz")
else()
    set(_ARCH_STEM "arm-gnu-toolchain-${TOOLCHAIN_VERSION}-x86_64-${TOOLCHAIN_PREFIX}")
    set(_ARCHIVE   "${_ARCH_STEM}.tar.xz")
endif()

set(_URL          "https://developer.arm.com/-/media/Files/downloads/gnu/${TOOLCHAIN_VERSION}/binrel/${_ARCHIVE}")
set(_SUBDIR_ROOT  "${TOOLCHAIN_ROOT}/${_ARCH_STEM}")   # layout after a fresh download
set(_GCC_EXE      "${TOOLCHAIN_PREFIX}-gcc${CMAKE_HOST_EXECUTABLE_SUFFIX}")

# Prefer the versioned subdirectory layout produced by a download (guarantees
# the correct version is used).  Fall back to a flat install only if the
# versioned layout is absent.
if(EXISTS "${_SUBDIR_ROOT}/bin/${_GCC_EXE}")
    set(TOOLCHAIN_BIN_DIR "${_SUBDIR_ROOT}/bin")
    set(_SYSROOT          "${_SUBDIR_ROOT}")
elseif(EXISTS "${TOOLCHAIN_ROOT}/bin/${_GCC_EXE}")
    set(TOOLCHAIN_BIN_DIR "${TOOLCHAIN_ROOT}/bin")
    set(_SYSROOT          "${TOOLCHAIN_ROOT}")
else()
    # Neither layout found — download and extract
    message(STATUS "ARM GNU toolchain not found — downloading v${TOOLCHAIN_VERSION}...")
    file(MAKE_DIRECTORY "${TOOLCHAIN_ROOT}")

    set(_ARCHIVE_PATH "${TOOLCHAIN_ROOT}/${_ARCHIVE}")
    file(DOWNLOAD "${_URL}" "${_ARCHIVE_PATH}"
        SHOW_PROGRESS
        STATUS _STATUS)
    list(GET _STATUS 0 _STATUS_CODE)
    if(NOT _STATUS_CODE EQUAL 0)
        message(FATAL_ERROR "Toolchain download failed: ${_STATUS}")
    endif()

    message(STATUS "Extracting ARM GNU toolchain...")
    file(ARCHIVE_EXTRACT INPUT "${_ARCHIVE_PATH}" DESTINATION "${TOOLCHAIN_ROOT}")
    message(STATUS "ARM GNU toolchain ready: ${_SUBDIR_ROOT}/bin")

    set(TOOLCHAIN_BIN_DIR "${_SUBDIR_ROOT}/bin")
    set(_SYSROOT          "${_SUBDIR_ROOT}")
endif()

# --- Cross-compilation settings ---

set(CMAKE_SYSTEM_NAME      Generic)
set(CMAKE_SYSTEM_PROCESSOR arm)

# Prevent CMake from link-testing the compiler (no OS / no libc on bare-metal)
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

set(CMAKE_C_COMPILER   "${TOOLCHAIN_BIN_DIR}/${TOOLCHAIN_PREFIX}-gcc${CMAKE_HOST_EXECUTABLE_SUFFIX}")
set(CMAKE_CXX_COMPILER "${TOOLCHAIN_BIN_DIR}/${TOOLCHAIN_PREFIX}-g++${CMAKE_HOST_EXECUTABLE_SUFFIX}")
set(CMAKE_ASM_COMPILER "${TOOLCHAIN_BIN_DIR}/${TOOLCHAIN_PREFIX}-gcc${CMAKE_HOST_EXECUTABLE_SUFFIX}")
set(CMAKE_OBJCOPY      "${TOOLCHAIN_BIN_DIR}/${TOOLCHAIN_PREFIX}-objcopy${CMAKE_HOST_EXECUTABLE_SUFFIX}")
set(CMAKE_SIZE         "${TOOLCHAIN_BIN_DIR}/${TOOLCHAIN_PREFIX}-size${CMAKE_HOST_EXECUTABLE_SUFFIX}")

# Export for use in CMakeLists.txt
set(ARM_OBJCOPY "${CMAKE_OBJCOPY}" CACHE FILEPATH "arm-none-eabi-objcopy")
set(ARM_SIZE    "${CMAKE_SIZE}"    CACHE FILEPATH "arm-none-eabi-size")

# Only search for headers/libs inside the sysroot, not the host system
set(CMAKE_FIND_ROOT_PATH "${_SYSROOT}")
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
