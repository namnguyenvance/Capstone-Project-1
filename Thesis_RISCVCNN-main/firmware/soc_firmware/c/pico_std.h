#ifndef AL_HELLO_WORLD_FW_H
#define AL_HELLO_WORLD_FW_H

#include <stdint.h>
#include <stdbool.h>

#if     defined(CL_TC0) ||\
        defined(CL_TC1) ||\
        defined(CL_TC2) ||\
        defined(CL_TC3) ||\
        defined(CL_TC4) ||\
        defined(CL_TC5) ||\
        defined(CL_TC6) || \
        defined(CL_TC7)
    #define CL_TEST
#elif   defined(FCL_TC0) ||\
        defined(FCL_TC1) ||\
        defined(FCL_TC2) ||\
        defined(FCL_TC3) ||\
        defined(FCL_TC4) ||\
        defined(FCL_TC5) ||\
        defined(FCL_TC6)
    #define FCL_TEST
#elif   defined(PL_TC0) ||\
        defined(PL_TC1) ||\
        defined(PL_TC2) ||\
        defined(PL_TC3) ||\
        defined(PL_TC4) ||\
        defined(PL_TC5) ||\
        defined(PL_TC6) 
    #define PL_TEST

#elif   defined(ML_TC0) ||\
        defined(ML_TC1) ||\
        defined(ML_TC2) ||\
        defined(ML_TC3) ||\
        defined(ML_TC4) ||\
        defined(ML_TC5) ||\
        defined(ML_TC6) 
    #define ML_TEST
#endif

#if defined(CL_TEST) || defined (FCL_TEST) || defined(PL_TEST) || defined(ML_TEST)
    #define LAYER_TEST
#endif

#include "dl_ops.h"
#include "pico_io.h"
#include "dl_quantize.h"
#include "fw_layer_test.h"
#include "fw_model_test.h"
#include "fw_utils.h"
#include "al_accel_cfg.h"

#ifdef ICEBREAKER
#  define MEM_TOTAL 0x20000 /* 128 KB */
#elif HX8KDEMO
#  define MEM_TOTAL 0x200   /* 2 KB */
#elif ULTRA96V2
#  define MEM_TOTAL 0x40000 /* 8 KB */
#else
#  error "Set -DICEBREAKER or -DHX8KDEMO or -DULTRA96V2 when compiling firmware.c"
#endif

#define reg_spictrl 	(*(volatile uint32_t*)0x02000000)
#define reg_uart_clkdiv (*(volatile uint32_t*)0x02000004)
#define reg_uart_data 	(*(volatile uint32_t*)0x02000008)
#define reg_leds 		(*(volatile uint32_t*)0x03000000)
#define picosoc_enb_reg (*(volatile uint32_t*)0x03000004)
#define reg_ifm_addr    (                     0x04000000)

#endif