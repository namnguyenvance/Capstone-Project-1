/*
 *  PicoSoC - A simple example SoC using PicoRV32
 *
 *  Copyright (C) 2017  Claire Xenia Wolf <claire@yosyshq.com>
 *
 *  Permission to use, copy, modify, and/or distribute this software for any
 *  purpose with or without fee is hereby granted, provided that the above
 *  copyright notice and this permission notice appear in all copies.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 *  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 *  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 *  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 *  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 *  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 *  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 */

`ifndef PICORV32_REGS
`ifdef PICORV32_V
//`error "picosoc.v must be read before picorv32.v!"
`endif

`define PICORV32_REGS picosoc_regs
`endif

// this macro can be used to check if the verilog files in your
// design are read in the correct order.
`define PICOSOC_V

module picosoc (
	input clk,
	input resetn,

	output        iomem_valid,
	input         iomem_ready,
	output [ 3:0] iomem_wstrb,
	output [31:0] iomem_addr,
	output [31:0] iomem_wdata,
	input  [31:0] iomem_rdata,

	input  irq_5,
	input  irq_6,
	input  irq_7,

	output ser_tx,
	input  ser_rx
);
	/* Parameter Defination */
	parameter [0:0] BARREL_SHIFTER = 1;
	parameter [0:0] ENABLE_MUL = 1;
	parameter [0:0] ENABLE_DIV = 1;
	parameter [0:0] ENABLE_FAST_MUL = 1;
	parameter [0:0] ENABLE_COMPRESSED = 1;
	parameter [0:0] ENABLE_COUNTERS = 1;
	parameter [0:0] ENABLE_IRQ_QREGS = 0;

	parameter integer MEM_WORDS = 4096;
	// parameter integer MEM_WORDS = 2048;
	parameter [63:0] IMEM_SIZE = 32768; 

	parameter [31:0] STACKADDR 		= 4*MEM_WORDS; 	  // end of memory
	parameter [31:0] PROGADDR_RESET = 32'h 0010_0000; // 1 MB into flash
	parameter [31:0] PROGADDR_IRQ 	= 32'h 0000_0000;

	parameter integer DMEM_DELAY = 5;
	parameter integer IMEM_DELAY = 1;
	integer i;

	/* Interrupt Declearation and Assignment */
	reg [31:0] irq;
	wire irq_stall = 0;
	wire irq_uart = 0;

	always @* begin
		irq = 0;
		irq[3] = irq_stall;
		irq[4] = irq_uart;
		irq[5] = irq_5;
		irq[6] = irq_6;
		irq[7] = irq_7;
	end

	/* Signal Declearation */
	wire mem_valid;
	wire mem_instr;
	wire mem_ready;
	wire [31:0] mem_addr;
	wire [31:0] mem_wdata;
	wire  [3:0] mem_wstrb;
	wire [31:0] mem_rdata;

	// assign iomem_valid = mem_valid && (mem_addr[31:24] > 8'h 01);
	assign iomem_valid 	= mem_valid && (mem_addr[31:24] > 8'h 02);
	assign iomem_wstrb 	= mem_wstrb;
	assign iomem_addr 	= mem_addr;
	assign iomem_wdata 	= mem_wdata;

	wire        simpleuart_reg_div_sel = mem_valid && (mem_addr == 32'h 0200_0004);
	wire [31:0] simpleuart_reg_div_do;

	wire        simpleuart_reg_dat_sel = mem_valid && (mem_addr == 32'h 0200_0008);
	wire [31:0] simpleuart_reg_dat_do;
	wire        simpleuart_reg_dat_wait;

	reg [IMEM_DELAY - 1:0] imem_ready;
	wire [31:0] imem_rdata;

	reg [DMEM_DELAY - 1:0] cpu_ram_ready;
	wire [31:0] ram_rdata;

	wire 			cpu_renb , cpu_wenb;
	wire [17:0] 	cpu_raddr, cpu_waddr;

	assign cpu_renb = mem_valid &&  mem_addr < 4*MEM_WORDS;
	assign cpu_wenb = mem_valid && !mem_ready && mem_addr < 4*MEM_WORDS && mem_wstrb != 4'b 0;
	assign cpu_raddr = mem_addr[19:2];
	assign cpu_waddr = mem_addr[19:2];



	assign mem_ready = (iomem_valid && iomem_ready) 
					|| imem_ready[IMEM_DELAY - 1]    & imem_ready[0]
					|| cpu_ram_ready[DMEM_DELAY - 1] & cpu_ram_ready[0] 
					|| simpleuart_reg_div_sel 
					|| (simpleuart_reg_dat_sel && !simpleuart_reg_dat_wait);

	assign mem_rdata = (iomem_valid && iomem_ready) 	? iomem_rdata 			: 
						imem_ready[IMEM_DELAY - 1]    & imem_ready[0] 	 ? imem_rdata :
						cpu_ram_ready[DMEM_DELAY - 1] & cpu_ram_ready[0] ? ram_rdata  : 
						simpleuart_reg_div_sel 			? simpleuart_reg_div_do :
						simpleuart_reg_dat_sel 			? simpleuart_reg_dat_do : 
						32'h 0000_0000;
	picorv32 #(
		.STACKADDR(STACKADDR),
		.PROGADDR_RESET(PROGADDR_RESET),
		.PROGADDR_IRQ(PROGADDR_IRQ),
		.BARREL_SHIFTER(BARREL_SHIFTER),
		.COMPRESSED_ISA(ENABLE_COMPRESSED),
		.ENABLE_COUNTERS(ENABLE_COUNTERS),
		.ENABLE_MUL(ENABLE_MUL),
		.ENABLE_DIV(ENABLE_DIV),
		.ENABLE_FAST_MUL(ENABLE_FAST_MUL),
		.ENABLE_IRQ(1),
		.ENABLE_IRQ_QREGS(ENABLE_IRQ_QREGS)
	) cpu (
		.clk         (clk        ),
		.resetn      (resetn     ),
		.mem_valid   (mem_valid  ),
		.mem_instr   (mem_instr  ),
		.mem_ready   (mem_ready  ),
		.mem_addr    (mem_addr   ),
		.mem_wdata   (mem_wdata  ),
		.mem_wstrb   (mem_wstrb  ),
		.mem_rdata   (mem_rdata  ),
		.irq         (irq        )
	);

	always @(posedge clk) begin
		// imem_ready <= mem_valid && !mem_ready && mem_addr >= 4*MEM_WORDS && mem_addr < 32'h 0200_0000;
		imem_ready[0] <= mem_valid && !mem_ready && mem_addr >= 4*MEM_WORDS && mem_addr < 32'h 0200_0000;
		if (IMEM_DELAY > 1) begin
			for (i = 1; i < IMEM_DELAY; i = i + 1) begin
				imem_ready[i] <= imem_ready[i - 1];
			end
		end
	end

	picosoc_imem #(
		.IMEM_SIZE(IMEM_SIZE)
	) imem (
		.renb 	(mem_valid && mem_addr >= 4*MEM_WORDS && mem_addr < 32'h 0200_0000),
		.raddr 	(mem_addr[19:2]),
		.rdata 	(imem_rdata),
		.clk	(clk)
	);

	simpleuart simpleuart (
		.clk         (clk         ),
		.resetn      (resetn      ),

		.ser_tx      (ser_tx      ),
		.ser_rx      (ser_rx      ),

		.reg_div_we  (simpleuart_reg_div_sel ? mem_wstrb : 4'b 0000),
		.reg_div_di  (mem_wdata),
		.reg_div_do  (simpleuart_reg_div_do),

		.reg_dat_we  (simpleuart_reg_dat_sel ? mem_wstrb[0] : 1'b 0),
		.reg_dat_re  (simpleuart_reg_dat_sel && !mem_wstrb),
		.reg_dat_di  (mem_wdata),
		.reg_dat_do  (simpleuart_reg_dat_do),
		.reg_dat_wait(simpleuart_reg_dat_wait)
	);

	always @(posedge clk) begin
		// cpu_ram_ready <= mem_valid && !mem_ready && mem_addr < 4*MEM_WORDS;
		cpu_ram_ready[0] <= mem_valid && !mem_ready && mem_addr < 4*MEM_WORDS;
		if (DMEM_DELAY > 1) begin
			for (i = 1; i < DMEM_DELAY; i = i + 1) begin
				cpu_ram_ready[i] <= cpu_ram_ready[i - 1];
			end
		end
	end

	picosoc_dmem #(
		.WORDS(MEM_WORDS)
	) memory (
		.renb 	(cpu_renb),
		.raddr 	(cpu_raddr),
		.rdata	(ram_rdata),

		.wenb	(cpu_wenb),
		.wstrb  (mem_wstrb),
		.waddr	(cpu_waddr),
		.wdata 	(mem_wdata),

		.clk(clk)
	);
endmodule

// Implementation note:
// Replace the following two modules with wrappers for your SRAM cells.

module picosoc_regs (
	input clk, wen,
	input [5:0] waddr,
	input [5:0] raddr1,
	input [5:0] raddr2,
	input [31:0] wdata,
	output [31:0] rdata1,
	output [31:0] rdata2
);
	reg [31:0] regs [0:31];

	always @(posedge clk)
		if (wen) regs[waddr[4:0]] <= wdata;

	assign rdata1 = regs[raddr1[4:0]];
	assign rdata2 = regs[raddr2[4:0]];
endmodule


module picosoc_dmem #(
	parameter integer WORDS = 256
) (
    input              renb,
    input       [17:0] raddr,
    output reg  [31:0] rdata,

    input              wenb,
	input       [ 3:0] wstrb,
	input       [17:0] waddr,
	input       [31:0] wdata,
	
    input clk
);
	reg [31:0] mem [WORDS - 1:0];

	always @(posedge clk) begin
        if (renb)
            rdata <= mem[raddr];
        
        if (wenb) begin
            if (wstrb[0]) mem[waddr][ 7: 0] <= wdata[ 7: 0];
            if (wstrb[1]) mem[waddr][15: 8] <= wdata[15: 8];
            if (wstrb[2]) mem[waddr][23:16] <= wdata[23:16];
            if (wstrb[3]) mem[waddr][31:24] <= wdata[31:24];
        end
	end
endmodule

module picosoc_imem #(
	parameter [63:0] IMEM_SIZE = 32768
) (
    input              renb,
    input       [17:0] raddr,
    output reg  [31:0] rdata,

    input clk
);
	always @(posedge clk) begin
        // if (renb)
        rdata <= memory[raddr];
	end

	reg [31:0]   memory [0:IMEM_SIZE - 1];

	// Simulation Part
	localparam BASE = 32'h 00100000;
	reg [1023:0] firmware_file;
	reg [ 7:0]	 tmp [0:BASE + IMEM_SIZE * 4 - 1];
	reg [63:0] i;
	initial begin
		if (!$value$plusargs("firmware=%s", firmware_file))
			firmware_file = "firmware.hex";
		$readmemh(firmware_file, tmp);

		for (i = 0; i < IMEM_SIZE; i = i + 1) begin
			memory[i][ 7: 0] = tmp[BASE + 4*i];
			memory[i][15: 8] = tmp[BASE + 4*i + 1];
			memory[i][23:16] = tmp[BASE + 4*i + 2];
			memory[i][31:24] = tmp[BASE + 4*i + 3];
		end

		// #100
		// for (i = 0; i < IMEM_SIZE; i = i + 1) begin
		// 	$display("Addr %h [%h]: %h %h %h %h | %h | %h", i, (i << 2),
		// 		$signed(memory[i][ 7: 0]), 
		// 		$signed(memory[i][15: 8]), 
		// 		$signed(memory[i][23:16]), 
		// 		$signed(memory[i][31:24]),
		// 		$signed(memory[i]),
		// 		$signed(memory[i])
		// 	); 
		// end
		// $display("*************");
	end

endmodule
