`timescale 1 ns / 1 ps

`define TIME_TO_REPEAT 1

module al_accel_elw_unit_tb;
    // Ctrl Signal Setting
    localparam 
        RELU    = 3'd0,
        RELU6   = 3'd1,
        SIGMOID = 3'd2,
        TANH    = 3'd3;

    reg clk;
	always #5 clk = (clk === 1'b0); 

    reg resetn;
    initial begin
        resetn = 1'b0;
        #52
        resetn = 1'b1;
    end

    reg enb;
    initial begin   
        quant_act_func_enb = 0; cp_enb = 1;
        #62
        quant_act_func_enb = 0; cp_enb = 0;
        #40
        quant_act_func_enb = 1; cp_enb = 1;
        #62
        quant_act_func_enb = 0; cp_enb = 0;
        #40
        quant_act_func_enb = 0; cp_enb = 1;
        #62
        quant_act_func_enb = 1; cp_enb = 0;
        #40
        quant_act_func_enb = 1; cp_enb = 1;
    end 
    

    // Input Signal Setting
    reg [31:0] elew_di_0;
    reg [ 7:0] elew_di_1;

    reg [31:0] elew_quant_muler;
    reg [ 4:0] elew_quant_rshift;
    reg [ 2:0] elew_act_func_typ;

    reg quant_act_func_enb;
    reg cp_clr, cp_enb;

    initial begin
        #42
        elew_di_0 = $random; elew_di_1 = $random; elew_quant_muler = 1073742347; elew_quant_rshift = 10;
        #10 
        elew_di_0 = $random; elew_di_1 = $random; elew_act_func_typ = RELU; cp_clr = 0;
    end

    al_accel_elw_unit uut (
        .elew_di_0 (elew_di_0),
        .elew_di_1 (elew_di_1),

        .elew_quant_muler   (elew_quant_muler),
        .elew_quant_rshift  (elew_quant_rshift),

        .elew_act_func_typ  (elew_act_func_typ),

        .quant_act_func_enb (quant_act_func_enb),

        .cp_clr (cp_clr),
        .cp_enb (cp_enb),

        .clk    (clk),
        .resetn (resetn)
    );

    // Debug Info
    initial begin
        $dumpfile("out_log/al_accel_elw_unit_tb.vcd");
        $dumpvars(0, al_accel_elw_unit_tb);

        repeat (`TIME_TO_REPEAT) begin
			repeat (1000) @(posedge clk);
		end
		$finish;
    end
endmodule