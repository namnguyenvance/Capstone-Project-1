module fs_accel_flow_ctrl(
/* Config Signals */
    // Base Address 
    input [31:0] i_base_addr,
    input [31:0] kw_base_addr,
    input [31:0] o_base_addr,
    input [31:0] b_base_addr,
    input [31:0] ps_base_addr,

    // Layer Info
    input [ 3:0] cfg_layer_typ,
    // input [ 3:0] cfg_act_func_typ,
    input [ 3:0] stride_width,
    input [ 3:0] stride_height, 

    input [15:0] weight_kernel_patch_width,
    input [15:0] weight_kernel_patch_height,

    input [15:0] kernel_ifm_depth,
    input [15:0] nok_ofm_depth,

    input [15:0] ifm_width,
    input [15:0] ifm_height,

    input [15:0] ofm_width,
    input [15:0] ofm_height,

    // Pre-Cal Config Signals
    input [31:0] kernel3D_size, // = kernel_width * kernel_height * kernel_depth
    input [15:0] input2D_size , // = ifm_width * ifm_height 
    input [15:0] output2D_size, // = ofm_widht * ofm_height

    // Pool Size
    input [15:0] ofm_pool_height,
    input [15:0] ofm_pool_width,
    input [31:0] output2D_pool_size,

/* Output Control Sigs */
  //// RDATA Stage
    // SoC Read Data Ctrl
    output     [31:0] flow_mem_raddr,
    output            flow_mem_renb,

    // Bias/Partial-Sum Buffer Ctrl
    output     [ 2:0] flow_bpbuf_ld_wrn,
    output     [ 2:0] flow_bpbuf_enb,

    // Input Buffer Ctrl
    output     [ 2:0] flow_ibuf_di_revert,
    output     [ 2:0] flow_ibuf_do_revert,
    output     [ 1:0] flow_ibuf_dens_wstrb,
    output     [ 2:0] flow_ibuf_conv_wstrb,
    output     [ 2:0] flow_ibuf_ld_wrn,
    output     [ 5:0] flow_ibuf_bank_sel,
    output            flow_ibuf_conv_fi_load,
    output            flow_ibuf_conv_se_load,
    output     [ 2:0] flow_ibuf_enb,

    // Weight Buffer Ctrl
    output     [ 5:0] flow_wbuf_wstrb,
    output     [ 2:0] flow_wbuf_ld_wrn,
    output     [ 5:0] flow_wbuf_bank_sel,
    output     [ 2:0] flow_wbuf_enb,

    // Input Demux and Register Ctrl
    output     [ 1:0] flow_idemux_sel,
    output     [ 8:0] flow_ireg_enb,

    // Weight Demux and Register Ctrl
    output     [ 1:0] flow_wdemux_sel,
    output     [26:0] flow_wreg_enb,

    // Conv Direction 
    output     [ 1:0] flow_pu_matrix_conv_dir,

    // Accumulate Matrix
    output            flow_acc_matrix_enb_0,
    output            flow_acc_matrix_bps_load,

  //// COMPS Stage
    // Processing Matrix Ctrl
    output     [ 8:0] flow_pu_enb,

    // Accumulate Matrix Ctrl
    // output reg        acc_matrix_enb,
    // output reg        flow_acc_matrix_inter_sum_load,
    output            flow_acc_matrix_enb_1,
    // output            flow_acc_matrix_inter_sum_load,
    output            flow_acc_matrix_bps_write,
    output            flow_acc_matrix_inter_sum_write,

  //// POOL Stage
    // Element-Wise Unit Ctrl
    output      [2:0] flow_quant_act_func_enb,
    output      [3:0] flow_sel_demux,
    output      [3:0] flow_sel_mux,
    output            flow_mpbuf_ld_wrn,
    output            flow_buf_enb,
    output            flow_cp_enb,
    output            flow_resetn_pool,
    output            flow_pool_ld_wrn,
    output            flow_pool_enb,

  //// WBACK Stage
    // SoC Write Data Ctrl
    output     [31:0] flow_mem_waddr,
    output     [ 3:0] flow_mem_wstrb,
    output            flow_mem_wenb_0,
    output            flow_mem_wenb_1,
    output            flow_mem_wenb_2,

    

    // output reg Buffer Ctrl
    output     [ 2:0] flow_obuf_enb,
    output     [ 2:0] flow_obuf_ld_wrn,

    // Out Sig Ctrl
    output            flow_is_out_fin,
    output     [ 3:0] flow_o_quant_sel,

/* Feedback Control Sigs */
  //// RDATA Stage
    // Input Buffer 
    input [ 2:0] flow_ibuf_0_valid,
    input [ 2:0] flow_ibuf_1_valid,
    input [ 2:0] flow_ibuf_2_valid,
    input [ 2:0] flow_ibuf_0_nxt_valid,
    input [ 2:0] flow_ibuf_1_nxt_valid,
    input [ 2:0] flow_ibuf_2_nxt_valid,
    
    // SoC Bus
    input        flow_mem_read_ready,
    input        flow_mem_write_ready,

  //// COMPS Stage
    // Processing Matrix
    input        flow_pu_matrix_rdy,

  //// WBACK Stage
    // Element-Wise Unit Ctrl
    input [ 2:0] flow_quant_act_func_rdy,

/* Mandatory Sigs */
    output       flow_cal_fin,

    input enb,
    input clk,
    input resetn
);
/* Internal Pipeline Signal */
    wire    RDATA_fin, RDATA_rdy,
            COMPS_fin, COMPS_rdy,
            POOL_fin, POOL_rdy,
            WBACK_fin, WBACK_rdy;

    wire    COMPS_start,
            POOL_start,
            WBACK_start;

    wire    RDATA_is_out_fin,
            COMPS_is_out_fin,
            POOL_is_out_fin,
            WBACK_is_out_fin;

    wire POOL_ignore;

    wire [31:0] RDATA_o_addr, RDATA_ps_addr, 
                COMPS_o_addr, COMPS_ps_addr, 
                POOL_o_addr, POOL_ps_addr,
                WBACK_o_addr, WBACK_ps_addr;

    wire [ 3:0] RDATA_o_quant_sel,
                COMPS_o_quant_sel,
                POOL_o_quant_sel;

    assign flow_is_out_fin  = WBACK_is_out_fin;
    assign flow_o_quant_sel = POOL_o_quant_sel;

    assign flow_cal_fin = WBACK_fin;

/* Controller Init */
    fs_accel_RDATA_ctrl RDATA_ctrl(
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
        .ifm_width      (ifm_width),
        .ifm_height     (ifm_height),
        .ofm_width      (ofm_width),
        .ofm_height     (ofm_height),

        // Pre-Cal Config Signals
        .kernel3D_size  (kernel3D_size),
        .input2D_size   (input2D_size),
        .output2D_size  (output2D_size),

    /* Output Control Sigs */
        // SoC Read Data Ctrl
        .mem_raddr      (flow_mem_raddr),
        .mem_renb       (flow_mem_renb),

        // Bias/Partial-Sum Buffer Ctrl
        .bpbuf_ld_wrn   (flow_bpbuf_ld_wrn),
        .bpbuf_enb      (flow_bpbuf_enb),

        // Input Buffer Ctrl
        .ibuf_di_revert     (flow_ibuf_di_revert),
        .ibuf_do_revert     (flow_ibuf_do_revert),
        .ibuf_dens_wstrb    (flow_ibuf_dens_wstrb),
        .ibuf_conv_wstrb    (flow_ibuf_conv_wstrb),
        .ibuf_ld_wrn        (flow_ibuf_ld_wrn),
        .ibuf_bank_sel      (flow_ibuf_bank_sel),
        // .ibuf_is_conv_layer (flow_ibuf_is_conv_layer),
        .ibuf_conv_fi_load  (flow_ibuf_conv_fi_load),
        .ibuf_conv_se_load  (flow_ibuf_conv_se_load),
        .ibuf_enb           (flow_ibuf_enb),

        // Weight Buffer Ctrl
        .wbuf_wstrb     (flow_wbuf_wstrb),
        .wbuf_ld_wrn    (flow_wbuf_ld_wrn),
        .wbuf_bank_sel  (flow_wbuf_bank_sel),
        .wbuf_enb       (flow_wbuf_enb),

        // Input Demux and Register Ctrl
        .idemux_sel (flow_idemux_sel),
        .ireg_enb   (flow_ireg_enb),

        // Weight Demux and Register Ctrl
        .wdemux_sel (flow_wdemux_sel),
        .wreg_enb   (flow_wreg_enb),

        // Conv Direction 
        .pu_matrix_conv_dir (flow_pu_matrix_conv_dir),

        // Accumulate Matrix
        .acc_matrix_enb             (flow_acc_matrix_enb_0),
        .acc_matrix_bps_load        (flow_acc_matrix_bps_load),

        // Pipeline Stage Ctrl
        .RDATA_fin  (RDATA_fin),
        .RDATA_rdy  (RDATA_rdy),
        .RDATA_is_out_fin   (RDATA_is_out_fin),
        .RDATA_ps_addr      (RDATA_ps_addr),
        .RDATA_o_addr       (RDATA_o_addr),
        .RDATA_o_quant_sel  (RDATA_o_quant_sel),

    /* Feedback Control Sigs */
        // Input Buffer 
        .ibuf_0_valid       (flow_ibuf_0_valid),
        .ibuf_1_valid       (flow_ibuf_1_valid),
        .ibuf_2_valid       (flow_ibuf_2_valid),
        .ibuf_0_nxt_valid   (flow_ibuf_0_nxt_valid),
        .ibuf_1_nxt_valid   (flow_ibuf_1_nxt_valid),
        .ibuf_2_nxt_valid   (flow_ibuf_2_nxt_valid),
        
        // SoC Bus
        .mem_read_ready  (flow_mem_read_ready),

        // COMPS Controller
        .COMPS_rdy      (COMPS_rdy),
        .COMPS_start    (COMPS_start),

        // POOL Controller
        .POOL_rdy       (POOL_rdy),
        .POOL_start     (POOL_start),

        // WBACK Controller
        .WBACK_rdy      (WBACK_rdy),
        .WBACK_start    (WBACK_start),

    /* Mandatory Sigs */
        .enb    (enb),
        .clk    (clk),
        .resetn (resetn)
    );

    fs_accel_COMPS_ctrl COMPS_ctrl(
    /* Config Sigs */
        .cfg_layer_typ  (cfg_layer_typ),

    /* Output Control Sigs */
        // Processing Matrix Ctrl
        .pu_enb (flow_pu_enb),

        // Accumulate Matrix Ctrl
        .acc_matrix_enb               (flow_acc_matrix_enb_1),
        // .acc_matrix_inter_sum_load    (flow_acc_matrix_inter_sum_load),
        .acc_matrix_bps_write       (flow_acc_matrix_bps_write),
        .acc_matrix_inter_sum_write (flow_acc_matrix_inter_sum_write),

        // Pipeline Stage Ctrl
        .COMPS_fin      (COMPS_fin),
        .COMPS_rdy      (COMPS_rdy),
        .COMPS_start    (COMPS_start),
        .COMPS_is_out_fin   (COMPS_is_out_fin),
        .COMPS_ps_addr      (COMPS_ps_addr),
        .COMPS_o_addr       (COMPS_o_addr),
        .COMPS_o_quant_sel  (COMPS_o_quant_sel),

    /* Feedback Control Sigs */
        // Processing Matrix
        .pu_matrix_rdy  (flow_pu_matrix_rdy),

        // RDATA Controller
        .RDATA_fin  (RDATA_fin),
        .RDATA_rdy  (RDATA_rdy), 
        .RDATA_is_out_fin   (RDATA_is_out_fin),
        .RDATA_ps_addr      (RDATA_ps_addr),
        .RDATA_o_addr       (RDATA_o_addr),
        .RDATA_o_quant_sel  (RDATA_o_quant_sel),

        .POOL_rdy (POOL_rdy),
        .POOL_start (POOL_start),

        // WBACK Controller
        .WBACK_rdy      (WBACK_rdy),
        .WBACK_start    (WBACK_start),

    /* Mandatory Sigs */
        .enb    (enb),
        .clk    (clk),
        .resetn (resetn)
    );

    fs_accel_POOL_ctrl POOL_ctrl(
    /* Config Sigs */
        .cfg_layer_typ      (cfg_layer_typ),
        .ofm_width          (ofm_width),
        .ofm_pool_width     (ofm_pool_width),
        .ofm_pool_height    (ofm_pool_height),
        .output2D_pool_size (output2D_pool_size),
        .o_base_addr        (o_base_addr),

    /* Output Control Sigs */
        // Processing Matrix Ctrl
        .quant_act_func_enb (flow_quant_act_func_enb),
        .sel_demux          (flow_sel_demux),
        .sel_mux            (flow_sel_mux),
        .mpbuf_ld_wrn       (flow_mpbuf_ld_wrn),
        .buf_enb            (flow_buf_enb),
        .cp_enb             (flow_cp_enb),
        .resetn_pool        (flow_resetn_pool),
        .pool_ld_wrn        (flow_pool_ld_wrn),
        .pool_enb           (flow_pool_enb),

        // Pipeline Stage Ctrl
        .POOL_fin      (POOL_fin),
        .POOL_rdy      (POOL_rdy),
        .POOL_start    (POOL_start),
        .POOL_is_out_fin    (POOL_is_out_fin),
        .POOL_o_addr        (POOL_o_addr),
        .POOL_ps_addr       (POOL_ps_addr),
        .POOL_o_quant_sel   (POOL_o_quant_sel),
        .POOL_ignore        (POOL_ignore),
    
    /* Feedback Control Sigs */
    // Element-Wise Unit Ctrl
        .quant_act_func_rdy (flow_quant_act_func_rdy),

        // RDATA Controller
        .RDATA_rdy  (RDATA_rdy),
        .RDATA_fin  (RDATA_fin), 
        .RDATA_is_out_fin   (RDATA_is_out_fin),
        .RDATA_o_addr       (RDATA_o_addr),

        // COMPS Controller
        .COMPS_fin          (COMPS_fin),
        .COMPS_rdy          (COMPS_rdy),
        .COMPS_start        (COMPS_start),
        .COMPS_is_out_fin   (COMPS_is_out_fin),
        .COMPS_o_addr       (COMPS_o_addr),
        .COMPS_ps_addr      (COMPS_ps_addr),
        .COMPS_o_quant_sel  (COMPS_o_quant_sel),

        // WBACK Controller
        .WBACK_start    (WBACK_start),
        .WBACK_rdy      (WBACK_rdy),

    /* Mandatory Sigs */
        .enb    (enb),
        .clk    (clk),
        .resetn (resetn)
    );

    fs_accel_WBACK_ctrl WBACK_ctrl(
    /* Config Sigs */
        // Layer Info
        .cfg_layer_typ  (cfg_layer_typ),

        // Pre-Cal Config Signals
        .output2D_size      (output2D_size), // = ofm_widht * ofm_height
        .output2D_pool_size (output2D_pool_size),

    /* Output Control Sigs */
        // SoC Write Data Ctrl
        .mem_waddr  (flow_mem_waddr),
        .mem_wstrb  (flow_mem_wstrb),
        .mem_wenb_0 (flow_mem_wenb_0),
        .mem_wenb_1 (flow_mem_wenb_1),
        .mem_wenb_2 (flow_mem_wenb_2),

        // Output Buffer Ctrl
        .obuf_enb       (flow_obuf_enb),
        .obuf_ld_wrn    (flow_obuf_ld_wrn),

        // Pipeline Stage Ctrl
        .WBACK_fin      (WBACK_fin),
        .WBACK_rdy      (WBACK_rdy),
        .WBACK_start    (WBACK_start),
        .WBACK_is_out_fin   (WBACK_is_out_fin),
        .WBACK_ps_addr      (WBACK_ps_addr),
        .WBACK_o_addr       (WBACK_o_addr),

    /* Feedback Control Sigs */
         // SoC Sig
        .mem_write_ready    (flow_mem_write_ready),

        // RDATA Controller
        .RDATA_rdy  (RDATA_rdy),
        .RDATA_fin  (RDATA_fin),
        .RDATA_is_out_fin   (RDATA_is_out_fin),
        .RDATA_o_addr       (RDATA_o_addr),

        // COMPS Controller
        .COMPS_fin          (COMPS_fin),
        .COMPS_rdy          (COMPS_rdy), 
        .COMPS_start        (COMPS_start),
        .COMPS_is_out_fin   (COMPS_is_out_fin),
        .COMPS_ps_addr      (COMPS_ps_addr),

        // POOL Controller
        .POOL_fin           (POOL_fin),
        .POOL_rdy           (POOL_rdy), 
        .POOL_start         (POOL_start),
        .POOL_is_out_fin    (POOL_is_out_fin),
        .POOL_o_addr        (POOL_o_addr),
        .POOL_ps_addr       (POOL_ps_addr),
        .POOL_ignore        (POOL_ignore),


    /* Mandatory Sigs */
        .enb    (enb),
        .clk    (clk),
        .resetn (resetn)
    );
endmodule