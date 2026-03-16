# cmake/at32f4.cmake
#
# AT32F43x family configuration (Artery BSP drivers).
# Expects BF_TARGET_MCU, BF_TARGET (for linker script selection), and
# BF_HSE_VALUE to be set before inclusion.

set(_AT32_DIR  "${BF_PLATFORM_DIR}/AT32")
set(_LIB_AT32  "${BF_LIB_DIR}/AT32F43x")
set(_PERIPH    "${_LIB_AT32}/drivers")
set(_MW        "${_LIB_AT32}/middlewares")

# ---- Architecture flags ----
set(BF_ARCH_FLAGS
    -std=c99
    -mthumb
    -mcpu=cortex-m4
    -march=armv7e-m
    -mfloat-abi=hard
    -mfpu=fpv4-sp-d16
)

# ---- Peripheral driver sources ----
set(_PERIPH_FILES
    at32f435_437_acc.c
    at32f435_437_adc.c
    at32f435_437_can.c
    at32f435_437_crc.c
    at32f435_437_crm.c
    at32f435_437_dac.c
    at32f435_437_debug.c
    at32f435_437_dma.c
    at32f435_437_dvp.c
    at32f435_437_edma.c
    at32f435_437_emac.c
    at32f435_437_ertc.c
    at32f435_437_exint.c
    at32f435_437_flash.c
    at32f435_437_gpio.c
    at32f435_437_i2c.c
    at32f435_437_misc.c
    at32f435_437_pwc.c
    at32f435_437_qspi.c
    at32f435_437_scfg.c
    at32f435_437_sdio.c
    at32f435_437_spi.c
    at32f435_437_tmr.c
    at32f435_437_usart.c
    at32f435_437_usb.c
    at32f435_437_wdt.c
    at32f435_437_wwdt.c
    at32f435_437_xmc.c
)

set(_PERIPH_FULL "")
foreach(_f ${_PERIPH_FILES})
    list(APPEND _PERIPH_FULL "${_PERIPH}/src/${_f}")
endforeach()

set(BF_DEVICE_LIB_SRCS
    ${_PERIPH_FULL}
    "${_AT32_DIR}/dma_reqmap_mcu.c"     # has naming discrepancies vs AT32 SDK headers
    "${_MW}/usb_drivers/src/usb_core.c"
    "${_MW}/usb_drivers/src/usbd_core.c"
    "${_MW}/usb_drivers/src/usbd_int.c"
    "${_MW}/usb_drivers/src/usbd_sdr.c"
    "${_MW}/usb_drivers/src/usbh_core.c"
    "${_MW}/usb_drivers/src/usbh_ctrl.c"
    "${_MW}/usb_drivers/src/usbh_int.c"
    "${_MW}/usbd_class/msc/msc_bot_scsi.c"
    "${_MW}/usbd_class/msc/msc_class.c"
    "${_MW}/usbd_class/msc/msc_desc.c"
)

# ---- Device flags ----
set(BF_DEVICE_FLAGS
    -DUSE_ATBSP_DRIVER
    -DAT32F43x
    -DAT32
    -DUSE_OTG_HOST_MODE
)

# ---- MCU-specific settings ----
if(BF_TARGET STREQUAL "AT32F435M")
    set(BF_LD_SCRIPT "${_AT32_DIR}/link/at32_flash_f43xm.ld")
else()
    set(BF_LD_SCRIPT "${_AT32_DIR}/link/at32_flash_f43xg.ld")
endif()

set(BF_STARTUP_SRCS "${_AT32_DIR}/startup/startup_at32f435_437.s")

# Flash size comes from target.mk MCU_FLASH_SIZE (AT32F435G=1024, AT32F435M=256)
if(NOT BF_MCU_FLASH_SIZE)
    set(BF_MCU_FLASH_SIZE 1024)
endif()

list(APPEND BF_DEVICE_FLAGS
    "-DHSE_VALUE=${BF_HSE_VALUE}"
)

# ---- Include directories ----
set(BF_PLATFORM_INCLUDE_DIRS
    "${_AT32_DIR}"
    "${_AT32_DIR}/include"
    "${_AT32_DIR}/startup"
    "${BF_PLATFORM_DIR}/common/stm32"
    "${_PERIPH}/inc"
    "${_LIB_AT32}/cmsis/cm4/core_support"
    "${_LIB_AT32}/cmsis/cm4"
    "${_MW}/i2c_application_library"
    "${_MW}/usbd_class/msc"
    "${_MW}/usb_drivers/inc"
    "${_MW}/usbd_class/cdc"
)

# ---- DSP library (reuse CMSIS DSP) ----
set(BF_DSP_LIB_DIR "${BF_LIB_DIR}/CMSIS/DSP")

# ---- MCU common sources ----
set(BF_MCU_SRCS
    "${BF_PLATFORM_DIR}/common/stm32/system.c"
    "${BF_PLATFORM_DIR}/common/stm32/io_impl.c"
    "${BF_PLATFORM_DIR}/common/stm32/config_flash.c"
    "${BF_PLATFORM_DIR}/common/stm32/mco.c"
    "${BF_PLATFORM_DIR}/common/stm32/pwm_output_beeper.c"
    "${BF_PLATFORM_DIR}/common/stm32/pwm_output_dshot_shared.c"
    "${BF_PLATFORM_DIR}/common/stm32/dshot_dpwm.c"
    "${BF_PLATFORM_DIR}/common/stm32/dshot_bitbang_shared.c"
    "${BF_PLATFORM_DIR}/common/stm32/bus_i2c_pinconfig.c"
    "${BF_PLATFORM_DIR}/common/stm32/bus_spi_hw.c"
    "${BF_PLATFORM_DIR}/common/stm32/bus_spi_pinconfig.c"
    "${BF_PLATFORM_DIR}/common/stm32/camera_control.c"
    "${BF_PLATFORM_DIR}/common/stm32/serial_uart_hw.c"
    "${BF_PLATFORM_DIR}/common/stm32/serial_uart_pinconfig.c"
    "${BF_PLATFORM_DIR}/common/stm32/ledstrip_ws2811_stm32.c"
    "${BF_PLATFORM_DIR}/common/stm32/debug_pin.c"
    "${BF_PLATFORM_DIR}/common/stm32/adc_impl.c"
    "${_AT32_DIR}/startup/at32f435_437_clock.c"
    "${_AT32_DIR}/startup/system_at32f435_437.c"
    "${_AT32_DIR}/system_at32f43x.c"
    "${_AT32_DIR}/adc_at32f43x.c"
    "${_AT32_DIR}/bus_i2c_atbsp.c"
    "${_AT32_DIR}/bus_i2c_atbsp_init.c"
    "${_AT32_DIR}/bus_spi_at32bsp.c"
    "${_AT32_DIR}/camera_control_at32.c"
    "${_AT32_DIR}/debug.c"
    "${_AT32_DIR}/dma_at32f43x.c"
    "${_AT32_DIR}/dshot_bitbang.c"
    "${_AT32_DIR}/dshot_bitbang_stdperiph.c"
    "${_AT32_DIR}/exti_at32.c"
    "${_AT32_DIR}/io_at32.c"
    "${_AT32_DIR}/light_ws2811strip_at32f43x.c"
    "${_AT32_DIR}/persistent_at32bsp.c"
    "${_AT32_DIR}/pwm_output_at32bsp.c"
    "${_AT32_DIR}/pwm_output_dshot.c"
    "${_AT32_DIR}/rcc_at32.c"
    "${_AT32_DIR}/serial_uart_at32bsp.c"
    "${_AT32_DIR}/serial_uart_at32f43x.c"
    "${_AT32_DIR}/serial_usb_vcp_at32f4.c"
    "${_AT32_DIR}/system_at32f43x.c"
    "${_AT32_DIR}/timer_at32bsp.c"
    "${_AT32_DIR}/timer_at32f43x.c"
    "${_AT32_DIR}/usb_msc_at32f43x.c"
    "${_MW}/i2c_application_library/i2c_application.c"
    "${BF_SRC_DIR}/drivers/accgyro/accgyro_mpu.c"
    "${BF_SRC_DIR}/drivers/dshot_bitbang_decode.c"
    "${BF_SRC_DIR}/drivers/inverter.c"
    "${BF_SRC_DIR}/drivers/bus_i2c_timing.c"
    "${BF_SRC_DIR}/drivers/usb_msc_common.c"
    "${BF_SRC_DIR}/drivers/adc.c"
    "${BF_SRC_DIR}/drivers/bus_spi_config.c"
    "${BF_SRC_DIR}/drivers/serial_escserial.c"
    "${BF_SRC_DIR}/drivers/serial_pinconfig.c"
    "${BF_SRC_DIR}/msc/usbd_storage.c"
    "${BF_SRC_DIR}/msc/usbd_storage_emfat.c"
    "${BF_SRC_DIR}/msc/emfat.c"
    "${BF_SRC_DIR}/msc/emfat_file.c"
    "${BF_SRC_DIR}/msc/usbd_storage_sd_spi.c"
)

# ---- VCP sources ----
set(BF_VCP_SRCS
    "${_MW}/usbd_class/cdc/cdc_class.c"
    "${_MW}/usbd_class/cdc/cdc_desc.c"
    "${BF_SRC_DIR}/drivers/usb_io.c"
)

# MSC is bundled in MCU_SRCS / DEVICE_LIB_SRCS for AT32
set(BF_MSC_SRCS "")

# ---- Per-file optimization overrides ----
set(BF_SPEED_OPTIMISED_SRCS
    "${BF_PLATFORM_DIR}/common/stm32/dshot_bitbang_shared.c"
    "${BF_PLATFORM_DIR}/common/stm32/pwm_output_dshot_shared.c"
    "${BF_PLATFORM_DIR}/common/stm32/bus_spi_hw.c"
    "${BF_PLATFORM_DIR}/common/stm32/system.c"
)

set(BF_SIZE_OPTIMISED_SRCS
    "${BF_SRC_DIR}/drivers/bus_i2c_timing.c"
    "${BF_SRC_DIR}/drivers/inverter.c"
    "${BF_SRC_DIR}/drivers/bus_spi_config.c"
    "${BF_PLATFORM_DIR}/common/stm32/bus_i2c_pinconfig.c"
    "${BF_PLATFORM_DIR}/common/stm32/bus_spi_pinconfig.c"
    "${BF_PLATFORM_DIR}/common/stm32/pwm_output_beeper.c"
    "${BF_PLATFORM_DIR}/common/stm32/serial_uart_pinconfig.c"
    "${BF_SRC_DIR}/drivers/serial_escserial.c"
    "${BF_SRC_DIR}/drivers/serial_pinconfig.c"
)
