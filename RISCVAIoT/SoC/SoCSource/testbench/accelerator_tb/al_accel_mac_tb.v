`timescale 1 ns / 1 ps

`define TIME_TO_REPEAT 1

module al_accel_mac_tb;
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
    // reg lut_ld_wrn;
    // initial begin
    //     #50 
    //     lut_ld_wrn = 1'd1;
    //     #20
    //     lut_ld_wrn = 1'd0;
    //     #20
    //     lut_ld_wrn = 1'd1;
    //     #20
    //     lut_ld_wrn = 1'd0;
    // end

    al_accel_mac uut (
        .mac_wdi_0 (-8'd10),
        .mac_wdi_1 (8'd64),
        .mac_wdi_2 (-8'd128),
        .mac_idi_0 (32'd0),
        .mac_idi_1 (32'd10),
        .mac_idi_2 (-32'd20),
        .mac_idi_3 (-32'd10),
        .mac_idi_4 (32'd30),
        .mac_idi_5 (32'd40),
        .mac_idi_6 (32'd10),
        .mac_idi_7 (32'd20),

        .enb    (enb),
        .clk    (clk),
        .resetn (resetn)
    );

    // Debug Info
    initial begin
        $dumpfile("out_log/al_accel_mac_tb.vcd");
        $dumpvars(0, al_accel_mac_tb);

        repeat (`TIME_TO_REPEAT) begin
			repeat (1000) @(posedge clk);
		end
		$finish;
    end
endmodule