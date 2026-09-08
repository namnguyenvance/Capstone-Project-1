`timescale 1 ns / 1 ps

`define TIME_TO_REPEAT 1

module al_accel_act_func_unit_tb;
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
    reg  [7:0] act_func_di;
    wire [7:0] act_func_do;
    reg  [2:0] act_func_typ;

    localparam 
        RELU    = 3'd0,
        RELU6   = 3'd1,
        SIGMOID = 3'd2,
        TANH    = 3'd3;

    initial begin
        #48
        act_func_di = $random; act_func_typ = RELU;
        #10
        act_func_di = -$random; act_func_typ = RELU;
        #10
        act_func_di = $random; act_func_typ = RELU6;
        #10
        act_func_di = -$random; act_func_typ = RELU6;
        #10
        act_func_di = -$random; act_func_typ = RELU6;
        #10
        act_func_di = -$random; act_func_typ = RELU;
        #10
        act_func_di = -$random; act_func_typ = RELU6;
        #10
        act_func_di = $random; act_func_typ = RELU;
        #10
        act_func_di = $random; act_func_typ = RELU6;
        #10
        act_func_di = -$random; act_func_typ = RELU6;
    end

    al_accel_act_func_unit uut (
        .act_func_di  (act_func_di),
        .act_func_do  (act_func_do),

        .act_func_typ (act_func_typ)
    );

    // Debug Info
    initial begin
        $dumpfile("out_log/al_accel_act_func_unit_tb.vcd");
        $dumpvars(0, al_accel_act_func_unit_tb);

        repeat (`TIME_TO_REPEAT) begin
			repeat (1000) @(posedge clk);
		end
		$finish;
    end
endmodule