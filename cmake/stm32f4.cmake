# cmake/stm32f4.cmake
#
# STM32F4 family configuration.
# Expects BF_TARGET_MCU and BF_HSE_VALUE to be set before inclusion.
# Sets: BF_ARCH_FLAGS, BF_DEVICE_FLAGS, BF_LD_SCRIPT, BF_LD_SCRIPTS,
#       BF_STARTUP_SRCS, BF_MCU_SRCS, BF_VCP_SRCS, BF_MSC_SRCS,
#       BF_DEVICE_LIB_SRCS, BF_PLATFORM_INCLUDE_DIRS, BF_MCU_FLASH_SIZE,
#       BF_DSP_LIB_DIR, BF_SPEED_OPTIMISED_SRCS, BF_SIZE_OPTIMISED_SRCS

set(_STM32_DIR   "${BF_PLATFORM_DIR}/STM32")
set(_LIB_F4_DIR  "${BF_LIB_DIR}/STM32F4/Drivers")
set(_CMSIS_DIR   "${BF_LIB_DIR}/CMSIS")

# ---- Architecture flags ----
set(BF_ARCH_FLAGS
    -mthumb
    -mcpu=cortex-m4
    -march=armv7e-m
    -mfloat-abi=hard
    -mfpu=fpv4-sp-d16
)

# ---- StdPeriph driver (default for F4) ----
set(_STDPERIPH_DIR "${_LIB_F4_DIR}/STM32F4xx_StdPeriph_Driver")
set(_STDPERIPH_SRC_DIR "${_STDPERIPH_DIR}/src")

set(_STDPERIPH_FILES
    misc.c
    stm32f4xx_adc.c
    stm32f4xx_dac.c
    stm32f4xx_dcmi.c
    stm32f4xx_dfsdm.c
    stm32f4xx_dma2d.c
    stm32f4xx_dma.c
    stm32f4xx_exti.c
    stm32f4xx_flash.c
    stm32f4xx_gpio.c
    stm32f4xx_i2c.c
    stm32f4xx_iwdg.c
    stm32f4xx_ltdc.c
    stm32f4xx_pwr.c
    stm32f4xx_rcc.c
    stm32f4xx_rng.c
    stm32f4xx_rtc.c
    stm32f4xx_sdio.c
    stm32f4xx_spi.c
    stm32f4xx_syscfg.c
    stm32f4xx_tim.c
    stm32f4xx_usart.c
    stm32f4xx_wwdg.c
)

# USB OTG / CDC / HID / MSC / wrapper (StdPeriph mode)
set(_USBOTG_DIR  "${BF_LIB_DIR}/STM32_USB_OTG_Driver")
set(_USBCORE_DIR "${BF_LIB_DIR}/STM32_USB_Device_Library/Core")
set(_USBCDC_DIR  "${BF_LIB_DIR}/STM32_USB_Device_Library/Class/cdc")
set(_USBHID_DIR  "${BF_LIB_DIR}/STM32_USB_Device_Library/Class/hid")
set(_USBMSC_DIR  "${BF_LIB_DIR}/STM32_USB_Device_Library/Class/msc")
set(_USBWRAPPER_DIR "${BF_LIB_DIR}/STM32_USB_Device_Library/Class/hid_cdc_wrapper")

# Prepend full paths for stdperiph + USB
foreach(_f ${_STDPERIPH_FILES})
    list(APPEND _STDPERIPH_FULL "${_STDPERIPH_SRC_DIR}/${_f}")
endforeach()

set(_USBOTG_SRCS
    "${_USBOTG_DIR}/src/usb_core.c"
    "${_USBOTG_DIR}/src/usb_dcd.c"
    "${_USBOTG_DIR}/src/usb_dcd_int.c"
)
set(_USBCORE_SRCS
    "${_USBCORE_DIR}/src/usbd_core.c"
    "${_USBCORE_DIR}/src/usbd_ioreq.c"
    "${_USBCORE_DIR}/src/usbd_req.c"
)
set(_USBCDC_SRCS  "${_USBCDC_DIR}/src/usbd_cdc_core.c")
set(_USBHID_SRCS  "${_USBHID_DIR}/src/usbd_hid_core.c")
set(_USBMSC_SRCS
    "${_USBMSC_DIR}/src/usbd_msc_bot.c"
    "${_USBMSC_DIR}/src/usbd_msc_core.c"
    "${_USBMSC_DIR}/src/usbd_msc_data.c"
    "${_USBMSC_DIR}/src/usbd_msc_scsi.c"
)
set(_USBWRAPPER_SRCS "${_USBWRAPPER_DIR}/src/usbd_hid_cdc_wrapper.c")

set(BF_DEVICE_LIB_SRCS
    ${_STDPERIPH_FULL}
    ${_USBOTG_SRCS}
    ${_USBCORE_SRCS}
    ${_USBCDC_SRCS}
    ${_USBHID_SRCS}
    ${_USBMSC_SRCS}
    ${_USBWRAPPER_SRCS}
)

# ---- Device flags ----
set(BF_DEVICE_FLAGS
    -DSTM32F4
    -DUSE_STDPERIPH_DRIVER
    -DARM_MATH_MATRIX_CHECK
    -DARM_MATH_ROUNDING
    -D__FPU_PRESENT=1
    -DUNALIGNED_SUPPORT_DISABLE
    -DARM_MATH_CM4
)

# ---- MCU-specific: linker script, startup, flash size, extra device flags ----
if(BF_TARGET_MCU STREQUAL "STM32F411xE")
    list(APPEND BF_DEVICE_FLAGS -DSTM32F411xE -finline-limit=20)
    set(BF_LD_SCRIPT  "${_STM32_DIR}/link/stm32_flash_f411.ld")
    set(BF_STARTUP_SRCS "${_STM32_DIR}/startup/startup_stm32f411xe.s")
    set(BF_MCU_FLASH_SIZE 512)

elseif(BF_TARGET_MCU STREQUAL "STM32F405xx")
    list(APPEND BF_DEVICE_FLAGS -DSTM32F40_41xxx -DSTM32F405xx)
    set(BF_LD_SCRIPT  "${_STM32_DIR}/link/stm32_flash_f405.ld")
    set(BF_STARTUP_SRCS "${_STM32_DIR}/startup/startup_stm32f40xx.s")
    set(BF_MCU_FLASH_SIZE 1024)

elseif(BF_TARGET_MCU STREQUAL "STM32F446xx")
    list(APPEND BF_DEVICE_FLAGS -DSTM32F446xx)
    set(BF_LD_SCRIPT  "${_STM32_DIR}/link/stm32_flash_f446.ld")
    set(BF_STARTUP_SRCS "${_STM32_DIR}/startup/startup_stm32f446xx.s")
    set(BF_MCU_FLASH_SIZE 512)

else()
    message(FATAL_ERROR "Unknown STM32F4 MCU: ${BF_TARGET_MCU}")
endif()

# STM32F411/F446 do not have FSMC
if(NOT BF_TARGET_MCU STREQUAL "STM32F411xE" AND NOT BF_TARGET_MCU STREQUAL "STM32F446xx")
    list(APPEND BF_DEVICE_LIB_SRCS "${_STDPERIPH_SRC_DIR}/stm32f4xx_fsmc.c")
endif()

list(APPEND BF_DEVICE_FLAGS "-DHSE_VALUE=${BF_HSE_VALUE}")

# ---- Include directories ----
set(BF_PLATFORM_INCLUDE_DIRS
    "${_STM32_DIR}"
    "${_STM32_DIR}/include"
    "${_STM32_DIR}/startup"
    "${_STM32_DIR}/vcpf4"
    "${BF_PLATFORM_DIR}/common/stm32"
    "${_STDPERIPH_DIR}/inc"
    "${_USBOTG_DIR}/inc"
    "${_USBCORE_DIR}/inc"
    "${_USBCDC_DIR}/inc"
    "${_USBHID_DIR}/inc"
    "${_USBWRAPPER_DIR}/inc"
    "${_USBMSC_DIR}/inc"
    "${_CMSIS_DIR}/Core/Include"
    "${_LIB_F4_DIR}/CMSIS/Device/ST/STM32F4xx"
)

# ---- DSP library ----
set(BF_DSP_LIB_DIR "${_CMSIS_DIR}/DSP")

# ---- MCU common sources ----
set(BF_MCU_SRCS
    "${BF_PLATFORM_DIR}/common/stm32/system.c"
    "${BF_PLATFORM_DIR}/common/stm32/config_flash.c"
    "${BF_SRC_DIR}/drivers/accgyro/accgyro_mpu.c"
    "${BF_SRC_DIR}/drivers/dshot_bitbang_decode.c"
    "${BF_SRC_DIR}/drivers/inverter.c"
    "${_STM32_DIR}/pwm_output_dshot.c"
    "${_STM32_DIR}/adc_stm32f4xx.c"
    "${_STM32_DIR}/bus_i2c_stm32f4xx.c"
    "${_STM32_DIR}/bus_spi_stdperiph.c"
    "${_STM32_DIR}/debug.c"
    "${_STM32_DIR}/dma_reqmap_mcu.c"
    "${_STM32_DIR}/dma_stm32f4xx.c"
    "${_STM32_DIR}/dshot_bitbang.c"
    "${_STM32_DIR}/dshot_bitbang_stdperiph.c"
    "${_STM32_DIR}/exti.c"
    "${_STM32_DIR}/io_stm32.c"
    "${_STM32_DIR}/light_ws2811strip_stdperiph.c"
    "${_STM32_DIR}/persistent.c"
    "${_STM32_DIR}/rcc_stm32.c"
    "${_STM32_DIR}/sdio_f4xx.c"
    "${_STM32_DIR}/serial_uart_stdperiph.c"
    "${_STM32_DIR}/serial_uart_stm32f4xx.c"
    "${_STM32_DIR}/system_stm32f4xx.c"
    "${_STM32_DIR}/timer_stdperiph.c"
    "${_STM32_DIR}/timer_stm32f4xx.c"
    "${_STM32_DIR}/transponder_ir_io_stdperiph.c"
    "${_STM32_DIR}/usbd_msc_desc.c"
    "${_STM32_DIR}/camera_control_stm32.c"
    "${BF_SRC_DIR}/drivers/adc.c"
    "${BF_SRC_DIR}/drivers/serial_escserial.c"
    "${_STM32_DIR}/startup/system_stm32f4xx.c"
)

# STM32_COMMON additions
list(APPEND BF_MCU_SRCS
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

# ---- VCP sources (StdPeriph / vcpf4) ----
set(BF_VCP_SRCS
    "${_STM32_DIR}/vcpf4/stm32f4xx_it.c"
    "${_STM32_DIR}/vcpf4/usb_bsp.c"
    "${_STM32_DIR}/vcpf4/usbd_desc.c"
    "${_STM32_DIR}/vcpf4/usbd_usr.c"
    "${_STM32_DIR}/vcpf4/usbd_cdc_vcp.c"
    "${_STM32_DIR}/vcpf4/usb_cdc_hid.c"
    "${_STM32_DIR}/serial_usb_vcp.c"
    "${BF_SRC_DIR}/drivers/usb_io.c"
)

# ---- MSC sources ----
set(BF_MSC_SRCS
    "${BF_SRC_DIR}/drivers/usb_msc_common.c"
    "${_STM32_DIR}/usb_msc_f4xx.c"
    "${BF_SRC_DIR}/msc/usbd_storage.c"
    "${BF_SRC_DIR}/msc/usbd_storage_emfat.c"
    "${BF_SRC_DIR}/msc/emfat.c"
    "${BF_SRC_DIR}/msc/emfat_file.c"
    "${BF_SRC_DIR}/msc/usbd_storage_sd_spi.c"
    "${BF_SRC_DIR}/msc/usbd_storage_sdio.c"
)

# ---- Per-file optimization overrides ----
set(BF_SPEED_OPTIMISED_SRCS
    "${BF_PLATFORM_DIR}/common/stm32/system.c"
    "${_STM32_DIR}/exti.c"
    # STM32_COMMON speed srcs
    "${BF_PLATFORM_DIR}/common/stm32/bus_spi_hw.c"
    "${BF_PLATFORM_DIR}/common/stm32/pwm_output_dshot_shared.c"
    "${_STM32_DIR}/pwm_output_hw.c"
    "${BF_PLATFORM_DIR}/common/stm32/dshot_bitbang_shared.c"
    "${BF_PLATFORM_DIR}/common/stm32/io_impl.c"
)

set(BF_SIZE_OPTIMISED_SRCS
    "${_STM32_DIR}/serial_usb_vcp.c"
    "${BF_SRC_DIR}/drivers/inverter.c"
    "${BF_SRC_DIR}/drivers/serial_escserial.c"
    # STM32_COMMON size srcs
    "${BF_SRC_DIR}/drivers/bus_spi_config.c"
    "${BF_SRC_DIR}/drivers/serial_pinconfig.c"
    "${BF_PLATFORM_DIR}/common/stm32/bus_i2c_pinconfig.c"
    "${BF_PLATFORM_DIR}/common/stm32/config_flash.c"
    "${BF_PLATFORM_DIR}/common/stm32/bus_spi_pinconfig.c"
    "${BF_PLATFORM_DIR}/common/stm32/pwm_output_beeper.c"
    "${BF_PLATFORM_DIR}/common/stm32/serial_uart_pinconfig.c"
)
