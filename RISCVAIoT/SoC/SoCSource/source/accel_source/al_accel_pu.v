module al_accel_pu(
    // Data Sigs
    input [ 7:0]  pu_wdi_0_0,
    input [ 7:0]  pu_wdi_0_1,
    input [ 7:0]  pu_wdi_0_2,
    input [ 7:0]  pu_wdi_1_0,
    input [ 7:0]  pu_wdi_1_1,
    input [ 7:0]  pu_wdi_1_2,
    input [ 7:0]  pu_wdi_2_0,
    input [ 7:0]  pu_wdi_2_1,
    input [ 7:0]  pu_wdi_2_2,

    input [ 7:0]  pu_idi_0,
    input [ 7:0]  pu_idi_1,
    input [ 7:0]  pu_idi_2,

    output [31:0] pu_odo_0,
    output [31:0] pu_odo_1,
    output [31:0] pu_odo_2,

    // Config Sigs
    input  [31:0] pu_input_offset,

    // Ctrl Sigs
    input   enb,
    output  rdy,

    // Mandatory Sigs
    input   clk,
    input   resetn
);
    wire[31:0] lut_to_mac_dat_0[7:0];
    wire[31:0] lut_to_mac_dat_1[7:0];
    wire[31:0] lut_to_mac_dat_2[7:0];
    wire[ 7:0] lpureg_to_mac_dat_0[2:0];
    wire[ 7:0] lpureg_to_mac_dat_1[2:0];
    wire[ 7:0] lpureg_to_mac_dat_2[2:0];
    wire mac_ld_ctrl_0;
    wire mac_ld_ctrl_1;
    wire mac_ld_ctrl_2;
    wire rdy_0, rdy_1, rdy_2;

    assign rdy = rdy_0 || rdy_1 || rdy_2;

    // LUT - MAC - LPUREG pair 0
    al_accel_lpureg lpureg_0 (
        .lpureg_di_0 (pu_wdi_0_0),
        .lpureg_di_1 (pu_wdi_0_1),
        .lpureg_di_2 (pu_wdi_0_2),

        .lpureg_do_0 (lpureg_to_mac_dat_0[0]),
        .lpureg_do_1 (lpureg_to_mac_dat_0[1]),
        .lpureg_do_2 (lpureg_to_mac_dat_0[2]),

        .lpureg_ld_wrn (mac_ld_ctrl_0),

        .enb    (enb),
        .clk    (clk),
        .resetn (resetn)
    );

    al_accel_lut lut_0(
        .lut_idi_0  (pu_idi_0),
        .lut_idi_1  (pu_idi_1),
        .lut_idi_2  (pu_idi_2),

        .lut_do_0   (lut_to_mac_dat_0[0]),
        .lut_do_1   (lut_to_mac_dat_0[1]),
        .lut_do_2   (lut_to_mac_dat_0[2]),
        .lut_do_3   (lut_to_mac_dat_0[3]),
        .lut_do_4   (lut_to_mac_dat_0[4]),
        .lut_do_5   (lut_to_mac_dat_0[5]),
        .lut_do_6   (lut_to_mac_dat_0[6]),
        .lut_do_7   (lut_to_mac_dat_0[7]),

        .lut_wdi_sbit_0 (pu_wdi_0_0[7]),
        .lut_wdi_sbit_1 (pu_wdi_0_1[7]), 
        .lut_wdi_sbit_2 (pu_wdi_0_2[7]),

        .lut_input_offset   (pu_input_offset),

        .lut_ld_wrn (mac_ld_ctrl_0),

        .enb    (enb),
        .clk    (clk),
        .resetn (resetn)
    );

    al_accel_mac mac_0(
        .mac_wdi_0  (lpureg_to_mac_dat_0[0]),
        .mac_wdi_1  (lpureg_to_mac_dat_0[1]),
        .mac_wdi_2  (lpureg_to_mac_dat_0[2]),

        .mac_idi_0  (lut_to_mac_dat_0[0]),
        .mac_idi_1  (lut_to_mac_dat_0[1]),
        .mac_idi_2  (lut_to_mac_dat_0[2]),
        .mac_idi_3  (lut_to_mac_dat_0[3]),
        .mac_idi_4  (lut_to_mac_dat_0[4]),
        .mac_idi_5  (lut_to_mac_dat_0[5]),
        .mac_idi_6  (lut_to_mac_dat_0[6]),
        .mac_idi_7  (lut_to_mac_dat_0[7]),

        .mac_odo    (pu_odo_0),

        .mac_load   (mac_ld_ctrl_0),
        
        .enb    (enb),
        .rdy    (rdy_0),
        .clk    (clk),
        .resetn (resetn)
    );

    // LUT - MAC - LPUREG pair 1
    al_accel_lpureg lpureg_1 (
        .lpureg_di_0 (pu_wdi_1_0),
        .lpureg_di_1 (pu_wdi_1_1),
        .lpureg_di_2 (pu_wdi_1_2),

        .lpureg_do_0 (lpureg_to_mac_dat_1[0]),
        .lpureg_do_1 (lpureg_to_mac_dat_1[1]),
        .lpureg_do_2 (lpureg_to_mac_dat_1[2]),

        .lpureg_ld_wrn (mac_ld_ctrl_1),

        .enb    (enb),
        .clk    (clk),
        .resetn (resetn)
    );

    al_accel_lut lut_1(
        .lut_idi_0  (pu_idi_0),
        .lut_idi_1  (pu_idi_1),
        .lut_idi_2  (pu_idi_2),

        .lut_do_0   (lut_to_mac_dat_1[0]),
        .lut_do_1   (lut_to_mac_dat_1[1]),
        .lut_do_2   (lut_to_mac_dat_1[2]),
        .lut_do_3   (lut_to_mac_dat_1[3]),
        .lut_do_4   (lut_to_mac_dat_1[4]),
        .lut_do_5   (lut_to_mac_dat_1[5]),
        .lut_do_6   (lut_to_mac_dat_1[6]),
        .lut_do_7   (lut_to_mac_dat_1[7]),

        .lut_wdi_sbit_0 (pu_wdi_1_0[7]),
        .lut_wdi_sbit_1 (pu_wdi_1_1[7]), 
        .lut_wdi_sbit_2 (pu_wdi_1_2[7]),

        .lut_input_offset   (pu_input_offset),

        .lut_ld_wrn (mac_ld_ctrl_1),

        .enb    (enb),
        .clk    (clk),
        .resetn (resetn)
    );

    al_accel_mac mac_1(
        .mac_wdi_0  (lpureg_to_mac_dat_1[0]),
        .mac_wdi_1  (lpureg_to_mac_dat_1[1]),
        .mac_wdi_2  (lpureg_to_mac_dat_1[2]),

        .mac_idi_0  (lut_to_mac_dat_1[0]),
        .mac_idi_1  (lut_to_mac_dat_1[1]),
        .mac_idi_2  (lut_to_mac_dat_1[2]),
        .mac_idi_3  (lut_to_mac_dat_1[3]),
        .mac_idi_4  (lut_to_mac_dat_1[4]),
        .mac_idi_5  (lut_to_mac_dat_1[5]),
        .mac_idi_6  (lut_to_mac_dat_1[6]),
        .mac_idi_7  (lut_to_mac_dat_1[7]),

        .mac_odo    (pu_odo_1),

        .mac_load   (mac_ld_ctrl_1),
        
        .enb    (enb),
        .rdy    (rdy_1),
        .clk    (clk),
        .resetn (resetn)
    );

    // LUT - MAC - LPUREG pair 2
    al_accel_lpureg lpureg_2 (
        .lpureg_di_0 (pu_wdi_2_0),
        .lpureg_di_1 (pu_wdi_2_1),
        .lpureg_di_2 (pu_wdi_2_2),

        .lpureg_do_0 (lpureg_to_mac_dat_2[0]),
        .lpureg_do_1 (lpureg_to_mac_dat_2[1]),
        .lpureg_do_2 (lpureg_to_mac_dat_2[2]),

        .lpureg_ld_wrn (mac_ld_ctrl_2),

        .enb    (enb),
        .clk    (clk),
        .resetn (resetn)
    );

    al_accel_lut lut_2(
        .lut_idi_0  (pu_idi_0),
        .lut_idi_1  (pu_idi_1),
        .lut_idi_2  (pu_idi_2),

        .lut_do_0   (lut_to_mac_dat_2[0]),
        .lut_do_1   (lut_to_mac_dat_2[1]),
        .lut_do_2   (lut_to_mac_dat_2[2]),
        .lut_do_3   (lut_to_mac_dat_2[3]),
        .lut_do_4   (lut_to_mac_dat_2[4]),
        .lut_do_5   (lut_to_mac_dat_2[5]),
        .lut_do_6   (lut_to_mac_dat_2[6]),
        .lut_do_7   (lut_to_mac_dat_2[7]),

        .lut_wdi_sbit_0 (pu_wdi_2_0[7]),
        .lut_wdi_sbit_1 (pu_wdi_2_1[7]), 
        .lut_wdi_sbit_2 (pu_wdi_2_2[7]),

        .lut_input_offset   (pu_input_offset),

        .lut_ld_wrn (mac_ld_ctrl_2),

        .enb    (enb),
        .clk    (clk),
        .resetn (resetn)
    );

    al_accel_mac mac_2(
        .mac_wdi_0  (lpureg_to_mac_dat_2[0]),
        .mac_wdi_1  (lpureg_to_mac_dat_2[1]),
        .mac_wdi_2  (lpureg_to_mac_dat_2[2]),

        .mac_idi_0  (lut_to_mac_dat_2[0]),
        .mac_idi_1  (lut_to_mac_dat_2[1]),
        .mac_idi_2  (lut_to_mac_dat_2[2]),
        .mac_idi_3  (lut_to_mac_dat_2[3]),
        .mac_idi_4  (lut_to_mac_dat_2[4]),
        .mac_idi_5  (lut_to_mac_dat_2[5]),
        .mac_idi_6  (lut_to_mac_dat_2[6]),
        .mac_idi_7  (lut_to_mac_dat_2[7]),

        .mac_odo    (pu_odo_2),

        .mac_load   (mac_ld_ctrl_2),
        
        .enb    (enb),
        .rdy    (rdy_2),
        .clk    (clk),
        .resetn (resetn)
    );

endmodule