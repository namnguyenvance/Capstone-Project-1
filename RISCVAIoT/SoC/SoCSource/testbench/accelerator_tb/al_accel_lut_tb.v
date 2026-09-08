`timescale 1 ns / 1 ps

`define TIME_TO_REPEAT 1

module al_accel_lut_tb;
    // Ctrl Signal Setting
    reg clk;
	always #5 clk = (clk === 1'b0); 

    reg resetn;
    initial begin
        resetn = 1'b0;
        #50 
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
    end 

    // Input Signal Setting
    reg lut_ld_wrn;
    initial begin
        #50 
        lut_ld_wrn = 1'd1;
        #20
        lut_ld_wrn = 1'd0;
        #20
        lut_ld_wrn = 1'd1;
        #20
        lut_ld_wrn = 1'd0;
    end

    al_accel_lut uut (
        .lut_idi_0  (-8'd10),
        .lut_idi_1  (8'd64),
        .lut_idi_2  (-8'd85),
        .lut_ld_wrn (lut_ld_wrn),

        .lut_wdi_sbit_0 (1'b0),
        .lut_wdi_sbit_1 (1'b0),
        .lut_wdi_sbit_2 (1'b0),

        .enb    (enb),
        .clk    (clk),
        .resetn (resetn)
    );

    // Debug Info
    initial begin
        $dumpfile("out_log/al_accel_lut_tb.vcd");
        $dumpvars(0, al_accel_lut_tb);

        repeat (`TIME_TO_REPEAT) begin
			repeat (1000) @(posedge clk);
		end
		$finish;
    end
endmodule