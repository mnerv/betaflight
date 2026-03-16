# cmake/apm32f4.cmake
#
# APM32F4 family configuration (Geehy DAL + DDL drivers).
# Expects BF_TARGET_MCU and BF_HSE_VALUE to be set before inclusion.

set(_APM32_DIR    "${BF_PLATFORM_DIR}/APM32")
set(_LIB_APM_DIR  "${BF_LIB_DIR}/APM32F4")
set(_CMSIS_DIR    "${BF_LIB_DIR}/CMSIS")

# ---- Architecture flags ----
set(BF_ARCH_FLAGS
    -mthumb
    -mcpu=cortex-m4
    -march=armv7e-m
    -mfloat-abi=hard
    -mfpu=fpv4-sp-d16
)

# ---- DAL/DDL driver sources ----
set(_STDPERIPH_DIR "${_LIB_APM_DIR}/Libraries/APM32F4xx_DAL_Driver")

set(_DAL_FILES
    apm32f4xx_dal_adc.c
    apm32f4xx_dal_adc_ex.c
    apm32f4xx_dal.c
    apm32f4xx_dal_can.c
    apm32f4xx_dal_comp.c
    apm32f4xx_dal_cortex.c
    apm32f4xx_dal_crc.c
    apm32f4xx_dal_cryp.c
    apm32f4xx_dal_cryp_ex.c
    apm32f4xx_dal_dac.c
    apm32f4xx_dal_dac_ex.c
    apm32f4xx_dal_dci.c
    apm32f4xx_dal_dci_ex.c
    apm32f4xx_dal_dma.c
    apm32f4xx_dal_dma_ex.c
    apm32f4xx_dal_eint.c
    apm32f4xx_dal_eth.c
    apm32f4xx_dal_flash.c
    apm32f4xx_dal_flash_ex.c
    apm32f4xx_dal_flash_ramfunc.c
    apm32f4xx_dal_gpio.c
    apm32f4xx_dal_hash.c
    apm32f4xx_dal_hash_ex.c
    apm32f4xx_dal_hcd.c
    apm32f4xx_dal_i2c.c
    apm32f4xx_dal_i2c_ex.c
    apm32f4xx_dal_i2s.c
    apm32f4xx_dal_i2s_ex.c
    apm32f4xx_dal_irda.c
    apm32f4xx_dal_iwdt.c
    apm32f4xx_dal_log.c
    apm32f4xx_dal_mmc.c
    apm32f4xx_dal_nand.c
    apm32f4xx_dal_nor.c
    apm32f4xx_dal_pccard.c
    apm32f4xx_dal_pcd.c
    apm32f4xx_dal_pcd_ex.c
    apm32f4xx_dal_pmu.c
    apm32f4xx_dal_pmu_ex.c
    apm32f4xx_dal_qspi.c
    apm32f4xx_dal_rcm.c
    apm32f4xx_dal_rcm_ex.c
    apm32f4xx_dal_rng.c
    apm32f4xx_dal_rtc.c
    apm32f4xx_dal_rtc_ex.c
    apm32f4xx_dal_sd.c
    apm32f4xx_dal_sdram.c
    apm32f4xx_dal_smartcard.c
    apm32f4xx_dal_smbus.c
    apm32f4xx_dal_spi.c
    apm32f4xx_dal_sram.c
    apm32f4xx_dal_tmr.c
    apm32f4xx_dal_tmr_ex.c
    apm32f4xx_dal_uart.c
    apm32f4xx_dal_usart.c
    apm32f4xx_dal_wwdt.c
    apm32f4xx_ddl_adc.c
    apm32f4xx_ddl_comp.c
    apm32f4xx_ddl_crc.c
    apm32f4xx_ddl_dac.c
    apm32f4xx_ddl_dma.c
    apm32f4xx_ddl_dmc.c
    apm32f4xx_ddl_eint.c
    apm32f4xx_ddl_gpio.c
    apm32f4xx_ddl_i2c.c
    apm32f4xx_ddl_pmu.c
    apm32f4xx_ddl_rcm.c
    apm32f4xx_ddl_rng.c
    apm32f4xx_ddl_rtc.c
    apm32f4xx_ddl_sdmmc.c
    apm32f4xx_ddl_smc.c
    apm32f4xx_ddl_spi.c
    apm32f4xx_ddl_tmr.c
    apm32f4xx_ddl_usart.c
    apm32f4xx_ddl_usb.c
    apm32f4xx_ddl_utils.c
)

set(_USB_CORE_DIR "${_LIB_APM_DIR}/Middlewares/APM32_USB_Library/Device/Core")
set(_USB_CDC_DIR  "${_LIB_APM_DIR}/Middlewares/APM32_USB_Library/Device/Class/CDC")
set(_USB_MSC_DIR  "${_LIB_APM_DIR}/Middlewares/APM32_USB_Library/Device/Class/MSC")

set(_USB_FILES
    "${_USB_CORE_DIR}/Src/usbd_core.c"
    "${_USB_CORE_DIR}/Src/usbd_dataXfer.c"
    "${_USB_CORE_DIR}/Src/usbd_stdReq.c"
    "${_USB_CDC_DIR}/Src/usbd_cdc.c"
    "${_USB_MSC_DIR}/Src/usbd_msc.c"
    "${_USB_MSC_DIR}/Src/usbd_msc_bot.c"
    "${_USB_MSC_DIR}/Src/usbd_msc_scsi.c"
)

set(_DAL_FULL "")
foreach(_f ${_DAL_FILES})
    list(APPEND _DAL_FULL "${_STDPERIPH_DIR}/Source/${_f}")
endforeach()

set(BF_DEVICE_LIB_SRCS ${_DAL_FULL} ${_USB_FILES})

# ---- Device flags ----
set(BF_DEVICE_FLAGS
    -DUSE_DAL_DRIVER
    -DUSE_FULL_DDL_DRIVER
    -DAPM32
    -DARM_MATH_MATRIX_CHECK
    -DARM_MATH_ROUNDING
    -DUNALIGNED_SUPPORT_DISABLE
    -DARM_MATH_CM4
)

# ---- MCU-specific settings ----
set(_STM32_LINK_DIR "${BF_PLATFORM_DIR}/STM32/link")

if(BF_TARGET_MCU STREQUAL "APM32F405xx")
    list(APPEND BF_DEVICE_FLAGS -DAPM32F405xx)
    set(BF_LD_SCRIPT      "${_APM32_DIR}/link/apm32_flash_f405.ld")
    set(BF_STARTUP_SRCS   "${_APM32_DIR}/startup/startup_apm32f405xx.S")
    set(BF_MCU_FLASH_SIZE 1024)
elseif(BF_TARGET_MCU STREQUAL "APM32F407xx")
    list(APPEND BF_DEVICE_FLAGS -DAPM32F407xx)
    set(BF_LD_SCRIPT      "${_APM32_DIR}/link/apm32_flash_f407.ld")
    set(BF_STARTUP_SRCS   "${_APM32_DIR}/startup/startup_apm32f407xx.S")
    set(BF_MCU_FLASH_SIZE 1024)
else()
    message(FATAL_ERROR "Unknown APM32F4 MCU: ${BF_TARGET_MCU}")
endif()

list(APPEND BF_DEVICE_FLAGS
    "-DHSE_VALUE=${BF_HSE_VALUE}"
    "-DHSE_STARTUP_TIMEOUT=1000"
)

# ---- Include directories ----
set(BF_PLATFORM_INCLUDE_DIRS
    "${_APM32_DIR}"
    "${_APM32_DIR}/include"
    "${_APM32_DIR}/startup"
    "${_APM32_DIR}/usb/vcp"
    "${_APM32_DIR}/usb/msc"
    "${_APM32_DIR}/usb"
    "${BF_PLATFORM_DIR}/common/stm32"
    "${_STDPERIPH_DIR}/Include"
    "${_USB_CORE_DIR}/Inc"
    "${_USB_CDC_DIR}/Inc"
    "${_USB_MSC_DIR}/Inc"
    "${_LIB_APM_DIR}/Libraries/Device/Geehy/APM32F4xx/Include"
    "${_CMSIS_DIR}/Core/Include"
    "${BF_SRC_DIR}/msc"
)

# ---- DSP library ----
set(BF_DSP_LIB_DIR "${_CMSIS_DIR}/DSP")

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
    "${BF_PLATFORM_DIR}/common/stm32/rx_pwm_hw.c"
    "${BF_PLATFORM_DIR}/common/stm32/ledstrip_ws2811_stm32.c"
    "${BF_PLATFORM_DIR}/common/stm32/debug_pin.c"
    "${BF_PLATFORM_DIR}/common/stm32/adc_impl.c"
    "${_APM32_DIR}/startup/system_apm32f4xx.c"
    "${_APM32_DIR}/system_apm32f4xx.c"
    "${_APM32_DIR}/bus_spi_apm32.c"
    "${_APM32_DIR}/bus_i2c_apm32.c"
    "${_APM32_DIR}/bus_i2c_apm32_init.c"
    "${_APM32_DIR}/camera_control_apm32.c"
    "${_APM32_DIR}/debug.c"
    "${_APM32_DIR}/dma_reqmap_mcu.c"
    "${_APM32_DIR}/dshot_bitbang.c"
    "${_APM32_DIR}/dshot_bitbang_ddl.c"
    "${_APM32_DIR}/eint_apm32.c"
    "${_APM32_DIR}/io_apm32.c"
    "${_APM32_DIR}/light_ws2811strip_apm32.c"
    "${_APM32_DIR}/persistent_apm32.c"
    "${_APM32_DIR}/pwm_output_apm32.c"
    "${_APM32_DIR}/pwm_output_dshot_apm32.c"
    "${_APM32_DIR}/rcm_apm32.c"
    "${_APM32_DIR}/serial_uart_apm32.c"
    "${_APM32_DIR}/timer_apm32.c"
    "${_APM32_DIR}/transponder_ir_io_apm32.c"
    "${_APM32_DIR}/timer_apm32f4xx.c"
    "${_APM32_DIR}/adc_apm32f4xx.c"
    "${_APM32_DIR}/dma_apm32f4xx.c"
    "${_APM32_DIR}/serial_uart_apm32f4xx.c"
    "${BF_SRC_DIR}/drivers/inverter.c"
    "${BF_SRC_DIR}/drivers/dshot_bitbang_decode.c"
    "${BF_SRC_DIR}/drivers/adc.c"
    "${BF_SRC_DIR}/drivers/bus_spi_config.c"
    "${BF_SRC_DIR}/drivers/serial_escserial.c"
    "${BF_SRC_DIR}/drivers/serial_pinconfig.c"
)

# ---- VCP sources ----
set(BF_VCP_SRCS
    "${_APM32_DIR}/usb/vcp/usbd_cdc_descriptor.c"
    "${_APM32_DIR}/usb/usbd_board_apm32f4.c"
    "${_APM32_DIR}/usb/vcp/usbd_cdc_vcp.c"
    "${_APM32_DIR}/usb/vcp/serial_usb_vcp.c"
    "${BF_SRC_DIR}/drivers/usb_io.c"
)

# ---- MSC sources ----
set(BF_MSC_SRCS
    "${BF_SRC_DIR}/drivers/usb_msc_common.c"
    "${_APM32_DIR}/usb/msc/usb_msc_apm32f4xx.c"
    "${_APM32_DIR}/usb/msc/usbd_memory.c"
    "${_APM32_DIR}/usb/msc/usbd_msc_descriptor.c"
    "${BF_SRC_DIR}/msc/usbd_storage.c"
    "${BF_SRC_DIR}/msc/usbd_storage_emfat.c"
    "${BF_SRC_DIR}/msc/emfat.c"
    "${BF_SRC_DIR}/msc/emfat_file.c"
    "${BF_SRC_DIR}/msc/usbd_storage_sd_spi.c"
    "${BF_SRC_DIR}/msc/usbd_storage_sdio.c"
)

# ---- Per-file optimization overrides ----
set(BF_SPEED_OPTIMISED_SRCS
    "${BF_PLATFORM_DIR}/common/stm32/dshot_bitbang_shared.c"
    "${BF_PLATFORM_DIR}/common/stm32/pwm_output_dshot_shared.c"
    "${BF_PLATFORM_DIR}/common/stm32/bus_spi_hw.c"
    "${BF_PLATFORM_DIR}/common/stm32/system.c"
)

set(BF_SIZE_OPTIMISED_SRCS
    "${_APM32_DIR}/usb/vcp/serial_usb_vcp.c"
    "${BF_SRC_DIR}/drivers/inverter.c"
    "${BF_SRC_DIR}/drivers/bus_spi_config.c"
    "${BF_PLATFORM_DIR}/common/stm32/bus_i2c_pinconfig.c"
    "${BF_PLATFORM_DIR}/common/stm32/bus_spi_pinconfig.c"
    "${BF_PLATFORM_DIR}/common/stm32/pwm_output_beeper.c"
    "${BF_PLATFORM_DIR}/common/stm32/serial_uart_pinconfig.c"
    "${BF_SRC_DIR}/drivers/serial_escserial.c"
    "${BF_SRC_DIR}/drivers/serial_pinconfig.c"
)
