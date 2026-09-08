`timescale 1 ns / 1 ps

`define TIME_TO_REPEAT 1

module al_accel_pu_tb;
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

    reg   [ 7:0]  pu_wdi_0_0;
    reg   [ 7:0]  pu_wdi_0_1;
    reg   [ 7:0]  pu_wdi_0_2;
    reg   [ 7:0]  pu_wdi_1_0;
    reg   [ 7:0]  pu_wdi_1_1;
    reg   [ 7:0]  pu_wdi_1_2;
    reg   [ 7:0]  pu_wdi_2_0;
    reg   [ 7:0]  pu_wdi_2_1;
    reg   [ 7:0]  pu_wdi_2_2;

    reg   [ 7:0]  pu_idi_0;
    reg   [ 7:0]  pu_idi_1;
    reg   [ 7:0]  pu_idi_2;
    initial begin   
        
        // Cycle 1: 
        pu_wdi_0_0 = -8'd10;
        pu_wdi_0_1 =  8'd64;
        pu_wdi_0_2 =  8'd85;
        pu_wdi_1_0 =  8'd13; 
        pu_wdi_1_1 = -8'd120;
        pu_wdi_1_2 = -8'd91;
        pu_wdi_2_0 =  8'd20;
        pu_wdi_2_1 =  8'd17; 
        pu_wdi_2_2 = -8'd100;
        
        pu_idi_0 =  8'd91;
        pu_idi_1 = -8'd19;
        pu_idi_2 =  8'd12;

        #145
        // Cycle 2: 
        pu_wdi_0_0 = -8'd 12;
        pu_wdi_0_1 =  8'd 12;
        pu_wdi_0_2 =  8'd 12;
        pu_wdi_1_0 =  8'd 12; 
        pu_wdi_1_1 = -8'd 12;
        pu_wdi_1_2 = -8'd 12;
        pu_wdi_2_0 =  8'd 12;
        pu_wdi_2_1 =  8'd 12; 
        pu_wdi_2_2 = -8'd 12;
        
        pu_idi_0 =  8'd   7;
        pu_idi_1 = -8'd 128;
        pu_idi_2 =  8'd  12;
    end 

    al_accel_pu uut (
        .pu_wdi_0_0 (pu_wdi_0_0),
        .pu_wdi_0_1 (pu_wdi_0_1),
        .pu_wdi_0_2 (pu_wdi_0_2),
        .pu_wdi_1_0 (pu_wdi_1_0),
        .pu_wdi_1_1 (pu_wdi_1_1),
        .pu_wdi_1_2 (pu_wdi_1_2),
        .pu_wdi_2_0 (pu_wdi_2_0),
        .pu_wdi_2_1 (pu_wdi_2_1),
        .pu_wdi_2_2 (pu_wdi_2_2),

        .pu_idi_0   (pu_idi_0),
        .pu_idi_1   (pu_idi_1),
        .pu_idi_2   (pu_idi_2),

        .enb    (enb),
        .clk    (clk),
        .resetn (resetn)
    );

    // Debug Info
    initial begin
        $dumpfile("out_log/al_accel_pu_tb.vcd");
        $dumpvars(0, al_accel_pu_tb);

        repeat (`TIME_TO_REPEAT) begin
			repeat (1000) @(posedge clk);
		end
		$finish;
    end
endmodule