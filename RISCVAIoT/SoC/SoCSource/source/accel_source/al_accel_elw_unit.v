module al_accel_elw_unit (
    // Data Sigs
    input  [31:0] elew_di_0_0,
    input  [31:0] elew_di_0_1,
    input  [31:0] elew_di_0_2,

    input  [ 7:0] elew_di_1_0,
    input  [ 7:0] elew_di_1_1,
    input  [ 7:0] elew_di_1_2,

    output [ 7:0] elew_do_0_0,
    output [ 7:0] elew_do_0_1,
    output [ 7:0] elew_do_0_2,

    output [ 7:0] elew_do_1,

    // Configs Sigs
    input  [31:0] elew_quant_muler_0,
    input  [31:0] elew_quant_muler_1,
    input  [31:0] elew_quant_muler_2,

    input  [ 7:0] elew_quant_rshift_0,
    input  [ 7:0] elew_quant_rshift_1,
    input  [ 7:0] elew_quant_rshift_2,

    input  [31:0] elew_output_offset,

    input  [ 3:0] elew_act_func_typ,
    // Ctrl Sigs
    input   quant_act_func_enb_0,
    input   quant_act_func_enb_1,
    input   quant_act_func_enb_2,
    output  quant_act_func_rdy_0,
    output  quant_act_func_rdy_1,
    output  quant_act_func_rdy_2, 
    input   cp_clr,
    input   cp2h_enb,
    input   cp2w_enb,
    input   cp_enb,

    // Mandatory Sigs
    input   clk,
    input   resetn
);    
    wire [31:0] quant_to_act_func_0,
                quant_to_act_func_1,
                quant_to_act_func_2;

    wire [31:0] act_func_do_0,
                act_func_do_1,
                act_func_do_2;

    wire [31:0] acc_SUB_offset_0,
                acc_SUB_offset_1,
                acc_SUB_offset_2;


    wire [63:0] lut_to_quant_0_0,
                lut_to_quant_0_1,
                lut_to_quant_0_2,
                lut_to_quant_0_3,
                lut_to_quant_0_4,
                lut_to_quant_0_5,
                lut_to_quant_0_6,
                lut_to_quant_0_7,
                lut_to_quant_0_8,
                lut_to_quant_0_9,
                lut_to_quant_0_10,
                lut_to_quant_0_11,
                lut_to_quant_0_12,
                lut_to_quant_0_13,
                lut_to_quant_0_14,
                lut_to_quant_0_15;

    wire [63:0] lut_to_quant_1_0,
                lut_to_quant_1_1,
                lut_to_quant_1_2,
                lut_to_quant_1_3,
                lut_to_quant_1_4,
                lut_to_quant_1_5,
                lut_to_quant_1_6,
                lut_to_quant_1_7,
                lut_to_quant_1_8,
                lut_to_quant_1_9,
                lut_to_quant_1_10,
                lut_to_quant_1_11,
                lut_to_quant_1_12,
                lut_to_quant_1_13,
                lut_to_quant_1_14,
                lut_to_quant_1_15;

    wire [63:0] lut_to_quant_2_0,
                lut_to_quant_2_1,
                lut_to_quant_2_2,
                lut_to_quant_2_3,
                lut_to_quant_2_4,
                lut_to_quant_2_5,
                lut_to_quant_2_6,
                lut_to_quant_2_7,
                lut_to_quant_2_8,
                lut_to_quant_2_9,
                lut_to_quant_2_10,
                lut_to_quant_2_11,
                lut_to_quant_2_12,
                lut_to_quant_2_13,
                lut_to_quant_2_14,
                lut_to_quant_2_15;

    // Pair 0
    al_accel_quant_lut  quant_lut_0 (
        .quant_muler    (elew_quant_muler_0),
        
        .quant_lut_val_0    (lut_to_quant_0_0),
        .quant_lut_val_1    (lut_to_quant_0_1),
        .quant_lut_val_2    (lut_to_quant_0_2),
        .quant_lut_val_3    (lut_to_quant_0_3),
        .quant_lut_val_4    (lut_to_quant_0_4),
        .quant_lut_val_5    (lut_to_quant_0_5),
        .quant_lut_val_6    (lut_to_quant_0_6),
        .quant_lut_val_7    (lut_to_quant_0_7),
        .quant_lut_val_8    (lut_to_quant_0_8),
        .quant_lut_val_9    (lut_to_quant_0_9),
        .quant_lut_val_10   (lut_to_quant_0_10),
        .quant_lut_val_11   (lut_to_quant_0_11),
        .quant_lut_val_12   (lut_to_quant_0_12),
        .quant_lut_val_13   (lut_to_quant_0_13),
        .quant_lut_val_14   (lut_to_quant_0_14),
        .quant_lut_val_15   (lut_to_quant_0_15)
    );

    al_accel_quant_unit quant_unit_0 (
        .quant_di       (elew_di_0_0),
        .quant_do       (quant_to_act_func_0),

        .quant_rshift   (elew_quant_rshift_0),

        .quant_lut_val_0    (lut_to_quant_0_0),
        .quant_lut_val_1    (lut_to_quant_0_1),
        .quant_lut_val_2    (lut_to_quant_0_2),
        .quant_lut_val_3    (lut_to_quant_0_3),
        .quant_lut_val_4    (lut_to_quant_0_4),
        .quant_lut_val_5    (lut_to_quant_0_5),
        .quant_lut_val_6    (lut_to_quant_0_6),
        .quant_lut_val_7    (lut_to_quant_0_7),
        .quant_lut_val_8    (lut_to_quant_0_8),
        .quant_lut_val_9    (lut_to_quant_0_9),
        .quant_lut_val_10   (lut_to_quant_0_10),
        .quant_lut_val_11   (lut_to_quant_0_11),
        .quant_lut_val_12   (lut_to_quant_0_12),
        .quant_lut_val_13   (lut_to_quant_0_13),
        .quant_lut_val_14   (lut_to_quant_0_14),
        .quant_lut_val_15   (lut_to_quant_0_15),

        .enb    (quant_act_func_enb_0),
        .rdy    (quant_act_func_rdy_0),
        .clk    (clk),
        .resetn (resetn)
    );

    al_accel_act_func_unit act_func_unit_0 (
        .act_func_di    (quant_to_act_func_0),
        // .act_func_do    (elew_do_0_0),
        .act_func_do    (act_func_do_0),

        .act_func_typ   (elew_act_func_typ)
    );

    // Pair 1
    al_accel_quant_lut  quant_lut_1 (
        .quant_muler    (elew_quant_muler_1),
        
        .quant_lut_val_0    (lut_to_quant_1_0),
        .quant_lut_val_1    (lut_to_quant_1_1),
        .quant_lut_val_2    (lut_to_quant_1_2),
        .quant_lut_val_3    (lut_to_quant_1_3),
        .quant_lut_val_4    (lut_to_quant_1_4),
        .quant_lut_val_5    (lut_to_quant_1_5),
        .quant_lut_val_6    (lut_to_quant_1_6),
        .quant_lut_val_7    (lut_to_quant_1_7),
        .quant_lut_val_8    (lut_to_quant_1_8),
        .quant_lut_val_9    (lut_to_quant_1_9),
        .quant_lut_val_10   (lut_to_quant_1_10),
        .quant_lut_val_11   (lut_to_quant_1_11),
        .quant_lut_val_12   (lut_to_quant_1_12),
        .quant_lut_val_13   (lut_to_quant_1_13),
        .quant_lut_val_14   (lut_to_quant_1_14),
        .quant_lut_val_15   (lut_to_quant_1_15)
    );

    al_accel_quant_unit quant_unit_1 (
        .quant_di       (elew_di_0_1),
        .quant_do       (quant_to_act_func_1),

        .quant_rshift   (elew_quant_rshift_1),

        .quant_lut_val_0    (lut_to_quant_1_0),
        .quant_lut_val_1    (lut_to_quant_1_1),
        .quant_lut_val_2    (lut_to_quant_1_2),
        .quant_lut_val_3    (lut_to_quant_1_3),
        .quant_lut_val_4    (lut_to_quant_1_4),
        .quant_lut_val_5    (lut_to_quant_1_5),
        .quant_lut_val_6    (lut_to_quant_1_6),
        .quant_lut_val_7    (lut_to_quant_1_7),
        .quant_lut_val_8    (lut_to_quant_1_8),
        .quant_lut_val_9    (lut_to_quant_1_9),
        .quant_lut_val_10   (lut_to_quant_1_10),
        .quant_lut_val_11   (lut_to_quant_1_11),
        .quant_lut_val_12   (lut_to_quant_1_12),
        .quant_lut_val_13   (lut_to_quant_1_13),
        .quant_lut_val_14   (lut_to_quant_1_14),
        .quant_lut_val_15   (lut_to_quant_1_15),

        .enb    (quant_act_func_enb_1),
        .rdy    (quant_act_func_rdy_1),
        .clk    (clk),
        .resetn (resetn)
    );

    al_accel_act_func_unit act_func_unit_1 (
        .act_func_di    (quant_to_act_func_1),
        // .act_func_do    (elew_do_0_1),
        .act_func_do    (act_func_do_1),

        .act_func_typ   (elew_act_func_typ)
    );

    // Pair 2
    al_accel_quant_lut  quant_lut_2 (
        .quant_muler    (elew_quant_muler_2),
        
        .quant_lut_val_0    (lut_to_quant_2_0),
        .quant_lut_val_1    (lut_to_quant_2_1),
        .quant_lut_val_2    (lut_to_quant_2_2),
        .quant_lut_val_3    (lut_to_quant_2_3),
        .quant_lut_val_4    (lut_to_quant_2_4),
        .quant_lut_val_5    (lut_to_quant_2_5),
        .quant_lut_val_6    (lut_to_quant_2_6),
        .quant_lut_val_7    (lut_to_quant_2_7),
        .quant_lut_val_8    (lut_to_quant_2_8),
        .quant_lut_val_9    (lut_to_quant_2_9),
        .quant_lut_val_10   (lut_to_quant_2_10),
        .quant_lut_val_11   (lut_to_quant_2_11),
        .quant_lut_val_12   (lut_to_quant_2_12),
        .quant_lut_val_13   (lut_to_quant_2_13),
        .quant_lut_val_14   (lut_to_quant_2_14),
        .quant_lut_val_15   (lut_to_quant_2_15)
    );

    al_accel_quant_unit quant_unit_2 (
        .quant_di       (elew_di_0_2),
        .quant_do       (quant_to_act_func_2),

        .quant_rshift   (elew_quant_rshift_2),

        .quant_lut_val_0    (lut_to_quant_2_0),
        .quant_lut_val_1    (lut_to_quant_2_1),
        .quant_lut_val_2    (lut_to_quant_2_2),
        .quant_lut_val_3    (lut_to_quant_2_3),
        .quant_lut_val_4    (lut_to_quant_2_4),
        .quant_lut_val_5    (lut_to_quant_2_5),
        .quant_lut_val_6    (lut_to_quant_2_6),
        .quant_lut_val_7    (lut_to_quant_2_7),
        .quant_lut_val_8    (lut_to_quant_2_8),
        .quant_lut_val_9    (lut_to_quant_2_9),
        .quant_lut_val_10   (lut_to_quant_2_10),
        .quant_lut_val_11   (lut_to_quant_2_11),
        .quant_lut_val_12   (lut_to_quant_2_12),
        .quant_lut_val_13   (lut_to_quant_2_13),
        .quant_lut_val_14   (lut_to_quant_2_14),
        .quant_lut_val_15   (lut_to_quant_2_15),

        .enb    (quant_act_func_enb_2),
        .rdy    (quant_act_func_rdy_2),
        .clk    (clk),
        .resetn (resetn)
    );

    al_accel_act_func_unit act_func_unit_2 (
        .act_func_di    (quant_to_act_func_2),
        // .act_func_do    (elew_do_0_2),
        .act_func_do    (act_func_do_2),

        .act_func_typ   (elew_act_func_typ)
    );

    // Compare Unit
    al_accel_cp_unit cp_unit (
        .cp_di_0    (elew_di_1_0),
        .cp_di_1    (elew_di_1_1),
        .cp_di_2    (elew_di_1_2),
        
        .cp_do      (elew_do_1),

        .cp_clr     (cp_clr),
        .cp2h_enb   (cp2h_enb),
        .cp2w_enb   (cp2w_enb),

        .enb    (cp_enb),
        .clk    (clk),
        .resetn (resetn)
    );

    assign acc_SUB_offset_0 = act_func_do_0 - elew_output_offset;
    assign acc_SUB_offset_1 = act_func_do_1 - elew_output_offset;
    assign acc_SUB_offset_2 = act_func_do_2 - elew_output_offset;

    assign elew_do_0_0 = acc_SUB_offset_0[7:0];
    assign elew_do_0_1 = acc_SUB_offset_1[7:0];
    assign elew_do_0_2 = acc_SUB_offset_2[7:0];

endmodule
