`timescale 1 ns / 1 ps

`define TIME_TO_REPEAT 1

module al_accel_pu_array_tb;
    // Local Parameter Define
    localparam 
        NON   = 2'b00,
        LEFT  = 2'b01,
        RIGHT = 2'b10,
        DOWN  = 2'b11; 

    integer i_0, i_1, i_2;

    // Ctrl Signal Setting
    reg clk;
	always #5 clk = (clk === 1'b0); 

    reg resetn;
    initial begin
        resetn = 1'b0;
        #52
        resetn = 1'b1;
    end

    // Enable Sigs Sim
    reg         wreg_enb    [2:0][2:0];
    reg         ireg_enb    [2:0];
    reg         pu_enb      [2:0];

    initial begin
        #52
        for (i_0 = 0; i_0 < 3; i_0 = i_0 + 1) 
            for (i_1 = 0; i_1 < 3; i_1 = i_1 + 1)
                wreg_enb[i_0][i_1] = 1'b 0;
        for (i_0 = 0; i_0 < 3; i_0 = i_0 + 1) begin
            ireg_enb[i_0]   = 1'b 0;
            pu_enb[i_0]     = 1'b 0;
        end

        #10
        for (i_0 = 0; i_0 < 3; i_0 = i_0 + 1) 
            for (i_1 = 0; i_1 < 3; i_1 = i_1 + 1)
                wreg_enb[i_0][i_1] = 1'b 1;
        for (i_0 = 0; i_0 < 3; i_0 = i_0 + 1) begin
            ireg_enb[i_0]   = 1'b 0;
            pu_enb[i_0]     = 1'b 0;
        end
        
        #10
        for (i_0 = 0; i_0 < 3; i_0 = i_0 + 1) 
            for (i_1 = 0; i_1 < 3; i_1 = i_1 + 1)
                wreg_enb[i_0][i_1] = 1'b 0;
        for (i_0 = 0; i_0 < 3; i_0 = i_0 + 1) begin
            ireg_enb[i_0]   = 1'b 1;
            pu_enb[i_0]     = 1'b 0;
        end

        #10
        for (i_0 = 0; i_0 < 3; i_0 = i_0 + 1) 
            for (i_1 = 0; i_1 < 3; i_1 = i_1 + 1)
                wreg_enb[i_0][i_1] = 1'b 0;
        for (i_0 = 0; i_0 < 3; i_0 = i_0 + 1) begin
            ireg_enb[i_0]   = 1'b 0;
            pu_enb[i_0]     = 1'b 1;
        end

        #90
        for (i_0 = 0; i_0 < 3; i_0 = i_0 + 1) 
            for (i_1 = 0; i_1 < 3; i_1 = i_1 + 1)
                wreg_enb[i_0][i_1] = 1'b 0;
        for (i_0 = 0; i_0 < 3; i_0 = i_0 + 1) begin
            ireg_enb[i_0]   = 1'b 1;
            pu_enb[i_0]     = 1'b 0;
        end

        #10
        for (i_0 = 0; i_0 < 3; i_0 = i_0 + 1) 
            for (i_1 = 0; i_1 < 3; i_1 = i_1 + 1)
                wreg_enb[i_0][i_1] = 1'b 0;
        for (i_0 = 0; i_0 < 3; i_0 = i_0 + 1) begin
            ireg_enb[i_0]   = 1'b 0;
            pu_enb[i_0]     = 1'b 1;
        end

        #90
        for (i_0 = 0; i_0 < 3; i_0 = i_0 + 1) 
            for (i_1 = 0; i_1 < 3; i_1 = i_1 + 1)
                wreg_enb[i_0][i_1] = 1'b 0;
        for (i_0 = 0; i_0 < 3; i_0 = i_0 + 1) begin
            ireg_enb[i_0]   = 1'b 1;
            pu_enb[i_0]     = 1'b 0;
        end

        #10
        for (i_0 = 0; i_0 < 3; i_0 = i_0 + 1) 
            for (i_1 = 0; i_1 < 3; i_1 = i_1 + 1)
                wreg_enb[i_0][i_1] = 1'b 0;
        for (i_0 = 0; i_0 < 3; i_0 = i_0 + 1) begin
            ireg_enb[i_0]   = 1'b 0;
            pu_enb[i_0]     = 1'b 1;
        end

        #90
        for (i_0 = 0; i_0 < 3; i_0 = i_0 + 1) 
            for (i_1 = 0; i_1 < 3; i_1 = i_1 + 1)
                wreg_enb[i_0][i_1] = 1'b 0;
        for (i_0 = 0; i_0 < 3; i_0 = i_0 + 1) begin
            ireg_enb[i_0]   = 1'b 1;
            pu_enb[i_0]     = 1'b 0;
        end

        #10
        for (i_0 = 0; i_0 < 3; i_0 = i_0 + 1) 
            for (i_1 = 0; i_1 < 3; i_1 = i_1 + 1)
                wreg_enb[i_0][i_1] = 1'b 0;
        for (i_0 = 0; i_0 < 3; i_0 = i_0 + 1) begin
            ireg_enb[i_0]   = 1'b 0;
            pu_enb[i_0]     = 1'b 1;
        end

        #90
        for (i_0 = 0; i_0 < 3; i_0 = i_0 + 1) 
            for (i_1 = 0; i_1 < 3; i_1 = i_1 + 1)
                wreg_enb[i_0][i_1] = 1'b 0;
        for (i_0 = 0; i_0 < 3; i_0 = i_0 + 1) begin
            ireg_enb[i_0]   = 1'b 1;
            pu_enb[i_0]     = 1'b 0;
        end

        #10
        for (i_0 = 0; i_0 < 3; i_0 = i_0 + 1) 
            for (i_1 = 0; i_1 < 3; i_1 = i_1 + 1)
                wreg_enb[i_0][i_1] = 1'b 0;
        for (i_0 = 0; i_0 < 3; i_0 = i_0 + 1) begin
            ireg_enb[i_0]   = 1'b 0;
            pu_enb[i_0]     = 1'b 1;
        end

        #90
        for (i_0 = 0; i_0 < 3; i_0 = i_0 + 1) 
            for (i_1 = 0; i_1 < 3; i_1 = i_1 + 1)
                wreg_enb[i_0][i_1] = 1'b 0;
        for (i_0 = 0; i_0 < 3; i_0 = i_0 + 1) begin
            ireg_enb[i_0]   = 1'b 1;
            pu_enb[i_0]     = 1'b 0;
        end

        #10
        for (i_0 = 0; i_0 < 3; i_0 = i_0 + 1) 
            for (i_1 = 0; i_1 < 3; i_1 = i_1 + 1)
                wreg_enb[i_0][i_1] = 1'b 0;
        for (i_0 = 0; i_0 < 3; i_0 = i_0 + 1) begin
            ireg_enb[i_0]   = 1'b 0;
            pu_enb[i_0]     = 1'b 1;
        end

        #90
        for (i_0 = 0; i_0 < 3; i_0 = i_0 + 1) 
            for (i_1 = 0; i_1 < 3; i_1 = i_1 + 1)
                wreg_enb[i_0][i_1] = 1'b 0;
        for (i_0 = 0; i_0 < 3; i_0 = i_0 + 1) begin
            ireg_enb[i_0]   = 1'b 1;
            pu_enb[i_0]     = 1'b 0;
        end

        #10
        for (i_0 = 0; i_0 < 3; i_0 = i_0 + 1) 
            for (i_1 = 0; i_1 < 3; i_1 = i_1 + 1)
                wreg_enb[i_0][i_1] = 1'b 0;
        for (i_0 = 0; i_0 < 3; i_0 = i_0 + 1) begin
            ireg_enb[i_0]   = 1'b 0;
            pu_enb[i_0]     = 1'b 1;
        end

        #90
        for (i_0 = 0; i_0 < 3; i_0 = i_0 + 1) 
            for (i_1 = 0; i_1 < 3; i_1 = i_1 + 1)
                wreg_enb[i_0][i_1] = 1'b 0;
        for (i_0 = 0; i_0 < 3; i_0 = i_0 + 1) begin
            ireg_enb[i_0]   = 1'b 0;
            pu_enb[i_0]     = 1'b 0;
        end
    end

    // Data Sigs Sim
    reg [ 7:0]  pu_arr_wdi  [2:0][2:0][2:0];
    reg [ 7:0]  pu_arr_idi  [2:0][2:0];
    reg [ 1:0]  pu_arr_conv_dir;

    initial begin
        #62 
        pu_arr_conv_dir = NON;
        for (i_0 = 0; i_0 < 3; i_0 = i_0 + 1) 
            for (i_1 = 0; i_1 < 3; i_1 = i_1 + 1) 
                for (i_2 = 0; i_2 < 3; i_2 = i_2 + 1) 
                    pu_arr_wdi[i_0][i_1][i_2] = $random;

        #10 
        for (i_0 = 0; i_0 < 3; i_0 = i_0 + 1) 
            for (i_1 = 0; i_1 < 3; i_1 = i_1 + 1) 
                pu_arr_idi[i_0][i_1] = $random;
        
        #90 #10
        pu_arr_conv_dir = LEFT;
        for (i_0 = 0; i_0 < 3; i_0 = i_0 + 1) 
            pu_arr_idi[0][i_0] = $random;

        #90 #10
        pu_arr_conv_dir = LEFT;
        for (i_0 = 0; i_0 < 3; i_0 = i_0 + 1) 
            pu_arr_idi[0][i_0] = $random;

        #90 #10
        pu_arr_conv_dir = DOWN;
        for (i_0 = 0; i_0 < 3; i_0 = i_0 + 1) 
            pu_arr_idi[0][i_0] = $random;

        #90 #10
        pu_arr_conv_dir = RIGHT;
        for (i_0 = 0; i_0 < 3; i_0 = i_0 + 1) 
            pu_arr_idi[0][i_0] = $random;

        #90 #10
        pu_arr_conv_dir = RIGHT;
        for (i_0 = 0; i_0 < 3; i_0 = i_0 + 1) 
            pu_arr_idi[0][i_0] = $random;
    end

    // Unit Under Test
    al_accel_pu_array uut (
        .pu_arr_wdi_0_0_0 (pu_arr_wdi[0][0][0]),
        .pu_arr_wdi_0_0_1 (pu_arr_wdi[0][0][1]),
        .pu_arr_wdi_0_0_2 (pu_arr_wdi[0][0][2]),
        .pu_arr_wdi_0_1_0 (pu_arr_wdi[0][1][0]),
        .pu_arr_wdi_0_1_1 (pu_arr_wdi[0][1][1]),
        .pu_arr_wdi_0_1_2 (pu_arr_wdi[0][1][2]),
        .pu_arr_wdi_0_2_0 (pu_arr_wdi[0][2][0]),
        .pu_arr_wdi_0_2_1 (pu_arr_wdi[0][2][1]),
        .pu_arr_wdi_0_2_2 (pu_arr_wdi[0][2][2]),
        .pu_arr_wdi_1_0_0 (pu_arr_wdi[1][0][0]),
        .pu_arr_wdi_1_0_1 (pu_arr_wdi[1][0][1]),
        .pu_arr_wdi_1_0_2 (pu_arr_wdi[1][0][2]),
        .pu_arr_wdi_1_1_0 (pu_arr_wdi[1][1][0]),
        .pu_arr_wdi_1_1_1 (pu_arr_wdi[1][1][1]),
        .pu_arr_wdi_1_1_2 (pu_arr_wdi[1][1][2]),
        .pu_arr_wdi_1_2_0 (pu_arr_wdi[1][2][0]),
        .pu_arr_wdi_1_2_1 (pu_arr_wdi[1][2][1]),
        .pu_arr_wdi_1_2_2 (pu_arr_wdi[1][2][2]),
        .pu_arr_wdi_2_0_0 (pu_arr_wdi[2][0][0]),
        .pu_arr_wdi_2_0_1 (pu_arr_wdi[2][0][1]),
        .pu_arr_wdi_2_0_2 (pu_arr_wdi[2][0][2]),
        .pu_arr_wdi_2_1_0 (pu_arr_wdi[2][1][0]),
        .pu_arr_wdi_2_1_1 (pu_arr_wdi[2][1][1]),
        .pu_arr_wdi_2_1_2 (pu_arr_wdi[2][1][2]),
        .pu_arr_wdi_2_2_0 (pu_arr_wdi[2][2][0]),
        .pu_arr_wdi_2_2_1 (pu_arr_wdi[2][2][1]),
        .pu_arr_wdi_2_2_2 (pu_arr_wdi[2][2][2]),

        .pu_arr_idi_0_0 (pu_arr_idi[0][0]),
        .pu_arr_idi_0_1 (pu_arr_idi[0][1]),
        .pu_arr_idi_0_2 (pu_arr_idi[0][2]),
        .pu_arr_idi_1_0 (pu_arr_idi[1][0]),
        .pu_arr_idi_1_1 (pu_arr_idi[1][1]),
        .pu_arr_idi_1_2 (pu_arr_idi[1][2]),
        .pu_arr_idi_2_0 (pu_arr_idi[2][0]),
        .pu_arr_idi_2_1 (pu_arr_idi[2][1]),
        .pu_arr_idi_2_2 (pu_arr_idi[2][2]),

        .pu_arr_is_conv_layer   (1'b 1),
        .pu_arr_conv_dir        (pu_arr_conv_dir),

        .wreg_enb_0_0   (wreg_enb[0][0]),
        .wreg_enb_0_1   (wreg_enb[0][1]),
        .wreg_enb_0_2   (wreg_enb[0][2]),
        .wreg_enb_1_0   (wreg_enb[1][0]),
        .wreg_enb_1_1   (wreg_enb[1][1]),
        .wreg_enb_1_2   (wreg_enb[1][2]),
        .wreg_enb_2_0   (wreg_enb[2][0]),
        .wreg_enb_2_1   (wreg_enb[2][1]),
        .wreg_enb_2_2   (wreg_enb[2][2]),

        .ireg_enb_0 (ireg_enb[0]),
        .ireg_enb_1 (ireg_enb[1]),
        .ireg_enb_2 (ireg_enb[2]),

        .pu_enb_0   (pu_enb[0]),
        .pu_enb_1   (pu_enb[1]),
        .pu_enb_2   (pu_enb[2]),

        .clk    (clk),
        .resetn (resetn)
    );

    // Debug Info
    initial begin
        $dumpfile("out_log/al_accel_pu_array_tb.vcd");
        $dumpvars(0, al_accel_pu_array_tb);

        repeat (`TIME_TO_REPEAT) begin
			repeat (1000) @(posedge clk);
		end
		$finish;
    end
endmodule