module fs_accel_elw_unit (
    /* Config Sigs */
    input [ 3:0]  cfg_layer_typ,
    // Data Sigs
    input  [31:0] elew_di_0,
    input  [31:0] elew_di_1,
    input  [31:0] elew_di_2,


    // For Max Pooling 
    input [3:0] sel_demux,
    input [3:0] sel_mux,
    input mpbuf_ld_wrn,
    input cp_enb,
    input buf_enb,
    input resetn_pool,

    output [ 7:0] pool_do_0,
    output [ 7:0] pool_do_1,
    output [ 7:0] pool_do_2,

    output reg [31:0] pool_buf_do_0,
    output reg [31:0] pool_buf_do_1,
    output reg [31:0] pool_buf_do_2,


    // Configs Sigs
    input  [31:0] elew_quant_muler_0,
    input  [31:0] elew_quant_muler_1,
    input  [31:0] elew_quant_muler_2, 

    input  [ 7:0] elew_quant_rshift_0,
    input  [ 7:0] elew_quant_rshift_1,
    input  [ 7:0] elew_quant_rshift_2,
    input  [31:0] elew_output_offset,
    input  [ 3:0] elew_act_func_typ,

    input   pool_ld_wrn,
    input   pool_enb,

    // Ctrl Sigs
    input   quant_act_func_enb_0,
    input   quant_act_func_enb_1,
    input   quant_act_func_enb_2,
    output  quant_act_func_rdy_0,
    output  quant_act_func_rdy_1,
    output  quant_act_func_rdy_2, 

    // Mandatory Sigs
    input   enb,
    input   clk,
    input   resetn
);     
    // Layer Param
    localparam 
        CONV    = 4'd 0,
        DENSE   = 4'd 1,
        MIXED    = 4'd 2;
        
    wire [31:0] quant_to_act_func_0,
                quant_to_act_func_1,
                quant_to_act_func_2;

    wire [31:0] act_func_do_0,
                act_func_do_1,
                act_func_do_2;

    wire [31:0] acc_SUB_offset_0,
                acc_SUB_offset_1,
                acc_SUB_offset_2;

    // For LUT Quantize
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


    wire [7:0] elew_do_0_0, elew_do_0_1, elew_do_0_2;
    
    wire [7:0] cp_do_0, cp_do_1, cp_do_2;

    assign pool_do_0 = (cfg_layer_typ == MIXED) ? cp_do_0 : elew_do_0_0;
    assign pool_do_1 = (cfg_layer_typ == MIXED) ? cp_do_1 : elew_do_0_1;
    assign pool_do_2 = (cfg_layer_typ == MIXED) ? cp_do_2 : elew_do_0_2;

    // Internal wires for pool input
    wire [7:0] act_result_0, act_result_1, act_result_2;

    // PAIR 0
    fs_accel_quant_lut  quant_lut_0 (
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

    fs_accel_quant_unit quant_unit_0 (
        .quant_di       (elew_di_0),
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

    fs_accel_act_func_unit act_func_unit_0 (
        .act_func_di    (quant_to_act_func_0),
        .act_func_do    (act_func_do_0),

        .act_func_typ   (elew_act_func_typ)
    );

    assign acc_SUB_offset_0 = act_func_do_0 - elew_output_offset;
    assign act_result_0 = acc_SUB_offset_0[7:0];
    assign elew_do_0_0 = act_result_0;

    fs_accel_pool pool_0(
        .pool_di        (act_result_0),
        .sel_demux      (sel_demux),
        .sel_mux        (sel_mux),
        .mpbuf_ld_wrn   (mpbuf_ld_wrn),
        .cp_enb         (cp_enb),
        .buf_enb        (buf_enb),
        .clk            (clk),
        .resetn         (resetn & resetn_pool),
        .pool_do        (cp_do_0)
    );

// PAIR 1
    fs_accel_quant_lut  quant_lut_1 (
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

    fs_accel_quant_unit quant_unit_1 (
        .quant_di       (elew_di_1),
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

    fs_accel_act_func_unit act_func_unit_1 (
        .act_func_di    (quant_to_act_func_1),
        .act_func_do    (act_func_do_1),

        .act_func_typ   (elew_act_func_typ)
    );

    assign acc_SUB_offset_1 = act_func_do_1 - elew_output_offset;
    assign act_result_1 = acc_SUB_offset_1[7:0];
    assign elew_do_0_1 = act_result_1;
    

    fs_accel_pool pool_1(
        .pool_di        (act_result_1),
        .sel_demux      (sel_demux),
        .sel_mux        (sel_mux),
        .mpbuf_ld_wrn   (mpbuf_ld_wrn),
        .cp_enb         (cp_enb),
        .buf_enb        (buf_enb),
        .clk            (clk),
        .resetn         (resetn & resetn_pool),
        .pool_do        (cp_do_1)
    );

// PAIR 2
    fs_accel_quant_lut  quant_lut_2 (
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

    fs_accel_quant_unit quant_unit_2 (
        .quant_di       (elew_di_2),
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

    fs_accel_act_func_unit act_func_unit_2 (
        .act_func_di    (quant_to_act_func_2),
        .act_func_do    (act_func_do_2),

        .act_func_typ   (elew_act_func_typ)
    );

    assign acc_SUB_offset_2 = act_func_do_2 - elew_output_offset;
    assign act_result_2 = acc_SUB_offset_2[7:0];
    assign elew_do_0_2 = act_result_2;

    
    fs_accel_pool pool_2(
        .pool_di        (act_result_2),
        .sel_demux      (sel_demux),
        .sel_mux        (sel_mux),
        .mpbuf_ld_wrn   (mpbuf_ld_wrn),
        .cp_enb         (cp_enb),
        .buf_enb        (buf_enb),
        .clk            (clk),
        .resetn         (resetn & resetn_pool),
        .pool_do        (cp_do_2)
    );


    // Pool Buffer
    always @(posedge clk) begin
        if(!resetn) begin
            pool_buf_do_0 <= 1'b0;
            pool_buf_do_0 <= 1'b0;
            pool_buf_do_0 <= 1'b0;
        end else if(pool_enb && enb) begin
            if(pool_ld_wrn) begin
                pool_buf_do_0 <= elew_di_0;
                pool_buf_do_1 <= elew_di_1;
                pool_buf_do_2 <= elew_di_2;
            end
        end
    end
    
endmodule
