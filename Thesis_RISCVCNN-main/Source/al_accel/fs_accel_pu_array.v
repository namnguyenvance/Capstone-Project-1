module fs_accel_pu_array(
    // Data Sigs
    input   [ 7:0]  pu_arr_wdi_0_0_0,
    input   [ 7:0]  pu_arr_wdi_0_0_1,
    input   [ 7:0]  pu_arr_wdi_0_0_2,
    input   [ 7:0]  pu_arr_wdi_0_1_0,
    input   [ 7:0]  pu_arr_wdi_0_1_1,
    input   [ 7:0]  pu_arr_wdi_0_1_2,
    input   [ 7:0]  pu_arr_wdi_0_2_0,
    input   [ 7:0]  pu_arr_wdi_0_2_1,
    input   [ 7:0]  pu_arr_wdi_0_2_2,
    input   [ 7:0]  pu_arr_wdi_1_0_0,
    input   [ 7:0]  pu_arr_wdi_1_0_1,
    input   [ 7:0]  pu_arr_wdi_1_0_2,
    input   [ 7:0]  pu_arr_wdi_1_1_0,
    input   [ 7:0]  pu_arr_wdi_1_1_1,
    input   [ 7:0]  pu_arr_wdi_1_1_2,
    input   [ 7:0]  pu_arr_wdi_1_2_0,
    input   [ 7:0]  pu_arr_wdi_1_2_1,
    input   [ 7:0]  pu_arr_wdi_1_2_2,
    input   [ 7:0]  pu_arr_wdi_2_0_0,
    input   [ 7:0]  pu_arr_wdi_2_0_1,
    input   [ 7:0]  pu_arr_wdi_2_0_2,
    input   [ 7:0]  pu_arr_wdi_2_1_0,
    input   [ 7:0]  pu_arr_wdi_2_1_1,
    input   [ 7:0]  pu_arr_wdi_2_1_2,
    input   [ 7:0]  pu_arr_wdi_2_2_0,
    input   [ 7:0]  pu_arr_wdi_2_2_1,
    input   [ 7:0]  pu_arr_wdi_2_2_2,

    input   [ 7:0]  pu_arr_idi_0_0,
    input   [ 7:0]  pu_arr_idi_0_1,
    input   [ 7:0]  pu_arr_idi_0_2,
    input   [ 7:0]  pu_arr_idi_1_0,
    input   [ 7:0]  pu_arr_idi_1_1,
    input   [ 7:0]  pu_arr_idi_1_2,
    input   [ 7:0]  pu_arr_idi_2_0,
    input   [ 7:0]  pu_arr_idi_2_1,
    input   [ 7:0]  pu_arr_idi_2_2,

    output  [31:0]  pu_arr_odo_0,
    output  [31:0]  pu_arr_odo_1,
    output  [31:0]  pu_arr_odo_2,

    // Config Sigs
    input           pu_arr_is_conv_layer,
    input   [ 1:0]  pu_arr_conv_dir,
    input   [31:0]  pu_arr_input_offset,

    // Ctrl Sigs
    input   wreg_enb_0_0,
    input   wreg_enb_0_1,
    input   wreg_enb_0_2,
    input   wreg_enb_1_0,
    input   wreg_enb_1_1,
    input   wreg_enb_1_2,
    input   wreg_enb_2_0,
    input   wreg_enb_2_1,
    input   wreg_enb_2_2,

    input   ireg_enb_0,
    input   ireg_enb_1,
    input   ireg_enb_2,

    input   pu_enb_0,
    input   pu_enb_1,
    input   pu_enb_2,

    // Mandatory Sigs
    output  rdy,
    input   clk,
    input   resetn
);
    // Direction Param
    localparam 
        NON   = 2'b00,
        LEFT  = 2'b01,
        RIGHT = 2'b10,
        DOWN  = 2'b11; 

    wire [7:0] wreg_to_pu [2:0][2:0][2:0];
    wire [7:0] ireg_to_pu [2:0][2:0];
    reg  [7:0] ireg_idi   [2:0][2:0];

    wire   rdy_0, rdy_1, rdy_2;
    assign rdy = rdy_0 || rdy_1 || rdy_2;

    /* Combinational Logic */
    always @(*) begin
        if (pu_arr_is_conv_layer) begin
            ireg_idi[0][0] = pu_arr_idi_0_0;
            ireg_idi[0][1] = pu_arr_idi_0_1;
            ireg_idi[0][2] = pu_arr_idi_0_2;
            ireg_idi[1][0] = pu_arr_idi_1_0;
            ireg_idi[1][1] = pu_arr_idi_1_1;
            ireg_idi[1][2] = pu_arr_idi_1_2;
            ireg_idi[2][0] = pu_arr_idi_2_0;
            ireg_idi[2][1] = pu_arr_idi_2_1;
            ireg_idi[2][2] = pu_arr_idi_2_2;
            case (pu_arr_conv_dir)
                RIGHT: begin
                    ireg_idi[0][0] = pu_arr_idi_0_0;
                    ireg_idi[0][1] = pu_arr_idi_0_1;
                    ireg_idi[0][2] = pu_arr_idi_0_2;
                    ireg_idi[1][0] = ireg_to_pu[0][0];
                    ireg_idi[1][1] = ireg_to_pu[0][1];
                    ireg_idi[1][2] = ireg_to_pu[0][2];
                    ireg_idi[2][0] = ireg_to_pu[1][0];
                    ireg_idi[2][1] = ireg_to_pu[1][1];
                    ireg_idi[2][2] = ireg_to_pu[1][2];
                end

                LEFT : begin
                    ireg_idi[0][0] = ireg_to_pu[1][0];
                    ireg_idi[0][1] = ireg_to_pu[1][1];
                    ireg_idi[0][2] = ireg_to_pu[1][2];
                    ireg_idi[1][0] = ireg_to_pu[2][0];
                    ireg_idi[1][1] = ireg_to_pu[2][1];
                    ireg_idi[1][2] = ireg_to_pu[2][2];
                    ireg_idi[2][0] = pu_arr_idi_0_0;
                    ireg_idi[2][1] = pu_arr_idi_0_1;
                    ireg_idi[2][2] = pu_arr_idi_0_2;
                end

                DOWN : begin
                    ireg_idi[0][0] = ireg_to_pu[0][1];
                    ireg_idi[0][1] = ireg_to_pu[0][2];
                    ireg_idi[0][2] = pu_arr_idi_0_0;
                    ireg_idi[1][0] = ireg_to_pu[1][1];
                    ireg_idi[1][1] = ireg_to_pu[1][2];
                    ireg_idi[1][2] = pu_arr_idi_0_1;
                    ireg_idi[2][0] = ireg_to_pu[2][1];
                    ireg_idi[2][1] = ireg_to_pu[2][2];
                    ireg_idi[2][2] = pu_arr_idi_0_2;
                end
            endcase
        end else begin
            ireg_idi[0][0] = pu_arr_idi_0_0;
            ireg_idi[0][1] = pu_arr_idi_0_1;
            ireg_idi[0][2] = pu_arr_idi_0_2;
            ireg_idi[1][0] = pu_arr_idi_1_0;
            ireg_idi[1][1] = pu_arr_idi_1_1;
            ireg_idi[1][2] = pu_arr_idi_1_2;
            ireg_idi[2][0] = pu_arr_idi_2_0;
            ireg_idi[2][1] = pu_arr_idi_2_1;
            ireg_idi[2][2] = pu_arr_idi_2_2;
        end
    end

    /* Submodule Instantiate */
    // Weight Register
    fs_accel_wreg wreg_0_0 (
        .wreg_di_0 (pu_arr_wdi_0_0_0),
        .wreg_di_1 (pu_arr_wdi_0_0_1),
        .wreg_di_2 (pu_arr_wdi_0_0_2),

        .wreg_do_0 (wreg_to_pu[0][0][0]),
        .wreg_do_1 (wreg_to_pu[0][0][1]),
        .wreg_do_2 (wreg_to_pu[0][0][2]), 

        .enb    (wreg_enb_0_0),
        .clk    (clk),
        .resetn (resetn)
    );
    
    fs_accel_wreg wreg_0_1 (
    .wreg_di_0 (pu_arr_wdi_0_1_0),
    .wreg_di_1 (pu_arr_wdi_0_1_1),
    .wreg_di_2 (pu_arr_wdi_0_1_2),

    .wreg_do_0 (wreg_to_pu[0][1][0]),
    .wreg_do_1 (wreg_to_pu[0][1][1]),
    .wreg_do_2 (wreg_to_pu[0][1][2]), 

    .enb    (wreg_enb_0_1),
    .clk    (clk),
    .resetn (resetn)
    );

    fs_accel_wreg wreg_0_2 (
        .wreg_di_0 (pu_arr_wdi_0_2_0),
        .wreg_di_1 (pu_arr_wdi_0_2_1),
        .wreg_di_2 (pu_arr_wdi_0_2_2),

        .wreg_do_0 (wreg_to_pu[0][2][0]),
        .wreg_do_1 (wreg_to_pu[0][2][1]),
        .wreg_do_2 (wreg_to_pu[0][2][2]), 

        .enb    (wreg_enb_0_2),
        .clk    (clk),
        .resetn (resetn)
    );

    fs_accel_wreg wreg_1_0 (
        .wreg_di_0 (pu_arr_wdi_1_0_0),
        .wreg_di_1 (pu_arr_wdi_1_0_1),
        .wreg_di_2 (pu_arr_wdi_1_0_2),

        .wreg_do_0 (wreg_to_pu[1][0][0]),
        .wreg_do_1 (wreg_to_pu[1][0][1]),
        .wreg_do_2 (wreg_to_pu[1][0][2]), 

        .enb    (wreg_enb_1_0),
        .clk    (clk),
        .resetn (resetn)
    );

    fs_accel_wreg wreg_1_1 (
        .wreg_di_0 (pu_arr_wdi_1_1_0),
        .wreg_di_1 (pu_arr_wdi_1_1_1),
        .wreg_di_2 (pu_arr_wdi_1_1_2),

        .wreg_do_0 (wreg_to_pu[1][1][0]),
        .wreg_do_1 (wreg_to_pu[1][1][1]),
        .wreg_do_2 (wreg_to_pu[1][1][2]), 

        .enb    (wreg_enb_1_1),
        .clk    (clk),
        .resetn (resetn)
    );

    fs_accel_wreg wreg_1_2 (
        .wreg_di_0 (pu_arr_wdi_1_2_0),
        .wreg_di_1 (pu_arr_wdi_1_2_1),
        .wreg_di_2 (pu_arr_wdi_1_2_2),

        .wreg_do_0 (wreg_to_pu[1][2][0]),
        .wreg_do_1 (wreg_to_pu[1][2][1]),
        .wreg_do_2 (wreg_to_pu[1][2][2]), 

        .enb    (wreg_enb_1_2),
        .clk    (clk),
        .resetn (resetn)
    );

    fs_accel_wreg wreg_2_0 (
        .wreg_di_0 (pu_arr_wdi_2_0_0),
        .wreg_di_1 (pu_arr_wdi_2_0_1),
        .wreg_di_2 (pu_arr_wdi_2_0_2),

        .wreg_do_0 (wreg_to_pu[2][0][0]),
        .wreg_do_1 (wreg_to_pu[2][0][1]),
        .wreg_do_2 (wreg_to_pu[2][0][2]), 

        .enb    (wreg_enb_2_0),
        .clk    (clk),
        .resetn (resetn)
    );

    fs_accel_wreg wreg_2_1 (
        .wreg_di_0 (pu_arr_wdi_2_1_0),
        .wreg_di_1 (pu_arr_wdi_2_1_1),
        .wreg_di_2 (pu_arr_wdi_2_1_2),

        .wreg_do_0 (wreg_to_pu[2][1][0]),
        .wreg_do_1 (wreg_to_pu[2][1][1]),
        .wreg_do_2 (wreg_to_pu[2][1][2]), 

        .enb    (wreg_enb_2_1),
        .clk    (clk),
        .resetn (resetn)
    );

    fs_accel_wreg wreg_2_2 (
        .wreg_di_0 (pu_arr_wdi_2_2_0),
        .wreg_di_1 (pu_arr_wdi_2_2_1),
        .wreg_di_2 (pu_arr_wdi_2_2_2),

        .wreg_do_0 (wreg_to_pu[2][2][0]),
        .wreg_do_1 (wreg_to_pu[2][2][1]),
        .wreg_do_2 (wreg_to_pu[2][2][2]), 

        .enb    (wreg_enb_2_2),
        .clk    (clk),
        .resetn (resetn)
    );

    // Input Register
    fs_accel_ireg ireg_0 (
        .ireg_di_0 (ireg_idi[0][0]),
        .ireg_di_1 (ireg_idi[0][1]),
        .ireg_di_2 (ireg_idi[0][2]),

        .ireg_do_0 (ireg_to_pu[0][0]),
        .ireg_do_1 (ireg_to_pu[0][1]),
        .ireg_do_2 (ireg_to_pu[0][2]),

        .enb    (ireg_enb_0),
        .clk    (clk),
        .resetn (resetn)
    );

    fs_accel_ireg ireg_1 (
        .ireg_di_0 (ireg_idi[1][0]),
        .ireg_di_1 (ireg_idi[1][1]),
        .ireg_di_2 (ireg_idi[1][2]),

        .ireg_do_0 (ireg_to_pu[1][0]),
        .ireg_do_1 (ireg_to_pu[1][1]),
        .ireg_do_2 (ireg_to_pu[1][2]),

        .enb    (ireg_enb_1),
        .clk    (clk),
        .resetn (resetn)
    );

    fs_accel_ireg ireg_2 (
        .ireg_di_0 (ireg_idi[2][0]),
        .ireg_di_1 (ireg_idi[2][1]),
        .ireg_di_2 (ireg_idi[2][2]),

        .ireg_do_0 (ireg_to_pu[2][0]),
        .ireg_do_1 (ireg_to_pu[2][1]),
        .ireg_do_2 (ireg_to_pu[2][2]),

        .enb    (ireg_enb_2),
        .clk    (clk),
        .resetn (resetn)
    );


    // Processing Unit
    fs_accel_pu pu_0 (
        .pu_wdi_0_0 (wreg_to_pu[0][0][0]),
        .pu_wdi_0_1 (wreg_to_pu[0][0][1]),
        .pu_wdi_0_2 (wreg_to_pu[0][0][2]),
        .pu_wdi_1_0 (wreg_to_pu[1][0][0]),
        .pu_wdi_1_1 (wreg_to_pu[1][0][1]),
        .pu_wdi_1_2 (wreg_to_pu[1][0][2]),
        .pu_wdi_2_0 (wreg_to_pu[2][0][0]),
        .pu_wdi_2_1 (wreg_to_pu[2][0][1]),
        .pu_wdi_2_2 (wreg_to_pu[2][0][2]),

        .pu_idi_0   (ireg_to_pu[0][0]),
        .pu_idi_1   (ireg_to_pu[0][1]),
        .pu_idi_2   (ireg_to_pu[0][2]),
        .pu_idi_3   (ireg_to_pu[1][0]),
        .pu_idi_4   (ireg_to_pu[1][1]),
        .pu_idi_5   (ireg_to_pu[1][2]),
        .pu_idi_6   (ireg_to_pu[2][0]),
        .pu_idi_7   (ireg_to_pu[2][1]),
        .pu_idi_8   (ireg_to_pu[2][2]),

        .pu_odo    (pu_arr_odo_0),

        .pu_input_offset    (pu_arr_input_offset), 

        .enb    (pu_enb_0),
        .rdy    (rdy_0),
        .clk    (clk),
        .resetn (resetn)
    );

    fs_accel_pu pu_1 (
        .pu_wdi_0_0 (wreg_to_pu[0][1][0]),
        .pu_wdi_0_1 (wreg_to_pu[0][1][1]),
        .pu_wdi_0_2 (wreg_to_pu[0][1][2]),
        .pu_wdi_1_0 (wreg_to_pu[1][1][0]),
        .pu_wdi_1_1 (wreg_to_pu[1][1][1]),
        .pu_wdi_1_2 (wreg_to_pu[1][1][2]),
        .pu_wdi_2_0 (wreg_to_pu[2][1][0]),
        .pu_wdi_2_1 (wreg_to_pu[2][1][1]),
        .pu_wdi_2_2 (wreg_to_pu[2][1][2]),

        .pu_idi_0   (ireg_to_pu[0][0]),
        .pu_idi_1   (ireg_to_pu[0][1]),
        .pu_idi_2   (ireg_to_pu[0][2]),
        .pu_idi_3   (ireg_to_pu[1][0]),
        .pu_idi_4   (ireg_to_pu[1][1]),
        .pu_idi_5   (ireg_to_pu[1][2]),
        .pu_idi_6   (ireg_to_pu[2][0]),
        .pu_idi_7   (ireg_to_pu[2][1]),
        .pu_idi_8   (ireg_to_pu[2][2]),

        .pu_odo    (pu_arr_odo_1),

        .pu_input_offset    (pu_arr_input_offset), 

        .enb    (pu_enb_1),
        .rdy    (rdy_1),
        .clk    (clk),
        .resetn (resetn)
    );

    fs_accel_pu pu_2 (
        .pu_wdi_0_0 (wreg_to_pu[0][2][0]),
        .pu_wdi_0_1 (wreg_to_pu[0][2][1]),
        .pu_wdi_0_2 (wreg_to_pu[0][2][2]),
        .pu_wdi_1_0 (wreg_to_pu[1][2][0]),
        .pu_wdi_1_1 (wreg_to_pu[1][2][1]),
        .pu_wdi_1_2 (wreg_to_pu[1][2][2]),
        .pu_wdi_2_0 (wreg_to_pu[2][2][0]),
        .pu_wdi_2_1 (wreg_to_pu[2][2][1]),
        .pu_wdi_2_2 (wreg_to_pu[2][2][2]),

        .pu_idi_0   (ireg_to_pu[0][0]),
        .pu_idi_1   (ireg_to_pu[0][1]),
        .pu_idi_2   (ireg_to_pu[0][2]),
        .pu_idi_3   (ireg_to_pu[1][0]),
        .pu_idi_4   (ireg_to_pu[1][1]),
        .pu_idi_5   (ireg_to_pu[1][2]),
        .pu_idi_6   (ireg_to_pu[2][0]),
        .pu_idi_7   (ireg_to_pu[2][1]),
        .pu_idi_8   (ireg_to_pu[2][2]),

        .pu_odo    (pu_arr_odo_2),

        .pu_input_offset    (pu_arr_input_offset), 

        .enb    (pu_enb_2),
        .rdy    (rdy_2),
        .clk    (clk),
        .resetn (resetn)
    );
    /************************************/
endmodule




