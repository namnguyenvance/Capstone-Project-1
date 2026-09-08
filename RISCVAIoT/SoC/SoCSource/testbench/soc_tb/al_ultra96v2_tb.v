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

`timescale 1 ns / 1 ps

`ifdef CL_TC0
	`define TIME_TO_REPEAT  22
`elsif CL_TC1
	`define TIME_TO_REPEAT  18
`elsif CL_TC2
	`define TIME_TO_REPEAT  24
`elsif CL_TC4
	`define TIME_TO_REPEAT  16	
`elsif CL_TC5
	`define TIME_TO_REPEAT  16
`elsif CL_TC6
	`define TIME_TO_REPEAT  15
`elsif FCL_TC0
	`define TIME_TO_REPEAT  10
`elsif PL_TC0
	`define TIME_TO_REPEAT   7
`elsif PL_TC1
	`define TIME_TO_REPEAT   7
`elsif PL_TC2
	`define TIME_TO_REPEAT   7
`else
	`define TIME_TO_REPEAT  20
`endif 

module al_ultra96v2_wrapper ();
	reg clk;
	always #5 clk = (clk === 1'b0); 

	localparam ser_half_period = 53;
	event ser_sample;

	initial begin
		$dumpfile("out_log/soc_log/al_ultra96v2_tb.vcd");
		$dumpvars(0, al_ultra96v2_wrapper);

		repeat (`TIME_TO_REPEAT) begin
			repeat (50000) @(posedge clk);
			// $display("+50000 cycles");
		end
		$display("\nTotal: %d x 50 000 Clock Cycles", `TIME_TO_REPEAT);
		$finish;
	end		
	

	integer cycle_cnt = 0;

	always @(posedge clk) begin
		cycle_cnt <= cycle_cnt + 1;
	end

	wire [1:0] leds;

	// wire ser_rx;
	reg ser_rx;
	wire ser_tx;

	always @(leds) begin
		#1 $display("%b", leds);
		// $fflush();
	end

	reg 		ifm_write_fin;
	reg  [31:0] ifm_data;
	wire [21:0]	ifm_waddr;
	wire 		ifm_write_rdy;

	al_ultra96v2 uut (
		.clk      (clk),
		.enb	  (1'd 1),

		.ifm_write_fin	(ifm_write_fin),
		.ifm_data		(ifm_data),
		.ifm_waddr		(ifm_waddr),
		.ifm_write_rdy	(ifm_write_rdy),

		.leds     (leds),

		.ins_mem_wenb	( 1'd 0),
		.ins_mem_waddr	(32'd 0),
		.ins_mem_wdata	(32'd 0),

		.ser_rx   (ser_rx),
		.ser_tx   (ser_tx)
	);

	/*****************/
	/* Write IMEM Part */
	localparam IMEM_SIZE 	= 32768;
	localparam BASE 		= 32'h 00100000;

	reg [1023:0] firmware_file;
	reg [ 7:0]	 tmp_mem [0:BASE + IMEM_SIZE * 4 - 1];
	reg [63:0] i;
	initial begin
		if (!$value$plusargs("firmware=%s", firmware_file))
			firmware_file = "firmware.hex";
		$readmemh(firmware_file, tmp_mem);

		for (i = 0; i < IMEM_SIZE; i = i + 1) begin
			uut.soc.imem.memory[i][ 7: 0] = tmp_mem[BASE + 4*i];
			uut.soc.imem.memory[i][15: 8] = tmp_mem[BASE + 4*i + 1];
			uut.soc.imem.memory[i][23:16] = tmp_mem[BASE + 4*i + 2];
			uut.soc.imem.memory[i][31:24] = tmp_mem[BASE + 4*i + 3];
		end

		// #100
		// for (i = 0; i < IMEM_SIZE; i = i + 1) begin
		// 	$display("Addr %h [%h]: %h %h %h %h | %h | %h", i, (i << 2),
		// 		$signed(uut.soc.imem.memory[i][ 7: 0]), 
		// 		$signed(uut.soc.imem.memory[i][15: 8]), 
		// 		$signed(uut.soc.imem.memory[i][23:16]), 
		// 		$signed(uut.soc.imem.memory[i][31:24]),
		// 		$signed(uut.soc.imem.memory[i]),
		// 		$signed(uut.soc.imem.memory[i])
		// 	); 
		// end
		// $display("*************");
	end
	/*****************/
	// IOMEM Part
	always begin
		ifm_write_fin = 0;
		@(posedge ifm_write_rdy);

		#100 ifm_data = $random;
		#10	 ifm_write_fin = 1;
		#140  ifm_write_fin = 0;
	end



	/*****************/
	/* Write UART Part */
	reg [7:0] buffer;

	always begin
		@(negedge ser_tx);

		repeat (ser_half_period) @(posedge clk);
		-> ser_sample; // start bit

		repeat (8) begin
			repeat (ser_half_period) @(posedge clk);
			repeat (ser_half_period) @(posedge clk);
			buffer = {ser_tx, buffer[7:1]};
			-> ser_sample; // data bit
		end

		repeat (ser_half_period) @(posedge clk);
		repeat (ser_half_period) @(posedge clk);
		-> ser_sample; // stop bit

		// if (buffer < 32 || buffer >= 127) begin
		// 	$display("Serial data: %d", buffer);
		// 	$write("%d", buffer);
		// 	$fflush();
		// end else begin
		// 	$display("Serial data: '%c'", buffer);
		// 	$write("%c", buffer);
		// 	$fflush();
		// end

		$write("%c", buffer);
		$fflush();
	end

	// ser_rx generating...
	localparam STR_LEN = 8;
	reg [8*STR_LEN - 1:0] str_buf;

	initial begin
		str_buf = "92345679";
		// $display("str_buf: %s", str_buf);
	end 

	reg [7:0] tmp;
	integer ctr = STR_LEN;

	initial begin	
		#1 ser_rx = 1'b1;
		
		repeat (50000 * 30) @(posedge clk); 
		repeat (STR_LEN) begin
			repeat (1000) @(posedge clk); 
			ser_rx = 1'b0; // start bit
			tmp = str_buf[8*ctr - 1 -: 8];
			// $display("tmp: %c", tmp);
			
			repeat (8) begin
				repeat (ser_half_period) @(posedge clk);
				repeat (ser_half_period) @(posedge clk);
				ser_rx = tmp[0];
				// $display("ser_rx: %b", ser_rx);
				tmp = {1'b0, tmp[7:1]}; // data bit
				// $display("tmp: %b", tmp);
			end 

			repeat (ser_half_period) @(posedge clk);
			repeat (ser_half_period) @(posedge clk);
			ser_rx = 1'b1; // end bit

			ctr = ctr - 1;
		end
	end
	/*****************/
endmodule
