#include <stdint.h>
#include <stdbool.h>
#include "pico_std.h"

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




int main() {
    reg_uart_clkdiv = 868;
    print("hello world\n");
	return 0;
}