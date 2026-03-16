# cmake/stm32h7.cmake
#
# STM32H7 family configuration (HAL + LL drivers).
# Expects BF_TARGET_MCU, BF_HSE_VALUE, BF_EXST, BF_RAM_BASED to be set.

set(_STM32_DIR  "${BF_PLATFORM_DIR}/STM32")
set(_LIB_H7_DIR "${BF_LIB_DIR}/STM32H7/Drivers")
set(_CMSIS_DIR  "${BF_LIB_DIR}/CMSIS")

# ---- Architecture flags ----
set(BF_ARCH_FLAGS
    -mthumb
    -mcpu=cortex-m7
    -mfloat-abi=hard
    -mfpu=fpv5-sp-d16
)

# ---- HAL driver sources ----
set(_STDPERIPH_DIR "${_LIB_H7_DIR}/STM32H7xx_HAL_Driver")

set(_HAL_FILES
    stm32h7xx_hal_adc.c
    stm32h7xx_hal_adc_ex.c
    stm32h7xx_hal.c
    stm32h7xx_hal_cordic.c
    stm32h7xx_hal_cortex.c
    stm32h7xx_hal_dac.c
    stm32h7xx_hal_dac_ex.c
    stm32h7xx_hal_dfsdm_ex.c
    stm32h7xx_hal_dma.c
    stm32h7xx_hal_dma_ex.c
    stm32h7xx_hal_dts.c
    stm32h7xx_hal_exti.c
    stm32h7xx_hal_flash.c
    stm32h7xx_hal_flash_ex.c
    stm32h7xx_hal_fmac.c
    stm32h7xx_hal_gfxmmu.c
    stm32h7xx_hal_gpio.c
    stm32h7xx_hal_i2c.c
    stm32h7xx_hal_i2c_ex.c
    stm32h7xx_hal_ospi.c
    stm32h7xx_hal_otfdec.c
    stm32h7xx_hal_pcd.c
    stm32h7xx_hal_pcd_ex.c
    stm32h7xx_hal_pssi.c
    stm32h7xx_hal_pwr.c
    stm32h7xx_hal_pwr_ex.c
    stm32h7xx_hal_qspi.c
    stm32h7xx_hal_rcc.c
    stm32h7xx_hal_rcc_ex.c
    stm32h7xx_hal_rng_ex.c
    stm32h7xx_hal_rtc_ex.c
    stm32h7xx_hal_sd.c
    stm32h7xx_hal_spi_ex.c
    stm32h7xx_hal_tim.c
    stm32h7xx_hal_tim_ex.c
    stm32h7xx_hal_uart.c
    stm32h7xx_hal_uart_ex.c
    stm32h7xx_ll_cordic.c
    stm32h7xx_ll_crs.c
    stm32h7xx_ll_dma.c
    stm32h7xx_ll_fmac.c
    stm32h7xx_ll_sdmmc.c
    stm32h7xx_ll_spi.c
    stm32h7xx_ll_tim.c
    stm32h7xx_ll_usb.c
)

foreach(_f ${_HAL_FILES})
    list(APPEND _HAL_FULL "${_STDPERIPH_DIR}/Src/${_f}")
endforeach()

# USB middleware
set(_USBCORE_DIR "STM32H7/Middlewares/ST/STM32_USB_Device_Library/Core")
set(_USBCDC_DIR  "STM32H7/Middlewares/ST/STM32_USB_Device_Library/Class/CDC")
set(_USBHID_DIR  "STM32H7/Middlewares/ST/STM32_USB_Device_Library/Class/HID")
set(_USBMSC_DIR  "STM32H7/Middlewares/ST/STM32_USB_Device_Library/Class/MSC")

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

# ---- Device flags (base, MCU-specific appended below) ----
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

set(BF_LD_SCRIPTS "")

# ---- MCU-specific settings ----
if(BF_TARGET_MCU STREQUAL "STM32H743xx")
    list(APPEND BF_DEVICE_FLAGS -DSTM32H743xx -DMAX_MPU_REGIONS=16)
    set(_DEFAULT_LD_SCRIPT "${_STM32_DIR}/link/stm32_flash_h743_2m.ld")
    set(BF_STARTUP_SRCS "${_STM32_DIR}/startup/startup_stm32h743xx.s")
    if(BF_RAM_BASED)
        set(BF_MCU_FLASH_SIZE 448)
        list(APPEND BF_DEVICE_FLAGS -DFIRMWARE_SIZE=448)
        set(_DEFAULT_LD_SCRIPT "${_STM32_DIR}/link/stm32_ram_h743.ld")
    else()
        set(BF_MCU_FLASH_SIZE 2048)
    endif()

elseif(BF_TARGET_MCU STREQUAL "STM32H7A3xxQ")
    list(APPEND BF_DEVICE_FLAGS -DSTM32H7A3xxQ -DMAX_MPU_REGIONS=16)
    set(_DEFAULT_LD_SCRIPT "${_STM32_DIR}/link/stm32_flash_h7a3_2m.ld")
    set(BF_STARTUP_SRCS "${_STM32_DIR}/startup/startup_stm32h7a3xx.s")
    if(BF_RAM_BASED)
        set(BF_MCU_FLASH_SIZE 448)
        list(APPEND BF_DEVICE_FLAGS -DFIRMWARE_SIZE=448)
        set(_DEFAULT_LD_SCRIPT "${_STM32_DIR}/link/stm32_flash_h7a3_ram_based.ld")
    else()
        set(BF_MCU_FLASH_SIZE 2048)
    endif()

elseif(BF_TARGET_MCU STREQUAL "STM32H7A3xx")
    list(APPEND BF_DEVICE_FLAGS -DSTM32H7A3xx -DMAX_MPU_REGIONS=16)
    set(_DEFAULT_LD_SCRIPT "${_STM32_DIR}/link/stm32_flash_h7a3_2m.ld")
    set(BF_STARTUP_SRCS "${_STM32_DIR}/startup/startup_stm32h7a3xx.s")
    if(BF_RAM_BASED)
        set(BF_MCU_FLASH_SIZE 448)
        list(APPEND BF_DEVICE_FLAGS -DFIRMWARE_SIZE=448)
        set(_DEFAULT_LD_SCRIPT "${_STM32_DIR}/link/stm32_flash_h7a3_ram_based.ld")
    else()
        set(BF_MCU_FLASH_SIZE 2048)
    endif()

elseif(BF_TARGET_MCU STREQUAL "STM32H723xx")
    list(APPEND BF_DEVICE_FLAGS -DSTM32H723xx -DMAX_MPU_REGIONS=16)
    set(BF_STARTUP_SRCS "${_STM32_DIR}/startup/startup_stm32h723xx.s")
    if(BF_EXST)
        set(BF_MCU_FLASH_SIZE 1024)
        list(APPEND BF_DEVICE_FLAGS -DFIRMWARE_SIZE=1024)
        set(_DEFAULT_LD_SCRIPT "${_STM32_DIR}/link/stm32_ram_h723_exst.ld")
        set(BF_LD_SCRIPTS
            "${_STM32_DIR}/link/stm32_h723_common.ld"
            "${_STM32_DIR}/link/stm32_h723_common_post.ld"
        )
    else()
        set(BF_MCU_FLASH_SIZE 1024)
        set(_DEFAULT_LD_SCRIPT "${_STM32_DIR}/link/stm32_flash_h723_1m.ld")
    endif()

elseif(BF_TARGET_MCU STREQUAL "STM32H725xx")
    list(APPEND BF_DEVICE_FLAGS -DSTM32H725xx -DMAX_MPU_REGIONS=16)
    set(_DEFAULT_LD_SCRIPT "${_STM32_DIR}/link/stm32_flash_h723_1m.ld")
    set(BF_STARTUP_SRCS "${_STM32_DIR}/startup/startup_stm32h723xx.s")
    set(BF_MCU_FLASH_SIZE 1024)

elseif(BF_TARGET_MCU STREQUAL "STM32H730xx")
    list(APPEND BF_DEVICE_FLAGS -DSTM32H730xx -DMAX_MPU_REGIONS=16)
    set(BF_STARTUP_SRCS "${_STM32_DIR}/startup/startup_stm32h730xx.s")
    if(BF_EXST)
        set(BF_MCU_FLASH_SIZE 1024)
        list(APPEND BF_DEVICE_FLAGS -DFIRMWARE_SIZE=1024)
        set(_DEFAULT_LD_SCRIPT "${_STM32_DIR}/link/stm32_ram_h730_exst.ld")
        set(BF_LD_SCRIPTS
            "${_STM32_DIR}/link/stm32_h730_common.ld"
            "${_STM32_DIR}/link/stm32_h730_common_post.ld"
        )
    else()
        set(BF_MCU_FLASH_SIZE 128)
        set(_DEFAULT_LD_SCRIPT "${_STM32_DIR}/link/stm32_flash_h730_128m.ld")
    endif()

elseif(BF_TARGET_MCU STREQUAL "STM32H735xx")
    list(APPEND BF_DEVICE_FLAGS -DSTM32H735xx -DMAX_MPU_REGIONS=16)
    set(BF_STARTUP_SRCS "${_STM32_DIR}/startup/startup_stm32h735xx.s")
    if(BF_EXST)
        set(BF_MCU_FLASH_SIZE 1024)
        list(APPEND BF_DEVICE_FLAGS -DFIRMWARE_SIZE=1024)
        set(_DEFAULT_LD_SCRIPT "${_STM32_DIR}/link/stm32_ram_h735_exst.ld")
        set(BF_LD_SCRIPTS
            "${_STM32_DIR}/link/stm32_h735_common.ld"
            "${_STM32_DIR}/link/stm32_h735_common_post.ld"
        )
    else()
        set(BF_MCU_FLASH_SIZE 1024)
        set(_DEFAULT_LD_SCRIPT "${_STM32_DIR}/link/stm32_flash_h735_1m.ld")
    endif()

elseif(BF_TARGET_MCU STREQUAL "STM32H750xx")
    list(APPEND BF_DEVICE_FLAGS -DSTM32H750xx)
    set(BF_STARTUP_SRCS "${_STM32_DIR}/startup/startup_stm32h743xx.s")
    if(BF_EXST)
        list(APPEND BF_DEVICE_FLAGS -DMAX_MPU_REGIONS=8)
        set(BF_MCU_FLASH_SIZE 448)
        list(APPEND BF_DEVICE_FLAGS -DFIRMWARE_SIZE=448)
        set(_DEFAULT_LD_SCRIPT "${_STM32_DIR}/link/stm32_ram_h750_exst.ld")
        # All optimisations go to -Os for EXST H750
        set(BF_OPTIMISE_DEFAULT "-Os")
        set(BF_OPTIMISE_SPEED   "-Os")
        set(BF_OPTIMISE_SIZE    "-Os")
    else()
        list(APPEND BF_DEVICE_FLAGS -DMAX_MPU_REGIONS=16)
        set(BF_MCU_FLASH_SIZE 128)
        set(_DEFAULT_LD_SCRIPT "${_STM32_DIR}/link/stm32_flash_h750_128k.ld")
        set(BF_OPTIMISE_DEFAULT "-Os")
        set(BF_OPTIMISE_SPEED   "-Os")
        set(BF_OPTIMISE_SIZE    "-Os")
    endif()

else()
    message(FATAL_ERROR "Unknown STM32H7 MCU: ${BF_TARGET_MCU}")
endif()

# Use default linker script if not overridden
if(NOT DEFINED BF_LD_SCRIPT OR BF_LD_SCRIPT STREQUAL "")
    set(BF_LD_SCRIPT "${_DEFAULT_LD_SCRIPT}")
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
    "${_STM32_DIR}/vcp_hal"
    "${BF_PLATFORM_DIR}/common/stm32"
    "${_STDPERIPH_DIR}/Inc"
    "${BF_LIB_DIR}/${_USBCORE_DIR}/Inc"
    "${BF_LIB_DIR}/${_USBCDC_DIR}/Inc"
    "${BF_LIB_DIR}/${_USBHID_DIR}/Inc"
    "${BF_LIB_DIR}/${_USBMSC_DIR}/Inc"
    "${_CMSIS_DIR}/Core/Include"
    "${_LIB_H7_DIR}/CMSIS/Device/ST/STM32H7xx/Include"
)

# ---- DSP library ----
set(BF_DSP_LIB_DIR "${_CMSIS_DIR}/DSP")

# ---- MCU common sources ----
set(BF_MCU_SRCS
    "${BF_SRC_DIR}/drivers/bus_i2c_timing.c"
    "${BF_SRC_DIR}/drivers/bus_quadspi.c"
    "${BF_SRC_DIR}/drivers/dshot_bitbang_decode.c"
    "${_STM32_DIR}/adc_stm32h7xx.c"
    "${_STM32_DIR}/audio_stm32h7xx.c"
    "${_STM32_DIR}/bus_i2c_hal_init.c"
    "${_STM32_DIR}/bus_i2c_hal.c"
    "${_STM32_DIR}/bus_spi_ll.c"
    "${_STM32_DIR}/bus_quadspi_hal.c"
    "${_STM32_DIR}/bus_octospi_stm32h7xx.c"
    "${_STM32_DIR}/debug.c"
    "${_STM32_DIR}/dma_reqmap_mcu.c"
    "${_STM32_DIR}/dma_stm32h7xx.c"
    "${_STM32_DIR}/dshot_bitbang_ll.c"
    "${_STM32_DIR}/dshot_bitbang.c"
    "${_STM32_DIR}/exti.c"
    "${_STM32_DIR}/io_stm32.c"
    "${_STM32_DIR}/light_ws2811strip_hal.c"
    "${_STM32_DIR}/memprot_hal.c"
    "${_STM32_DIR}/memprot_stm32h7xx.c"
    "${_STM32_DIR}/persistent.c"
    "${_STM32_DIR}/pwm_output_dshot_hal.c"
    "${_STM32_DIR}/rcc_stm32.c"
    "${_STM32_DIR}/sdio_h7xx.c"
    "${_STM32_DIR}/serial_uart_hal.c"
    "${_STM32_DIR}/serial_uart_stm32h7xx.c"
    "${_STM32_DIR}/system_stm32h7xx.c"
    "${_STM32_DIR}/timer_hal.c"
    "${_STM32_DIR}/timer_stm32h7xx.c"
    "${_STM32_DIR}/transponder_ir_io_hal.c"
    "${_STM32_DIR}/camera_control_stm32.c"
    "${BF_SRC_DIR}/drivers/adc.c"
    "${BF_SRC_DIR}/drivers/serial_escserial.c"
    "${_STM32_DIR}/startup/system_stm32h7xx.c"
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
    "${_STM32_DIR}/vcp_hal/usbd_conf_stm32h7xx.c"
    "${_STM32_DIR}/vcp_hal/usbd_cdc_hid.c"
    "${_STM32_DIR}/vcp_hal/usbd_cdc_interface.c"
    "${_STM32_DIR}/serial_usb_vcp.c"
    "${BF_SRC_DIR}/drivers/usb_io.c"
)

# ---- MSC sources ----
set(BF_MSC_SRCS
    "${_STM32_DIR}/usb_msc_hal.c"
    "${BF_SRC_DIR}/drivers/usb_msc_common.c"
    "${BF_SRC_DIR}/msc/usbd_storage.c"
    "${BF_SRC_DIR}/msc/usbd_storage_emfat.c"
    "${BF_SRC_DIR}/msc/emfat.c"
    "${BF_SRC_DIR}/msc/emfat_file.c"
    "${BF_SRC_DIR}/msc/usbd_storage_sd_spi.c"
    "${BF_SRC_DIR}/msc/usbd_storage_sdio.c"
)

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
