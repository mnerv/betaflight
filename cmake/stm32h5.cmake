# cmake/stm32h5.cmake
#
# STM32H5 family configuration (HAL + LL drivers).
# Expects BF_TARGET_MCU and BF_HSE_VALUE to be set before inclusion.
# NOTE: USB support is not yet implemented for H5 (uses USBX, WIP upstream).

set(_STM32_DIR  "${BF_PLATFORM_DIR}/STM32")
set(_LIB_H5_DIR "${BF_LIB_DIR}/STM32H5/Drivers")
set(_CMSIS_DIR  "${BF_LIB_DIR}/CMSIS")

# ---- Architecture flags ----
set(BF_ARCH_FLAGS
    -mthumb
    -mcpu=cortex-m7
    -mfloat-abi=hard
    -mfpu=fpv5-sp-d16
)

# ---- HAL driver sources ----
set(_STDPERIPH_DIR "${_LIB_H5_DIR}/STM32H5xx_HAL_Driver")

set(_HAL_FILES
    stm32h5xx_hal_adc.c
    stm32h5xx_hal_adc_ex.c
    stm32h5xx_hal.c
    stm32h5xx_hal_cordic.c
    stm32h5xx_hal_cortex.c
    stm32h5xx_hal_dac.c
    stm32h5xx_hal_dac_ex.c
    stm32h5xx_hal_dcache.c
    stm32h5xx_hal_dma.c
    stm32h5xx_hal_dma_ex.c
    stm32h5xx_hal_dts.c
    stm32h5xx_hal_exti.c
    stm32h5xx_hal_flash.c
    stm32h5xx_hal_flash_ex.c
    stm32h5xx_hal_fmac.c
    stm32h5xx_hal_gpio.c
    stm32h5xx_hal_gtzc.c
    stm32h5xx_hal_i2c.c
    stm32h5xx_hal_i2c_ex.c
    stm32h5xx_hal_i3c.c
    stm32h5xx_hal_icache.c
    stm32h5xx_hal_otfdec.c
    stm32h5xx_hal_pcd.c
    stm32h5xx_hal_pcd_ex.c
    stm32h5xx_hal_pka.c
    stm32h5xx_hal_pssi.c
    stm32h5xx_hal_pwr.c
    stm32h5xx_hal_pwr_ex.c
    stm32h5xx_hal_ramcfg.c
    stm32h5xx_hal_rcc.c
    stm32h5xx_hal_rcc_ex.c
    stm32h5xx_hal_rng_ex.c
    stm32h5xx_hal_rtc_ex.c
    stm32h5xx_hal_sd.c
    stm32h5xx_hal_smbus_ex.c
    stm32h5xx_hal_spi_ex.c
    stm32h5xx_hal_tim.c
    stm32h5xx_hal_tim_ex.c
    stm32h5xx_hal_uart.c
    stm32h5xx_hal_uart_ex.c
    stm32h5xx_hal_xspi.c
    stm32h5xx_ll_cordic.c
    stm32h5xx_ll_crs.c
    stm32h5xx_ll_dlyb.c
    stm32h5xx_ll_dma.c
    stm32h5xx_ll_fmac.c
    stm32h5xx_ll_i3c.c
    stm32h5xx_ll_icache.c
    stm32h5xx_ll_pka.c
    stm32h5xx_ll_sdmmc.c
    stm32h5xx_ll_spi.c
    stm32h5xx_ll_tim.c
    stm32h5xx_ll_ucpd.c
    stm32h5xx_ll_usb.c
    stm32h5xx_util_i3c.c
)

foreach(_f ${_HAL_FILES})
    list(APPEND _HAL_FULL "${_STDPERIPH_DIR}/Src/${_f}")
endforeach()

# USB not yet supported on H5
set(BF_DEVICE_LIB_SRCS ${_HAL_FULL})

# ---- Device flags ----
set(BF_DEVICE_FLAGS
    -DUSE_HAL_DRIVER
    -DUSE_FULL_LL_DRIVER
    -DSTM32
    -DARM_MATH_MATRIX_CHECK
    -DARM_MATH_ROUNDING
    -DUNALIGNED_SUPPORT_DISABLE
    -DARM_MATH_CM7
)

# ---- MCU-specific settings ----
if(BF_TARGET_MCU STREQUAL "STM32H563xx")
    list(APPEND BF_DEVICE_FLAGS -DSTM32H563xx -DMAX_MPU_REGIONS=16)
    set(BF_LD_SCRIPT "${_STM32_DIR}/link/stm32_flash_h563_2m.ld")
    set(BF_STARTUP_SRCS "${_STM32_DIR}/startup/startup_stm32h563xx.s")
    set(BF_MCU_FLASH_SIZE 2048)
    # H5 uses -Os optimisation by default
    set(BF_OPTIMISE_DEFAULT "-Os")
    set(BF_OPTIMISE_SPEED   "-Os")
    set(BF_OPTIMISE_SIZE    "-Os")
else()
    message(FATAL_ERROR "Unknown STM32H5 MCU: ${BF_TARGET_MCU}")
endif()

list(APPEND BF_DEVICE_FLAGS
    "-DHSE_VALUE=${BF_HSE_VALUE}"
    "-DHSE_STARTUP_TIMEOUT=1000"
)

# ---- Include directories ----
set(BF_PLATFORM_INCLUDE_DIRS
    "${_STM32_DIR}"
    "${_STM32_DIR}/include"
    "${_STM32_DIR}/startup"
    "${BF_PLATFORM_DIR}/common/stm32"
    "${_STDPERIPH_DIR}/Inc"
    "${_CMSIS_DIR}/Core/Include"
    "${_LIB_H5_DIR}/CMSIS/Device/ST/STM32H5xx/Include"
)

# ---- DSP library ----
set(BF_DSP_LIB_DIR "${_CMSIS_DIR}/DSP")

# ---- MCU common sources ----
set(BF_MCU_SRCS
    "${BF_SRC_DIR}/drivers/bus_i2c_timing.c"
    "${BF_SRC_DIR}/drivers/bus_quadspi.c"
    "${BF_SRC_DIR}/drivers/dshot_bitbang_decode.c"
    "${_STM32_DIR}/bus_i2c_hal_init.c"
    "${_STM32_DIR}/bus_i2c_hal.c"
    "${_STM32_DIR}/bus_spi_ll.c"
    "${_STM32_DIR}/bus_quadspi_hal.c"
    "${_STM32_DIR}/debug.c"
    "${_STM32_DIR}/dma_reqmap_mcu.c"
    "${_STM32_DIR}/dshot_bitbang_ll.c"
    "${_STM32_DIR}/dshot_bitbang.c"
    "${_STM32_DIR}/exti.c"
    "${_STM32_DIR}/io_stm32.c"
    "${_STM32_DIR}/light_ws2811strip_hal.c"
    "${_STM32_DIR}/persistent.c"
    "${_STM32_DIR}/pwm_output_dshot_hal.c"
    "${_STM32_DIR}/rcc_stm32.c"
    "${_STM32_DIR}/serial_uart_hal.c"
    "${_STM32_DIR}/timer_hal.c"
    "${_STM32_DIR}/transponder_ir_io_hal.c"
    "${_STM32_DIR}/camera_control_stm32.c"
    "${_STM32_DIR}/system_stm32h5xx.c"
    "${BF_SRC_DIR}/drivers/adc.c"
    "${BF_SRC_DIR}/drivers/serial_escserial.c"
    "${_STM32_DIR}/startup/system_stm32h5xx.c"
    # STM32_COMMON
    "${BF_PLATFORM_DIR}/common/stm32/system.c"
    "${BF_PLATFORM_DIR}/common/stm32/config_flash.c"
    "${BF_PLATFORM_DIR}/common/stm32/bus_spi_pinconfig.c"
    "${BF_PLATFORM_DIR}/common/stm32/mco.c"
    "${BF_SRC_DIR}/drivers/bus_spi_config.c"
    "${BF_SRC_DIR}/drivers/serial_pinconfig.c"
    "${BF_PLATFORM_DIR}/common/stm32/bus_i2c_pinconfig.c"
    "${BF_PLATFORM_DIR}/common/stm32/bus_spi_hw.c"
    "${BF_PLATFORM_DIR}/common/stm32/camera_control.c"
    "${BF_PLATFORM_DIR}/common/stm32/io_impl.c"
    "${BF_PLATFORM_DIR}/common/stm32/serial_uart_hw.c"
    "${BF_PLATFORM_DIR}/common/stm32/serial_uart_pinconfig.c"
    "${BF_PLATFORM_DIR}/common/stm32/dshot_dpwm.c"
    "${_STM32_DIR}/pwm_output_hw.c"
    "${BF_PLATFORM_DIR}/common/stm32/rx_pwm_hw.c"
    "${BF_PLATFORM_DIR}/common/stm32/pwm_output_dshot_shared.c"
    "${BF_PLATFORM_DIR}/common/stm32/pwm_output_beeper.c"
    "${BF_PLATFORM_DIR}/common/stm32/dshot_bitbang_shared.c"
    "${BF_PLATFORM_DIR}/common/stm32/ledstrip_ws2811_stm32.c"
    "${BF_PLATFORM_DIR}/common/stm32/debug_pin.c"
    "${BF_PLATFORM_DIR}/common/stm32/adc_impl.c"
)

# VCP / MSC not yet supported on H5
set(BF_VCP_SRCS "")
set(BF_MSC_SRCS "")

# ---- Per-file optimization overrides ----
set(BF_SPEED_OPTIMISED_SRCS
    "${_STM32_DIR}/exti.c"
    "${BF_PLATFORM_DIR}/common/stm32/system.c"
    "${BF_PLATFORM_DIR}/common/stm32/bus_spi_hw.c"
    "${BF_PLATFORM_DIR}/common/stm32/pwm_output_dshot_shared.c"
    "${_STM32_DIR}/pwm_output_hw.c"
    "${BF_PLATFORM_DIR}/common/stm32/dshot_bitbang_shared.c"
    "${BF_PLATFORM_DIR}/common/stm32/io_impl.c"
)

set(BF_SIZE_OPTIMISED_SRCS
    "${BF_SRC_DIR}/drivers/bus_i2c_timing.c"
    "${_STM32_DIR}/bus_i2c_hal_init.c"
    "${_STM32_DIR}/serial_usb_vcp.c"
    "${BF_SRC_DIR}/drivers/serial_escserial.c"
    "${BF_SRC_DIR}/drivers/bus_spi_config.c"
    "${BF_SRC_DIR}/drivers/serial_pinconfig.c"
    "${BF_PLATFORM_DIR}/common/stm32/bus_i2c_pinconfig.c"
    "${BF_PLATFORM_DIR}/common/stm32/config_flash.c"
    "${BF_PLATFORM_DIR}/common/stm32/bus_spi_pinconfig.c"
    "${BF_PLATFORM_DIR}/common/stm32/pwm_output_beeper.c"
    "${BF_PLATFORM_DIR}/common/stm32/serial_uart_pinconfig.c"
)
