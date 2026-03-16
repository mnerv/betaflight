# cmake/rp2350.cmake
#
# Raspberry Pi RP2350 family configuration (pico-sdk + TinyUSB).
# Expects BF_TARGET_MCU and BF_HSE_VALUE to be set before inclusion.

set(_PICO_DIR    "${BF_PLATFORM_DIR}/PICO")
set(_SDK_DIR     "${BF_LIB_DIR}/pico-sdk/src")
set(_TUSB_DIR    "${BF_LIB_DIR}/pico-sdk/lib/tinyusb/src")
set(_CMSIS_STUB  "${_SDK_DIR}/rp2_common/cmsis/stub/CMSIS")

# ---- Architecture flags ----
set(BF_ARCH_FLAGS
    -mthumb
    -mcpu=cortex-m33
    -march=armv8-m.main+fp+dsp
    -mcmse
    -mfloat-abi=softfp
    -DPICO_COPY_TO_RAM=1
    -fno-builtin-memcpy
    -fno-builtin-memset
)

# ---- pico-sdk library sources ----
set(_PICO_LIB_REL
    rp2_common/pico_crt0/crt0.S
    rp2_common/hardware_sync_spin_lock/sync_spin_lock.c
    rp2_common/hardware_gpio/gpio.c
    rp2_common/hardware_uart/uart.c
    rp2_common/hardware_irq/irq.c
    rp2_common/hardware_irq/irq_handler_chain.S
    rp2_common/hardware_timer/timer.c
    rp2_common/hardware_clocks/clocks.c
    rp2_common/hardware_pll/pll.c
    rp2_common/hardware_dma/dma.c
    rp2_common/hardware_spi/spi.c
    rp2_common/hardware_i2c/i2c.c
    rp2_common/hardware_adc/adc.c
    rp2_common/hardware_pio/pio.c
    rp2_common/hardware_watchdog/watchdog.c
    rp2_common/hardware_flash/flash.c
    rp2_common/pico_unique_id/unique_id.c
    rp2_common/pico_platform_panic/panic.c
    rp2_common/pico_multicore/multicore.c
    common/pico_sync/mutex.c
    common/pico_time/time.c
    common/pico_sync/lock_core.c
    common/hardware_claim/claim.c
    common/pico_sync/critical_section.c
    rp2_common/hardware_sync/sync.c
    rp2_common/pico_runtime_init/runtime_init.c
    rp2_common/pico_runtime_init/runtime_init_clocks.c
    rp2_common/pico_runtime_init/runtime_init_stack_guard.c
    rp2_common/pico_runtime/runtime.c
    rp2_common/hardware_ticks/ticks.c
    rp2_common/hardware_xosc/xosc.c
    common/pico_sync/sem.c
    common/pico_time/timeout_helper.c
    common/pico_util/datetime.c
    common/pico_util/pheap.c
    common/pico_util/queue.c
    rp2350/pico_platform/platform.c
    rp2_common/pico_atomic/atomic.c
    rp2_common/pico_bootrom/bootrom.c
    rp2_common/pico_bootrom/bootrom_lock.c
    rp2_common/pico_divider/divider_compiler.c
    rp2_common/pico_flash/flash.c
    rp2_common/hardware_divider/divider.c
    rp2_common/hardware_vreg/vreg.c
    rp2_common/hardware_xip_cache/xip_cache.c
    rp2_common/pico_standard_binary_info/standard_binary_info.c
    rp2_common/pico_clib_interface/newlib_interface.c
    rp2_common/pico_malloc/malloc.c
    rp2_common/pico_stdlib/stdlib.c
    rp2_common/pico_bit_ops/bit_ops_aeabi.S
    # float
    rp2_common/pico_float/float_common_m33.S
    rp2_common/pico_float/float_conv32_vfp.S
    rp2_common/pico_float/float_math.c
    rp2_common/pico_float/float_sci_m33_vfp.S
    # double: use the "none" pass-through implementation since the DCP-accelerated
    # files (double_aeabi_dcp.S, double_fma_dcp.S) need hardware/dcp_instr.inc.S
    # which is not available in this checkout.  double_none.S provides all the
    # required __wrap___aeabi_d* symbols by forwarding to the standard library.
    rp2_common/pico_double/double_none.S
    # stdio / printf
    rp2_common/pico_stdio/stdio.c
    rp2_common/pico_printf/printf.c
    # USB reset interface (RP2040 fix applies to RP2350 too)
    rp2_common/pico_stdio_usb/reset_interface.c
    rp2_common/pico_fix/rp2040_usb_device_enumeration/rp2040_usb_device_enumeration.c
)

set(_PICO_LIB_SRCS "")
foreach(_f ${_PICO_LIB_REL})
    list(APPEND _PICO_LIB_SRCS "${_SDK_DIR}/${_f}")
endforeach()

# PICO/memfunctions.S lives in the platform dir
list(APPEND _PICO_LIB_SRCS "${_PICO_DIR}/memfunctions.S")

# ---- TinyUSB sources ----
# TinyUSB is a nested sub-submodule inside pico-sdk. Initialize it with:
#   git submodule update --init lib/main/pico-sdk/lib/tinyusb
if(NOT EXISTS "${_TUSB_DIR}/tusb.c")
    message(WARNING
        "TinyUSB not found at ${_TUSB_DIR}.\n"
        "USB/VCP support will be absent for RP2350.\n"
        "Initialize it with: git submodule update --init lib/main/pico-sdk/lib/tinyusb")
    set(_TUSB_SRCS "")
else()
    set(_TUSB_SRCS
        "${_TUSB_DIR}/tusb.c"
        "${_TUSB_DIR}/class/cdc/cdc_device.c"
        "${_TUSB_DIR}/common/tusb_fifo.c"
        "${_TUSB_DIR}/device/usbd.c"
        "${_TUSB_DIR}/device/usbd_control.c"
        "${_TUSB_DIR}/portable/raspberrypi/rp2040/dcd_rp2040.c"
        "${_TUSB_DIR}/portable/raspberrypi/rp2040/rp2040_usb.c"
        "${_TUSB_DIR}/class/vendor/vendor_device.c"
        "${_TUSB_DIR}/class/net/ecm_rndis_device.c"
        "${_TUSB_DIR}/class/net/ncm_device.c"
        "${_TUSB_DIR}/class/dfu/dfu_rt_device.c"
        "${_TUSB_DIR}/class/dfu/dfu_device.c"
        "${_TUSB_DIR}/class/msc/msc_device.c"
        "${_TUSB_DIR}/class/midi/midi_device.c"
        "${_TUSB_DIR}/class/video/video_device.c"
        "${_TUSB_DIR}/class/hid/hid_device.c"
        "${_TUSB_DIR}/class/usbtmc/usbtmc_device.c"
        "${_TUSB_DIR}/class/audio/audio_device.c"
    )
endif()

set(BF_DEVICE_LIB_SRCS ${_PICO_LIB_SRCS} ${_TUSB_SRCS})

# ---- Device flags ----
set(BF_DEVICE_FLAGS
    -DPICO_RP2350=1
    -DPICO_RP2350_A2_SUPPORTED=1
    -DPICO_32BIT=1
    -DPICO_BUILD=1
    -DPICO_CXX_ENABLE_EXCEPTIONS=0
    -DPICO_NO_FLASH=0
    -DPICO_NO_HARDWARE=0
    -DPICO_ON_DEVICE=1
    -DPICO_USE_BLOCKED_RAM=0
    -DPICO_CORE1_STACK_SIZE=0x1000
    -DLIB_BOOT_STAGE2_HEADERS=1
    -DLIB_PICO_ATOMIC=1
    -DLIB_PICO_BIT_OPS=1
    -DLIB_PICO_BIT_OPS_PICO=1
    -DLIB_PICO_CLIB_INTERFACE=1
    -DLIB_PICO_CRT0=1
    -DLIB_PICO_CXX_OPTIONS=1
    -DLIB_PICO_DIVIDER=1
    -DLIB_PICO_DIVIDER_COMPILER=1
    -DLIB_PICO_DOUBLE=1
    -DLIB_PICO_DOUBLE_PICO=1
    -DLIB_PICO_FLOAT=1
    -DLIB_PICO_FLOAT_PICO=1
    -DLIB_PICO_FLOAT_PICO_VFP=1
    -DLIB_PICO_INT64_OPS=1
    -DLIB_PICO_INT64_OPS_COMPILER=1
    -DLIB_PICO_MALLOC=1
    -DLIB_PICO_MEM_OPS=1
    -DLIB_PICO_MEM_OPS_COMPILER=1
    -DLIB_PICO_NEWLIB_INTERFACE=1
    -DLIB_PICO_PLATFORM=1
    -DLIB_PICO_PLATFORM_COMPILER=1
    -DLIB_PICO_PLATFORM_PANIC=1
    -DLIB_PICO_PLATFORM_SECTIONS=1
    -DLIB_PICO_PRINTF=1
    -DLIB_PICO_PRINTF_PICO=1
    -DLIB_PICO_RUNTIME=1
    -DLIB_PICO_RUNTIME_INIT=1
    -DLIB_PICO_STANDARD_BINARY_INFO=1
    -DLIB_PICO_STANDARD_LINK=1
    -DLIB_PICO_STDIO=1
    -DLIB_PICO_STDIO_UART=1
    -DLIB_PICO_STDIO_USB=1
    -DLIB_PICO_STDLIB=1
    -DLIB_PICO_SYNC=1
    -DLIB_PICO_SYNC_CRITICAL_SECTION=1
    -DLIB_PICO_SYNC_MUTEX=1
    -DLIB_PICO_SYNC_SEM=1
    -DLIB_PICO_TIME=1
    -DLIB_PICO_TIME_ADAPTER=1
    -DLIB_PICO_UTIL=1
    -DLIB_PICO_UNIQUEID=1
    -DLIB_PICO_FIX_RP2040_USB_DEVICE_ENUMERATION=1
    -DLIB_PICO_PRINTF=1
    -DLIB_PICO_PRINTF_PICO=1
    -DCFG_TUSB_DEBUG=0
    -DCFG_TUSB_MCU=OPT_MCU_RP2040
    -DCFG_TUSB_OS=OPT_OS_NONE
    -DPICO_RP2040_USB_DEVICE_UFRAME_FIX=1
    -DPICO_STDIO_USB_CONNECT_WAIT_TIMEOUT_MS=3000
    "-DHSE_VALUE=${BF_HSE_VALUE}"
    -DPICO
)

# ---- MCU-specific settings ----
if(BF_TARGET_MCU STREQUAL "RP2350A")
    list(APPEND BF_DEVICE_FLAGS -DRP2350A)
elseif(BF_TARGET_MCU STREQUAL "RP2350B")
    list(APPEND BF_DEVICE_FLAGS -DRP2350B)
else()
    message(FATAL_ERROR "Unknown RP2350 MCU: ${BF_TARGET_MCU}")
endif()

# Default 4 MB flash; can be overridden via BF_PICO_FLASH_MB
if(NOT DEFINED BF_PICO_FLASH_MB)
    set(BF_PICO_FLASH_MB 4)
endif()
set(BF_LD_SCRIPT    "${_PICO_DIR}/link/pico_flash_${BF_PICO_FLASH_MB}MB.ld")
set(BF_LD_SCRIPTS   "${_PICO_DIR}/link/pico_rp2350_RunFromRAM.ld")
set(BF_STARTUP_SRCS "")   # crt0.S is in pico-sdk (part of DEVICE_LIB_SRCS)
set(BF_MCU_FLASH_SIZE "${BF_PICO_FLASH_MB}192")   # approx KB (4MB = 4096KB)

# Speed opt capped at -O2 to save flash (same as Makefile OPTIMISE_SPEED override)
set(BF_OPTIMISE_SPEED "-O2")

# ---- Include directories ----
set(_TUSB_INCLUDE "")
if(_TUSB_SRCS)
    set(_TUSB_INCLUDE "${_TUSB_DIR}")
endif()

# Betaflight PICO platform dirs (our code — warnings are expected to be clean)
set(BF_PLATFORM_INCLUDE_DIRS
    "${_PICO_DIR}"
    "${_PICO_DIR}/include"
    "${_PICO_DIR}/usb"
    "${_PICO_DIR}/startup"
)

# pico-sdk and CMSIS stub dirs as SYSTEM includes so their headers don't
# trigger -Werror on old-style definitions, redefinitions, etc.
set(BF_PLATFORM_SYSTEM_INCLUDE_DIRS
    ${_TUSB_INCLUDE}
    "${_SDK_DIR}/common/pico_bit_ops_headers/include"
    "${_SDK_DIR}/common/pico_base_headers/include"
    "${_SDK_DIR}/common/boot_picoboot_headers/include"
    "${_SDK_DIR}/common/pico_usb_reset_interface_headers/include"
    "${_SDK_DIR}/common/pico_time/include"
    "${_SDK_DIR}/common/boot_uf2_headers/include"
    "${_SDK_DIR}/common/pico_divider_headers/include"
    "${_SDK_DIR}/common/boot_picobin_headers/include"
    "${_SDK_DIR}/common/pico_util/include"
    "${_SDK_DIR}/common/pico_stdlib_headers/include"
    "${_SDK_DIR}/common/hardware_claim/include"
    "${_SDK_DIR}/common/pico_binary_info/include"
    "${_SDK_DIR}/common/pico_sync/include"
    "${_SDK_DIR}/rp2_common/pico_stdio_uart/include"
    "${_SDK_DIR}/rp2_common/pico_stdio_usb/include"
    "${_SDK_DIR}/rp2_common/tinyusb/include"
    "${_SDK_DIR}/rp2_common/hardware_boot_lock/include"
    "${_SDK_DIR}/rp2_common/pico_mem_ops/include"
    "${_SDK_DIR}/rp2_common/hardware_exception/include"
    "${_SDK_DIR}/rp2_common/hardware_sync_spin_lock/include"
    "${_SDK_DIR}/rp2_common/pico_runtime_init/include"
    "${_SDK_DIR}/rp2_common/pico_standard_link/include"
    "${_SDK_DIR}/rp2_common/hardware_pio/include"
    "${_SDK_DIR}/rp2_common/pico_platform_compiler/include"
    "${_SDK_DIR}/rp2_common/hardware_divider/include"
    "${_SDK_DIR}/rp2_common/hardware_flash/include"
    "${_SDK_DIR}/rp2_common/hardware_ticks/include"
    "${_SDK_DIR}/rp2_common/hardware_dma/include"
    "${_SDK_DIR}/rp2_common/pico_bit_ops/include"
    "${_SDK_DIR}/rp2_common/hardware_clocks/include"
    "${_SDK_DIR}/rp2_common/pico_unique_id/include"
    "${_SDK_DIR}/rp2_common/hardware_watchdog/include"
    "${_SDK_DIR}/rp2_common/hardware_uart/include"
    "${_SDK_DIR}/rp2_common/hardware_interp/include"
    "${_SDK_DIR}/rp2_common/pico_printf/include"
    "${_SDK_DIR}/rp2_common/pico_double/include"
    "${_SDK_DIR}/rp2_common/hardware_vreg/include"
    "${_SDK_DIR}/rp2_common/hardware_spi/include"
    "${_SDK_DIR}/rp2_common/pico_standard_binary_info/include"
    "${_SDK_DIR}/rp2_common/pico_int64_ops/include"
    "${_SDK_DIR}/rp2_common/hardware_irq/include"
    "${_SDK_DIR}/rp2_common/pico_divider/include"
    "${_SDK_DIR}/rp2_common/pico_flash/include"
    "${_SDK_DIR}/rp2_common/hardware_sync/include"
    "${_SDK_DIR}/rp2_common/pico_bootrom/include"
    "${_SDK_DIR}/rp2_common/pico_crt0/include"
    "${_SDK_DIR}/rp2_common/pico_clib_interface/include"
    "${_SDK_DIR}/rp2_common/pico_stdio/include"
    "${_SDK_DIR}/rp2_common/pico_runtime/include"
    "${_SDK_DIR}/rp2_common/pico_time_adapter/include"
    "${_SDK_DIR}/rp2_common/pico_platform_panic/include"
    "${_SDK_DIR}/rp2_common/hardware_adc/include"
    "${_SDK_DIR}/rp2_common/cmsis/include"
    "${_SDK_DIR}/rp2_common/hardware_pll/include"
    "${_SDK_DIR}/rp2_common/pico_platform_sections/include"
    "${_SDK_DIR}/rp2_common/boot_bootrom_headers/include"
    "${_SDK_DIR}/rp2_common/pico_fix/include"
    "${_SDK_DIR}/rp2_common/hardware_base/include"
    "${_SDK_DIR}/rp2_common/hardware_xosc/include"
    "${_SDK_DIR}/rp2_common/hardware_pwm/include"
    "${_SDK_DIR}/rp2_common/pico_float/include"
    "${_SDK_DIR}/rp2_common/hardware_resets/include"
    "${_SDK_DIR}/rp2_common/pico_stdlib/include"
    "${_SDK_DIR}/rp2_common/hardware_i2c/include"
    "${_SDK_DIR}/rp2_common/pico_atomic/include"
    "${_SDK_DIR}/rp2_common/pico_multicore/include"
    "${_SDK_DIR}/rp2_common/hardware_gpio/include"
    "${_SDK_DIR}/rp2_common/pico_malloc/include"
    "${_SDK_DIR}/rp2_common/hardware_timer/include"
    "${_SDK_DIR}/rp2_common/hardware_xip_cache/include"
    "${_CMSIS_STUB}/Core/Include"
    "${_CMSIS_STUB}/Device/RP2350/Include"
    "${_SDK_DIR}/rp2350/pico_platform/include"
    "${_SDK_DIR}/rp2350/hardware_regs/include"
    "${_SDK_DIR}/rp2350/hardware_structs/include"
    "${_SDK_DIR}/rp2350/boot_stage2/include"
    "${_SDK_DIR}/rp2_common/pico_fix/rp2040_usb_device_enumeration/include"
)

# No CMSIS DSP for PICO
set(BF_DSP_LIB_DIR "")

# pico-sdk --wrap= linker flags do not work with LTO; compile pico-sdk
# device lib files without LTO.
set(BF_DEVICE_LIB_NO_LTO TRUE)

# ---- MCU common sources ----
set(BF_MCU_SRCS
    "${BF_SRC_DIR}/drivers/accgyro/accgyro_mpu.c"
    "${BF_SRC_DIR}/drivers/dshot_bitbang_decode.c"
    "${BF_SRC_DIR}/drivers/inverter.c"
    "${BF_SRC_DIR}/drivers/bus_spi.c"
    "${BF_SRC_DIR}/drivers/bus_spi_config.c"
    "${BF_SRC_DIR}/drivers/bus_i2c_utils.c"
    "${BF_SRC_DIR}/drivers/serial_pinconfig.c"
    "${BF_SRC_DIR}/drivers/usb_io.c"
    "${BF_SRC_DIR}/drivers/dshot.c"
    "${BF_SRC_DIR}/drivers/adc.c"
    "${_PICO_DIR}/adc_pico.c"
    "${_PICO_DIR}/bus_i2c_pico.c"
    "${_PICO_DIR}/bus_spi_pico.c"
    "${_PICO_DIR}/bus_quadspi_pico.c"
    "${_PICO_DIR}/config_flash.c"
    "${_PICO_DIR}/debug_pico.c"
    "${_PICO_DIR}/dma_pico.c"
    "${_PICO_DIR}/dshot_bidir_pico.c"
    "${_PICO_DIR}/dshot_pico.c"
    "${_PICO_DIR}/exti_pico.c"
    "${_PICO_DIR}/io_pico.c"
    "${_PICO_DIR}/persistent.c"
    "${_PICO_DIR}/pwm_motor_pico.c"
    "${_PICO_DIR}/pwm_servo_pico.c"
    "${_PICO_DIR}/pwm_beeper_pico.c"
    "${_PICO_DIR}/serial_usb_vcp_pico.c"
    "${_PICO_DIR}/system.c"
    "${_PICO_DIR}/uart/serial_uart_pico.c"
    "${_PICO_DIR}/uart/uart_hw.c"
    "${_PICO_DIR}/uart/uart_pio.c"
    "${_PICO_DIR}/uart/uart_rx_program.c"
    "${_PICO_DIR}/uart/uart_tx_program.c"
    "${_PICO_DIR}/usb/usb_cdc.c"
    "${_PICO_DIR}/usb/usb_descriptors.c"
    "${_PICO_DIR}/usb/usb_msc_pico.c"
    "${_PICO_DIR}/multicore.c"
    "${_PICO_DIR}/debug_pin.c"
    "${_PICO_DIR}/light_ws2811strip_pico.c"
    "${BF_SRC_DIR}/drivers/usb_msc_common.c"
    "${BF_SRC_DIR}/msc/usbd_storage.c"
    "${BF_SRC_DIR}/msc/usbd_storage_emfat.c"
    "${BF_SRC_DIR}/msc/emfat.c"
    "${BF_SRC_DIR}/msc/emfat_file.c"
)

# VCP is integrated into MCU_SRCS for PICO (serial_usb_vcp_pico.c + usb/)
set(BF_VCP_SRCS "")
set(BF_MSC_SRCS "")

# ---- Linker wrap flags (pico-sdk float/double/mem/stdio wrapping) ----
set(_FLOAT_WRAPS
    __aeabi_f2lz __aeabi_f2ulz __aeabi_l2f __aeabi_ul2f
    acosf acoshf asinf asinhf atan2f atanf atanhf cbrtf ceilf copysignf
    cosf coshf dremf exp10f exp2f expf expm1f floorf fmaf fmodf hypotf
    ldexpf log10f log1pf log2f logf powf powintf remainderf remquof
    roundf sincosf sinf sinhf tanf tanhf truncf
)
set(_DOUBLE_WRAPS
    __aeabi_cdcmpeq __aeabi_cdcmple __aeabi_cdrcmple
    __aeabi_d2f __aeabi_d2iz __aeabi_d2lz __aeabi_d2uiz __aeabi_d2ulz
    __aeabi_dadd __aeabi_dcmpeq __aeabi_dcmpge __aeabi_dcmpgt
    __aeabi_dcmple __aeabi_dcmplt __aeabi_dcmpun
    __aeabi_ddiv __aeabi_dmul __aeabi_drsub __aeabi_dsub
    __aeabi_i2d __aeabi_l2d __aeabi_ui2d __aeabi_ul2d
    acos acosh asin asinh atan atan2 atanh cbrt ceil copysign cos cosh
    drem exp exp10 exp2 expm1 floor fma fmod hypot ldexp log log10 log1p
    log2 pow powint remainder remquo round sin sincos sinh sqrt tan tanh trunc
)
set(_STDIO_WRAPS sprintf snprintf vsnprintf printf vprintf puts putchar getchar)
set(_MEM_WRAPS   memcpy_44 memcpy memset_4 memset)

set(BF_EXTRA_LD_FLAGS "")
foreach(_fn ${_FLOAT_WRAPS} ${_DOUBLE_WRAPS} ${_STDIO_WRAPS})
    list(APPEND BF_EXTRA_LD_FLAGS "SHELL:-Wl,--wrap=${_fn}")
endforeach()
list(APPEND BF_EXTRA_LD_FLAGS "SHELL:-Wl,--wrap=__ctzdi2")
foreach(_fn ${_MEM_WRAPS})
    list(APPEND BF_EXTRA_LD_FLAGS "SHELL:-Wl,--wrap=${_fn}")
endforeach()

# ---- Per-file optimization overrides ----
# pico-sdk files built at -O2 (matches Makefile PICO_LIB_OPTIMISATION)
set(BF_SPEED_OPTIMISED_SRCS ${_PICO_LIB_SRCS} ${_TUSB_SRCS})
set(BF_SIZE_OPTIMISED_SRCS "")
