module fs_accel_pu_matrix(
    // Data Sigs
    input   [ 7:0] pu_matrix_wdi_0_0,
    input   [ 7:0] pu_matrix_wdi_0_1,
    input   [ 7:0] pu_matrix_wdi_0_2,
    input   [ 7:0] pu_matrix_wdi_1_0,
    input   [ 7:0] pu_matrix_wdi_1_1,
    input   [ 7:0] pu_matrix_wdi_1_2,
    input   [ 7:0] pu_matrix_wdi_2_0,
    input   [ 7:0] pu_matrix_wdi_2_1,
    input   [ 7:0] pu_matrix_wdi_2_2,

    input   [ 1:0] pu_matrix_wsel_0,
    input   [ 1:0] pu_matrix_wsel_1,
    input   [ 1:0] pu_matrix_wsel_2,

    input   [ 7:0] pu_matrix_idi_0_0,
    input   [ 7:0] pu_matrix_idi_0_1,
    input   [ 7:0] pu_matrix_idi_0_2,
    input   [ 7:0] pu_matrix_idi_1_0,
    input   [ 7:0] pu_matrix_idi_1_1,
    input   [ 7:0] pu_matrix_idi_1_2,
    input   [ 7:0] pu_matrix_idi_2_0,
    input   [ 7:0] pu_matrix_idi_2_1,
    input   [ 7:0] pu_matrix_idi_2_2,

    input   [ 1:0] pu_matrix_isel_0,
    input   [ 1:0] pu_matrix_isel_1,
    input   [ 1:0] pu_matrix_isel_2,

    output  [31:0] pu_matrix_odo_0_0,
    output  [31:0] pu_matrix_odo_0_1,
    output  [31:0] pu_matrix_odo_0_2,
    output  [31:0] pu_matrix_odo_1_0,
    output  [31:0] pu_matrix_odo_1_1,
    output  [31:0] pu_matrix_odo_1_2,
    output  [31:0] pu_matrix_odo_2_0,
    output  [31:0] pu_matrix_odo_2_1,
    output  [31:0] pu_matrix_odo_2_2,

    // Config Sigs
    input          pu_matrix_is_conv_layer,
    input   [ 1:0] pu_matrix_conv_dir,
    input   [31:0] pu_matrix_input_offset,

    // Ctrl Sigs
    input   pu_matrix_wreg_enb_0_0_0,
    input   pu_matrix_wreg_enb_0_0_1,
    input   pu_matrix_wreg_enb_0_0_2,
    input   pu_matrix_wreg_enb_0_1_0,
    input   pu_matrix_wreg_enb_0_1_1,
    input   pu_matrix_wreg_enb_0_1_2,
    input   pu_matrix_wreg_enb_0_2_0,
    input   pu_matrix_wreg_enb_0_2_1,
    input   pu_matrix_wreg_enb_0_2_2,
    input   pu_matrix_wreg_enb_1_0_0,
    input   pu_matrix_wreg_enb_1_0_1,
    input   pu_matrix_wreg_enb_1_0_2,
    input   pu_matrix_wreg_enb_1_1_0,
    input   pu_matrix_wreg_enb_1_1_1,
    input   pu_matrix_wreg_enb_1_1_2,
    input   pu_matrix_wreg_enb_1_2_0,
    input   pu_matrix_wreg_enb_1_2_1,
    input   pu_matrix_wreg_enb_1_2_2,
    input   pu_matrix_wreg_enb_2_0_0,
    input   pu_matrix_wreg_enb_2_0_1,
    input   pu_matrix_wreg_enb_2_0_2,
    input   pu_matrix_wreg_enb_2_1_0,
    input   pu_matrix_wreg_enb_2_1_1,
    input   pu_matrix_wreg_enb_2_1_2,
    input   pu_matrix_wreg_enb_2_2_0,
    input   pu_matrix_wreg_enb_2_2_1,
    input   pu_matrix_wreg_enb_2_2_2,

    input   pu_matrix_ireg_enb_0_0,
    input   pu_matrix_ireg_enb_0_1,
    input   pu_matrix_ireg_enb_0_2,
    input   pu_matrix_ireg_enb_1_0,
    input   pu_matrix_ireg_enb_1_1,
    input   pu_matrix_ireg_enb_1_2,
    input   pu_matrix_ireg_enb_2_0,
    input   pu_matrix_ireg_enb_2_1,
    input   pu_matrix_ireg_enb_2_2,

    input   pu_enb_0_0,
    input   pu_enb_0_1,
    input   pu_enb_0_2,
    input   pu_enb_1_0,
    input   pu_enb_1_1,
    input   pu_enb_1_2,
    input   pu_enb_2_0,
    input   pu_enb_2_1,
    input   pu_enb_2_2,

    // Feedback Sigs
    output  rdy,

    // Mandatory Sigs
    input   clk,
    input   resetn
);
    wire    [ 7:0] wdemux_to_pu_arr [2:0][2:0][2:0];
    wire    [ 7:0] idemux_to_pu_arr [2:0][2:0][2:0];

    wire   rdy_0, rdy_1, rdy_2;
    assign rdy = rdy_0 || rdy_1 || rdy_2;

    /* Submodule Instantiate */
    // Weight Demuxer
    fs_accel_wdemux wdemux_0 (
        .wdemux_di_0 (pu_matrix_wdi_0_0),
        .wdemux_di_1 (pu_matrix_wdi_0_1),
        .wdemux_di_2 (pu_matrix_wdi_0_2), 

        .wdemux_do_0_0 (wdemux_to_pu_arr[0][0][0]),
        .wdemux_do_0_1 (wdemux_to_pu_arr[0][0][1]),
        .wdemux_do_0_2 (wdemux_to_pu_arr[0][0][2]),
        .wdemux_do_1_0 (wdemux_to_pu_arr[1][0][0]),
        .wdemux_do_1_1 (wdemux_to_pu_arr[1][0][1]),
        .wdemux_do_1_2 (wdemux_to_pu_arr[1][0][2]),
        .wdemux_do_2_0 (wdemux_to_pu_arr[2][0][0]),
        .wdemux_do_2_1 (wdemux_to_pu_arr[2][0][1]),
        .wdemux_do_2_2 (wdemux_to_pu_arr[2][0][2]),

        .wdemux_sel (pu_matrix_wsel_0)
    );

    fs_accel_wdemux wdemux_1 (
        .wdemux_di_0 (pu_matrix_wdi_1_0),
        .wdemux_di_1 (pu_matrix_wdi_1_1),
        .wdemux_di_2 (pu_matrix_wdi_1_2), 

        .wdemux_do_0_0 (wdemux_to_pu_arr[0][1][0]),
        .wdemux_do_0_1 (wdemux_to_pu_arr[0][1][1]),
        .wdemux_do_0_2 (wdemux_to_pu_arr[0][1][2]),
        .wdemux_do_1_0 (wdemux_to_pu_arr[1][1][0]),
        .wdemux_do_1_1 (wdemux_to_pu_arr[1][1][1]),
        .wdemux_do_1_2 (wdemux_to_pu_arr[1][1][2]),
        .wdemux_do_2_0 (wdemux_to_pu_arr[2][1][0]),
        .wdemux_do_2_1 (wdemux_to_pu_arr[2][1][1]),
        .wdemux_do_2_2 (wdemux_to_pu_arr[2][1][2]),

        .wdemux_sel (pu_matrix_wsel_1)
    );

    fs_accel_wdemux wdemux_2 (
        .wdemux_di_0 (pu_matrix_wdi_2_0),
        .wdemux_di_1 (pu_matrix_wdi_2_1),
        .wdemux_di_2 (pu_matrix_wdi_2_2), 

        .wdemux_do_0_0 (wdemux_to_pu_arr[0][2][0]),
        .wdemux_do_0_1 (wdemux_to_pu_arr[0][2][1]),
        .wdemux_do_0_2 (wdemux_to_pu_arr[0][2][2]),
        .wdemux_do_1_0 (wdemux_to_pu_arr[1][2][0]),
        .wdemux_do_1_1 (wdemux_to_pu_arr[1][2][1]),
        .wdemux_do_1_2 (wdemux_to_pu_arr[1][2][2]),
        .wdemux_do_2_0 (wdemux_to_pu_arr[2][2][0]),
        .wdemux_do_2_1 (wdemux_to_pu_arr[2][2][1]),
        .wdemux_do_2_2 (wdemux_to_pu_arr[2][2][2]),

        .wdemux_sel (pu_matrix_wsel_2)
    );

    // Input Demuxer
    fs_accel_idemux idemux_0 (
        .idemux_di_0 (pu_matrix_idi_0_0),
        .idemux_di_1 (pu_matrix_idi_0_1),
        .idemux_di_2 (pu_matrix_idi_0_2),

        .idemux_do_0_0 (idemux_to_pu_arr[0][0][0]),
        .idemux_do_0_1 (idemux_to_pu_arr[0][0][1]),
        .idemux_do_0_2 (idemux_to_pu_arr[0][0][2]),
        .idemux_do_1_0 (idemux_to_pu_arr[0][1][0]),
        .idemux_do_1_1 (idemux_to_pu_arr[0][1][1]),
        .idemux_do_1_2 (idemux_to_pu_arr[0][1][2]),
        .idemux_do_2_0 (idemux_to_pu_arr[0][2][0]),
        .idemux_do_2_1 (idemux_to_pu_arr[0][2][1]),
        .idemux_do_2_2 (idemux_to_pu_arr[0][2][2]),

        .idemux_sel (pu_matrix_isel_0)
    );

    fs_accel_idemux idemux_1 (
        .idemux_di_0 (pu_matrix_idi_1_0),
        .idemux_di_1 (pu_matrix_idi_1_1),
        .idemux_di_2 (pu_matrix_idi_1_2),

        .idemux_do_0_0 (idemux_to_pu_arr[1][0][0]),
        .idemux_do_0_1 (idemux_to_pu_arr[1][0][1]),
        .idemux_do_0_2 (idemux_to_pu_arr[1][0][2]),
        .idemux_do_1_0 (idemux_to_pu_arr[1][1][0]),
        .idemux_do_1_1 (idemux_to_pu_arr[1][1][1]),
        .idemux_do_1_2 (idemux_to_pu_arr[1][1][2]),
        .idemux_do_2_0 (idemux_to_pu_arr[1][2][0]),
        .idemux_do_2_1 (idemux_to_pu_arr[1][2][1]),
        .idemux_do_2_2 (idemux_to_pu_arr[1][2][2]),

        .idemux_sel (pu_matrix_isel_1)
    );

    fs_accel_idemux idemux_2 (
        .idemux_di_0 (pu_matrix_idi_2_0),
        .idemux_di_1 (pu_matrix_idi_2_1),
        .idemux_di_2 (pu_matrix_idi_2_2),

        .idemux_do_0_0 (idemux_to_pu_arr[2][0][0]),
        .idemux_do_0_1 (idemux_to_pu_arr[2][0][1]),
        .idemux_do_0_2 (idemux_to_pu_arr[2][0][2]),
        .idemux_do_1_0 (idemux_to_pu_arr[2][1][0]),
        .idemux_do_1_1 (idemux_to_pu_arr[2][1][1]),
        .idemux_do_1_2 (idemux_to_pu_arr[2][1][2]),
        .idemux_do_2_0 (idemux_to_pu_arr[2][2][0]),
        .idemux_do_2_1 (idemux_to_pu_arr[2][2][1]),
        .idemux_do_2_2 (idemux_to_pu_arr[2][2][2]),

        .idemux_sel (pu_matrix_isel_2)
    );

    // Processing Array
    fs_accel_pu_array pu_array_0 (
        // Data Sigs
        .pu_arr_wdi_0_0_0 (wdemux_to_pu_arr[0][0][0]),
        .pu_arr_wdi_0_0_1 (wdemux_to_pu_arr[0][0][1]),
        .pu_arr_wdi_0_0_2 (wdemux_to_pu_arr[0][0][2]),
        .pu_arr_wdi_0_1_0 (wdemux_to_pu_arr[0][1][0]),
        .pu_arr_wdi_0_1_1 (wdemux_to_pu_arr[0][1][1]),
        .pu_arr_wdi_0_1_2 (wdemux_to_pu_arr[0][1][2]),
        .pu_arr_wdi_0_2_0 (wdemux_to_pu_arr[0][2][0]),
        .pu_arr_wdi_0_2_1 (wdemux_to_pu_arr[0][2][1]),
        .pu_arr_wdi_0_2_2 (wdemux_to_pu_arr[0][2][2]),
        .pu_arr_wdi_1_0_0 (wdemux_to_pu_arr[1][0][0]),
        .pu_arr_wdi_1_0_1 (wdemux_to_pu_arr[1][0][1]),
        .pu_arr_wdi_1_0_2 (wdemux_to_pu_arr[1][0][2]),
        .pu_arr_wdi_1_1_0 (wdemux_to_pu_arr[1][1][0]),
        .pu_arr_wdi_1_1_1 (wdemux_to_pu_arr[1][1][1]),
        .pu_arr_wdi_1_1_2 (wdemux_to_pu_arr[1][1][2]),
        .pu_arr_wdi_1_2_0 (wdemux_to_pu_arr[1][2][0]),
        .pu_arr_wdi_1_2_1 (wdemux_to_pu_arr[1][2][1]),
        .pu_arr_wdi_1_2_2 (wdemux_to_pu_arr[1][2][2]),
        .pu_arr_wdi_2_0_0 (wdemux_to_pu_arr[2][0][0]),
        .pu_arr_wdi_2_0_1 (wdemux_to_pu_arr[2][0][1]),
        .pu_arr_wdi_2_0_2 (wdemux_to_pu_arr[2][0][2]),
        .pu_arr_wdi_2_1_0 (wdemux_to_pu_arr[2][1][0]),
        .pu_arr_wdi_2_1_1 (wdemux_to_pu_arr[2][1][1]),
        .pu_arr_wdi_2_1_2 (wdemux_to_pu_arr[2][1][2]),
        .pu_arr_wdi_2_2_0 (wdemux_to_pu_arr[2][2][0]),
        .pu_arr_wdi_2_2_1 (wdemux_to_pu_arr[2][2][1]),
        .pu_arr_wdi_2_2_2 (wdemux_to_pu_arr[2][2][2]),

        .pu_arr_idi_0_0 (idemux_to_pu_arr[0][0][0]),
        .pu_arr_idi_0_1 (idemux_to_pu_arr[0][0][1]),
        .pu_arr_idi_0_2 (idemux_to_pu_arr[0][0][2]),
        .pu_arr_idi_1_0 (idemux_to_pu_arr[0][1][0]),
        .pu_arr_idi_1_1 (idemux_to_pu_arr[0][1][1]),
        .pu_arr_idi_1_2 (idemux_to_pu_arr[0][1][2]),
        .pu_arr_idi_2_0 (idemux_to_pu_arr[0][2][0]),
        .pu_arr_idi_2_1 (idemux_to_pu_arr[0][2][1]),
        .pu_arr_idi_2_2 (idemux_to_pu_arr[0][2][2]),

        .pu_arr_odo_0 (pu_matrix_odo_0_0),
        .pu_arr_odo_1 (pu_matrix_odo_0_1),
        .pu_arr_odo_2 (pu_matrix_odo_0_2),

        // Config Sigs
        .pu_arr_is_conv_layer   (pu_matrix_is_conv_layer),
        .pu_arr_conv_dir        (pu_matrix_conv_dir),
        .pu_arr_input_offset    (pu_matrix_input_offset),

        // Ctrl Sigs
        .wreg_enb_0_0   (pu_matrix_wreg_enb_0_0_0),
        .wreg_enb_0_1   (pu_matrix_wreg_enb_0_0_1),
        .wreg_enb_0_2   (pu_matrix_wreg_enb_0_0_2),
        .wreg_enb_1_0   (pu_matrix_wreg_enb_0_1_0),
        .wreg_enb_1_1   (pu_matrix_wreg_enb_0_1_1),
        .wreg_enb_1_2   (pu_matrix_wreg_enb_0_1_2),
        .wreg_enb_2_0   (pu_matrix_wreg_enb_0_2_0),
        .wreg_enb_2_1   (pu_matrix_wreg_enb_0_2_1),
        .wreg_enb_2_2   (pu_matrix_wreg_enb_0_2_2),

        .ireg_enb_0     (pu_matrix_ireg_enb_0_0),
        .ireg_enb_1     (pu_matrix_ireg_enb_0_1),
        .ireg_enb_2     (pu_matrix_ireg_enb_0_2),

        .pu_enb_0       (pu_enb_0_0),
        .pu_enb_1       (pu_enb_0_1),
        .pu_enb_2       (pu_enb_0_2),

        // Mandatory Sigs
        .rdy    (rdy_0),
        .clk    (clk),
        .resetn (resetn)
    );

    fs_accel_pu_array pu_array_1 (
        // Data Sigs
        .pu_arr_wdi_0_0_0 (wdemux_to_pu_arr[0][0][0]),
        .pu_arr_wdi_0_0_1 (wdemux_to_pu_arr[0][0][1]),
        .pu_arr_wdi_0_0_2 (wdemux_to_pu_arr[0][0][2]),
        .pu_arr_wdi_0_1_0 (wdemux_to_pu_arr[0][1][0]),
        .pu_arr_wdi_0_1_1 (wdemux_to_pu_arr[0][1][1]),
        .pu_arr_wdi_0_1_2 (wdemux_to_pu_arr[0][1][2]),
        .pu_arr_wdi_0_2_0 (wdemux_to_pu_arr[0][2][0]),
        .pu_arr_wdi_0_2_1 (wdemux_to_pu_arr[0][2][1]),
        .pu_arr_wdi_0_2_2 (wdemux_to_pu_arr[0][2][2]),
        .pu_arr_wdi_1_0_0 (wdemux_to_pu_arr[1][0][0]),
        .pu_arr_wdi_1_0_1 (wdemux_to_pu_arr[1][0][1]),
        .pu_arr_wdi_1_0_2 (wdemux_to_pu_arr[1][0][2]),
        .pu_arr_wdi_1_1_0 (wdemux_to_pu_arr[1][1][0]),
        .pu_arr_wdi_1_1_1 (wdemux_to_pu_arr[1][1][1]),
        .pu_arr_wdi_1_1_2 (wdemux_to_pu_arr[1][1][2]),
        .pu_arr_wdi_1_2_0 (wdemux_to_pu_arr[1][2][0]),
        .pu_arr_wdi_1_2_1 (wdemux_to_pu_arr[1][2][1]),
        .pu_arr_wdi_1_2_2 (wdemux_to_pu_arr[1][2][2]),
        .pu_arr_wdi_2_0_0 (wdemux_to_pu_arr[2][0][0]),
        .pu_arr_wdi_2_0_1 (wdemux_to_pu_arr[2][0][1]),
        .pu_arr_wdi_2_0_2 (wdemux_to_pu_arr[2][0][2]),
        .pu_arr_wdi_2_1_0 (wdemux_to_pu_arr[2][1][0]),
        .pu_arr_wdi_2_1_1 (wdemux_to_pu_arr[2][1][1]),
        .pu_arr_wdi_2_1_2 (wdemux_to_pu_arr[2][1][2]),
        .pu_arr_wdi_2_2_0 (wdemux_to_pu_arr[2][2][0]),
        .pu_arr_wdi_2_2_1 (wdemux_to_pu_arr[2][2][1]),
        .pu_arr_wdi_2_2_2 (wdemux_to_pu_arr[2][2][2]),

        .pu_arr_idi_0_0 (idemux_to_pu_arr[1][0][0]),
        .pu_arr_idi_0_1 (idemux_to_pu_arr[1][0][1]),
        .pu_arr_idi_0_2 (idemux_to_pu_arr[1][0][2]),
        .pu_arr_idi_1_0 (idemux_to_pu_arr[1][1][0]),
        .pu_arr_idi_1_1 (idemux_to_pu_arr[1][1][1]),
        .pu_arr_idi_1_2 (idemux_to_pu_arr[1][1][2]),
        .pu_arr_idi_2_0 (idemux_to_pu_arr[1][2][0]),
        .pu_arr_idi_2_1 (idemux_to_pu_arr[1][2][1]),
        .pu_arr_idi_2_2 (idemux_to_pu_arr[1][2][2]),

        .pu_arr_odo_0 (pu_matrix_odo_1_0),
        .pu_arr_odo_1 (pu_matrix_odo_1_1),
        .pu_arr_odo_2 (pu_matrix_odo_1_2),

        // Config Sigs
        .pu_arr_is_conv_layer   (pu_matrix_is_conv_layer),
        .pu_arr_conv_dir        (pu_matrix_conv_dir),
        .pu_arr_input_offset    (pu_matrix_input_offset),

        // Ctrl Sigs
        .wreg_enb_0_0   (pu_matrix_wreg_enb_1_0_0),
        .wreg_enb_0_1   (pu_matrix_wreg_enb_1_0_1),
        .wreg_enb_0_2   (pu_matrix_wreg_enb_1_0_2),
        .wreg_enb_1_0   (pu_matrix_wreg_enb_1_1_0),
        .wreg_enb_1_1   (pu_matrix_wreg_enb_1_1_1),
        .wreg_enb_1_2   (pu_matrix_wreg_enb_1_1_2),
        .wreg_enb_2_0   (pu_matrix_wreg_enb_1_2_0),
        .wreg_enb_2_1   (pu_matrix_wreg_enb_1_2_1),
        .wreg_enb_2_2   (pu_matrix_wreg_enb_1_2_2),

        .ireg_enb_0     (pu_matrix_ireg_enb_1_0),
        .ireg_enb_1     (pu_matrix_ireg_enb_1_1),
        .ireg_enb_2     (pu_matrix_ireg_enb_1_2),

        .pu_enb_0       (pu_enb_1_0),
        .pu_enb_1       (pu_enb_1_1),
        .pu_enb_2       (pu_enb_1_2),

        // Mandatory Sigs
        .rdy    (rdy_1),
        .clk    (clk),
        .resetn (resetn)
    );

    fs_accel_pu_array pu_array_2 (
        // Data Sigs
        .pu_arr_wdi_0_0_0 (wdemux_to_pu_arr[0][0][0]),
        .pu_arr_wdi_0_0_1 (wdemux_to_pu_arr[0][0][1]),
        .pu_arr_wdi_0_0_2 (wdemux_to_pu_arr[0][0][2]),
        .pu_arr_wdi_0_1_0 (wdemux_to_pu_arr[0][1][0]),
        .pu_arr_wdi_0_1_1 (wdemux_to_pu_arr[0][1][1]),
        .pu_arr_wdi_0_1_2 (wdemux_to_pu_arr[0][1][2]),
        .pu_arr_wdi_0_2_0 (wdemux_to_pu_arr[0][2][0]),
        .pu_arr_wdi_0_2_1 (wdemux_to_pu_arr[0][2][1]),
        .pu_arr_wdi_0_2_2 (wdemux_to_pu_arr[0][2][2]),
        .pu_arr_wdi_1_0_0 (wdemux_to_pu_arr[1][0][0]),
        .pu_arr_wdi_1_0_1 (wdemux_to_pu_arr[1][0][1]),
        .pu_arr_wdi_1_0_2 (wdemux_to_pu_arr[1][0][2]),
        .pu_arr_wdi_1_1_0 (wdemux_to_pu_arr[1][1][0]),
        .pu_arr_wdi_1_1_1 (wdemux_to_pu_arr[1][1][1]),
        .pu_arr_wdi_1_1_2 (wdemux_to_pu_arr[1][1][2]),
        .pu_arr_wdi_1_2_0 (wdemux_to_pu_arr[1][2][0]),
        .pu_arr_wdi_1_2_1 (wdemux_to_pu_arr[1][2][1]),
        .pu_arr_wdi_1_2_2 (wdemux_to_pu_arr[1][2][2]),
        .pu_arr_wdi_2_0_0 (wdemux_to_pu_arr[2][0][0]),
        .pu_arr_wdi_2_0_1 (wdemux_to_pu_arr[2][0][1]),
        .pu_arr_wdi_2_0_2 (wdemux_to_pu_arr[2][0][2]),
        .pu_arr_wdi_2_1_0 (wdemux_to_pu_arr[2][1][0]),
        .pu_arr_wdi_2_1_1 (wdemux_to_pu_arr[2][1][1]),
        .pu_arr_wdi_2_1_2 (wdemux_to_pu_arr[2][1][2]),
        .pu_arr_wdi_2_2_0 (wdemux_to_pu_arr[2][2][0]),
        .pu_arr_wdi_2_2_1 (wdemux_to_pu_arr[2][2][1]),
        .pu_arr_wdi_2_2_2 (wdemux_to_pu_arr[2][2][2]),

        .pu_arr_idi_0_0 (idemux_to_pu_arr[2][0][0]),
        .pu_arr_idi_0_1 (idemux_to_pu_arr[2][0][1]),
        .pu_arr_idi_0_2 (idemux_to_pu_arr[2][0][2]),
        .pu_arr_idi_1_0 (idemux_to_pu_arr[2][1][0]),
        .pu_arr_idi_1_1 (idemux_to_pu_arr[2][1][1]),
        .pu_arr_idi_1_2 (idemux_to_pu_arr[2][1][2]),
        .pu_arr_idi_2_0 (idemux_to_pu_arr[2][2][0]),
        .pu_arr_idi_2_1 (idemux_to_pu_arr[2][2][1]),
        .pu_arr_idi_2_2 (idemux_to_pu_arr[2][2][2]),

        .pu_arr_odo_0 (pu_matrix_odo_2_0),
        .pu_arr_odo_1 (pu_matrix_odo_2_1),
        .pu_arr_odo_2 (pu_matrix_odo_2_2),

        // Config Sigs
        .pu_arr_is_conv_layer   (pu_matrix_is_conv_layer),
        .pu_arr_conv_dir        (pu_matrix_conv_dir),
        .pu_arr_input_offset    (pu_matrix_input_offset),

        // Ctrl Sigs
        .wreg_enb_0_0   (pu_matrix_wreg_enb_2_0_0),
        .wreg_enb_0_1   (pu_matrix_wreg_enb_2_0_1),
        .wreg_enb_0_2   (pu_matrix_wreg_enb_2_0_2),
        .wreg_enb_1_0   (pu_matrix_wreg_enb_2_1_0),
        .wreg_enb_1_1   (pu_matrix_wreg_enb_2_1_1),
        .wreg_enb_1_2   (pu_matrix_wreg_enb_2_1_2),
        .wreg_enb_2_0   (pu_matrix_wreg_enb_2_2_0),
        .wreg_enb_2_1   (pu_matrix_wreg_enb_2_2_1),
        .wreg_enb_2_2   (pu_matrix_wreg_enb_2_2_2),

        .ireg_enb_0     (pu_matrix_ireg_enb_2_0),
        .ireg_enb_1     (pu_matrix_ireg_enb_2_1),
        .ireg_enb_2     (pu_matrix_ireg_enb_2_2),

        .pu_enb_0       (pu_enb_2_0),
        .pu_enb_1       (pu_enb_2_1),
        .pu_enb_2       (pu_enb_2_2),

        // Mandatory Sigs
        .rdy    (rdy_2),
        .clk    (clk),
        .resetn (resetn)
    );
endmodule