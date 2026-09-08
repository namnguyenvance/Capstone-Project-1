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

`define TIME_TO_REPEAT  10000

module ultra96v2_wrapper ();
	reg clk;
	always #5 clk = (clk === 1'b0); 

	localparam integer SER_FULL_PERIOD = 868;   // số chu kỳ clock cho 1 bit
    localparam integer SER_HALF_PERIOD = 434;   // nửa bit
	event ser_sample;

	initial begin
		// $dumpfile("out_log/soc_log/ultra96v2_tb.vcd");
		// $dumpvars(0, ultra96v2_wrapper);

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


	ultra96v2 uut (
		.clk      (clk),
		.enb	  (1'd 1),

		.leds     (leds),

		// .ins_mem_wenb	( 1'd 0),
		// .ins_mem_waddr	(32'd 0),
		// .ins_mem_wdata	(32'd 0),

		.ser_rx   (ser_rx),
		.ser_tx   (ser_tx)
	);

	/*****************/
	/* Write IMEM Part */
	localparam IMEM_SIZE 	= 262144;
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


    /*****************/
    /* Write UART Part */
    reg [7:0] buffer;

    always begin
        @(negedge ser_tx);  // phát hiện start bit

        repeat (SER_HALF_PERIOD) @(posedge clk);
        -> ser_sample; // sample start bit

        repeat (8) begin
            repeat (SER_FULL_PERIOD) @(posedge clk);
            buffer = {ser_tx, buffer[7:1]};
            -> ser_sample; // sample data bit
        end

        repeat (SER_FULL_PERIOD) @(posedge clk);
        -> ser_sample; // sample stop bit

        $write("%c", buffer);
        $fflush();
    end

    // ser_rx generating...
    localparam STR_LEN = 8;
    reg [8*STR_LEN - 1:0] str_buf;

    initial begin
        str_buf = "92345679";
        ser_rx  = 1'b1; // idle = 1
    end 
endmodule
