module fs_accel (
/* Config Interface */
	input  [31:0] al_accel_cfgreg_di,
    input  [ 4:0] al_accel_cfgreg_sel, 
    input         al_accel_cfgreg_wenb,

/* Data Interface */
    // Read Data Interface
    input  [31:0] al_accel_rdata,
    output [31:0] al_accel_raddr, 
    output        al_accel_renb,
    input         al_accel_mem_read_ready,
    input         al_accel_mem_write_ready,

    // Write Data Interface
    output [31:0] al_accel_wdata,
    output [31:0] al_accel_waddr,
    output        al_accel_wenb,
    output [ 3:0] al_accel_wstrb,

/* System Interface */
    input         al_accel_flow_enb,
    input         al_accel_flow_resetn,
    output        al_accel_cal_fin,
    
/* Mandatory Sigs */
    input clk,
	input resetn
);

/*  ALL Parameter Definition */
    // Layer Param
    localparam 
        CONV    = 4'd 0,
        DENSE   = 4'd 1,
        MIXED   = 4'd 2;

/* Connection Declaration */
    wire        is_conv_layer;
    wire        is_out_fin;
    wire [ 3:0] o_quant_sel;

    wire [31:0] bpbuf_2_do,     bpbuf_1_do,     bpbuf_0_do;
    wire        bpbuf_2_ld_wrn, bpbuf_1_ld_wrn, bpbuf_0_ld_wrn;
    wire        bpbuf_2_enb,    bpbuf_1_enb,    bpbuf_0_enb;

    wire [ 7:0] wbuf_2_do_0,        wbuf_1_do_0,        wbuf_0_do_0,
                wbuf_2_do_1,        wbuf_1_do_1,        wbuf_0_do_1,
                wbuf_2_do_2,        wbuf_1_do_2,        wbuf_0_do_2;
    wire [ 1:0] wbuf_2_wstrb,       wbuf_1_wstrb,       wbuf_0_wstrb;
    wire        wbuf_2_ld_wrn,      wbuf_1_ld_wrn,      wbuf_0_ld_wrn;
    wire [ 1:0] wbuf_2_bank_sel,    wbuf_1_bank_sel,    wbuf_0_bank_sel;
    wire        wbuf_2_enb,         wbuf_1_enb,         wbuf_0_enb;

    wire [ 7:0] ibuf_2_do_0,        ibuf_1_do_0,        ibuf_0_do_0,
                ibuf_2_do_1,        ibuf_1_do_1,        ibuf_0_do_1,
                ibuf_2_do_2,        ibuf_1_do_2,        ibuf_0_do_2;
    wire [ 2:0] ibuf_2_valid,       ibuf_1_valid,       ibuf_0_valid;
    wire [ 2:0] ibuf_2_nxt_valid,   ibuf_1_nxt_valid,   ibuf_0_nxt_valid;
    wire        ibuf_2_di_revert,   ibuf_1_di_revert,   ibuf_0_di_revert;
    wire        ibuf_2_do_revert,   ibuf_1_do_revert,   ibuf_0_do_revert;
    wire [ 1:0] ibuf_dens_wstrb;
    wire [ 2:0] ibuf_conv_wstrb;
    wire        ibuf_2_ld_wrn,      ibuf_1_ld_wrn,      ibuf_0_ld_wrn;
    wire [ 1:0] ibuf_2_bank_sel,    ibuf_1_bank_sel,    ibuf_0_bank_sel;
    wire        ibuf_conv_fi_load;
    wire        ibuf_conv_se_load;
    wire        ibuf_2_enb,         ibuf_1_enb,         ibuf_0_enb;

    wire [ 1:0] pu_matrix_wsel;
    wire [ 1:0] pu_matrix_isel;
    // wire [31:0] pu_matrix_odo_0_0_0,    pu_matrix_odo_0_0_1,    pu_matrix_odo_0_0_2,
    //             pu_matrix_odo_0_1_0,    pu_matrix_odo_0_1_1,    pu_matrix_odo_0_1_2,
    //             pu_matrix_odo_0_2_0,    pu_matrix_odo_0_2_1,    pu_matrix_odo_0_2_2,
    //             pu_matrix_odo_1_0_0,    pu_matrix_odo_1_0_1,    pu_matrix_odo_1_0_2,
    //             pu_matrix_odo_1_1_0,    pu_matrix_odo_1_1_1,    pu_matrix_odo_1_1_2,
    //             pu_matrix_odo_1_2_0,    pu_matrix_odo_1_2_1,    pu_matrix_odo_1_2_2,
    //             pu_matrix_odo_2_0_0,    pu_matrix_odo_2_0_1,    pu_matrix_odo_2_0_2,
    //             pu_matrix_odo_2_1_0,    pu_matrix_odo_2_1_1,    pu_matrix_odo_2_1_2,
    //             pu_matrix_odo_2_2_0,    pu_matrix_odo_2_2_1,    pu_matrix_odo_2_2_2;

    wire [31:0] pu_matrix_odo_0_0,    pu_matrix_odo_0_1,    pu_matrix_odo_0_2,
            pu_matrix_odo_1_0,    pu_matrix_odo_1_1,    pu_matrix_odo_1_2,
            pu_matrix_odo_2_0,    pu_matrix_odo_2_1,    pu_matrix_odo_2_2;

    wire [ 1:0] pu_matrix_conv_dir;
    wire        pu_matrix_rdy;

    wire        wreg_enb_0_0_0, wreg_enb_0_0_1, wreg_enb_0_0_2,
                wreg_enb_0_1_0, wreg_enb_0_1_1, wreg_enb_0_1_2,
                wreg_enb_0_2_0, wreg_enb_0_2_1, wreg_enb_0_2_2,
                wreg_enb_1_0_0, wreg_enb_1_0_1, wreg_enb_1_0_2,
                wreg_enb_1_1_0, wreg_enb_1_1_1, wreg_enb_1_1_2,
                wreg_enb_1_2_0, wreg_enb_1_2_1, wreg_enb_1_2_2,
                wreg_enb_2_0_0, wreg_enb_2_0_1, wreg_enb_2_0_2,
                wreg_enb_2_1_0, wreg_enb_2_1_1, wreg_enb_2_1_2,
                wreg_enb_2_2_0, wreg_enb_2_2_1, wreg_enb_2_2_2;

    wire        ireg_enb_0_0, ireg_enb_0_1, ireg_enb_0_2,
                ireg_enb_1_0, ireg_enb_1_1, ireg_enb_1_2,
                ireg_enb_2_0, ireg_enb_2_1, ireg_enb_2_2;

    wire        pu_enb_0_0, pu_enb_0_1, pu_enb_0_2,
                pu_enb_1_0, pu_enb_1_1, pu_enb_1_2,
                pu_enb_2_0, pu_enb_2_1, pu_enb_2_2;
    
    wire [31:0] acc_matrix_do_2 , acc_matrix_do_1, acc_matrix_do_0;
    wire        acc_matrix_bps_load;
    wire        acc_matrix_bps_write;
    wire        acc_matrix_inter_sum_write;
    wire        acc_matrix_enb_0, acc_matrix_enb_1;

    wire [31:0] obuf_2_di,      obuf_1_di,      obuf_0_di;
    wire [31:0] obuf_2_do,      obuf_1_do,      obuf_0_do;
    wire        obuf_2_ld_wrn,  obuf_1_ld_wrn,  obuf_0_ld_wrn;
    wire        obuf_2_enb,     obuf_1_enb,     obuf_0_enb;

    wire [7:0] pool_do_0, pool_do_1, pool_do_2;
    wire [31:0] pool_buf_do_0, pool_buf_do_1, pool_buf_do_2;
    wire [3:0] sel_demux, sel_mux;
    wire mpbuf_ld_wrn, cp_enb, buf_enb;
    wire resetn_pool;
    wire pool_ld_wrn, pool_enb;

    wire        quant_act_func_enb_2, quant_act_func_enb_1, quant_act_func_enb_0;
    wire        quant_act_func_rdy_2, quant_act_func_rdy_1, quant_act_func_rdy_0;

    wire [31:0] i_base_addr;
    wire [31:0] kw_base_addr;
    wire [31:0] o_base_addr;
    wire [31:0] b_base_addr;
    wire [31:0] ps_base_addr;

    wire [ 3:0] cfg_layer_typ;
    wire [ 3:0] cfg_act_func_typ; 
    wire [ 3:0] stride_width;
    wire [ 3:0] stride_height;
    wire [15:0] weight_kernel_patch_width; 
    wire [15:0] weight_kernel_patch_height;
    wire [15:0] kernel_ifm_depth; 
    wire [15:0] nok_ofm_depth;
    wire [15:0] ifm_width;
    wire [15:0] ifm_height;   
    wire [15:0] ofm_width; 
    wire [15:0] ofm_height;  
    wire [15:0] input2D_size;
    wire [15:0] output2D_size;
    wire [31:0] kernel3D_size;

    wire [31:0] output_multiplier_0;
    wire [31:0] output_multiplier_1;
    wire [31:0] output_multiplier_2;
    wire [ 7:0] output_shift_0;
    wire [ 7:0] output_shift_1;
    wire [ 7:0] output_shift_2;

    wire [31:0] input_offset;
    wire [31:0] output_offset;

    wire [15:0] ofm_pool_height, ofm_pool_width;
    wire [31:0] output2D_pool_size;

    wire        al_accel_wenb_0, al_accel_wenb_1, al_accel_wenb_2;

    assign al_accel_wenb = al_accel_wenb_0 | al_accel_wenb_1 | al_accel_wenb_2;
    
    // For output buffer
    assign obuf_0_di = is_out_fin ? {4{pool_do_0}}: ((cfg_layer_typ == DENSE) ? acc_matrix_do_0 : pool_buf_do_0);
    assign obuf_1_di = is_out_fin ? {4{pool_do_1}}: ((cfg_layer_typ == DENSE) ? acc_matrix_do_1 : pool_buf_do_1); 
    assign obuf_2_di = is_out_fin ? {4{pool_do_2}}: ((cfg_layer_typ == DENSE) ? acc_matrix_do_2 : pool_buf_do_2);  

    assign al_accel_wdata = (al_accel_wenb_2) ? obuf_2_do : 
                            (al_accel_wenb_1) ? obuf_1_do : 
                            (al_accel_wenb_0) ? obuf_0_do : 
                            32'd 0;

/* Submodule Instantiate */
    // Bias/Parital-Sum Buffer: 3 instances
    fs_accel_bpbuf bpbuf_0 (
        // Data Sigs
        .bpbuf_di   (al_accel_rdata),
        .bpbuf_do   (bpbuf_0_do),

        // Ctrl Sigs 
        .bpbuf_ld_wrn (bpbuf_0_ld_wrn),

        // Mandatory Sigs
        .enb    (bpbuf_0_enb &  al_accel_flow_enb),
        .clk    (clk),
        .resetn (resetn & al_accel_flow_resetn)
    );

    fs_accel_bpbuf bpbuf_1 (
        // Data Sigs
        .bpbuf_di   (al_accel_rdata),
        .bpbuf_do   (bpbuf_1_do),

        // Ctrl Sigs 
        .bpbuf_ld_wrn (bpbuf_1_ld_wrn),

        // Mandatory Sigs
        .enb    (bpbuf_1_enb &  al_accel_flow_enb),
        .clk    (clk),
        .resetn (resetn & al_accel_flow_resetn)
    );

    fs_accel_bpbuf bpbuf_2 (
        // Data Sigs
        .bpbuf_di   (al_accel_rdata),
        .bpbuf_do   (bpbuf_2_do),

        // Ctrl Sigs 
        .bpbuf_ld_wrn (bpbuf_2_ld_wrn),

        // Mandatory Sigs
        .enb    (bpbuf_2_enb &  al_accel_flow_enb),
        .clk    (clk),
        .resetn (resetn & al_accel_flow_resetn)
    );

    // Weight Buffer: 3 instances
    fs_accel_wbuf wbuf_0 (
        // Data Sigs
        .wbuf_di    (al_accel_rdata),
        .wbuf_init  (8'd 0),

        .wbuf_do_0  (wbuf_0_do_0),
        .wbuf_do_1  (wbuf_0_do_1),
        .wbuf_do_2  (wbuf_0_do_2),
    
        // Ctrl Sigs 
        .wbuf_wstrb     (wbuf_0_wstrb),
        .wbuf_ld_wrn    (wbuf_0_ld_wrn),
        .wbuf_bank_sel  (wbuf_0_bank_sel),

        // Mandatory Sigs
        .enb    (wbuf_0_enb &  al_accel_flow_enb),
        .clk    (clk),
        .resetn (resetn & al_accel_flow_resetn)
    );

    fs_accel_wbuf wbuf_1 (
        // Data Sigs
        .wbuf_di    (al_accel_rdata),
        .wbuf_init  (8'd 0),

        .wbuf_do_0  (wbuf_1_do_0),
        .wbuf_do_1  (wbuf_1_do_1),
        .wbuf_do_2  (wbuf_1_do_2),
    
        // Ctrl Sigs 
        .wbuf_wstrb     (wbuf_1_wstrb),
        .wbuf_ld_wrn    (wbuf_1_ld_wrn),
        .wbuf_bank_sel  (wbuf_1_bank_sel),

        // Mandatory Sigs
        .enb    (wbuf_1_enb &  al_accel_flow_enb),
        .clk    (clk),
        .resetn (resetn & al_accel_flow_resetn)
    );

    fs_accel_wbuf wbuf_2 (
        // Data Sigs
        .wbuf_di    (al_accel_rdata),
        .wbuf_init  (8'd 0),

        .wbuf_do_0  (wbuf_2_do_0),
        .wbuf_do_1  (wbuf_2_do_1),
        .wbuf_do_2  (wbuf_2_do_2),
    
        // Ctrl Sigs 
        .wbuf_wstrb     (wbuf_2_wstrb),
        .wbuf_ld_wrn    (wbuf_2_ld_wrn),
        .wbuf_bank_sel  (wbuf_2_bank_sel),

        // Mandatory Sigs
        .enb    (wbuf_2_enb &  al_accel_flow_enb),
        .clk    (clk),
        .resetn (resetn & al_accel_flow_resetn)
    );

    // Input Buffer: 3 instances
    fs_accel_ibuf ibuf_0 (
        // Config Sigs
        .cfg_layer_typ  (cfg_layer_typ),

        // Data Sigs
        .ibuf_di    (al_accel_rdata),
        .ibuf_init  (8'd 0),

        .ibuf_do_0  (ibuf_0_do_0),
        .ibuf_do_1  (ibuf_0_do_1),
        .ibuf_do_2  (ibuf_0_do_2),

        // Feedback Sigs
        .ibuf_valid     (ibuf_0_valid),
        .ibuf_nxt_valid (ibuf_0_nxt_valid),

        // Ctrl Sigs
        .ibuf_di_revert     (ibuf_0_di_revert),
        .ibuf_do_revert     (ibuf_0_do_revert),
        .ibuf_dens_wstrb    (ibuf_dens_wstrb),
        .ibuf_conv_wstrb    (ibuf_conv_wstrb),
        .ibuf_ld_wrn        (ibuf_0_ld_wrn),
        .ibuf_bank_sel      (ibuf_0_bank_sel),
        // .ibuf_is_conv_layer (is_conv_layer),
        .ibuf_conv_fi_load  (ibuf_conv_fi_load),
        .ibuf_conv_se_load  (ibuf_conv_se_load),

        // Mandatory Sigs
        .enb    (ibuf_0_enb & al_accel_flow_enb),
        .clk    (clk),
        .resetn (resetn & al_accel_flow_resetn)
    );

    fs_accel_ibuf ibuf_1 (
        // Config Sigs
        .cfg_layer_typ  (cfg_layer_typ),

        // Data Sigs
        .ibuf_di    (al_accel_rdata),
        .ibuf_init  (8'd 0),

        .ibuf_do_0  (ibuf_1_do_0),
        .ibuf_do_1  (ibuf_1_do_1),
        .ibuf_do_2  (ibuf_1_do_2),

        // Feedback Sigs
        .ibuf_valid     (ibuf_1_valid),
        .ibuf_nxt_valid (ibuf_1_nxt_valid),

        // Ctrl Sigs
        .ibuf_di_revert     (ibuf_1_di_revert),
        .ibuf_do_revert     (ibuf_1_do_revert),
        .ibuf_dens_wstrb    (ibuf_dens_wstrb),
        .ibuf_conv_wstrb    (ibuf_conv_wstrb),
        .ibuf_ld_wrn        (ibuf_1_ld_wrn),
        .ibuf_bank_sel      (ibuf_1_bank_sel),
        // .ibuf_is_conv_layer (is_conv_layer),
        .ibuf_conv_fi_load  (ibuf_conv_fi_load),
        .ibuf_conv_se_load  (ibuf_conv_se_load),

        // Mandatory Sigs
        .enb    (ibuf_1_enb &  al_accel_flow_enb),
        .clk    (clk),
        .resetn (resetn & al_accel_flow_resetn)
    );

    fs_accel_ibuf ibuf_2 (
        // Config Sigs
        .cfg_layer_typ  (cfg_layer_typ),

        // Data Sigs
        .ibuf_di    (al_accel_rdata),
        .ibuf_init  (8'd 0),

        .ibuf_do_0  (ibuf_2_do_0),
        .ibuf_do_1  (ibuf_2_do_1),
        .ibuf_do_2  (ibuf_2_do_2),

        // Feedback Sigs
        .ibuf_valid     (ibuf_2_valid),
        .ibuf_nxt_valid (ibuf_2_nxt_valid),

        // Ctrl Sigs
        .ibuf_di_revert     (ibuf_2_di_revert),
        .ibuf_do_revert     (ibuf_2_do_revert),
        .ibuf_dens_wstrb    (ibuf_dens_wstrb),
        .ibuf_conv_wstrb    (ibuf_conv_wstrb),
        .ibuf_ld_wrn        (ibuf_2_ld_wrn),
        .ibuf_bank_sel      (ibuf_2_bank_sel),
        // .ibuf_is_conv_layer (is_conv_layer),
        .ibuf_conv_fi_load  (ibuf_conv_fi_load),
        .ibuf_conv_se_load  (ibuf_conv_se_load),

        // Mandatory Sigs
        .enb    (ibuf_2_enb &  al_accel_flow_enb),
        .clk    (clk),
        .resetn (resetn & al_accel_flow_resetn)
    );

    // Processing Matrix: 1 instance
    fs_accel_pu_matrix pu_matrix (
        // Data Sigs
        .pu_matrix_wdi_0_0  (wbuf_0_do_0),
        .pu_matrix_wdi_0_1  (wbuf_0_do_1),
        .pu_matrix_wdi_0_2  (wbuf_0_do_2),
        .pu_matrix_wdi_1_0  (wbuf_1_do_0),
        .pu_matrix_wdi_1_1  (wbuf_1_do_1),
        .pu_matrix_wdi_1_2  (wbuf_1_do_2),
        .pu_matrix_wdi_2_0  (wbuf_2_do_0),
        .pu_matrix_wdi_2_1  (wbuf_2_do_1),
        .pu_matrix_wdi_2_2  (wbuf_2_do_2),

        .pu_matrix_wsel_0   (pu_matrix_wsel),
        .pu_matrix_wsel_1   (pu_matrix_wsel),
        .pu_matrix_wsel_2   (pu_matrix_wsel),

        .pu_matrix_idi_0_0  (ibuf_0_do_0),
        .pu_matrix_idi_0_1  (ibuf_0_do_1),
        .pu_matrix_idi_0_2  (ibuf_0_do_2),
        .pu_matrix_idi_1_0  (ibuf_1_do_0),
        .pu_matrix_idi_1_1  (ibuf_1_do_1),
        .pu_matrix_idi_1_2  (ibuf_1_do_2),
        .pu_matrix_idi_2_0  (ibuf_2_do_0),
        .pu_matrix_idi_2_1  (ibuf_2_do_1),
        .pu_matrix_idi_2_2  (ibuf_2_do_2),

        .pu_matrix_isel_0   (pu_matrix_isel),
        .pu_matrix_isel_1   (pu_matrix_isel),
        .pu_matrix_isel_2   (pu_matrix_isel),

        .pu_matrix_odo_0_0    (pu_matrix_odo_0_0),
        .pu_matrix_odo_0_1    (pu_matrix_odo_0_1),
        .pu_matrix_odo_0_2    (pu_matrix_odo_0_2),
        .pu_matrix_odo_1_0    (pu_matrix_odo_1_0),
        .pu_matrix_odo_1_1    (pu_matrix_odo_1_1),
        .pu_matrix_odo_1_2    (pu_matrix_odo_1_2),
        .pu_matrix_odo_2_0    (pu_matrix_odo_2_0),
        .pu_matrix_odo_2_1    (pu_matrix_odo_2_1),
        .pu_matrix_odo_2_2    (pu_matrix_odo_2_2),

        // Config Sigs
        .pu_matrix_is_conv_layer    (cfg_layer_typ == CONV || cfg_layer_typ == MIXED),
        .pu_matrix_conv_dir         (pu_matrix_conv_dir),
        .pu_matrix_input_offset     (input_offset), 

        // Ctrl Sigs
        .pu_matrix_wreg_enb_0_0_0   (wreg_enb_0_0_0 &  al_accel_flow_enb),
        .pu_matrix_wreg_enb_0_0_1   (wreg_enb_0_0_1 &  al_accel_flow_enb),
        .pu_matrix_wreg_enb_0_0_2   (wreg_enb_0_0_2 &  al_accel_flow_enb),
        .pu_matrix_wreg_enb_0_1_0   (wreg_enb_0_1_0 &  al_accel_flow_enb),
        .pu_matrix_wreg_enb_0_1_1   (wreg_enb_0_1_1 &  al_accel_flow_enb),
        .pu_matrix_wreg_enb_0_1_2   (wreg_enb_0_1_2 &  al_accel_flow_enb),
        .pu_matrix_wreg_enb_0_2_0   (wreg_enb_0_2_0 &  al_accel_flow_enb),
        .pu_matrix_wreg_enb_0_2_1   (wreg_enb_0_2_1 &  al_accel_flow_enb),
        .pu_matrix_wreg_enb_0_2_2   (wreg_enb_0_2_2 &  al_accel_flow_enb),
        .pu_matrix_wreg_enb_1_0_0   (wreg_enb_1_0_0 &  al_accel_flow_enb),
        .pu_matrix_wreg_enb_1_0_1   (wreg_enb_1_0_1 &  al_accel_flow_enb),
        .pu_matrix_wreg_enb_1_0_2   (wreg_enb_1_0_2 &  al_accel_flow_enb),
        .pu_matrix_wreg_enb_1_1_0   (wreg_enb_1_1_0 &  al_accel_flow_enb),
        .pu_matrix_wreg_enb_1_1_1   (wreg_enb_1_1_1 &  al_accel_flow_enb),
        .pu_matrix_wreg_enb_1_1_2   (wreg_enb_1_1_2 &  al_accel_flow_enb),
        .pu_matrix_wreg_enb_1_2_0   (wreg_enb_1_2_0 &  al_accel_flow_enb),
        .pu_matrix_wreg_enb_1_2_1   (wreg_enb_1_2_1 &  al_accel_flow_enb),
        .pu_matrix_wreg_enb_1_2_2   (wreg_enb_1_2_2 &  al_accel_flow_enb),
        .pu_matrix_wreg_enb_2_0_0   (wreg_enb_2_0_0 &  al_accel_flow_enb),
        .pu_matrix_wreg_enb_2_0_1   (wreg_enb_2_0_1 &  al_accel_flow_enb),
        .pu_matrix_wreg_enb_2_0_2   (wreg_enb_2_0_2 &  al_accel_flow_enb),
        .pu_matrix_wreg_enb_2_1_0   (wreg_enb_2_1_0 &  al_accel_flow_enb),
        .pu_matrix_wreg_enb_2_1_1   (wreg_enb_2_1_1 &  al_accel_flow_enb),
        .pu_matrix_wreg_enb_2_1_2   (wreg_enb_2_1_2 &  al_accel_flow_enb),
        .pu_matrix_wreg_enb_2_2_0   (wreg_enb_2_2_0 &  al_accel_flow_enb),
        .pu_matrix_wreg_enb_2_2_1   (wreg_enb_2_2_1 &  al_accel_flow_enb),
        .pu_matrix_wreg_enb_2_2_2   (wreg_enb_2_2_2 &  al_accel_flow_enb),

        .pu_matrix_ireg_enb_0_0     (ireg_enb_0_0 &  al_accel_flow_enb),
        .pu_matrix_ireg_enb_0_1     (ireg_enb_0_1 &  al_accel_flow_enb),
        .pu_matrix_ireg_enb_0_2     (ireg_enb_0_2 &  al_accel_flow_enb),
        .pu_matrix_ireg_enb_1_0     (ireg_enb_1_0 &  al_accel_flow_enb),
        .pu_matrix_ireg_enb_1_1     (ireg_enb_1_1 &  al_accel_flow_enb),
        .pu_matrix_ireg_enb_1_2     (ireg_enb_1_2 &  al_accel_flow_enb),
        .pu_matrix_ireg_enb_2_0     (ireg_enb_2_0 &  al_accel_flow_enb),
        .pu_matrix_ireg_enb_2_1     (ireg_enb_2_1 &  al_accel_flow_enb),
        .pu_matrix_ireg_enb_2_2     (ireg_enb_2_2 &  al_accel_flow_enb),

        .pu_enb_0_0 (pu_enb_0_0 &  al_accel_flow_enb),
        .pu_enb_0_1 (pu_enb_0_1 &  al_accel_flow_enb),
        .pu_enb_0_2 (pu_enb_0_2 &  al_accel_flow_enb),
        .pu_enb_1_0 (pu_enb_1_0 &  al_accel_flow_enb),
        .pu_enb_1_1 (pu_enb_1_1 &  al_accel_flow_enb),
        .pu_enb_1_2 (pu_enb_1_2 &  al_accel_flow_enb),
        .pu_enb_2_0 (pu_enb_2_0 &  al_accel_flow_enb),
        .pu_enb_2_1 (pu_enb_2_1 &  al_accel_flow_enb),
        .pu_enb_2_2 (pu_enb_2_2 &  al_accel_flow_enb),

        // Feedback Sigs
        .rdy    (pu_matrix_rdy),

        // Mandatory Sigs
        .clk    (clk),
        .resetn (resetn & al_accel_flow_resetn)
    );

    // Accumulate Matrix: 1 instance
    fs_accel_acc_matrix acc_matrix(
        // Data Sigs
        .acc_matrix_bps_0   (bpbuf_0_do),
        .acc_matrix_bps_1   (bpbuf_1_do),
        .acc_matrix_bps_2   (bpbuf_2_do),

        .acc_matrix_di_0_0    (pu_matrix_odo_0_0),
        .acc_matrix_di_0_1    (pu_matrix_odo_0_1),
        .acc_matrix_di_0_2    (pu_matrix_odo_0_2),
        .acc_matrix_di_1_0    (pu_matrix_odo_1_0),
        .acc_matrix_di_1_1    (pu_matrix_odo_1_1),
        .acc_matrix_di_1_2    (pu_matrix_odo_1_2),
        .acc_matrix_di_2_0    (pu_matrix_odo_2_0),
        .acc_matrix_di_2_1    (pu_matrix_odo_2_1),
        .acc_matrix_di_2_2    (pu_matrix_odo_2_2),

        .acc_matrix_do_0    (acc_matrix_do_0),
        .acc_matrix_do_1    (acc_matrix_do_1),
        .acc_matrix_do_2    (acc_matrix_do_2),

        // Config Sigs
        .acc_matrix_bps_load        (acc_matrix_bps_load),
        // .acc_matrix_inter_sum_load  (acc_matrix_inter_sum_load),
        .acc_matrix_bps_write       (acc_matrix_bps_write),
        .acc_matrix_inter_sum_write (acc_matrix_inter_sum_write),

        // Mandatory Sigs
        .enb    ((acc_matrix_enb_0 | acc_matrix_enb_1) &  al_accel_flow_enb),
        .clk    (clk),
        .resetn (resetn & al_accel_flow_resetn)
    );

    // Output Buffer: 3 instances
    fs_accel_obuf obuf_0(
        // Data Sigs
        .obuf_di    (obuf_0_di),
        .obuf_do    (obuf_0_do),

        // Ctrl Sigs
        .obuf_ld_wrn    (obuf_0_ld_wrn),

        // Mandatory Sigs
        .enb    (obuf_0_enb &  al_accel_flow_enb),
        .clk    (clk),
        .resetn (resetn & al_accel_flow_resetn)
    );

    fs_accel_obuf obuf_1(
        // Data Sigs
        .obuf_di    (obuf_1_di),
        .obuf_do    (obuf_1_do),

        // Ctrl Sigs
        .obuf_ld_wrn    (obuf_1_ld_wrn),

        // Mandatory Sigs
        .enb    (obuf_1_enb &  al_accel_flow_enb),
        .clk    (clk),
        .resetn (resetn & al_accel_flow_resetn)
    );

    fs_accel_obuf obuf_2(
        // Data Sigs
        .obuf_di    (obuf_2_di),
        .obuf_do    (obuf_2_do),

        // Ctrl Sigs
        .obuf_ld_wrn    (obuf_2_ld_wrn),

        // Mandatory Sigs
        .enb    (obuf_2_enb &  al_accel_flow_enb),
        .clk    (clk),
        .resetn (resetn & al_accel_flow_resetn)
    );

    // Element-Wise Unit: 1 instances
    fs_accel_elw_unit elw_unit (
        .cfg_layer_typ (cfg_layer_typ),
        // Data Sigs
        .elew_di_0    (acc_matrix_do_0),
        .elew_di_1    (acc_matrix_do_1),
        .elew_di_2    (acc_matrix_do_2),

        // For Max Pooling
        .sel_demux      (sel_demux),
        .sel_mux        (sel_mux),
        .mpbuf_ld_wrn   (mpbuf_ld_wrn),
        .cp_enb         (cp_enb),
        .buf_enb        (buf_enb),
        .resetn_pool     (resetn_pool),

        .pool_do_0      (pool_do_0),
        .pool_do_1      (pool_do_1),
        .pool_do_2      (pool_do_2),

        .pool_buf_do_0  (pool_buf_do_0),
        .pool_buf_do_1  (pool_buf_do_1),
        .pool_buf_do_2  (pool_buf_do_2),

        // Configs Sigs
        .elew_quant_muler_0     (output_multiplier_0),
        .elew_quant_muler_1     ((cfg_layer_typ == CONV || cfg_layer_typ == MIXED) ? output_multiplier_1 : output_multiplier_0),
        .elew_quant_muler_2     ((cfg_layer_typ == CONV || cfg_layer_typ == MIXED) ? output_multiplier_2 : output_multiplier_0),

        .elew_quant_rshift_0    (output_shift_0),
        .elew_quant_rshift_1    ((cfg_layer_typ == CONV || cfg_layer_typ == MIXED) ? output_shift_1 : output_shift_0),
        .elew_quant_rshift_2    ((cfg_layer_typ == CONV || cfg_layer_typ == MIXED) ? output_shift_2 : output_shift_0),

        .elew_output_offset     (output_offset),
        
        .elew_act_func_typ      (cfg_act_func_typ),

        .pool_ld_wrn            (pool_ld_wrn),
        .pool_enb               (pool_enb),
        
        // Ctrl Sigs
        .quant_act_func_enb_0   (quant_act_func_enb_0 &  al_accel_flow_enb),
        .quant_act_func_enb_1   (quant_act_func_enb_1 &  al_accel_flow_enb),
        .quant_act_func_enb_2   (quant_act_func_enb_2 &  al_accel_flow_enb),

        // Feedback Sigs
        .quant_act_func_rdy_0   (quant_act_func_rdy_0),
        .quant_act_func_rdy_1   (quant_act_func_rdy_1),
        .quant_act_func_rdy_2   (quant_act_func_rdy_2),

        // Mandatory Sigs
        .enb    (al_accel_flow_enb),
        .clk    (clk),
        .resetn (resetn & al_accel_flow_resetn)
    );

    // Configuration Register Files: 1 instance
    fs_accel_config_regs config_regs (
        // Data Sigs
        .config_data    (al_accel_cfgreg_di),
        .config_sel     (al_accel_cfgreg_sel),

        .output_quant_buf_outsel    (o_quant_sel),

        // Configuration Memory Sigs
        .i_base_addr    (i_base_addr),
        .kw_base_addr   (kw_base_addr),
        .o_base_addr    (o_base_addr),
        .b_base_addr    (b_base_addr),
        .ps_base_addr   (ps_base_addr),

        // Configuration Layer Sigs
        .cfg_layer_typ      (cfg_layer_typ),
        .cfg_act_func_typ   (cfg_act_func_typ),

        .stride_width   (stride_width),
        .stride_height  (stride_height),

        .weight_kernel_patch_width  (weight_kernel_patch_width),
        .weight_kernel_patch_height (weight_kernel_patch_height),

        .kernel_ifm_depth   (kernel_ifm_depth),
        .nok_ofm_depth      (nok_ofm_depth),

        .ifm_width      (ifm_width),
        .ifm_height     (ifm_height),

        .ofm_width      (ofm_width),
        .ofm_height     (ofm_height),

        .input2D_size   (input2D_size),
        .output2D_size  (output2D_size),
        .kernel3D_size  (kernel3D_size),

        .output_multiplier_0    (output_multiplier_0),
        .output_multiplier_1    (output_multiplier_1),
        .output_multiplier_2    (output_multiplier_2),

        .output_shift_0         (output_shift_0),
        .output_shift_1         (output_shift_1),
        .output_shift_2         (output_shift_2),

        .input_offset           (input_offset),
        .output_offset          (output_offset),

        .ofm_pool_height        (ofm_pool_height),
        .ofm_pool_width         (ofm_pool_width),
        .output2D_pool_size     (output2D_pool_size),

        // Ctrl Sigs
        .config_wen     (al_accel_cfgreg_wenb),

        // Mandatory Sigs
        .clk    (clk),
        .resetn (resetn)
    );

    // Flow Controller: 1 instance
    fs_accel_flow_ctrl flow_ctrl (
        /* Config Signals */
        // Base Address 
        .i_base_addr    (i_base_addr),
        .kw_base_addr   (kw_base_addr),
        .o_base_addr    (o_base_addr),
        .b_base_addr    (b_base_addr),
        .ps_base_addr   (ps_base_addr),

        // Layer Info
        .cfg_layer_typ  (cfg_layer_typ),

        .stride_width   (stride_width),
        .stride_height  (stride_height),

        .weight_kernel_patch_width  (weight_kernel_patch_width),
        .weight_kernel_patch_height (weight_kernel_patch_height),

        .kernel_ifm_depth   (kernel_ifm_depth),
        .nok_ofm_depth      (nok_ofm_depth),

        .ifm_width  (ifm_width),
        .ifm_height (ifm_height),

        .ofm_width  (ofm_width),
        .ofm_height (ofm_height),

        // Pre-Cal Config Signals
        .kernel3D_size  (kernel3D_size), // = kernel_width * kernel_height * kernel_depth
        .input2D_size   (input2D_size), // = ifm_width * ifm_height
        .output2D_size  (output2D_size), // = ofm_widht * ofm_height

        // Pool Size
        .ofm_pool_height    (ofm_pool_height),
        .ofm_pool_width     (ofm_pool_width),
        .output2D_pool_size (output2D_pool_size),

        /* Output Control Sigs */
        // SoC Read Data Ctrl
        .flow_mem_raddr  (al_accel_raddr),
        .flow_mem_renb   (al_accel_renb),

        // SoC Write Data Ctrl
        .flow_mem_waddr  (al_accel_waddr),
        .flow_mem_wstrb  (al_accel_wstrb),
        .flow_mem_wenb_0 (al_accel_wenb_0),
        .flow_mem_wenb_1 (al_accel_wenb_1),
        .flow_mem_wenb_2 (al_accel_wenb_2),

        // Bias/Partial-Sum Buffer Ctrl
        .flow_bpbuf_ld_wrn   ({bpbuf_2_ld_wrn, bpbuf_1_ld_wrn, bpbuf_0_ld_wrn}),
        .flow_bpbuf_enb      ({bpbuf_2_enb,    bpbuf_1_enb,    bpbuf_0_enb}),

        // Input Buffer Ctrl
        .flow_ibuf_di_revert     ({ibuf_2_di_revert, ibuf_1_di_revert, ibuf_0_di_revert}),
        .flow_ibuf_do_revert     ({ibuf_2_do_revert, ibuf_1_do_revert, ibuf_0_do_revert}),
        .flow_ibuf_dens_wstrb    (ibuf_dens_wstrb),
        .flow_ibuf_conv_wstrb    (ibuf_conv_wstrb),
        .flow_ibuf_ld_wrn        ({ibuf_2_ld_wrn,    ibuf_1_ld_wrn,    ibuf_0_ld_wrn}),
        .flow_ibuf_bank_sel      ({ibuf_2_bank_sel,  ibuf_1_bank_sel,  ibuf_0_bank_sel}),
        .flow_ibuf_conv_fi_load  (ibuf_conv_fi_load),
        .flow_ibuf_conv_se_load  (ibuf_conv_se_load),
        .flow_ibuf_enb           ({ibuf_2_enb,       ibuf_1_enb,       ibuf_0_enb}),

        // Weight Buffer Ctrl
        .flow_wbuf_wstrb     ({wbuf_2_wstrb,    wbuf_1_wstrb,    wbuf_0_wstrb}),
        .flow_wbuf_ld_wrn    ({wbuf_2_ld_wrn,   wbuf_1_ld_wrn,   wbuf_0_ld_wrn}),
        .flow_wbuf_bank_sel  ({wbuf_2_bank_sel, wbuf_1_bank_sel, wbuf_0_bank_sel}),
        .flow_wbuf_enb       ({wbuf_2_enb,      wbuf_1_enb,      wbuf_0_enb}),

        // Input Demux and Register Ctrl
        .flow_idemux_sel (pu_matrix_isel),
        .flow_ireg_enb   ({
            ireg_enb_2_2, ireg_enb_2_1, ireg_enb_2_0,
            ireg_enb_1_2, ireg_enb_1_1, ireg_enb_1_0,
            ireg_enb_0_2, ireg_enb_0_1, ireg_enb_0_0
        }),

        // Weight Demux and Register Ctrl
        .flow_wdemux_sel (pu_matrix_wsel),
        .flow_wreg_enb   ({
            wreg_enb_2_2_2, wreg_enb_2_2_1, wreg_enb_2_2_0,
            wreg_enb_2_1_2, wreg_enb_2_1_1, wreg_enb_2_1_0,
            wreg_enb_2_0_2, wreg_enb_2_0_1, wreg_enb_2_0_0,
            wreg_enb_1_2_2, wreg_enb_1_2_1, wreg_enb_1_2_0,
            wreg_enb_1_1_2, wreg_enb_1_1_1, wreg_enb_1_1_0,
            wreg_enb_1_0_2, wreg_enb_1_0_1, wreg_enb_1_0_0,
            wreg_enb_0_2_2, wreg_enb_0_2_1, wreg_enb_0_2_0,
            wreg_enb_0_1_2, wreg_enb_0_1_1, wreg_enb_0_1_0,
            wreg_enb_0_0_2, wreg_enb_0_0_1, wreg_enb_0_0_0
        }),

        // Conv Direction 
        .flow_pu_matrix_conv_dir (pu_matrix_conv_dir),

        // Accumulate Matrix
        .flow_acc_matrix_enb_0           (acc_matrix_enb_0),
        .flow_acc_matrix_enb_1           (acc_matrix_enb_1),
        .flow_acc_matrix_bps_load        (acc_matrix_bps_load),
        .flow_acc_matrix_bps_write       (acc_matrix_bps_write),
        .flow_acc_matrix_inter_sum_write (acc_matrix_inter_sum_write),

        // Processing Matrix Ctrl
        .flow_pu_enb ({
            pu_enb_2_2, pu_enb_2_1, pu_enb_2_0,
            pu_enb_1_2, pu_enb_1_1, pu_enb_1_0,
            pu_enb_0_2, pu_enb_0_1, pu_enb_0_0
        }),

        // Element-Wise Unit Ctrl
        .flow_quant_act_func_enb ({quant_act_func_enb_2, quant_act_func_enb_1, quant_act_func_enb_0}),
        .flow_sel_demux          (sel_demux),
        .flow_sel_mux            (sel_mux),
        .flow_mpbuf_ld_wrn       (mpbuf_ld_wrn),
        .flow_buf_enb            (buf_enb),
        .flow_cp_enb             (cp_enb),
        .flow_resetn_pool        (resetn_pool),
        .flow_pool_ld_wrn        (pool_ld_wrn),
        .flow_pool_enb           (pool_enb),      


        // Output Buffer Ctrl
        .flow_obuf_enb       ({obuf_2_enb,    obuf_1_enb,    obuf_0_enb}),
        .flow_obuf_ld_wrn    ({obuf_2_ld_wrn, obuf_1_ld_wrn, obuf_0_ld_wrn}),

        // Out Sig Ctrl
        .flow_is_out_fin     (is_out_fin),
        .flow_o_quant_sel    (o_quant_sel),

        /* Feedback Control Sigs */
        // Input Buffer 
        .flow_ibuf_0_valid      (ibuf_0_valid),
        .flow_ibuf_1_valid      (ibuf_1_valid),
        .flow_ibuf_2_valid      (ibuf_2_valid),
        .flow_ibuf_0_nxt_valid  (ibuf_0_nxt_valid),
        .flow_ibuf_1_nxt_valid  (ibuf_1_nxt_valid),
        .flow_ibuf_2_nxt_valid  (ibuf_2_nxt_valid),
        
        // SoC Bus
        .flow_mem_read_ready      (al_accel_mem_read_ready),
        .flow_mem_write_ready     (al_accel_mem_write_ready),

        // Processing Matrix
        .flow_pu_matrix_rdy  (pu_matrix_rdy),

        // Element-Wise Unit Ctrl
        .flow_quant_act_func_rdy ({quant_act_func_rdy_2, quant_act_func_rdy_1, quant_act_func_rdy_0}),

        /* Mandatory Sigs */
        .flow_cal_fin       (al_accel_cal_fin),

        .enb    (al_accel_flow_enb),
        .clk    (clk),
        .resetn (resetn & al_accel_flow_resetn)
    );
endmodule
