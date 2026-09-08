`timescale 1 ns / 1 ps

`define TIME_TO_REPEAT 1

module al_accel_pu_matrix_tb;
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

    // Ctrl Sigs Sim
    reg         pu_matrix_wreg_enb  [2:0][2:0][2:0];
    reg         pu_matrix_ireg_enb  [2:0][2:0];
    reg         pu_enb              [2:0][2:0];

    // Data Sigs Sim
    reg [ 7:0]  pu_matrix_wdi  [2:0][2:0];
    reg [ 1:0]  pu_matrix_wsel;
    reg [ 7:0]  pu_matrix_idi  [2:0][2:0];
    reg [ 1:0]  pu_matrix_isel;
    reg [ 1:0]  pu_matrix_conv_dir;

    initial begin
        #52
        // Init
        for (i_0 = 0; i_0 < 3; i_0 = i_0 + 1) 
            for (i_1 = 0; i_1 < 3; i_1 = i_1 + 1) begin
                for (i_2 = 0; i_2 < 3; i_2 = i_2 + 1)
                    pu_matrix_wreg_enb[i_0][i_1][i_2] = 1'b 0;
                pu_matrix_ireg_enb[i_0][i_1] = 1'b 0;
                pu_enb[i_0][i_1] = 1'b0;
            end
        #10 

        // Weight LOAD
        pu_matrix_wsel = 0;
        pu_matrix_wreg_enb[0][0][0] = 1'b 1;
        pu_matrix_wreg_enb[0][0][1] = 1'b 1;
        pu_matrix_wreg_enb[0][0][2] = 1'b 1;
        pu_matrix_wdi[0][0] = $random; pu_matrix_wdi[0][1] = $random; pu_matrix_wdi[0][2] = $random; 
        pu_matrix_wdi[1][0] = $random; pu_matrix_wdi[1][1] = $random; pu_matrix_wdi[1][2] = $random; 
        pu_matrix_wdi[2][0] = $random; pu_matrix_wdi[2][1] = $random; pu_matrix_wdi[2][2] = $random;
        #10 
        pu_matrix_wreg_enb[0][0][0] = 1'b 0;
        pu_matrix_wreg_enb[0][0][1] = 1'b 0;
        pu_matrix_wreg_enb[0][0][2] = 1'b 0;

        // Weight LOAD
        pu_matrix_wsel = 1;
        pu_matrix_wreg_enb[0][1][0] = 1'b 1;
        pu_matrix_wreg_enb[0][1][1] = 1'b 1;
        pu_matrix_wreg_enb[0][1][2] = 1'b 1;
        pu_matrix_wdi[0][0] = $random; pu_matrix_wdi[0][1] = $random; pu_matrix_wdi[0][2] = $random; 
        pu_matrix_wdi[1][0] = $random; pu_matrix_wdi[1][1] = $random; pu_matrix_wdi[1][2] = $random; 
        pu_matrix_wdi[2][0] = $random; pu_matrix_wdi[2][1] = $random; pu_matrix_wdi[2][2] = $random;
        #10 
        pu_matrix_wreg_enb[0][1][0] = 1'b 0;
        pu_matrix_wreg_enb[0][1][1] = 1'b 0;
        pu_matrix_wreg_enb[0][1][2] = 1'b 0;

        // Weight LOAD
        pu_matrix_wsel = 2;
        pu_matrix_wreg_enb[0][2][0] = 1'b 1;
        pu_matrix_wreg_enb[0][2][1] = 1'b 1;
        pu_matrix_wreg_enb[0][2][2] = 1'b 1;
        pu_matrix_wdi[0][0] = $random; pu_matrix_wdi[0][1] = $random; pu_matrix_wdi[0][2] = $random; 
        pu_matrix_wdi[1][0] = $random; pu_matrix_wdi[1][1] = $random; pu_matrix_wdi[1][2] = $random; 
        pu_matrix_wdi[2][0] = $random; pu_matrix_wdi[2][1] = $random; pu_matrix_wdi[2][2] = $random;
        #10 
        pu_matrix_wreg_enb[0][2][0] = 1'b 0;
        pu_matrix_wreg_enb[0][2][1] = 1'b 0;
        pu_matrix_wreg_enb[0][2][2] = 1'b 0;

        // Weight LOAD
        pu_matrix_wsel = 0;
        pu_matrix_wreg_enb[1][0][0] = 1'b 1;
        pu_matrix_wreg_enb[1][0][1] = 1'b 1;
        pu_matrix_wreg_enb[1][0][2] = 1'b 1;
        pu_matrix_wdi[0][0] = $random; pu_matrix_wdi[0][1] = $random; pu_matrix_wdi[0][2] = $random; 
        pu_matrix_wdi[1][0] = $random; pu_matrix_wdi[1][1] = $random; pu_matrix_wdi[1][2] = $random; 
        pu_matrix_wdi[2][0] = $random; pu_matrix_wdi[2][1] = $random; pu_matrix_wdi[2][2] = $random;
        #10 
        pu_matrix_wreg_enb[1][0][0] = 1'b 0;
        pu_matrix_wreg_enb[1][0][1] = 1'b 0;
        pu_matrix_wreg_enb[1][0][2] = 1'b 0;

        // Weight LOAD
        pu_matrix_wsel = 1;
        pu_matrix_wreg_enb[1][1][0] = 1'b 1;
        pu_matrix_wreg_enb[1][1][1] = 1'b 1;
        pu_matrix_wreg_enb[1][1][2] = 1'b 1;
        pu_matrix_wdi[0][0] = $random; pu_matrix_wdi[0][1] = $random; pu_matrix_wdi[0][2] = $random; 
        pu_matrix_wdi[1][0] = $random; pu_matrix_wdi[1][1] = $random; pu_matrix_wdi[1][2] = $random; 
        pu_matrix_wdi[2][0] = $random; pu_matrix_wdi[2][1] = $random; pu_matrix_wdi[2][2] = $random;
        #10 
        pu_matrix_wreg_enb[1][1][0] = 1'b 0;
        pu_matrix_wreg_enb[1][1][1] = 1'b 0;
        pu_matrix_wreg_enb[1][1][2] = 1'b 0;

        // Weight LOAD
        pu_matrix_wsel = 2;
        pu_matrix_wreg_enb[1][2][0] = 1'b 1;
        pu_matrix_wreg_enb[1][2][1] = 1'b 1;
        pu_matrix_wreg_enb[1][2][2] = 1'b 1;
        pu_matrix_wdi[0][0] = $random; pu_matrix_wdi[0][1] = $random; pu_matrix_wdi[0][2] = $random; 
        pu_matrix_wdi[1][0] = $random; pu_matrix_wdi[1][1] = $random; pu_matrix_wdi[1][2] = $random; 
        pu_matrix_wdi[2][0] = $random; pu_matrix_wdi[2][1] = $random; pu_matrix_wdi[2][2] = $random;
        #10 
        pu_matrix_wreg_enb[1][2][0] = 1'b 0;
        pu_matrix_wreg_enb[1][2][1] = 1'b 0;
        pu_matrix_wreg_enb[1][2][2] = 1'b 0;

        // Weight LOAD
        pu_matrix_wsel = 0;
        pu_matrix_wreg_enb[2][0][0] = 1'b 1;
        pu_matrix_wreg_enb[2][0][1] = 1'b 1;
        pu_matrix_wreg_enb[2][0][2] = 1'b 1;
        pu_matrix_wdi[0][0] = $random; pu_matrix_wdi[0][1] = $random; pu_matrix_wdi[0][2] = $random; 
        pu_matrix_wdi[1][0] = $random; pu_matrix_wdi[1][1] = $random; pu_matrix_wdi[1][2] = $random; 
        pu_matrix_wdi[2][0] = $random; pu_matrix_wdi[2][1] = $random; pu_matrix_wdi[2][2] = $random;
        #10 
        pu_matrix_wreg_enb[2][0][0] = 1'b 0;
        pu_matrix_wreg_enb[2][0][1] = 1'b 0;
        pu_matrix_wreg_enb[2][0][2] = 1'b 0;

        // Weight LOAD
        pu_matrix_wsel = 1;
        pu_matrix_wreg_enb[2][1][0] = 1'b 1;
        pu_matrix_wreg_enb[2][1][1] = 1'b 1;
        pu_matrix_wreg_enb[2][1][2] = 1'b 1;
        pu_matrix_wdi[0][0] = $random; pu_matrix_wdi[0][1] = $random; pu_matrix_wdi[0][2] = $random; 
        pu_matrix_wdi[1][0] = $random; pu_matrix_wdi[1][1] = $random; pu_matrix_wdi[1][2] = $random; 
        pu_matrix_wdi[2][0] = $random; pu_matrix_wdi[2][1] = $random; pu_matrix_wdi[2][2] = $random;
        #10 
        pu_matrix_wreg_enb[2][1][0] = 1'b 0;
        pu_matrix_wreg_enb[2][1][1] = 1'b 0;
        pu_matrix_wreg_enb[2][1][2] = 1'b 0;

        // Weight LOAD
        pu_matrix_wsel = 2;
        pu_matrix_wreg_enb[2][2][0] = 1'b 1;
        pu_matrix_wreg_enb[2][2][1] = 1'b 1;
        pu_matrix_wreg_enb[2][2][2] = 1'b 1;
        pu_matrix_wdi[0][0] = $random; pu_matrix_wdi[0][1] = $random; pu_matrix_wdi[0][2] = $random; 
        pu_matrix_wdi[1][0] = $random; pu_matrix_wdi[1][1] = $random; pu_matrix_wdi[1][2] = $random; 
        pu_matrix_wdi[2][0] = $random; pu_matrix_wdi[2][1] = $random; pu_matrix_wdi[2][2] = $random;
        #10 
        pu_matrix_wreg_enb[2][2][0] = 1'b 0;
        pu_matrix_wreg_enb[2][2][1] = 1'b 0;
        pu_matrix_wreg_enb[2][2][2] = 1'b 0;
        #10

        // Input LOAD
        pu_matrix_conv_dir = NON;
        pu_matrix_isel = 0;
        pu_matrix_ireg_enb[0][0] = 1'b 1;
        pu_matrix_ireg_enb[1][0] = 1'b 1;
        pu_matrix_ireg_enb[2][0] = 1'b 1;
        pu_matrix_idi[0][0] = $random; pu_matrix_idi[0][1] = $random; pu_matrix_idi[0][2] = $random;
        pu_matrix_idi[1][0] = $random; pu_matrix_idi[1][1] = $random; pu_matrix_idi[1][2] = $random;
        pu_matrix_idi[2][0] = $random; pu_matrix_idi[2][1] = $random; pu_matrix_idi[2][2] = $random;
        #10
        pu_matrix_ireg_enb[0][0] = 1'b 0;
        pu_matrix_ireg_enb[1][0] = 1'b 0;
        pu_matrix_ireg_enb[2][0] = 1'b 0;

        // Input LOAD
        pu_matrix_conv_dir = NON;
        pu_matrix_isel = 1;
        pu_matrix_ireg_enb[0][1] = 1'b 1;
        pu_matrix_ireg_enb[1][1] = 1'b 1;
        pu_matrix_ireg_enb[2][1] = 1'b 1;
        pu_matrix_idi[0][0] = $random; pu_matrix_idi[0][1] = $random; pu_matrix_idi[0][2] = $random;
        pu_matrix_idi[1][0] = $random; pu_matrix_idi[1][1] = $random; pu_matrix_idi[1][2] = $random;
        pu_matrix_idi[2][0] = $random; pu_matrix_idi[2][1] = $random; pu_matrix_idi[2][2] = $random;
        #10
        pu_matrix_ireg_enb[0][1] = 1'b 0;
        pu_matrix_ireg_enb[1][1] = 1'b 0;
        pu_matrix_ireg_enb[2][1] = 1'b 0;

        // Input LOAD
        pu_matrix_conv_dir = NON;
        pu_matrix_isel = 2;
        pu_matrix_ireg_enb[0][2] = 1'b 1;
        pu_matrix_ireg_enb[1][2] = 1'b 1;
        pu_matrix_ireg_enb[2][2] = 1'b 1;
        pu_matrix_idi[0][0] = $random; pu_matrix_idi[0][1] = $random; pu_matrix_idi[0][2] = $random;
        pu_matrix_idi[1][0] = $random; pu_matrix_idi[1][1] = $random; pu_matrix_idi[1][2] = $random;
        pu_matrix_idi[2][0] = $random; pu_matrix_idi[2][1] = $random; pu_matrix_idi[2][2] = $random;
        #10
        pu_matrix_ireg_enb[0][2] = 1'b 0;
        pu_matrix_ireg_enb[1][2] = 1'b 0;
        pu_matrix_ireg_enb[2][2] = 1'b 0;

        #10

        // COMPUTATION
        pu_enb[0][0] = 1'b 1; pu_enb[0][1] = 1'b 1; pu_enb[0][2] = 1'b 1; 
        pu_enb[1][0] = 1'b 1; pu_enb[1][1] = 1'b 1; pu_enb[1][2] = 1'b 1; 
        pu_enb[2][0] = 1'b 1; pu_enb[2][1] = 1'b 1; pu_enb[2][2] = 1'b 1; 
        #90
        pu_enb[0][0] = 1'b 0; pu_enb[0][1] = 1'b 0; pu_enb[0][2] = 1'b 0; 
        pu_enb[1][0] = 1'b 0; pu_enb[1][1] = 1'b 0; pu_enb[1][2] = 1'b 0; 
        pu_enb[2][0] = 1'b 0; pu_enb[2][1] = 1'b 0; pu_enb[2][2] = 1'b 0; 

        // Input LOAD
        pu_matrix_conv_dir = LEFT;
        pu_matrix_isel = 0;
        pu_matrix_ireg_enb[0][0] = 1'b 1;
        pu_matrix_ireg_enb[1][0] = 1'b 1;
        pu_matrix_ireg_enb[2][0] = 1'b 1;
        pu_matrix_ireg_enb[0][1] = 1'b 1;
        pu_matrix_ireg_enb[1][1] = 1'b 1;
        pu_matrix_ireg_enb[2][1] = 1'b 1;
        pu_matrix_ireg_enb[0][2] = 1'b 1;
        pu_matrix_ireg_enb[1][2] = 1'b 1;
        pu_matrix_ireg_enb[2][2] = 1'b 1;
        pu_matrix_idi[0][0] = $random; pu_matrix_idi[0][1] = $random; pu_matrix_idi[0][2] = $random;
        pu_matrix_idi[1][0] = $random; pu_matrix_idi[1][1] = $random; pu_matrix_idi[1][2] = $random;
        pu_matrix_idi[2][0] = $random; pu_matrix_idi[2][1] = $random; pu_matrix_idi[2][2] = $random;
        #10 
        pu_matrix_ireg_enb[0][0] = 1'b 0;
        pu_matrix_ireg_enb[1][0] = 1'b 0;
        pu_matrix_ireg_enb[2][0] = 1'b 0;
        pu_matrix_ireg_enb[0][1] = 1'b 0;
        pu_matrix_ireg_enb[1][1] = 1'b 0;
        pu_matrix_ireg_enb[2][1] = 1'b 0;
        pu_matrix_ireg_enb[0][2] = 1'b 0;
        pu_matrix_ireg_enb[1][2] = 1'b 0;
        pu_matrix_ireg_enb[2][2] = 1'b 0;

        // COMPUTATION
        pu_enb[0][0] = 1'b 1; pu_enb[0][1] = 1'b 1; pu_enb[0][2] = 1'b 1; 
        pu_enb[1][0] = 1'b 1; pu_enb[1][1] = 1'b 1; pu_enb[1][2] = 1'b 1; 
        pu_enb[2][0] = 1'b 1; pu_enb[2][1] = 1'b 1; pu_enb[2][2] = 1'b 1; 
        #90
        pu_enb[0][0] = 1'b 0; pu_enb[0][1] = 1'b 0; pu_enb[0][2] = 1'b 0; 
        pu_enb[1][0] = 1'b 0; pu_enb[1][1] = 1'b 0; pu_enb[1][2] = 1'b 0; 
        pu_enb[2][0] = 1'b 0; pu_enb[2][1] = 1'b 0; pu_enb[2][2] = 1'b 0; 

        // Input LOAD
        pu_matrix_conv_dir = DOWN;
        pu_matrix_isel = 0;
        pu_matrix_ireg_enb[0][0] = 1'b 1;
        pu_matrix_ireg_enb[1][0] = 1'b 1;
        pu_matrix_ireg_enb[2][0] = 1'b 1;
        pu_matrix_ireg_enb[0][1] = 1'b 1;
        pu_matrix_ireg_enb[1][1] = 1'b 1;
        pu_matrix_ireg_enb[2][1] = 1'b 1;
        pu_matrix_ireg_enb[0][2] = 1'b 1;
        pu_matrix_ireg_enb[1][2] = 1'b 1;
        pu_matrix_ireg_enb[2][2] = 1'b 1;
        pu_matrix_idi[0][0] = $random; pu_matrix_idi[0][1] = $random; pu_matrix_idi[0][2] = $random;
        pu_matrix_idi[1][0] = $random; pu_matrix_idi[1][1] = $random; pu_matrix_idi[1][2] = $random;
        pu_matrix_idi[2][0] = $random; pu_matrix_idi[2][1] = $random; pu_matrix_idi[2][2] = $random;
        #10 
        pu_matrix_ireg_enb[0][0] = 1'b 0;
        pu_matrix_ireg_enb[1][0] = 1'b 0;
        pu_matrix_ireg_enb[2][0] = 1'b 0;
        pu_matrix_ireg_enb[0][1] = 1'b 0;
        pu_matrix_ireg_enb[1][1] = 1'b 0;
        pu_matrix_ireg_enb[2][1] = 1'b 0;
        pu_matrix_ireg_enb[0][2] = 1'b 0;
        pu_matrix_ireg_enb[1][2] = 1'b 0;
        pu_matrix_ireg_enb[2][2] = 1'b 0;

        // COMPUTATION
        pu_enb[0][0] = 1'b 1; pu_enb[0][1] = 1'b 1; pu_enb[0][2] = 1'b 1; 
        pu_enb[1][0] = 1'b 1; pu_enb[1][1] = 1'b 1; pu_enb[1][2] = 1'b 1; 
        pu_enb[2][0] = 1'b 1; pu_enb[2][1] = 1'b 1; pu_enb[2][2] = 1'b 1; 
        #90
        pu_enb[0][0] = 1'b 0; pu_enb[0][1] = 1'b 0; pu_enb[0][2] = 1'b 0; 
        pu_enb[1][0] = 1'b 0; pu_enb[1][1] = 1'b 0; pu_enb[1][2] = 1'b 0; 
        pu_enb[2][0] = 1'b 0; pu_enb[2][1] = 1'b 0; pu_enb[2][2] = 1'b 0; 

        // Input LOAD
        pu_matrix_conv_dir = RIGHT;
        pu_matrix_isel = 0;
        pu_matrix_ireg_enb[0][0] = 1'b 1;
        pu_matrix_ireg_enb[1][0] = 1'b 1;
        pu_matrix_ireg_enb[2][0] = 1'b 1;
        pu_matrix_ireg_enb[0][1] = 1'b 1;
        pu_matrix_ireg_enb[1][1] = 1'b 1;
        pu_matrix_ireg_enb[2][1] = 1'b 1;
        pu_matrix_ireg_enb[0][2] = 1'b 1;
        pu_matrix_ireg_enb[1][2] = 1'b 1;
        pu_matrix_ireg_enb[2][2] = 1'b 1;
        pu_matrix_idi[0][0] = $random; pu_matrix_idi[0][1] = $random; pu_matrix_idi[0][2] = $random;
        pu_matrix_idi[1][0] = $random; pu_matrix_idi[1][1] = $random; pu_matrix_idi[1][2] = $random;
        pu_matrix_idi[2][0] = $random; pu_matrix_idi[2][1] = $random; pu_matrix_idi[2][2] = $random;
        #10 
        pu_matrix_ireg_enb[0][0] = 1'b 0;
        pu_matrix_ireg_enb[1][0] = 1'b 0;
        pu_matrix_ireg_enb[2][0] = 1'b 0;
        pu_matrix_ireg_enb[0][1] = 1'b 0;
        pu_matrix_ireg_enb[1][1] = 1'b 0;
        pu_matrix_ireg_enb[2][1] = 1'b 0;
        pu_matrix_ireg_enb[0][2] = 1'b 0;
        pu_matrix_ireg_enb[1][2] = 1'b 0;
        pu_matrix_ireg_enb[2][2] = 1'b 0;

        // COMPUTATION
        pu_enb[0][0] = 1'b 1; pu_enb[0][1] = 1'b 1; pu_enb[0][2] = 1'b 1; 
        pu_enb[1][0] = 1'b 1; pu_enb[1][1] = 1'b 1; pu_enb[1][2] = 1'b 1; 
        pu_enb[2][0] = 1'b 1; pu_enb[2][1] = 1'b 1; pu_enb[2][2] = 1'b 1; 
        #90
        pu_enb[0][0] = 1'b 0; pu_enb[0][1] = 1'b 0; pu_enb[0][2] = 1'b 0; 
        pu_enb[1][0] = 1'b 0; pu_enb[1][1] = 1'b 0; pu_enb[1][2] = 1'b 0; 
        pu_enb[2][0] = 1'b 0; pu_enb[2][1] = 1'b 0; pu_enb[2][2] = 1'b 0; 
    end

    // Unit Under Test
    al_accel_pu_matrix uut (
        .pu_matrix_wdi_0_0  (pu_matrix_wdi[0][0]),
        .pu_matrix_wdi_0_1  (pu_matrix_wdi[0][1]),
        .pu_matrix_wdi_0_2  (pu_matrix_wdi[0][2]),
        .pu_matrix_wdi_1_0  (pu_matrix_wdi[1][0]),
        .pu_matrix_wdi_1_1  (pu_matrix_wdi[1][1]),
        .pu_matrix_wdi_1_2  (pu_matrix_wdi[1][2]),
        .pu_matrix_wdi_2_0  (pu_matrix_wdi[2][0]),
        .pu_matrix_wdi_2_1  (pu_matrix_wdi[2][1]),
        .pu_matrix_wdi_2_2  (pu_matrix_wdi[2][2]),

        .pu_matrix_wsel_0   (pu_matrix_wsel),
        .pu_matrix_wsel_1   (pu_matrix_wsel),
        .pu_matrix_wsel_2   (pu_matrix_wsel),

        .pu_matrix_idi_0_0  (pu_matrix_idi[0][0]),
        .pu_matrix_idi_0_1  (pu_matrix_idi[0][1]),
        .pu_matrix_idi_0_2  (pu_matrix_idi[0][2]),
        .pu_matrix_idi_1_0  (pu_matrix_idi[1][0]),
        .pu_matrix_idi_1_1  (pu_matrix_idi[1][1]),
        .pu_matrix_idi_1_2  (pu_matrix_idi[1][2]),
        .pu_matrix_idi_2_0  (pu_matrix_idi[2][0]),
        .pu_matrix_idi_2_1  (pu_matrix_idi[2][1]),
        .pu_matrix_idi_2_2  (pu_matrix_idi[2][2]),

        .pu_matrix_isel_0   (pu_matrix_isel),
        .pu_matrix_isel_1   (pu_matrix_isel),
        .pu_matrix_isel_2   (pu_matrix_isel),

        .pu_matrix_is_conv_layer   (1'b 1),
        .pu_matrix_conv_dir        (pu_matrix_conv_dir),
        .pu_matrix_input_offset     (32'b0),

        .pu_matrix_wreg_enb_0_0_0   (pu_matrix_wreg_enb[0][0][0]),
        .pu_matrix_wreg_enb_0_0_1   (pu_matrix_wreg_enb[0][0][1]),
        .pu_matrix_wreg_enb_0_0_2   (pu_matrix_wreg_enb[0][0][2]),
        .pu_matrix_wreg_enb_0_1_0   (pu_matrix_wreg_enb[0][1][0]),
        .pu_matrix_wreg_enb_0_1_1   (pu_matrix_wreg_enb[0][1][1]),
        .pu_matrix_wreg_enb_0_1_2   (pu_matrix_wreg_enb[0][1][2]),
        .pu_matrix_wreg_enb_0_2_0   (pu_matrix_wreg_enb[0][2][0]),
        .pu_matrix_wreg_enb_0_2_1   (pu_matrix_wreg_enb[0][2][1]),
        .pu_matrix_wreg_enb_0_2_2   (pu_matrix_wreg_enb[0][2][2]),
        .pu_matrix_wreg_enb_1_0_0   (pu_matrix_wreg_enb[1][0][0]),
        .pu_matrix_wreg_enb_1_0_1   (pu_matrix_wreg_enb[1][0][1]),
        .pu_matrix_wreg_enb_1_0_2   (pu_matrix_wreg_enb[1][0][2]),
        .pu_matrix_wreg_enb_1_1_0   (pu_matrix_wreg_enb[1][1][0]),
        .pu_matrix_wreg_enb_1_1_1   (pu_matrix_wreg_enb[1][1][1]),
        .pu_matrix_wreg_enb_1_1_2   (pu_matrix_wreg_enb[1][1][2]),
        .pu_matrix_wreg_enb_1_2_0   (pu_matrix_wreg_enb[1][2][0]),
        .pu_matrix_wreg_enb_1_2_1   (pu_matrix_wreg_enb[1][2][1]),
        .pu_matrix_wreg_enb_1_2_2   (pu_matrix_wreg_enb[1][2][2]),
        .pu_matrix_wreg_enb_2_0_0   (pu_matrix_wreg_enb[2][0][0]),
        .pu_matrix_wreg_enb_2_0_1   (pu_matrix_wreg_enb[2][0][1]),
        .pu_matrix_wreg_enb_2_0_2   (pu_matrix_wreg_enb[2][0][2]),
        .pu_matrix_wreg_enb_2_1_0   (pu_matrix_wreg_enb[2][1][0]),
        .pu_matrix_wreg_enb_2_1_1   (pu_matrix_wreg_enb[2][1][1]),
        .pu_matrix_wreg_enb_2_1_2   (pu_matrix_wreg_enb[2][1][2]),
        .pu_matrix_wreg_enb_2_2_0   (pu_matrix_wreg_enb[2][2][0]),
        .pu_matrix_wreg_enb_2_2_1   (pu_matrix_wreg_enb[2][2][1]),
        .pu_matrix_wreg_enb_2_2_2   (pu_matrix_wreg_enb[2][2][2]),

        .pu_matrix_ireg_enb_0_0     (pu_matrix_ireg_enb[0][0]),
        .pu_matrix_ireg_enb_0_1     (pu_matrix_ireg_enb[0][1]),
        .pu_matrix_ireg_enb_0_2     (pu_matrix_ireg_enb[0][2]),
        .pu_matrix_ireg_enb_1_0     (pu_matrix_ireg_enb[1][0]),
        .pu_matrix_ireg_enb_1_1     (pu_matrix_ireg_enb[1][1]),
        .pu_matrix_ireg_enb_1_2     (pu_matrix_ireg_enb[1][2]),
        .pu_matrix_ireg_enb_2_0     (pu_matrix_ireg_enb[2][0]),
        .pu_matrix_ireg_enb_2_1     (pu_matrix_ireg_enb[2][1]),
        .pu_matrix_ireg_enb_2_2     (pu_matrix_ireg_enb[2][2]),

        .pu_enb_0_0 (pu_enb[0][0]),
        .pu_enb_0_1 (pu_enb[0][1]),
        .pu_enb_0_2 (pu_enb[0][2]),
        .pu_enb_1_0 (pu_enb[1][0]),
        .pu_enb_1_1 (pu_enb[1][1]),
        .pu_enb_1_2 (pu_enb[1][2]),
        .pu_enb_2_0 (pu_enb[2][0]),
        .pu_enb_2_1 (pu_enb[2][1]),
        .pu_enb_2_2 (pu_enb[2][2]),

        .clk    (clk),
        .resetn (resetn)
    );

    // Debug Info
    initial begin
        $dumpfile("accel_vcd/al_accel_pu_matrix_tb.vcd");
        $dumpvars(0, al_accel_pu_matrix_tb);
        repeat (`TIME_TO_REPEAT) begin
			repeat (1000) @(posedge clk);
		end
		$finish;
    end
endmodule