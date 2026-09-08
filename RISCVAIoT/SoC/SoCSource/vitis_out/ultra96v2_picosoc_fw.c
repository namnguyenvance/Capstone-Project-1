/******************************************************************************
*
* Copyright (C) 2009 - 2014 Xilinx, Inc.  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* Use of the Software is limited solely to applications:
* (a) running on a Xilinx device, or
* (b) that interact with a Xilinx device through a bus or interconnect.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
* XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
* OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
* Except as contained in this notice, the name of the Xilinx shall not be used
* in advertising or otherwise to promote the sale, use or other dealings in
* this Software without prior written authorization from Xilinx.
*
******************************************************************************/

/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xparameters.h"

#include "ultra96v2_fw_hex_data.h"


#define	BASE_ADDR	0x00100000

#define wenb_reg 		(*(volatile unsigned int*)0xa0000000)
#define waddr_reg 		(*(volatile unsigned int*)0xa0010000)
#define wdata_reg		(*(volatile unsigned int*)0xa0020000)
#define picosoc_enb_reg (*(volatile unsigned int*)0xa0030000)
#define ps_read_rdy_reg (*(volatile unsigned int*)0xa0040000)
#define ps_data_reg 	(*(volatile unsigned int*)0xa0050000)
#define ps_read_fin_reg (*(volatile unsigned int*)0xa0060000)

int main()
{
    init_platform();

    printf("Hello World\n\r");
    printf("Successfully ran Hello World application\n\r");


    // Write Data to Instruction Memory
    wenb_reg	= 1;
    for (int i = 0; i < fw_hex_data_len; i++) {
    	waddr_reg = BASE_ADDR + 4 * i;
    	wdata_reg = fw_hex_data[i];
    }
    wenb_reg	= 0;

    // Run Enable
    picosoc_enb_reg = 1;
    ps_read_fin_reg = 0;
    while (1) {
    	if (ps_read_rdy_reg) {
    		printf("%c", (char)ps_data_reg);

    		ps_read_fin_reg = 1;
    		ps_read_fin_reg = 0;
    	}
    }

    cleanup_platform();
    return 0;
}


