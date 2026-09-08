`timescale 1 ns / 1 ps

`define TIME_TO_REPEAT 1

module al_accel_quant_unit_tb;
    // Ctrl Signal Setting
    reg clk;
	always #5 clk = (clk === 1'b0); 

    reg resetn;
    initial begin
        resetn = 1'b0;
        #48
        resetn = 1'b1;
    end

    reg enb;
    initial begin   
        // enb = 1'b0;
        // #111;
        // enb = 1'b1;
        // #30;
        // enb = 1'b0;
        // #20;
        enb = 1'b1;
        #58
        enb = 1'b0;
        #10
        enb = 1'b1;
    end 

    // Input Signal Setting
    reg  [31:0] quant_di;
    wire [ 7:0] quant_do;
    reg  [31:0] quant_muler;
    reg  [ 4:0] quant_rshift;
    initial begin
        #48
        quant_di = -32657; quant_muler = 1073742347; quant_rshift = 10;
        #40
        quant_di = 3452; 
    end

    al_accel_quant_unit uut (
        .quant_di     (quant_di),
        .quant_do     (quant_do),
        .quant_muler  (quant_muler),
        .quant_rshift (quant_rshift),

        .enb    (enb),
        .clk    (clk),
        .resetn (resetn)
    );

    // Debug Info
    initial begin
        $dumpfile("out_log/al_accel_quant_unit_tb.vcd");
        $dumpvars(0, al_accel_quant_unit_tb);

        repeat (`TIME_TO_REPEAT) begin
			repeat (1000) @(posedge clk);
		end
		$finish;
    end
endmodule