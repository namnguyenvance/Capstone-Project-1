`timescale 1 ns / 1 ps

`define TIME_TO_REPEAT 1

module al_accel_COMPS_ctrl_tb;
    // Param
    localparam 
        CONV    = 4'd 0,
        DENSE   = 4'd 1,
        POOL    = 4'd 2;

    // Ctrl Signal Setting
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
        enb = 1'b0;
        #52
        enb = 1'b1;
    end 

    // Input Signal Setting
    reg  [ 2:0] pu_matrix_rdy;

    reg         RDATA_fin, RDATA_rdy, RDATA_out_is_fin;
    reg  [31:0] RDATA_o_addr;
    initial begin
        #52
        pu_matrix_rdy = 0;
        RDATA_fin = 0; RDATA_rdy = 0; RDATA_out_is_fin = 0;
        RDATA_o_addr = 0;

        #20 
        RDATA_o_addr = 1000;

        #40
        RDATA_rdy = 1;
        #10
        RDATA_rdy = 0;

        #80 
        pu_matrix_rdy = ~0;

        #40
        RDATA_rdy = 1;
        #10
        RDATA_rdy = 0;

        #80 
        pu_matrix_rdy = ~0;

        #40
        RDATA_fin = 1;
    end

    al_accel_COMPS_ctrl uut (
        .cfg_layer_typ  (CONV),

        .pu_matrix_rdy  (pu_matrix_rdy),

        .RDATA_fin          (RDATA_fin),
        .RDATA_rdy          (RDATA_rdy),
        .RDATA_out_is_fin   (RDATA_out_is_fin),
        .RDATA_o_addr       (RDATA_o_addr),

        .enb    (enb),
        .clk    (clk),
        .resetn (resetn)
    );

    // Debug Info
    initial begin
        $dumpfile("out_log/al_accel_COMPS_ctrl_tb.vcd");
        $dumpvars(0, al_accel_COMPS_ctrl_tb);

        repeat (`TIME_TO_REPEAT) begin
			repeat (1000) @(posedge clk);
		end
		$finish;
    end
endmodule

// Maybe the COMPS_rdy may cause some undefined bugs, you should take note about this one.