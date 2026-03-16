# cmake/stm32f7.cmake
#
# STM32F7 family configuration (HAL + LL drivers).
# Expects BF_TARGET_MCU and BF_HSE_VALUE to be set before inclusion.

set(_STM32_DIR  "${BF_PLATFORM_DIR}/STM32")
set(_LIB_F7_DIR "${BF_LIB_DIR}/STM32F7/Drivers")
set(_CMSIS_DIR  "${BF_LIB_DIR}/CMSIS")

# ---- Architecture flags ----
set(BF_ARCH_FLAGS
    -mthumb
    -mcpu=cortex-m7
    -mfloat-abi=hard
    -mfpu=fpv5-sp-d16
)

# ---- HAL driver sources ----
set(_STDPERIPH_DIR "${_LIB_F7_DIR}/STM32F7xx_HAL_Driver")

set(_HAL_FILES
    stm32f7xx_hal_adc.c
    stm32f7xx_hal_adc_ex.c
    stm32f7xx_hal.c
    stm32f7xx_hal_cortex.c
    stm32f7xx_hal_dac.c
    stm32f7xx_hal_dac_ex.c
    stm32f7xx_hal_dma.c
    stm32f7xx_hal_dma_ex.c
    stm32f7xx_hal_exti.c
    stm32f7xx_hal_flash.c
    stm32f7xx_hal_flash_ex.c
    stm32f7xx_hal_gpio.c
    stm32f7xx_hal_i2c.c
    stm32f7xx_hal_i2c_ex.c
    stm32f7xx_hal_pcd.c
    stm32f7xx_hal_pcd_ex.c
    stm32f7xx_hal_pwr.c
    stm32f7xx_hal_pwr_ex.c
    stm32f7xx_hal_rcc.c
    stm32f7xx_hal_rcc_ex.c
    stm32f7xx_hal_rtc.c
    stm32f7xx_hal_rtc_ex.c
    stm32f7xx_hal_spi.c
    stm32f7xx_hal_spi_ex.c
    stm32f7xx_hal_tim.c
    stm32f7xx_hal_tim_ex.c
    stm32f7xx_hal_uart.c
    stm32f7xx_hal_uart_ex.c
    stm32f7xx_hal_usart.c
    stm32f7xx_ll_dma2d.c
    stm32f7xx_ll_dma.c
    stm32f7xx_ll_gpio.c
    stm32f7xx_ll_rcc.c
    stm32f7xx_ll_spi.c
    stm32f7xx_ll_tim.c
    stm32f7xx_ll_usb.c
    stm32f7xx_ll_utils.c
)

foreach(_f ${_HAL_FILES})
    list(APPEND _HAL_FULL "${_STDPERIPH_DIR}/Src/${_f}")
endforeach()

# USB middleware
set(_USBCORE_DIR "STM32F7/Middlewares/ST/STM32_USB_Device_Library/Core")
set(_USBCDC_DIR  "STM32F7/Middlewares/ST/STM32_USB_Device_Library/Class/CDC")
set(_USBHID_DIR  "STM32F7/Middlewares/ST/STM32_USB_Device_Library/Class/HID")
set(_USBMSC_DIR  "STM32F7/Middlewares/ST/STM32_USB_Device_Library/Class/MSC")

set(BF_DEVICE_LIB_SRCS
    ${_HAL_FULL}
    "${BF_LIB_DIR}/${_USBCORE_DIR}/Src/usbd_core.c"
    "${BF_LIB_DIR}/${_USBCORE_DIR}/Src/usbd_ctlreq.c"
    "${BF_LIB_DIR}/${_USBCORE_DIR}/Src/usbd_ioreq.c"
    "${BF_LIB_DIR}/${_USBCDC_DIR}/Src/usbd_cdc.c"
    "${BF_LIB_DIR}/${_USBHID_DIR}/Src/usbd_hid.c"
    "${BF_LIB_DIR}/${_USBMSC_DIR}/Src/usbd_msc_bot.c"
    "${BF_LIB_DIR}/${_USBMSC_DIR}/Src/usbd_msc.c"
    "${BF_LIB_DIR}/${_USBMSC_DIR}/Src/usbd_msc_data.c"
    "${BF_LIB_DIR}/${_USBMSC_DIR}/Src/usbd_msc_scsi.c"
)

# ---- Device flags ----
set(BF_DEVICE_FLAGS
    -DUSE_HAL_DRIVER
    -DUSE_FULL_LL_DRIVER
    -DSTM32
    -DARM_MATH_MATRIX_CHECK
    -DARM_MATH_ROUNDING
    -D__FPU_PRESENT=1
    -DUNALIGNED_SUPPORT_DISABLE
    -DARM_MATH_CM7
)

# ---- MCU-specific settings ----
set(BF_LD_SCRIPTS "")

if(BF_TARGET_MCU STREQUAL "STM32F765xx")
    list(APPEND BF_DEVICE_FLAGS -DSTM32F765xx)
    set(BF_LD_SCRIPT "${_STM32_DIR}/link/stm32_flash_f765.ld")
    set(BF_STARTUP_SRCS "${_STM32_DIR}/startup/startup_stm32f765xx.s")
    set(BF_MCU_FLASH_SIZE 2048)

elseif(BF_TARGET_MCU STREQUAL "STM32F745xx")
    list(APPEND BF_DEVICE_FLAGS -DSTM32F745xx)
    set(BF_LD_SCRIPT "${_STM32_DIR}/link/stm32_flash_f74x.ld")
    set(BF_STARTUP_SRCS "${_STM32_DIR}/startup/startup_stm32f745xx.s")
    set(BF_MCU_FLASH_SIZE 1024)

elseif(BF_TARGET_MCU STREQUAL "STM32F746xx")
    list(APPEND BF_DEVICE_FLAGS -DSTM32F746xx)
    set(BF_LD_SCRIPT "${_STM32_DIR}/link/stm32_flash_f74x.ld")
    set(BF_STARTUP_SRCS "${_STM32_DIR}/startup/startup_stm32f746xx.s")
    set(BF_MCU_FLASH_SIZE 1024)

elseif(BF_TARGET_MCU STREQUAL "STM32F722xx")
    list(APPEND BF_DEVICE_FLAGS -DSTM32F722xx)
    set(BF_LD_SCRIPT "${_STM32_DIR}/link/stm32_flash_f722.ld")
    set(BF_STARTUP_SRCS "${_STM32_DIR}/startup/startup_stm32f722xx.s")
    set(BF_MCU_FLASH_SIZE 512)
    # Override speed optimisation to save flash on 512 KB targets
    set(BF_OPTIMISE_SPEED "-O2")

else()
    message(FATAL_ERROR "Unknown STM32F7 MCU: ${BF_TARGET_MCU}")
endif()

list(APPEND BF_DEVICE_FLAGS "-DHSE_VALUE=${BF_HSE_VALUE}")

# ---- Include directories ----
set(BF_PLATFORM_INCLUDE_DIRS
    "${_STM32_DIR}"
    "${_STM32_DIR}/include"
    "${_STM32_DIR}/startup"
    "${_STM32_DIR}/vcp_hal"
    "${BF_PLATFORM_DIR}/common/stm32"
    "${_STDPERIPH_DIR}/Inc"
    "${BF_LIB_DIR}/${_USBCORE_DIR}/Inc"
    "${BF_LIB_DIR}/${_USBCDC_DIR}/Inc"
    "${BF_LIB_DIR}/${_USBHID_DIR}/Inc"
    "${BF_LIB_DIR}/${_USBMSC_DIR}/Inc"
    "${_CMSIS_DIR}/Core/Include"
    "${_LIB_F7_DIR}/CMSIS/Device/ST/STM32F7xx/Include"
)

# ---- DSP library ----
set(BF_DSP_LIB_DIR "${_CMSIS_DIR}/DSP")

# ---- MCU common sources ----
set(BF_MCU_SRCS
    "${BF_SRC_DIR}/drivers/accgyro/accgyro_mpu.c"
    "${BF_SRC_DIR}/drivers/bus_i2c_timing.c"
    "${BF_SRC_DIR}/drivers/dshot_bitbang_decode.c"
    "${_STM32_DIR}/adc_stm32f7xx.c"
    "${_STM32_DIR}/audio_stm32f7xx.c"
    "${_STM32_DIR}/bus_i2c_hal_init.c"
    "${_STM32_DIR}/bus_i2c_hal.c"
    "${_STM32_DIR}/bus_spi_ll.c"
    "${_STM32_DIR}/debug.c"
    "${_STM32_DIR}/dma_reqmap_mcu.c"
    "${_STM32_DIR}/dma_stm32f7xx.c"
    "${_STM32_DIR}/dshot_bitbang_ll.c"
    "${_STM32_DIR}/dshot_bitbang.c"
    "${_STM32_DIR}/exti.c"
    "${_STM32_DIR}/io_stm32.c"
    "${_STM32_DIR}/light_ws2811strip_hal.c"
    "${_STM32_DIR}/persistent.c"
    "${_STM32_DIR}/pwm_output_dshot_hal.c"
    "${_STM32_DIR}/rcc_stm32.c"
    "${_STM32_DIR}/sdio_f7xx.c"
    "${_STM32_DIR}/serial_uart_hal.c"
    "${_STM32_DIR}/serial_uart_stm32f7xx.c"
    "${_STM32_DIR}/system_stm32f7xx.c"
    "${_STM32_DIR}/timer_hal.c"
    "${_STM32_DIR}/timer_stm32f7xx.c"
    "${_STM32_DIR}/transponder_ir_io_hal.c"
    "${_STM32_DIR}/camera_control_stm32.c"
    "${BF_SRC_DIR}/drivers/adc.c"
    "${BF_SRC_DIR}/drivers/serial_escserial.c"
    "${_STM32_DIR}/startup/system_stm32f7xx.c"
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

# ---- VCP sources ----
set(BF_VCP_SRCS
    "${_STM32_DIR}/vcp_hal/usbd_desc.c"
    "${_STM32_DIR}/vcp_hal/usbd_conf_stm32f7xx.c"
    "${_STM32_DIR}/vcp_hal/usbd_cdc_hid.c"
    "${_STM32_DIR}/vcp_hal/usbd_cdc_interface.c"
    "${_STM32_DIR}/serial_usb_vcp.c"
    "${BF_SRC_DIR}/drivers/usb_io.c"
)

# ---- MSC sources ----
set(BF_MSC_SRCS
    "${BF_SRC_DIR}/drivers/usb_msc_common.c"
    "${_STM32_DIR}/usb_msc_hal.c"
    "${BF_SRC_DIR}/msc/usbd_storage.c"
    "${BF_SRC_DIR}/msc/usbd_storage_emfat.c"
    "${BF_SRC_DIR}/msc/emfat.c"
    "${BF_SRC_DIR}/msc/emfat_file.c"
    "${BF_SRC_DIR}/msc/usbd_storage_sdio.c"
    "${BF_SRC_DIR}/msc/usbd_storage_sd_spi.c"
)

# ---- Per-file optimization overrides ----
set(BF_SPEED_OPTIMISED_SRCS
    "${_STM32_DIR}/bus_i2c_hal.c"
    "${_STM32_DIR}/bus_spi_ll.c"
    "${BF_SRC_DIR}/drivers/max7456.c"
    "${_STM32_DIR}/pwm_output_dshot_hal.c"
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
