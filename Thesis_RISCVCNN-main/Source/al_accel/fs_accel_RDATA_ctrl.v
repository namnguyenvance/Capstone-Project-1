module fs_accel_RDATA_ctrl (
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
    input [15:0] output2D_size, // = ofm_width * ofm_height

/* Output Control Sigs */
    // SoC Read Data Ctrl
    output reg [31:0] mem_raddr,
    output reg        mem_renb,

    // Bias/Partial-Sum Buffer Ctrl
    output reg [ 2:0] bpbuf_ld_wrn,
    output reg [ 2:0] bpbuf_enb,

    // Input Buffer Ctrl
    output reg [ 2:0] ibuf_di_revert,
    output reg [ 2:0] ibuf_do_revert,
    output reg [ 1:0] ibuf_dens_wstrb,
    output reg [ 2:0] ibuf_conv_wstrb,
    output reg [ 2:0] ibuf_ld_wrn,
    output reg [ 5:0] ibuf_bank_sel,
    output reg        ibuf_conv_fi_load,
    output reg        ibuf_conv_se_load,
    output reg [ 2:0] ibuf_enb,

    // Weight Buffer Ctrl
    output reg [ 5:0] wbuf_wstrb,
    output reg [ 2:0] wbuf_ld_wrn,
    output reg [ 5:0] wbuf_bank_sel,
    output reg [ 2:0] wbuf_enb,

    // Input Demux and Register Ctrl
    output reg [ 1:0] idemux_sel,
    output reg [ 8:0] ireg_enb,

    // Weight Demux and Register Ctrl
    output reg [ 1:0] wdemux_sel,
    output reg [26:0] wreg_enb,

    // Conv Direction 
    output reg [ 1:0] pu_matrix_conv_dir,

    // Accumulate Matrix
    output reg        acc_matrix_enb,
    output reg        acc_matrix_bps_load,


    // Pipeline Stage Ctrl
    output reg        RDATA_fin,
    output reg        RDATA_rdy,
    output reg        RDATA_is_out_fin,
    output reg [31:0] RDATA_ps_addr,
    output reg [31:0] RDATA_o_addr,
    output reg [ 3:0] RDATA_o_quant_sel,

/* Feedback Control Sigs */
    // Input Buffer 
    input [ 2:0] ibuf_0_valid,
    input [ 2:0] ibuf_1_valid,
    input [ 2:0] ibuf_2_valid,
    input [ 2:0] ibuf_0_nxt_valid,
    input [ 2:0] ibuf_1_nxt_valid,
    input [ 2:0] ibuf_2_nxt_valid,
    
    // // SoC Bus
    input        mem_read_ready,

    // COMPS Controller
    input        COMPS_rdy,
    input        COMPS_start,

    // POOL Controller
    input       POOL_rdy,
    input       POOL_start,

    // WBACK Controller
    input        WBACK_rdy,
    input        WBACK_start,

/* Mandatory Sigs */
    input enb,
    input clk,
    input resetn
);
/* SoC Parameter Definition */
    // parameter NUMBER_OF_ = 1;

/* ALL Local Param Definition */
    // Layer Param
    localparam 
        CONV    = 4'd 0,
        DENSE   = 4'd 1,
        MIXED    = 4'd 2;

    // State Param
    localparam
        G_START     = 4'd 0,
        G_WREAD     = 4'd 1,
        G_WLOAD     = 4'd 2,
        G_BREAD     = 4'd 3,
        G_PSREAD    = 4'd 4,
        G_BPSLOAD   = 4'd 5,
        G_IREAD     = 4'd 6,
        G_ILOAD     = 4'd 7,
        G_WAIT      = 4'd 8,
        G_FINISH    = 4'd 9;

    // Mini State Param
    localparam 
        W_READ_0    = 3'd 0,
        W_READ_1    = 3'd 1,
        W_READ_2    = 3'd 2, 
        W_LOAD_0    = 3'd 3,
        W_LOAD_1    = 3'd 4,
        W_LOAD_2    = 3'd 5;

    // Mini State Param
    localparam
        I_START         = 3'd 0,
        I_SHIFT_LEFT    = 3'd 1,
        I_DOWN_R2L      = 3'd 2,
        I_SHIFT_RIGHT   = 3'd 3,
        I_DOWN_L2R      = 3'd 4,
        I_FINISH_L      = 3'd 5,
        I_FINISH_R      = 3'd 6; 

    // Direction Param
    localparam 
        NON   = 2'b 00,
        LEFT  = 2'b 01,
        RIGHT = 2'b 10,
        DOWN  = 2'b 11; 

/*  ALL Signal Definition */
    // State Define
    reg [3:0] RDATA_gstate;
    reg [3:0] RDATA_wmini_state;
    reg [3:0] RDATA_imini_state;
    
    // Coordinate Define
    reg [15:0] in_x, in_y;
    reg [15:0] kw_x, kw_y, kw_in_z, kw_num_ou_z;
    reg [15:0] ou_x, ou_y;

    // Counter Define
    reg [ 4:0] state_cnt;
    reg [ 4:0] stride_cnt;

    reg [ 4:0] sp_init_ictn_0;
    reg [ 4:0] sp_init_ictn_1;

    reg [ 4:0] sp_run_ictn;

    reg        read_mem_state;

    // Address Control
    reg  [31:0] kw_addr_0_0;
    wire [31:0] kw_addr_0_1, kw_addr_0_2;
    wire [31:0] kw_addr_1_0;
    wire [31:0] kw_addr_1_1, kw_addr_1_2;
    wire [31:0] kw_addr_2_0;
    wire [31:0] kw_addr_2_1, kw_addr_2_2;
    assign kw_addr_0_1 = kw_addr_0_0 + 9;
    assign kw_addr_0_2 = kw_addr_0_1 + 9;
    assign kw_addr_1_0 = kw_addr_0_0 + kernel3D_size;
    assign kw_addr_1_1 = kw_addr_1_0 + 9;
    assign kw_addr_1_2 = kw_addr_1_1 + 9;
    assign kw_addr_2_0 = kw_addr_1_0 + kernel3D_size;
    assign kw_addr_2_1 = kw_addr_2_0 + 9;
    assign kw_addr_2_2 = kw_addr_2_1 + 9; 

    wire [31:0] kw_addr_0, kw_addr_1, kw_addr_2;
    assign kw_addr_0 = kw_addr_0_0;
    assign kw_addr_1 = kw_addr_0 + weight_kernel_patch_width;
    assign kw_addr_2 = kw_addr_1 + weight_kernel_patch_width;

    reg  [31:0] i_addr_0_0;
    wire [31:0] i_addr_0_1, i_addr_0_2;
    wire [31:0] i_addr_1_0;
    wire [31:0] i_addr_1_1, i_addr_1_2;
    wire [31:0] i_addr_2_0;
    wire [31:0] i_addr_2_1, i_addr_2_2;
    assign i_addr_0_1 = i_addr_0_0 + ifm_width;
    assign i_addr_0_2 = i_addr_0_1 + ifm_width;
    assign i_addr_1_0 = i_addr_0_0 + input2D_size;
    assign i_addr_1_1 = i_addr_1_0 + ifm_width;
    assign i_addr_1_2 = i_addr_1_1 + ifm_width;
    assign i_addr_2_0 = i_addr_1_0 + input2D_size;
    assign i_addr_2_1 = i_addr_2_0 + ifm_width;
    assign i_addr_2_2 = i_addr_2_1 + ifm_width;

    wire [31:0] i_p_addr_2, i_p_addr_1, i_p_addr_0;
    assign i_p_addr_0 = i_addr_0_0;
    assign i_p_addr_1 = i_addr_0_1;
    assign i_p_addr_2 = i_addr_0_2;

    wire [31:0] i_sl_addr_0_0, i_sl_addr_0_1, i_sl_addr_0_2;
    wire [31:0] i_sl_addr_1_0, i_sl_addr_1_1, i_sl_addr_1_2;
    wire [31:0] i_sl_addr_2_0, i_sl_addr_2_1, i_sl_addr_2_2;
    assign i_sl_addr_0_0 = i_addr_0_0 + 3;
    assign i_sl_addr_0_1 = i_addr_0_1 + 3;
    assign i_sl_addr_0_2 = i_addr_0_2 + 3;
    assign i_sl_addr_1_0 = i_addr_1_0 + 3;
    assign i_sl_addr_1_1 = i_addr_1_1 + 3;
    assign i_sl_addr_1_2 = i_addr_1_2 + 3;
    assign i_sl_addr_2_0 = i_addr_2_0 + 3;
    assign i_sl_addr_2_1 = i_addr_2_1 + 3;
    assign i_sl_addr_2_2 = i_addr_2_2 + 3;

    wire [31:0] i_dr2l_addr_0, i_dr2l_addr_1, i_dr2l_addr_2;
    assign i_dr2l_addr_0 = i_addr_0_2 + ifm_width + 2;
    assign i_dr2l_addr_1 = i_addr_1_2 + ifm_width + 2;
    assign i_dr2l_addr_2 = i_addr_2_2 + ifm_width + 2;

    wire [31:0] i_sr_addr_0_0, i_sr_addr_0_1, i_sr_addr_0_2;
    wire [31:0] i_sr_addr_1_0, i_sr_addr_1_1, i_sr_addr_1_2;
    wire [31:0] i_sr_addr_2_0, i_sr_addr_2_1, i_sr_addr_2_2;
    assign i_sr_addr_0_0 = i_addr_0_0 - 1;
    assign i_sr_addr_0_1 = i_addr_0_1 - 1;
    assign i_sr_addr_0_2 = i_addr_0_2 - 1;
    assign i_sr_addr_1_0 = i_addr_1_0 - 1;
    assign i_sr_addr_1_1 = i_addr_1_1 - 1;
    assign i_sr_addr_1_2 = i_addr_1_2 - 1;
    assign i_sr_addr_2_0 = i_addr_2_0 - 1;
    assign i_sr_addr_2_1 = i_addr_2_1 - 1;
    assign i_sr_addr_2_2 = i_addr_2_2 - 1;

    wire [31:0] i_dl2r_addr_0, i_dl2r_addr_1, i_dl2r_addr_2;
    assign i_dl2r_addr_0 = i_addr_0_2 + ifm_width;
    assign i_dl2r_addr_1 = i_addr_1_2 + ifm_width;
    assign i_dl2r_addr_2 = i_addr_2_2 + ifm_width;

    reg  [31:0] b_addr_0;
    wire [31:0] b_addr_1, b_addr_2;
    assign b_addr_1 = b_addr_0 + 4;
    assign b_addr_2 = b_addr_1 + 4;

    reg  [31:0] ps_addr_0;
    wire [31:0] ps_addr_1, ps_addr_2;
    assign ps_addr_1[ 1:0] = ps_addr_0[ 1:0];
    assign ps_addr_1[31:2] = ps_addr_0[31:2] + output2D_size;
    assign ps_addr_2[ 1:0] = ps_addr_1[ 1:0];
    assign ps_addr_2[31:2] = ps_addr_1[31:2] + output2D_size;

    reg  [31:0] o_addr_0;
    wire [31:0] o_addr_1, o_addr_2;
    assign o_addr_1 = o_addr_0 + output2D_size;
    assign o_addr_2 = o_addr_1 + output2D_size;

    reg  [ 3:0] o_quant_sel;

// ALL Control Signal
    // Output Control Signals
    // reg [31:0] mem_raddr;
    // reg        mem_renb;

    // reg [ 2:0] bpbuf_ld_wrn;
    // reg [ 2:0] bpbuf_enb;

    // reg [ 2:0] ibuf_di_revert;
    // reg [ 2:0] ibuf_do_revert;
    // reg [ 1:0] ibuf_dens_wstrb;
    // reg [ 2:0] ibuf_conv_wstrb;
    // reg [ 2:0] ibuf_ld_wrn;
    // reg [ 5:0] ibuf_bank_sel;
    // reg        ibuf_conv_fi_load;
    // reg        ibuf_conv_se_load;
    // reg [ 2:0] ibuf_enb;

    // reg [ 5:0] wbuf_wstrb;
    // reg [ 2:0] wbuf_ld_wrn;
    // reg [ 5:0] wbuf_bank_sel;
    // reg [ 2:0] wbuf_enb;
    
    // reg [ 1:0] idemux_sel;
    // reg [ 8:0] ireg_enb;

    // reg [ 1:0] wdemux_sel;
    // reg [26:0] wreg_enb;

    // reg [ 1:0] pu_matrix_conv_dir;

    // reg        acc_matrix_enb;
    // reg        acc_matrix_bps_load;


    // // Pipeline Sigs
    // reg         RDATA_rdy;
    // reg         RDATA_fin;
    // reg         RDATA_is_out_fin;
    // reg [31:0]  RDATA_ps_addr;
    // reg [31:0]  RDATA_o_addr;
    // reg [ 3:0]  RDATA_o_quant_sel;

    reg         is_out_fin;

    reg [31:0]  inter_ps_addr;
    reg [31:0]  inter_o_addr;
    reg [ 3:0]  inter_o_quant_sel;

    always @(*) begin
        is_out_fin = 0;
        case (cfg_layer_typ)
            CONV    : is_out_fin = (kw_in_z + 3    >= kernel_ifm_depth         );
            DENSE   : is_out_fin = (in_x + 9       >= weight_kernel_patch_width);
            MIXED   : is_out_fin = (kw_in_z + 3    >= kernel_ifm_depth         );
        endcase
    end

/* Internal Sigs */
    wire RDATA_reg_enb;
    assign RDATA_reg_enb = RDATA_rdy && (COMPS_rdy || COMPS_start) && (POOL_rdy || POOL_start) && (WBACK_rdy || WBACK_start) & enb;

    reg [15:0] ifm_width_X_stride_height_SUB_offset; 
    // ifm_width_X_stride_height + 1 - ifm_width;
    always @(*) begin
        ifm_width_X_stride_height_SUB_offset = 1;
        case (stride_height)
            4'd 1: ifm_width_X_stride_height_SUB_offset = 1 + kernel3D_size;
            4'd 2: ifm_width_X_stride_height_SUB_offset = 1 + ifm_width + kernel3D_size;
            4'd 3: ifm_width_X_stride_height_SUB_offset = 1 + ifm_width + ifm_width + kernel3D_size;
        endcase
    end

    reg [15:0] ifm_width_X_padding;
    always @(*) begin
        ifm_width_X_padding = 0;
        case (kernel3D_size)
            4'd 1: ifm_width_X_padding = ifm_width;
            4'd 2: ifm_width_X_padding = ifm_width + ifm_width;
        endcase
    end

    reg [15:0] ifm_width_X_patch_height_SUB_offset;
    // ifm_width_X_patch_height + 1 - ifm_width
    always @(*) begin
        ifm_width_X_patch_height_SUB_offset = 0;
        case (weight_kernel_patch_width)
            4'd 1: ifm_width_X_patch_height_SUB_offset = 1 + kernel3D_size + ifm_width_X_padding;
            4'd 2: ifm_width_X_patch_height_SUB_offset = 1 + ifm_width + kernel3D_size + ifm_width_X_padding;
            4'd 3: ifm_width_X_patch_height_SUB_offset = 1 + ifm_width + ifm_width + kernel3D_size + ifm_width_X_padding;
        endcase
    end

    wire [4:0] stride_cnt_max;
    assign stride_cnt_max = (in_x < weight_kernel_patch_width) ? weight_kernel_patch_width : stride_width;

/* FSM Transition */
    always @(posedge clk) begin
        if (!resetn) begin
            RDATA_gstate      <= G_START;
            RDATA_wmini_state <= W_READ_0;
            RDATA_imini_state <= I_START;
        end 
        else if (enb) begin
            case (cfg_layer_typ)

/* CONVOLUTIONAL LAYER */
// Kernel-Based Computation FSM
                CONV: begin
                case (RDATA_gstate)
        // State: G_START
                    G_START: // Inite state and value
                    begin
                        RDATA_gstate      <= G_WREAD;
                        RDATA_wmini_state <= W_READ_0;
                        RDATA_imini_state <= I_START;
                    end

        // State: G_WREAD        
                    G_WREAD: // Read total 27 Kernel values (4 Sequential Value per 1 Read)
                    if (state_cnt >= 9 - 1 && read_mem_state) begin
                        if (mem_read_ready) begin
                            RDATA_gstate <= G_WLOAD; 
                            case (RDATA_wmini_state)
                                W_READ_0: RDATA_wmini_state <= W_LOAD_0;
                                W_READ_1: RDATA_wmini_state <= W_LOAD_1;
                                W_READ_2: RDATA_wmini_state <= W_LOAD_2;
                            endcase
                        end
                    end

        // State: G_WLOAD
                    G_WLOAD: // Load 3 times (9 Kernel values per time)
                    if (state_cnt >= 3 - 1) begin
                        case (RDATA_wmini_state)
                            W_LOAD_0: begin
                                RDATA_gstate <= G_WREAD;
                                RDATA_wmini_state <= W_READ_1;
                            end

                            W_LOAD_1: begin
                                RDATA_gstate <= G_WREAD;
                                RDATA_wmini_state <= W_READ_2;
                            end

                            W_LOAD_2: begin
                                if (kw_in_z < 3)
                                    RDATA_gstate <= G_BREAD;
                                    // RDATA_gstate <= G_BPSLOAD;
                                else 
                                    RDATA_gstate <= G_PSREAD;
                                RDATA_wmini_state <= W_READ_0;
                            end
                        endcase
                    end

        // State: G_BREAD
                    G_BREAD: // Read 3 Bias values
                    if ((state_cnt >= 3 - 1) && read_mem_state) begin
                        if (mem_read_ready)
                            RDATA_gstate <= G_BPSLOAD;
                    end

        // State: G_PSREAD
                    G_PSREAD: // Read 3 Partial-Sum values
                    if ((state_cnt >= 3 - 1) && read_mem_state) begin 
                        if (mem_read_ready)
                            RDATA_gstate <= G_BPSLOAD;
                    end
                        
        // State: G_BPSLOAD
                    G_BPSLOAD: begin // Load 1 times from BPBUF (3 Bias/Partial-Sum values per time)
                        if (RDATA_imini_state == I_SHIFT_LEFT || RDATA_imini_state == I_SHIFT_RIGHT) begin
                            if (sp_init_ictn_0 < 9) 
                                RDATA_gstate <= G_IREAD;
                            else
                                RDATA_gstate <= G_ILOAD;
                        end else RDATA_gstate <= G_IREAD;
                    end
                        
        // State: G_IREAD
                    G_IREAD: // Load Input Feature Map (The most complicated part)
                    if (read_mem_state) begin
                        if (mem_read_ready) begin
                        case (RDATA_imini_state)
            // Mini State: I_START
                            I_START: // Read 9 Input Feature Map values
                            if (state_cnt >= 18 - 1) begin 
                                RDATA_gstate <= G_ILOAD;
                            end

            // Mini State: I_SHIFT_LEFT
                            I_SHIFT_LEFT: 
                            if (sp_run_ictn >= 9) begin
                                RDATA_gstate <= G_ILOAD;
                            end
                            
            // Mini State: I_DOWN_R2L
                            I_DOWN_R2L: 
                            if (state_cnt >= 6 - 1) begin
                                RDATA_gstate <= G_ILOAD;
                            end 

            // Mini State: I_SHIFT_RIGHT
                            I_SHIFT_RIGHT: 
                            if (sp_run_ictn >= 9) begin
                                RDATA_gstate <= G_ILOAD;
                            end

            // Mini State: I_DOWN_L2R
                            I_DOWN_L2R: 
                            if (state_cnt >= 6 - 1) begin
                                RDATA_gstate <= G_ILOAD;
                            end

            // Mini State: I_FINISH_L
                            // I_FINISH_L: 

            // Mini State: I_FINISH_R
                            // I_FINISH_R: 
                        endcase 
                        end
                    end
                        
        // State: G_ILOAD
                    G_ILOAD:
                    case (RDATA_imini_state) 
            // Mini State: I_SLOAD
                        I_START: // Load 3 times (9 Input Feature Map values per time)
                        if (state_cnt >= 3 - 1) begin
                            RDATA_imini_state <= I_SHIFT_LEFT;
                            RDATA_gstate <= G_WAIT;
                        end

            // Mini State: I_SHIFT_LEFT
                        I_SHIFT_LEFT: begin
                            if (stride_cnt >= stride_width - 1) begin
                                if (in_x + weight_kernel_patch_width + stride_width >= ifm_width) begin
                                    if (in_y + weight_kernel_patch_height >= ifm_height)
                                        RDATA_imini_state <= I_FINISH_L;
                                    else
                                        RDATA_imini_state <= I_DOWN_R2L;
                                end

                                RDATA_gstate <= G_WAIT;
                            end
                            else begin
                                if (sp_init_ictn_1 < 9)
                                    RDATA_gstate <= G_IREAD;
                                else
                                    RDATA_gstate <= G_ILOAD;
                            end
                        end

            // Mini State: I_DOWN_R2L
                        I_DOWN_R2L: begin
                            if (stride_cnt >= stride_height - 1) begin
                                RDATA_gstate <= G_WAIT;
                                RDATA_imini_state <= I_SHIFT_RIGHT;
                            end
                            else 
                                RDATA_gstate <= G_IREAD;
                        end

            // Mini State: I_SHIFT_RIGHT
                        I_SHIFT_RIGHT: begin
                            if (stride_cnt >= stride_width - 1) begin
                                if (in_x <= stride_width) begin
                                    if (in_y + weight_kernel_patch_height >= ifm_height) 
                                        RDATA_imini_state <= I_FINISH_R;
                                    else
                                        RDATA_imini_state <= I_DOWN_L2R;
                                end

                                RDATA_gstate <= G_WAIT;
                            end
                            else begin
                                if (sp_init_ictn_1 < 9)
                                    RDATA_gstate <= G_IREAD;
                                else
                                    RDATA_gstate <= G_ILOAD;
                            end 
                        end

            // Mini State: I_DOWN_L2R
                        I_DOWN_L2R: begin
                            if (stride_cnt >= stride_height - 1) begin
                                RDATA_imini_state <= I_SHIFT_LEFT;

                                RDATA_gstate <= G_WAIT;
                            end
                            else 
                                RDATA_gstate <= G_IREAD;
                        end

            // Mini State: I_FINISH_L
                        // I_FINISH_L: 

            // Mini State: I_FINISH_R
                        // I_FINISH_R: 

                    endcase

        // State: G_WAIT    
                    G_WAIT: begin
                        if (RDATA_rdy && (COMPS_rdy || COMPS_start) && (POOL_rdy || POOL_start)  &&(WBACK_rdy || WBACK_start)) begin
                            if (RDATA_imini_state == I_FINISH_L || RDATA_imini_state == I_FINISH_R) begin
                                RDATA_imini_state <= I_START;
                                if (kw_num_ou_z + 3 >= nok_ofm_depth && kw_in_z + 3 >= kernel_ifm_depth) 
                                    RDATA_gstate <= G_FINISH;
                                else 
                                    RDATA_gstate <= G_WREAD;
                            end else begin
                                if (kw_in_z < 3)
                                    RDATA_gstate <= G_BPSLOAD;
                                else 
                                    RDATA_gstate <= G_PSREAD;
                            end         
                        end
                    end

        // State: G_FINISH
                    // G_FINISH:
                endcase
                end
/***************************/

/*** FULLY-CONNECTED LAYER ***/
// Input-Based Computation FSM
                DENSE: begin
                case (RDATA_gstate)
        // State: G_START
                    G_START: // Inite state and value
                    begin
                        RDATA_gstate <= G_IREAD;
                    end

        // State: G_WREAD
                    G_WREAD: // Read total 27 Kernel values (4 Sequential Value per 1 Read)
                    if (state_cnt >= 9 - 1 && read_mem_state) begin
                        if (mem_read_ready) 
                            RDATA_gstate <= G_WLOAD; 
                    end

        // State: G_WLOAD
                    G_WLOAD: 
                    if (state_cnt >= 3 - 1) begin
                        RDATA_gstate <= G_WAIT;
                    end

        // State: G_BREAD
                    G_BREAD: 
                    if ((state_cnt >= 3 - 1) && read_mem_state) begin 
                        if (mem_read_ready)
                            RDATA_gstate <= G_BPSLOAD;
                    end

        // State: G_PSREAD
                    G_PSREAD: 
                    if ((state_cnt >= 3 - 1) && read_mem_state) begin 
                        if (mem_read_ready)
                            RDATA_gstate <= G_BPSLOAD;
                    end

        // State: G_BPSLOAD
                    G_BPSLOAD: begin
                        RDATA_gstate <= G_WREAD;
                    end

        // State: G_IREAD
                    G_IREAD: // Read 9 Input value (3 WORDS)
                    if (state_cnt >= 3 - 1 && read_mem_state) begin
                        if (mem_read_ready)
                            RDATA_gstate <= G_ILOAD; 
                    end

        // State: G_ILOAD
                    G_ILOAD: 
                    if (state_cnt >= 3 - 1) begin
                        if (in_x < 9) 
                            RDATA_gstate <= G_BREAD;
                        else
                            RDATA_gstate <= G_PSREAD;
                    end

        // State: G_WAIT
                    G_WAIT: begin
                        if (RDATA_rdy && (COMPS_rdy || COMPS_start) && (POOL_rdy || POOL_start)  &&(WBACK_rdy || WBACK_start)) begin
                            if (ou_x + 3 >= weight_kernel_patch_height) begin
                                if (in_x + 9 >= weight_kernel_patch_width) 
                                    RDATA_gstate <= G_FINISH;
                                else
                                    RDATA_gstate <= G_IREAD;
                            end
                            else begin
                                // RDATA_gstate <= G_WREAD;
                                if (in_x < 9) 
                                    RDATA_gstate <= G_BREAD;
                                else
                                    RDATA_gstate <= G_PSREAD;
                            end
                        end
                    end
    
        // State: G_FINISH
                    // G_FINISH: 

                endcase
                end
/*****************************/

/*** MIXED LAYER ***/
// No-Comp Computation FSM
                MIXED: begin
                case (RDATA_gstate)
        // State: G_START
                    G_START: // Inite state and value
                    begin
                        RDATA_gstate      <= G_WREAD;
                        RDATA_wmini_state <= W_READ_0;
                        RDATA_imini_state <= I_START;
                    end

        // State: G_WREAD        
                    G_WREAD: // Read total 27 Kernel values (4 Sequential Value per 1 Read)
                    if (state_cnt >= 9 - 1 && read_mem_state) begin
                        if (mem_read_ready) begin
                            RDATA_gstate <= G_WLOAD; 
                            case (RDATA_wmini_state)
                                W_READ_0: RDATA_wmini_state <= W_LOAD_0;
                                W_READ_1: RDATA_wmini_state <= W_LOAD_1;
                                W_READ_2: RDATA_wmini_state <= W_LOAD_2;
                            endcase
                        end
                    end

        // State: G_WLOAD
                    G_WLOAD: // Load 3 times (9 Kernel values per time)
                    if (state_cnt >= 3 - 1) begin
                        case (RDATA_wmini_state)
                            W_LOAD_0: begin
                                RDATA_gstate <= G_WREAD;
                                RDATA_wmini_state <= W_READ_1;
                            end

                            W_LOAD_1: begin
                                RDATA_gstate <= G_WREAD;
                                RDATA_wmini_state <= W_READ_2;
                            end

                            W_LOAD_2: begin
                                if (kw_in_z < 3)
                                    RDATA_gstate <= G_BREAD;
                                    // RDATA_gstate <= G_BPSLOAD;
                                else 
                                    RDATA_gstate <= G_PSREAD;
                                RDATA_wmini_state <= W_READ_0;
                            end
                        endcase
                    end

        // State: G_BREAD
                    G_BREAD: // Read 3 Bias values
                    if ((state_cnt >= 3 - 1) && read_mem_state) begin
                        if (mem_read_ready)
                            RDATA_gstate <= G_BPSLOAD;
                    end

        // State: G_PSREAD
                    G_PSREAD: // Read 3 Partial-Sum values
                    if ((state_cnt >= 3 - 1) && read_mem_state) begin 
                        if (mem_read_ready)
                            RDATA_gstate <= G_BPSLOAD;
                    end
                        
        // State: G_BPSLOAD
                    G_BPSLOAD: begin // Load 1 times from BPBUF (3 Bias/Partial-Sum values per time)
                        if (RDATA_imini_state == I_SHIFT_LEFT || RDATA_imini_state == I_SHIFT_RIGHT) begin
                            if (sp_init_ictn_0 < 9) 
                                RDATA_gstate <= G_IREAD;
                            else
                                RDATA_gstate <= G_ILOAD;
                        end else RDATA_gstate <= G_IREAD;
                    end
                        
        // State: G_IREAD
                    G_IREAD: // Load Input Feature Map (The most complicated part)
                    if (read_mem_state) begin
                        if (mem_read_ready) begin
                        case (RDATA_imini_state)
            // Mini State: I_START
                            I_START: // Read 9 Input Feature Map values
                            if (state_cnt >= 18 - 1) begin 
                                RDATA_gstate <= G_ILOAD;
                            end

            // Mini State: I_SHIFT_LEFT
                            I_SHIFT_LEFT: 
                            if (sp_run_ictn >= 9) begin
                                RDATA_gstate <= G_ILOAD;
                            end
                            
            // Mini State: I_DOWN_R2L
                            I_DOWN_R2L: 
                            if (state_cnt >= 6 - 1) begin
                                RDATA_gstate <= G_ILOAD;
                            end 

            // Mini State: I_SHIFT_RIGHT
                            I_SHIFT_RIGHT: 
                            if (sp_run_ictn >= 9) begin
                                RDATA_gstate <= G_ILOAD;
                            end

            // Mini State: I_DOWN_L2R
                            I_DOWN_L2R: 
                            if (state_cnt >= 6 - 1) begin
                                RDATA_gstate <= G_ILOAD;
                            end

            // Mini State: I_FINISH_L
                            // I_FINISH_L: 

            // Mini State: I_FINISH_R
                            // I_FINISH_R: 
                        endcase 
                        end
                    end
                        
        // State: G_ILOAD
                    G_ILOAD:
                    case (RDATA_imini_state) 
            // Mini State: I_SLOAD
                        I_START: // Load 3 times (9 Input Feature Map values per time)
                        if (state_cnt >= 3 - 1) begin
                            RDATA_imini_state <= I_SHIFT_LEFT;
                            RDATA_gstate <= G_WAIT;
                        end

            // Mini State: I_SHIFT_LEFT
                        I_SHIFT_LEFT: begin
                            if (stride_cnt >= stride_width - 1) begin
                                if (in_x + weight_kernel_patch_width + stride_width >= ifm_width) begin
                                    if (in_y + weight_kernel_patch_height >= ifm_height)
                                        RDATA_imini_state <= I_FINISH_L;
                                    else
                                        RDATA_imini_state <= I_DOWN_R2L;
                                end

                                RDATA_gstate <= G_WAIT;
                            end
                            else begin
                                if (sp_init_ictn_1 < 9)
                                    RDATA_gstate <= G_IREAD;
                                else
                                    RDATA_gstate <= G_ILOAD;
                            end
                        end

            // Mini State: I_DOWN_R2L
                        I_DOWN_R2L: begin
                            if (stride_cnt >= stride_height - 1) begin
                                RDATA_gstate <= G_WAIT;
                                RDATA_imini_state <= I_SHIFT_RIGHT;
                            end
                            else 
                                RDATA_gstate <= G_IREAD;
                        end

            // Mini State: I_SHIFT_RIGHT
                        I_SHIFT_RIGHT: begin
                            if (stride_cnt >= stride_width - 1) begin
                                if (in_x <= stride_width) begin
                                    if (in_y + weight_kernel_patch_height >= ifm_height) 
                                        RDATA_imini_state <= I_FINISH_R;
                                    else
                                        RDATA_imini_state <= I_DOWN_L2R;
                                end

                                RDATA_gstate <= G_WAIT;
                            end
                            else begin
                                if (sp_init_ictn_1 < 9)
                                    RDATA_gstate <= G_IREAD;
                                else
                                    RDATA_gstate <= G_ILOAD;
                            end 
                        end

            // Mini State: I_DOWN_L2R
                        I_DOWN_L2R: begin
                            if (stride_cnt >= stride_height - 1) begin
                                RDATA_imini_state <= I_SHIFT_LEFT;

                                RDATA_gstate <= G_WAIT;
                            end
                            else 
                                RDATA_gstate <= G_IREAD;
                        end

            // Mini State: I_FINISH_L
                        // I_FINISH_L: 

            // Mini State: I_FINISH_R
                        // I_FINISH_R: 

                    endcase

        // State: G_WAIT    
                    G_WAIT: begin
                        if (RDATA_rdy && (COMPS_rdy || COMPS_start) && (POOL_rdy || POOL_start)  &&(WBACK_rdy || WBACK_start)) begin
                            if (RDATA_imini_state == I_FINISH_L || RDATA_imini_state == I_FINISH_R) begin
                                RDATA_imini_state <= I_START;
                                if (kw_num_ou_z + 3 >= nok_ofm_depth && kw_in_z + 3 >= kernel_ifm_depth) 
                                    RDATA_gstate <= G_FINISH;
                                else 
                                    RDATA_gstate <= G_WREAD;
                            end else begin
                                if (kw_in_z < 3)
                                    RDATA_gstate <= G_BPSLOAD;
                                else 
                                    RDATA_gstate <= G_PSREAD;
                            end         
                        end
                    end

        // State: G_FINISH
                    // G_FINISH:
                endcase
                end
/*********************/
            endcase
        end
    end

/* FSM Register Control */
    always @(posedge clk) begin
        if (!resetn) begin
            // Coordinate
            in_x <= 0;
            in_y <= 0;

            kw_x <= 0;
            kw_y <= 0;
            kw_in_z <= 0;
            kw_num_ou_z <= 0;

            ou_x <= 0;
            ou_y <= 0;

            // Address
            kw_addr_0_0 <= 0;
            i_addr_0_0  <= 0;
            b_addr_0    <= 0;
            ps_addr_0   <= 0;
            o_addr_0    <= 0;
            o_quant_sel <= 0;

            // State Counter
            state_cnt   <= 0;
            stride_cnt  <= 0;

            read_mem_state <= 0;

            // Pipeline Signal
            inter_ps_addr       <= 0;
            inter_o_addr        <= 0;
            inter_o_quant_sel   <= 0;
        end 
        else if (enb) begin
            case (cfg_layer_typ)

/* CONVOLUTIONAL LAYER */
// Kernel-Based Computation FSM
                CONV: begin
                case (RDATA_gstate)
     // State: G_START
                    G_START: begin
                        // Coordinate 
                        in_x <= 0;
                        in_y <= 0;

                        kw_x <= 0;
                        kw_y <= 0;
                        kw_in_z <= 0;
                        kw_num_ou_z <= 0;

                        ou_x <= 0;
                        ou_y <= 0;

                        // Address
                        kw_addr_0_0 <= kw_base_addr;
                        i_addr_0_0  <= i_base_addr;
                        b_addr_0    <= b_base_addr;
                        ps_addr_0   <= ps_base_addr;
                        o_addr_0    <= o_base_addr;
                        o_quant_sel <= 1;

                        // State Counter
                        state_cnt <= 0;
                        stride_cnt <= 0;

                        read_mem_state <= 0;
                    end
                         
        // State: G_WREAD
                    G_WREAD: begin
                        if (read_mem_state) begin
                            if (mem_read_ready) begin
                                if (state_cnt >= 9 - 1) begin
                                    state_cnt <= 0;
                                end else state_cnt <= state_cnt + 1;

                                read_mem_state <= ~read_mem_state;
                            end
                        end 
                        else 
                            read_mem_state <= ~read_mem_state;
                    end

        // State: G_WLOAD
                    G_WLOAD:
                    if (state_cnt >= 3 - 1) 
                        state_cnt <= 0;
                    else 
                        state_cnt <= state_cnt + 1;  

        // State: G_BREAD
                    G_BREAD: begin
                        if (read_mem_state) begin
                            if (mem_read_ready) begin
                                if (state_cnt >= 3 - 1) begin
                                    state_cnt <= 0;
                                end else state_cnt <= state_cnt + 1;
                            
                                read_mem_state <= ~read_mem_state;
                            end
                        end
                        else 
                            read_mem_state <= ~read_mem_state;
                    end

        // State: G_PSREAD
                    G_PSREAD: begin
                        if (read_mem_state) begin
                            if (mem_read_ready) begin
                                if (state_cnt >= 3 - 1) begin
                                    state_cnt <= 0;
                                end else state_cnt <= state_cnt + 1;

                                read_mem_state <= ~read_mem_state;
                            end
                        end
                        else 
                            read_mem_state <= ~read_mem_state;
                    end
                        
        // State: G_BPSLOAD
                    G_BPSLOAD: begin
                        if (RDATA_imini_state == I_SHIFT_LEFT || RDATA_imini_state == I_SHIFT_RIGHT) begin
                            if (sp_init_ictn_0 < 9)
                                state_cnt <= sp_init_ictn_0;
                        end 
                    end

        // State: G_IREAD        
                    G_IREAD: begin
                        if (read_mem_state) begin
                            if (mem_read_ready) begin
                            case (RDATA_imini_state)
            // Mini State: I_START
                                I_START: 
                                if (state_cnt >= 18 - 1) begin
                                    state_cnt <= 0;
                                end else begin
                                    if (ibuf_conv_wstrb < 3'd2) 
                                        state_cnt <= state_cnt + 2;
                                    else
                                        state_cnt <= state_cnt + 1;
                                end

            // Mini State: I_SHIFT_LEFT
                                I_SHIFT_LEFT: begin
                                    if (sp_run_ictn < 9)
                                        state_cnt <= sp_run_ictn;
                                    else 
                                        state_cnt <= 0;
                                end

            // Mini State: I_DOWN_R2L
                                I_DOWN_R2L: 
                                if (state_cnt >= 6 - 1) begin
                                    state_cnt <= 0;
                                end else begin
                                    if (ibuf_conv_wstrb < 3'd2) 
                                        state_cnt <= state_cnt + 2;
                                    else
                                        state_cnt <= state_cnt + 1;
                                end

            // Mini State: I_SHIFT_RIGHT
                                I_SHIFT_RIGHT: begin
                                    if (sp_run_ictn < 9)
                                        state_cnt <= sp_run_ictn;
                                    else 
                                        state_cnt <= 0;
                                end

            // Mini State: I_DOWN_L2R
                                I_DOWN_L2R: 
                                if (state_cnt >= 6 - 1) begin
                                    state_cnt <= 0;
                                end else begin
                                    if (ibuf_conv_wstrb < 3'd2) 
                                        state_cnt <= state_cnt + 2;
                                    else
                                        state_cnt <= state_cnt + 1;
                                end

            // Mini State: I_FINISH_L
                                // I_FINISH_L:

            // Mini State: I_FINISH_R
                                // I_FINISH_R: 
                            endcase
                            
                            read_mem_state <= ~read_mem_state;
                            end
                        end
                        else 
                            read_mem_state <= ~read_mem_state;
                    end

        // State: G_ILOAD       
                    G_ILOAD: begin
                        inter_ps_addr       <= ps_addr_0;
                        inter_o_addr        <= o_addr_0;
                        inter_o_quant_sel   <= o_quant_sel;
                        case (RDATA_imini_state)
            // Mini State: I_START
                            I_START: begin
                                if (state_cnt >= 3 - 1) begin
                                    ps_addr_0[31:2] <= ps_addr_0[31:2] + 1;
                                    if (is_out_fin) begin
                                        o_addr_0 <= o_addr_0 + 1;
                                    end

                                    state_cnt <= 0;
                                end else state_cnt <= state_cnt + 1;
                            end

            // Mini State: I_SHIFT_LEFT 
                            I_SHIFT_LEFT: begin
                                if (stride_cnt >= stride_width - 1) begin
                                    ou_x <= ou_x + 1;
                                    if (in_x + weight_kernel_patch_width + stride_width >= ifm_width) begin
                                        if (in_y + weight_kernel_patch_height >= ifm_height) begin
                                            if (kw_in_z + 3 >= kernel_ifm_depth) begin
                                                // ps_addr_0[31:2] <= ps_addr_2[31:2] + 1;
                                                ps_addr_0 <= ps_base_addr;
                                                if (is_out_fin) begin
                                                    o_addr_0 <= o_addr_2 + 1;
                                                    o_quant_sel <= o_quant_sel + 1;
                                                end
                                            end else begin
                                                ps_addr_0[31:2] <= ps_addr_0[31:2] - output2D_size + 1;
                                            end
                                        end else begin
                                            ps_addr_0[31:2] <= ps_addr_0[31:2] + ofm_width;
                                            if (is_out_fin) 
                                                o_addr_0 <= o_addr_0 + ofm_width;
                                        end
                                    end else begin
                                        ps_addr_0[31:2] <= ps_addr_0[31:2] + 1;
                                        if (is_out_fin) 
                                            o_addr_0 <= o_addr_0 + 1;
                                    end

                                    stride_cnt <= 0;
                                end else begin
                                    // if (sp_init_ictn < 9)
                                    //     state_cnt <= sp_init_ictn;
                                    
                                    if (sp_init_ictn_1 < 9)
                                        state_cnt <= sp_init_ictn_1;

                                    stride_cnt <= stride_cnt + 1;
                                end

                                in_x <= in_x + 1;
                                i_addr_0_0 <= i_addr_0_0 + 1;
                            end 

            // Mini State: I_DOWN_R2L
                            I_DOWN_R2L: begin
                                if (stride_cnt >= stride_height - 1) begin
                                    ou_y <= ou_y + 1;
                                    ps_addr_0[31:2] <= ps_addr_0[31:2] - 1;
                                    if (is_out_fin && stride_cnt >= stride_height - 1) 
                                        o_addr_0 <= o_addr_0 - 1;

                                    stride_cnt <= 0;
                                end else begin 
                                    stride_cnt <= stride_cnt + 1;
                                end

                                in_y <= in_y + 1;
                                i_addr_0_0 <= i_addr_0_0 + ifm_width;
                            end 

            // Mini State: I_SHIFT_RIGHT
                            I_SHIFT_RIGHT: begin
                                if (stride_cnt >= stride_width - 1) begin                            
                                    ou_x <= ou_x - 1;

                                    if (in_x <= stride_width) begin
                                        if (in_y + weight_kernel_patch_height >= ifm_height) begin
                                            if (kw_in_z + 3 >= kernel_ifm_depth) begin
                                                // ps_addr_0[31:2] <= ps_addr_2[31:2] + 1;
                                                ps_addr_0[31:2] <= ps_base_addr;
                                                if (is_out_fin) begin
                                                    // o_addr_0 <= o_addr_2 + 1;
                                                    o_addr_0 <= o_addr_2 + ofm_width;
                                                    o_quant_sel <= o_quant_sel + 1;
                                                end
                                            end else begin
                                                ps_addr_0[31:2] <= ps_addr_0[31:2] - output2D_size + 1;
                                            end
                                        end else begin
                                            ps_addr_0[31:2] <= ps_addr_0[31:2] + ofm_width;
                                            if (is_out_fin) 
                                                o_addr_0 <= o_addr_0 + ofm_width;
                                        end
                                    end else begin
                                        ps_addr_0[31:2] <= ps_addr_0[31:2] - 1;
                                        if (is_out_fin)
                                            o_addr_0 <= o_addr_0 - 1;
                                    end

                                    stride_cnt <= 0;
                                end
                                else begin
                                    if (sp_init_ictn_1 < 9)
                                        state_cnt <= sp_init_ictn_1;

                                    stride_cnt <= stride_cnt + 1;
                                end

                                in_x <= in_x - 1;
                                i_addr_0_0 <= i_addr_0_0 - 1;
                            end

            // Mini State: I_DOWN_L2R
                            I_DOWN_L2R: begin
                                if (stride_cnt >= stride_height - 1) begin
                                    ou_y <= ou_y + 1;

                                    ps_addr_0[31:2] <= ps_addr_0[31:2] + 1;
                                    if (is_out_fin) 
                                        o_addr_0 <= o_addr_0 + 1;

                                    stride_cnt <= 0;
                                end else begin
                                    stride_cnt <= stride_cnt + 1;
                                end

                                in_y <= in_y + 1;
                                i_addr_0_0 <= i_addr_0_0 + ifm_width;
                            end
                        endcase
                    end

        // State: G_WAIT
                    G_WAIT: begin
                        if (RDATA_rdy && (COMPS_rdy || COMPS_start) &&  (POOL_rdy || POOL_start) && (WBACK_rdy || WBACK_start)) begin
                            if (RDATA_imini_state == I_FINISH_L || RDATA_imini_state == I_FINISH_R) begin
                                in_x <= 0; ou_x <= 0;
                                in_y <= 0; ou_y <= 0;
                                
                                if (kw_in_z < 3) begin
                                    b_addr_0 <= b_addr_0 + 12;
                                end

                                if (kw_in_z + 3 >= kernel_ifm_depth) begin
                                    // Coordinates
                                    kw_in_z <= 0;
                                    kw_num_ou_z <= kw_num_ou_z + 3;

                                    // Address
                                    kw_addr_0_0 <= kw_addr_2_2 + 9;
                                    i_addr_0_0 <= i_base_addr;
                                end else begin
                                    // Coordinates
                                    kw_in_z <= kw_in_z + 3;
                                    
                                    // Address
                                    kw_addr_0_0 <= kw_addr_0_2 + 9;
                                    if (RDATA_imini_state == I_FINISH_L) begin
                                        i_addr_0_0 <= i_addr_2_2 + weight_kernel_patch_width;
                                    end
                                    else begin
                                        i_addr_0_0 <= i_addr_2_2 + ifm_width;
                                    end
                                end
                            end 
                        end
                    end

        // State: G_FINISH
                    // G_FINISH: 
                endcase 
                end
/*****************************/

/* FULLY-CONNECTED LAYER */
// Input-Based Computation FSM
                DENSE: begin
                case (RDATA_gstate)
        // State: G_START
                    G_START: begin
                        // Coordinate 
                        in_x <= 0;
                        ou_x <= 0;

                        // Address
                        kw_addr_0_0 <= kw_base_addr;
                        i_addr_0_0  <= i_base_addr;
                        b_addr_0    <= b_base_addr;
                        ps_addr_0   <= ps_base_addr;
                        o_addr_0    <= o_base_addr;
                        o_quant_sel <= 1;

                        // Counter
                        state_cnt <= 0;

                        read_mem_state <= 0;
                    end

        // State: G_WREAD
                    G_WREAD: begin
                        if (read_mem_state) begin
                            if (mem_read_ready) begin
                                if (state_cnt >= 9 - 1) begin
                                    state_cnt <= 0;
                                end else state_cnt <= state_cnt + 1;

                                read_mem_state <= ~read_mem_state;
                            end
                        end
                        else 
                            read_mem_state <= ~read_mem_state;
                    end

        // State: G_WLOAD
                    G_WLOAD: begin
                        inter_ps_addr       <= ps_addr_0;
                        inter_o_addr        <= o_addr_0;
                        inter_o_quant_sel   <= o_quant_sel;
                        if (state_cnt >= 3 - 1) begin
                            if (ou_x + 3 >= weight_kernel_patch_height)
                                ps_addr_0 <= ps_base_addr;
                            else 
                                ps_addr_0 <= ps_addr_0 + 12;

                            if (is_out_fin) 
                                o_addr_0 <= o_addr_0 + 3;

                            state_cnt <= 0;
                        end else state_cnt <= state_cnt + 1; 
                    end

        // State: G_BREAD
                    G_BREAD: begin
                        if (read_mem_state) begin
                            if (mem_read_ready) begin
                                if (state_cnt >= 3 - 1) begin
                                    state_cnt <= 0;
                                end else state_cnt <= state_cnt + 1;

                                read_mem_state <= ~read_mem_state;
                            end
                        end
                        else 
                            read_mem_state <= ~read_mem_state;
                    end

        // State: G_PSREAD
                    G_PSREAD: begin
                        if (read_mem_state) begin
                            if (mem_read_ready) begin
                                if (state_cnt >= 3 - 1) begin
                                    state_cnt <= 0;
                                end else state_cnt <= state_cnt + 1;

                                read_mem_state <= ~read_mem_state;
                            end
                        end
                        else 
                            read_mem_state <= ~read_mem_state;
                    end
                        
        // State: G_BPSLOAD
                    G_BPSLOAD: begin

                    end

        // State: G_IREAD
                    G_IREAD: begin
                        if (read_mem_state) begin
                            if (mem_read_ready) begin
                                if (state_cnt >= 3 - 1) begin
                                    state_cnt <= 0;
                                end else state_cnt <= state_cnt + 1;

                                read_mem_state <= ~read_mem_state;
                            end
                        end
                        else 
                            read_mem_state <= ~read_mem_state;
                    end

        // State: G_ILOAD
                    G_ILOAD: begin
                        if (state_cnt >= 3 - 1) begin
                            state_cnt <= 0;
                        end else state_cnt <= state_cnt + 1;
                    end

        // State: G_WAIT
                    G_WAIT: begin
                        if (RDATA_rdy && (COMPS_rdy || COMPS_start) &&  (POOL_rdy || POOL_start) && (WBACK_rdy || WBACK_start)) begin
                            if (in_x < 9)
                                b_addr_0 <= b_addr_0 + 12;
 
                            if (ou_x + 3 >= weight_kernel_patch_height) begin
                                ou_x <= 0;
                                in_x <= in_x + 9;
                                
                                kw_addr_0_0 <= kw_addr_2 + weight_kernel_patch_width - kernel3D_size + 9;
                                i_addr_0_0 <= i_addr_0_0 + 9;
                            end else begin
                                ou_x <= ou_x + 3;

                                kw_addr_0_0 <= kw_addr_2 + weight_kernel_patch_width;
                            end
                        end 
                    end

        // State: G_FINISH
                    // G_FINISH:
                endcase
                end
/*****************************/

/* POOLING LAYER */
// No-Comp Computation FSM
            MIXED: begin
                case (RDATA_gstate)
     // State: G_START
                    G_START: begin
                        // Coordinate 
                        in_x <= 0;
                        in_y <= 0;

                        kw_x <= 0;
                        kw_y <= 0;
                        kw_in_z <= 0;
                        kw_num_ou_z <= 0;

                        ou_x <= 0;
                        ou_y <= 0;

                        // Address
                        kw_addr_0_0 <= kw_base_addr;
                        i_addr_0_0  <= i_base_addr;
                        b_addr_0    <= b_base_addr;
                        ps_addr_0   <= ps_base_addr;
                        o_addr_0    <= o_base_addr;
                        o_quant_sel <= 1;

                        // State Counter
                        state_cnt <= 0;
                        stride_cnt <= 0;

                        read_mem_state <= 0;
                    end
                         
        // State: G_WREAD
                    G_WREAD: begin
                        if (read_mem_state) begin
                            if (mem_read_ready) begin
                                if (state_cnt >= 9 - 1) begin
                                    state_cnt <= 0;
                                end else state_cnt <= state_cnt + 1;

                                read_mem_state <= ~read_mem_state;
                            end
                        end 
                        else 
                            read_mem_state <= ~read_mem_state;
                    end

        // State: G_WLOAD
                    G_WLOAD:
                    if (state_cnt >= 3 - 1) 
                        state_cnt <= 0;
                    else 
                        state_cnt <= state_cnt + 1;  

        // State: G_BREAD
                    G_BREAD: begin
                        if (read_mem_state) begin
                            if (mem_read_ready) begin
                                if (state_cnt >= 3 - 1) begin
                                    state_cnt <= 0;
                                end else state_cnt <= state_cnt + 1;
                            
                                read_mem_state <= ~read_mem_state;
                            end
                        end
                        else 
                            read_mem_state <= ~read_mem_state;
                    end

        // State: G_PSREAD
                    G_PSREAD: begin
                        if (read_mem_state) begin
                            if (mem_read_ready) begin
                                if (state_cnt >= 3 - 1) begin
                                    state_cnt <= 0;
                                end else state_cnt <= state_cnt + 1;

                                read_mem_state <= ~read_mem_state;
                            end
                        end
                        else 
                            read_mem_state <= ~read_mem_state;
                    end
                        
        // State: G_BPSLOAD
                    G_BPSLOAD: begin
                        if (RDATA_imini_state == I_SHIFT_LEFT || RDATA_imini_state == I_SHIFT_RIGHT) begin
                            if (sp_init_ictn_0 < 9)
                                state_cnt <= sp_init_ictn_0;
                        end 
                    end

        // State: G_IREAD        
                    G_IREAD: begin
                        if (read_mem_state) begin
                            if (mem_read_ready) begin
                            case (RDATA_imini_state)
            // Mini State: I_START
                                I_START: 
                                if (state_cnt >= 18 - 1) begin
                                    state_cnt <= 0;
                                end else begin
                                    if (ibuf_conv_wstrb < 3'd2) 
                                        state_cnt <= state_cnt + 2;
                                    else
                                        state_cnt <= state_cnt + 1;
                                end

            // Mini State: I_SHIFT_LEFT
                                I_SHIFT_LEFT: begin
                                    if (sp_run_ictn < 9)
                                        state_cnt <= sp_run_ictn;
                                    else 
                                        state_cnt <= 0;
                                end

            // Mini State: I_DOWN_R2L
                                I_DOWN_R2L: 
                                if (state_cnt >= 6 - 1) begin
                                    state_cnt <= 0;
                                end else begin
                                    if (ibuf_conv_wstrb < 3'd2) 
                                        state_cnt <= state_cnt + 2;
                                    else
                                        state_cnt <= state_cnt + 1;
                                end

            // Mini State: I_SHIFT_RIGHT
                                I_SHIFT_RIGHT: begin
                                    if (sp_run_ictn < 9)
                                        state_cnt <= sp_run_ictn;
                                    else 
                                        state_cnt <= 0;
                                end

            // Mini State: I_DOWN_L2R
                                I_DOWN_L2R: 
                                if (state_cnt >= 6 - 1) begin
                                    state_cnt <= 0;
                                end else begin
                                    if (ibuf_conv_wstrb < 3'd2) 
                                        state_cnt <= state_cnt + 2;
                                    else
                                        state_cnt <= state_cnt + 1;
                                end

            // Mini State: I_FINISH_L
                                // I_FINISH_L:

            // Mini State: I_FINISH_R
                                // I_FINISH_R: 
                            endcase
                            
                            read_mem_state <= ~read_mem_state;
                            end
                        end
                        else 
                            read_mem_state <= ~read_mem_state;
                    end

        // State: G_ILOAD       
                    G_ILOAD: begin
                        inter_ps_addr       <= ps_addr_0;
                        inter_o_addr        <= o_addr_0;
                        inter_o_quant_sel   <= o_quant_sel;
                        case (RDATA_imini_state)
            // Mini State: I_START
                            I_START: begin
                                if (state_cnt >= 3 - 1) begin
                                    ps_addr_0[31:2] <= ps_addr_0[31:2] + 1;
                                    if (is_out_fin) begin
                                        o_addr_0 <= o_addr_0 + 1;
                                    end

                                    state_cnt <= 0;
                                end else state_cnt <= state_cnt + 1;
                            end

            // Mini State: I_SHIFT_LEFT 
                            I_SHIFT_LEFT: begin
                                if (stride_cnt >= stride_width - 1) begin
                                    ou_x <= ou_x + 1;
                                    if (in_x + weight_kernel_patch_width + stride_width >= ifm_width) begin
                                        if (in_y + weight_kernel_patch_height >= ifm_height) begin
                                            if (kw_in_z + 3 >= kernel_ifm_depth) begin
                                                // ps_addr_0[31:2] <= ps_addr_2[31:2] + 1;
                                                ps_addr_0 <= ps_base_addr;
                                                if (is_out_fin) begin
                                                    o_addr_0 <= o_addr_2 + 1;
                                                    o_quant_sel <= o_quant_sel + 1;
                                                end
                                            end else begin
                                                ps_addr_0[31:2] <= ps_addr_0[31:2] - output2D_size + 1;
                                            end
                                        end else begin
                                            ps_addr_0[31:2] <= ps_addr_0[31:2] + ofm_width;
                                            if (is_out_fin) 
                                                o_addr_0 <= o_addr_0 + ofm_width;
                                        end
                                    end else begin
                                        ps_addr_0[31:2] <= ps_addr_0[31:2] + 1;
                                        if (is_out_fin) 
                                            o_addr_0 <= o_addr_0 + 1;
                                    end

                                    stride_cnt <= 0;
                                end else begin
                                    // if (sp_init_ictn < 9)
                                    //     state_cnt <= sp_init_ictn;
                                    
                                    if (sp_init_ictn_1 < 9)
                                        state_cnt <= sp_init_ictn_1;

                                    stride_cnt <= stride_cnt + 1;
                                end

                                in_x <= in_x + 1;
                                i_addr_0_0 <= i_addr_0_0 + 1;
                            end 

            // Mini State: I_DOWN_R2L
                            I_DOWN_R2L: begin
                                if (stride_cnt >= stride_height - 1) begin
                                    ou_y <= ou_y + 1;
                                    ps_addr_0[31:2] <= ps_addr_0[31:2] - 1;
                                    if (is_out_fin && stride_cnt >= stride_height - 1) 
                                        o_addr_0 <= o_addr_0 - 1;

                                    stride_cnt <= 0;
                                end else begin 
                                    stride_cnt <= stride_cnt + 1;
                                end

                                in_y <= in_y + 1;
                                i_addr_0_0 <= i_addr_0_0 + ifm_width;
                            end 

            // Mini State: I_SHIFT_RIGHT
                            I_SHIFT_RIGHT: begin
                                if (stride_cnt >= stride_width - 1) begin                            
                                    ou_x <= ou_x - 1;

                                    if (in_x <= stride_width) begin
                                        if (in_y + weight_kernel_patch_height >= ifm_height) begin
                                            if (kw_in_z + 3 >= kernel_ifm_depth) begin
                                                // ps_addr_0[31:2] <= ps_addr_2[31:2] + 1;
                                                ps_addr_0[31:2] <= ps_base_addr;
                                                if (is_out_fin) begin
                                                    // o_addr_0 <= o_addr_2 + 1;
                                                    o_addr_0 <= o_addr_2 + ofm_width;
                                                    o_quant_sel <= o_quant_sel + 1;
                                                end
                                            end else begin
                                                ps_addr_0[31:2] <= ps_addr_0[31:2] - output2D_size + 1;
                                            end
                                        end else begin
                                            ps_addr_0[31:2] <= ps_addr_0[31:2] + ofm_width;
                                            if (is_out_fin) 
                                                o_addr_0 <= o_addr_0 + ofm_width;
                                        end
                                    end else begin
                                        ps_addr_0[31:2] <= ps_addr_0[31:2] - 1;
                                        if (is_out_fin)
                                            o_addr_0 <= o_addr_0 - 1;
                                    end

                                    stride_cnt <= 0;
                                end
                                else begin
                                    if (sp_init_ictn_1 < 9)
                                        state_cnt <= sp_init_ictn_1;

                                    stride_cnt <= stride_cnt + 1;
                                end

                                in_x <= in_x - 1;
                                i_addr_0_0 <= i_addr_0_0 - 1;
                            end

            // Mini State: I_DOWN_L2R
                            I_DOWN_L2R: begin
                                if (stride_cnt >= stride_height - 1) begin
                                    ou_y <= ou_y + 1;

                                    ps_addr_0[31:2] <= ps_addr_0[31:2] + 1;
                                    if (is_out_fin) 
                                        o_addr_0 <= o_addr_0 + 1;

                                    stride_cnt <= 0;
                                end else begin
                                    stride_cnt <= stride_cnt + 1;
                                end

                                in_y <= in_y + 1;
                                i_addr_0_0 <= i_addr_0_0 + ifm_width;
                            end
                        endcase
                    end

        // State: G_WAIT
                    G_WAIT: begin
                        if (RDATA_rdy && (COMPS_rdy || COMPS_start) && (POOL_rdy || POOL_start) && (WBACK_rdy || WBACK_start)) begin
                            if (RDATA_imini_state == I_FINISH_L || RDATA_imini_state == I_FINISH_R) begin
                                in_x <= 0; ou_x <= 0;
                                in_y <= 0; ou_y <= 0;
                                
                                if (kw_in_z < 3) begin
                                    b_addr_0 <= b_addr_0 + 12;
                                end

                                if (kw_in_z + 3 >= kernel_ifm_depth) begin
                                    // Coordinates
                                    kw_in_z <= 0;
                                    kw_num_ou_z <= kw_num_ou_z + 3;

                                    // Address
                                    kw_addr_0_0 <= kw_addr_2_2 + 9;
                                    i_addr_0_0 <= i_base_addr;
                                end else begin
                                    // Coordinates
                                    kw_in_z <= kw_in_z + 3;
                                    
                                    // Address
                                    kw_addr_0_0 <= kw_addr_0_2 + 9;
                                    if (RDATA_imini_state == I_FINISH_L) begin
                                        i_addr_0_0 <= i_addr_2_2 + weight_kernel_patch_width;
                                    end
                                    else begin
                                        i_addr_0_0 <= i_addr_2_2 + ifm_width;
                                    end
                                end
                            end 
                        end
                    end

        // State: G_FINISH
                    // G_FINISH: 
                endcase 
                end
/*********************/
            endcase
        end
    end

/* FSM Output Ctrl Signals */
    always @(*) begin
    // Inital All Ctrl Sigs
        mem_raddr = 0;
        mem_renb  = 0;

        bpbuf_ld_wrn = 0;
        bpbuf_enb = 0;

        ibuf_di_revert = 0;
        ibuf_do_revert = 0;
        ibuf_dens_wstrb = 0;
        ibuf_conv_wstrb = 0;
        ibuf_ld_wrn = 0;
        ibuf_bank_sel = 0;
        ibuf_conv_fi_load = 0;
        ibuf_conv_se_load = 0;
        ibuf_enb = 0;

        wbuf_wstrb = 0;
        wbuf_ld_wrn = 0;
        wbuf_bank_sel = 0;
        wbuf_enb = 0;

        idemux_sel = 0;
        ireg_enb = 0;

        wdemux_sel = 0;
        wreg_enb = 0;

        pu_matrix_conv_dir = 0;

        acc_matrix_enb = 0;
        acc_matrix_bps_load = 0;

        RDATA_rdy = 0; 
        RDATA_fin = 0;

    // ****************** //
        case (cfg_layer_typ)

/* CONVOLUTIONAL LAYER */
// Kernel-Based Computation FSM
            CONV: begin
            case (RDATA_gstate)
        // State: G_START
                // G_START:           

        // State: G_WREAD
                G_WREAD: begin
                    mem_renb = 1;
                    if (read_mem_state) begin
                        if (mem_read_ready) begin
                            mem_renb = 0;
                            // Ctrl Sigs
                            case (state_cnt)
                                4'd0: begin
                                    wbuf_enb[0]         = 1;
                                    wbuf_ld_wrn[0]      = 1;
                                    wbuf_bank_sel[1:0]  = 1;
                                    case (RDATA_wmini_state)
                                        W_READ_0: wbuf_wstrb[1:0] = kw_addr_0_0[1:0];
                                        W_READ_1: wbuf_wstrb[1:0] = kw_addr_0_1[1:0];
                                        W_READ_2: wbuf_wstrb[1:0] = kw_addr_0_2[1:0];
                                    endcase
                                end

                                4'd1: begin
                                    wbuf_enb[0]         = 1;
                                    wbuf_ld_wrn[0]      = 1;
                                    wbuf_bank_sel[1:0]  = 2;
                                    case (RDATA_wmini_state)
                                        W_READ_0: wbuf_wstrb[1:0] = kw_addr_0_0[1:0];
                                        W_READ_1: wbuf_wstrb[1:0] = kw_addr_0_1[1:0];
                                        W_READ_2: wbuf_wstrb[1:0] = kw_addr_0_2[1:0];
                                    endcase
                                end

                                4'd2: begin
                                    wbuf_enb[0]         = 1;
                                    wbuf_ld_wrn[0]      = 1;
                                    wbuf_bank_sel[1:0]  = 3;
                                    case (RDATA_wmini_state)
                                        W_READ_0: wbuf_wstrb[1:0] = kw_addr_0_0[1:0];
                                        W_READ_1: wbuf_wstrb[1:0] = kw_addr_0_1[1:0]; 
                                        W_READ_2: wbuf_wstrb[1:0] = kw_addr_0_2[1:0]; 
                                    endcase
                                end

                                4'd3: begin
                                    wbuf_enb[1]         = 1;
                                    wbuf_ld_wrn[1]      = 1;
                                    wbuf_bank_sel[3:2]  = 1;
                                    case (RDATA_wmini_state)
                                        W_READ_0: wbuf_wstrb[3:2] = kw_addr_1_0[1:0];
                                        W_READ_1: wbuf_wstrb[3:2] = kw_addr_1_1[1:0];
                                        W_READ_2: wbuf_wstrb[3:2] = kw_addr_1_2[1:0];
                                    endcase
                                end

                                4'd4: begin
                                    wbuf_enb[1]         = 1;
                                    wbuf_ld_wrn[1]      = 1;
                                    wbuf_bank_sel[3:2]  = 2;
                                    case (RDATA_wmini_state)
                                        W_READ_0: wbuf_wstrb[3:2] = kw_addr_1_0[1:0];
                                        W_READ_1: wbuf_wstrb[3:2] = kw_addr_1_1[1:0];
                                        W_READ_2: wbuf_wstrb[3:2] = kw_addr_1_2[1:0];
                                    endcase
                                end

                                4'd5: begin
                                    wbuf_enb[1]         = 1;
                                    wbuf_ld_wrn[1]      = 1;
                                    wbuf_bank_sel[3:2]  = 3;
                                    case (RDATA_wmini_state)
                                        W_READ_0: wbuf_wstrb[3:2] = kw_addr_1_0[1:0];
                                        W_READ_1: wbuf_wstrb[3:2] = kw_addr_1_1[1:0];
                                        W_READ_2: wbuf_wstrb[3:2] = kw_addr_1_2[1:0];
                                    endcase
                                end

                                4'd6: begin
                                    wbuf_enb[2]         = 1;
                                    wbuf_ld_wrn[2]      = 1;
                                    wbuf_bank_sel[5:4]  = 1;
                                    case (RDATA_wmini_state)
                                        W_READ_0: wbuf_wstrb[5:4] = kw_addr_2_0[1:0];
                                        W_READ_1: wbuf_wstrb[5:4] = kw_addr_2_1[1:0];
                                        W_READ_2: wbuf_wstrb[5:4] = kw_addr_2_2[1:0];
                                    endcase
                                end

                                4'd7: begin
                                    wbuf_enb[2]         = 1;
                                    wbuf_ld_wrn[2]      = 1;
                                    wbuf_bank_sel[5:4]  = 2;
                                    case (RDATA_wmini_state)
                                        W_READ_0: wbuf_wstrb[5:4] = kw_addr_2_0[1:0];
                                        W_READ_1: wbuf_wstrb[5:4] = kw_addr_2_1[1:0];
                                        W_READ_2: wbuf_wstrb[5:4] = kw_addr_2_2[1:0];
                                    endcase
                                end

                                4'd8: begin
                                    wbuf_enb[2]         = 1;
                                    wbuf_ld_wrn[2]      = 1;
                                    wbuf_bank_sel[5:4]  = 3;
                                    case (RDATA_wmini_state)
                                        W_READ_0: wbuf_wstrb[5:4] = kw_addr_2_0[1:0];
                                        W_READ_1: wbuf_wstrb[5:4] = kw_addr_2_1[1:0];
                                        W_READ_2: wbuf_wstrb[5:4] = kw_addr_2_2[1:0];
                                    endcase
                                end
                            endcase
                        end
                    end
                    // else begin
                    //     mem_renb = 1;
                    // end

                        case (state_cnt)
                            4'd0: begin
                                case (RDATA_wmini_state)
                                    W_READ_0: mem_raddr       = kw_addr_0_0;
                                    W_READ_1: mem_raddr       = kw_addr_0_1; 
                                    W_READ_2: mem_raddr       = kw_addr_0_2;  
                                endcase
                            end

                            4'd1: begin
                                case (RDATA_wmini_state)
                                    W_READ_0: mem_raddr       = kw_addr_0_0 + 4;
                                    W_READ_1: mem_raddr       = kw_addr_0_1 + 4;
                                    W_READ_2: mem_raddr       = kw_addr_0_2 + 4;
                                endcase
                            end

                            4'd2: begin
                                case (RDATA_wmini_state)
                                    W_READ_0: mem_raddr       = kw_addr_0_0 + 8;
                                    W_READ_1: mem_raddr       = kw_addr_0_1 + 8;
                                    W_READ_2: mem_raddr       = kw_addr_0_2 + 8;
                                endcase
                            end

                            4'd3: begin
                                case (RDATA_wmini_state)
                                    W_READ_0: mem_raddr       = kw_addr_1_0;
                                    W_READ_1: mem_raddr       = kw_addr_1_1; 
                                    W_READ_2: mem_raddr       = kw_addr_1_2;  
                                endcase
                            end

                            4'd4: begin
                                case (RDATA_wmini_state)
                                    W_READ_0: mem_raddr       = kw_addr_1_0 + 4;
                                    W_READ_1: mem_raddr       = kw_addr_1_1 + 4;
                                    W_READ_2: mem_raddr       = kw_addr_1_2 + 4;
                                endcase
                            end

                            4'd5: begin
                                case (RDATA_wmini_state)
                                    W_READ_0: mem_raddr       = kw_addr_1_0 + 8;
                                    W_READ_1: mem_raddr       = kw_addr_1_1 + 8;
                                    W_READ_2: mem_raddr       = kw_addr_1_2 + 8;
                                endcase
                            end

                            4'd6: begin
                                case (RDATA_wmini_state)
                                    W_READ_0: mem_raddr       = kw_addr_2_0;
                                    W_READ_1: mem_raddr       = kw_addr_2_1; 
                                    W_READ_2: mem_raddr       = kw_addr_2_2;  
                                endcase
                            end

                            4'd7: begin
                                case (RDATA_wmini_state)
                                    W_READ_0: mem_raddr       = kw_addr_2_0 + 4;
                                    W_READ_1: mem_raddr       = kw_addr_2_1 + 4;
                                    W_READ_2: mem_raddr       = kw_addr_2_2 + 4;
                                endcase
                            end

                            4'd8: begin
                                case (RDATA_wmini_state)
                                    W_READ_0: mem_raddr       = kw_addr_2_0 + 8;
                                    W_READ_1: mem_raddr       = kw_addr_2_1 + 8;
                                    W_READ_2: mem_raddr       = kw_addr_2_2 + 8;
                                endcase
                            end
                        endcase
                end

        // State: G_WLOAD
                G_WLOAD: begin
                    wbuf_enb    = 3'b111;
                    wbuf_ld_wrn = 3'b000;
                    case (state_cnt)
                        4'd0: begin
                            wdemux_sel = 0;
                            case (RDATA_wmini_state)
                                W_LOAD_0: wreg_enb[ 2: 0] = 3'b111;
                                W_LOAD_1: wreg_enb[11: 9] = 3'b111;
                                W_LOAD_2: wreg_enb[20:18] = 3'b111;
                            endcase
                        end

                        4'd1: begin
                            wdemux_sel = 1;
                            case (RDATA_wmini_state)
                                W_LOAD_0: wreg_enb[ 5: 3] = 3'b111;
                                W_LOAD_1: wreg_enb[14:12] = 3'b111;
                                W_LOAD_2: wreg_enb[23:21] = 3'b111;
                            endcase
                        end

                        4'd2: begin
                            wdemux_sel = 2;
                            case (RDATA_wmini_state)
                                W_LOAD_0: wreg_enb[ 8: 6] = 3'b111;
                                W_LOAD_1: wreg_enb[17:15] = 3'b111;
                                W_LOAD_2: wreg_enb[26:24] = 3'b111;
                            endcase
                        end
                    endcase
                end

        // State: G_BREAD
                G_BREAD: begin
                    mem_renb    = 1;
                    if (read_mem_state) begin
                        if (mem_read_ready) begin
                            mem_renb    = 0;
                            // Ctrl Sigs
                            case (state_cnt)
                                4'd0: begin
                                    bpbuf_enb[0]    = 1;
                                    bpbuf_ld_wrn[0] = 1;
                                end
                                    
                                4'd1: begin
                                    bpbuf_enb[1]    = 1;
                                    bpbuf_ld_wrn[1] = 1;
                                end
                                    
                                4'd2: begin
                                    bpbuf_enb[2]    = 1;
                                    bpbuf_ld_wrn[2] = 1;
                                end
                            endcase

                        end
                    end 
                    // else begin
                    //     mem_renb    = 1;
                    // end

                    case (state_cnt)
                        4'd0: mem_raddr   = b_addr_0;
                        4'd1: mem_raddr   = b_addr_1;
                        4'd2: mem_raddr   = b_addr_2; 
                    endcase
                end

        // State: G_PSREAD
                G_PSREAD: begin
                    mem_renb    = 1;
                    if (read_mem_state) begin
                        if (mem_read_ready) begin 
                            mem_renb    = 0;
                            case (state_cnt)
                                4'd0: begin
                                    bpbuf_enb[0]    = 1;
                                    bpbuf_ld_wrn[0] = 1;
                                end

                                4'd1: begin
                                    bpbuf_enb[1]    = 1;
                                    bpbuf_ld_wrn[1] = 1;
                                end

                                4'd2: begin
                                    bpbuf_enb[2]    = 1;
                                    bpbuf_ld_wrn[2] = 1;
                                end
                            endcase
                        end
                    end 
                    // else begin
                    //     begin 
                    //         mem_renb    = 1;
                    //     end
                    // end

                        case (state_cnt)
                            4'd0: mem_raddr   = ps_addr_0; 
                            4'd1: mem_raddr   = ps_addr_1; 
                            4'd2: mem_raddr   = ps_addr_2; 
                        endcase
                end

        // State: G_BPSLOAD
                G_BPSLOAD: begin
                    bpbuf_enb           = 3'b111;
                    bpbuf_ld_wrn        = 3'b000;

                    acc_matrix_enb      = 1;
                    acc_matrix_bps_load = 1;
                end
                        
        // State: G_IREAD
                G_IREAD: begin // Load Input Feature Map 
                    mem_renb    = 1;
                    if (read_mem_state) begin  
                        if (mem_read_ready) begin
                            mem_renb    = 0;
                        case (RDATA_imini_state)
            // Mini State: I_START
                        I_START: begin// Read 9 Input Feature Map values
                            case (state_cnt)
                                5'd 0: begin
                                    ibuf_enb[0] = 1'b1;
                                    ibuf_ld_wrn[0] = 1'b1;
                                    ibuf_bank_sel[1:0] = 2'd1;
                                    ibuf_conv_wstrb = {1'b0, i_addr_0_0[1:0]};
                                end

                                5'd 1: begin
                                    ibuf_enb[0] = 1'b1;
                                    ibuf_ld_wrn[0] = 1'b1;
                                    ibuf_bank_sel[1:0] = 2'd1;
                                    ibuf_conv_wstrb = {1'b0, i_addr_0_0[1:0]} + 3'd3;
                                end 

                                5'd 2: begin
                                    ibuf_enb[0] = 1'b1;
                                    ibuf_ld_wrn[0] = 1'b1;
                                    ibuf_bank_sel[1:0] = 2'd2;
                                    ibuf_conv_wstrb = {1'b0, i_addr_0_1[1:0]};
                                end

                                5'd 3: begin
                                    ibuf_enb[0] = 1'b1;
                                    ibuf_ld_wrn[0] = 1'b1;
                                    ibuf_bank_sel[1:0] = 2'd2;
                                    ibuf_conv_wstrb = {1'b0, i_addr_0_1[1:0]} + 3'd3;
                                end 

                                5'd 4: begin
                                    ibuf_enb[0] = 1'b1;
                                    ibuf_ld_wrn[0] = 1'b1;
                                    ibuf_bank_sel[1:0] = 2'd3;
                                    ibuf_conv_wstrb = {1'b0, i_addr_0_2[1:0]};
                                end

                                5'd 5: begin
                                    ibuf_enb[0] = 1'b1;
                                    ibuf_ld_wrn[0] = 1'b1;
                                    ibuf_bank_sel[1:0] = 2'd3;
                                    ibuf_conv_wstrb = {1'b0, i_addr_0_2[1:0]} + 3'd3;
                                end 

                                5'd 6: begin
                                    ibuf_enb[1] = 1'b1;
                                    ibuf_ld_wrn[1] = 1'b1;
                                    ibuf_bank_sel[3:2] = 2'd1;
                                    ibuf_conv_wstrb = {1'b0, i_addr_1_0[1:0]};
                                end

                                5'd 7: begin
                                    ibuf_enb[1] = 1'b1;
                                    ibuf_ld_wrn[1] = 1'b1;
                                    ibuf_bank_sel[3:2] = 2'd1;
                                    ibuf_conv_wstrb = {1'b0, i_addr_1_0[1:0]} + 3'd3;
                                end 

                                5'd 8: begin
                                    ibuf_enb[1] = 1'b1;
                                    ibuf_ld_wrn[1] = 1'b1;
                                    ibuf_bank_sel[3:2] = 2'd2;
                                    ibuf_conv_wstrb = {1'b0, i_addr_1_1[1:0]};
                                end

                                5'd 9: begin
                                    ibuf_enb[1] = 1'b1;
                                    ibuf_ld_wrn[1] = 1'b1;
                                    ibuf_bank_sel[3:2] = 2'd2;
                                    ibuf_conv_wstrb = {1'b0, i_addr_1_1[1:0]} + 3'd3;
                                end 

                                5'd10: begin
                                    ibuf_enb[1] = 1'b1;
                                    ibuf_ld_wrn[1] = 1'b1;
                                    ibuf_bank_sel[3:2] = 2'd3;
                                    ibuf_conv_wstrb = {1'b0, i_addr_1_2[1:0]};
                                end

                                5'd11: begin
                                    ibuf_enb[1] = 1'b1;
                                    ibuf_ld_wrn[1] = 1'b1;
                                    ibuf_bank_sel[3:2] = 2'd3;
                                    ibuf_conv_wstrb = {1'b0, i_addr_1_2[1:0]} + 3'd3;
                                end 

                                5'd12: begin
                                    ibuf_enb[2] = 1'b1;
                                    ibuf_ld_wrn[2] = 1'b1;
                                    ibuf_bank_sel[5:4] = 2'd1;
                                    ibuf_conv_wstrb = {1'b0, i_addr_2_0[1:0]};
                                end

                                5'd13: begin
                                    ibuf_enb[2] = 1'b1;
                                    ibuf_ld_wrn[2] = 1'b1;
                                    ibuf_bank_sel[5:4] = 2'd1;
                                    ibuf_conv_wstrb = {1'b0, i_addr_2_0[1:0]} + 3'd3;
                                end 

                                5'd14: begin
                                    ibuf_enb[2] = 1'b1;
                                    ibuf_ld_wrn[2] = 1'b1;
                                    ibuf_bank_sel[5:4] = 2'd2;
                                    ibuf_conv_wstrb = {1'b0, i_addr_2_1[1:0]};
                                end

                                5'd15: begin
                                    ibuf_enb[2] = 1'b1;
                                    ibuf_ld_wrn[2] = 1'b1;
                                    ibuf_bank_sel[5:4] = 2'd2;
                                    ibuf_conv_wstrb = {1'b0, i_addr_2_1[1:0]} + 3'd3;
                                end 

                                5'd16: begin
                                    ibuf_enb[2] = 1'b1;
                                    ibuf_ld_wrn[2] = 1'b1;
                                    ibuf_bank_sel[5:4] = 2'd3;
                                    ibuf_conv_wstrb = {1'b0, i_addr_2_2[1:0]};
                                end

                                5'd17: begin
                                    ibuf_enb[2] = 1'b1;
                                    ibuf_ld_wrn[2] = 1'b1;
                                    ibuf_bank_sel[5:4] = 2'd3;
                                    ibuf_conv_wstrb = {1'b0, i_addr_2_2[1:0]} + 3'd3;
                                end 
                            endcase
                        end

            // Mini State: I_SHIFT_LEFT
                        I_SHIFT_LEFT: begin
                            case (state_cnt)
                                5'd0: begin
                                    ibuf_enb[0] = 1'b1;
                                    ibuf_ld_wrn[0] = 1'b1;
                                    ibuf_bank_sel[1:0] = 2'd1;
                                    ibuf_conv_wstrb = {1'b0, i_sl_addr_0_0[1:0]};
                                end

                                5'd1: begin
                                    ibuf_enb[0] = 1'b1;
                                    ibuf_ld_wrn[0] = 1'b1;
                                    ibuf_bank_sel[1:0] = 2'd2;
                                    ibuf_conv_wstrb = {1'b0, i_sl_addr_0_1[1:0]};
                                end

                                5'd2: begin
                                    ibuf_enb[0] = 1'b1;
                                    ibuf_ld_wrn[0] = 1'b1;
                                    ibuf_bank_sel[1:0] = 2'd3;
                                    ibuf_conv_wstrb = {1'b0, i_sl_addr_0_2[1:0]};
                                end

                                5'd3: begin
                                    ibuf_enb[1] = 1'b1;
                                    ibuf_ld_wrn[1] = 1'b1;
                                    ibuf_bank_sel[3:2] = 2'd1;
                                    ibuf_conv_wstrb = {1'b0, i_sl_addr_1_0[1:0]};
                                end

                                5'd4: begin
                                    ibuf_enb[1] = 1'b1;
                                    ibuf_ld_wrn[1] = 1'b1;
                                    ibuf_bank_sel[3:2] = 2'd2;
                                    ibuf_conv_wstrb = {1'b0, i_sl_addr_1_1[1:0]};
                                end

                                5'd5: begin
                                    ibuf_enb[1] = 1'b1;
                                    ibuf_ld_wrn[1] = 1'b1;
                                    ibuf_bank_sel[3:2] = 2'd3;
                                    ibuf_conv_wstrb = {1'b0, i_sl_addr_1_2[1:0]};
                                end

                                5'd6: begin
                                    ibuf_enb[2] = 1'b1;
                                    ibuf_ld_wrn[2] = 1'b1;
                                    ibuf_bank_sel[5:4] = 2'd1;
                                    ibuf_conv_wstrb = {1'b0, i_sl_addr_2_0[1:0]};
                                end

                                5'd7: begin
                                    ibuf_enb[2] = 1'b1;
                                    ibuf_ld_wrn[2] = 1'b1;
                                    ibuf_bank_sel[5:4] = 2'd2;
                                    ibuf_conv_wstrb = {1'b0, i_sl_addr_2_1[1:0]};
                                end

                                5'd8: begin
                                    ibuf_enb[2] = 1'b1;
                                    ibuf_ld_wrn[2] = 1'b1;
                                    ibuf_bank_sel[5:4] = 2'd3;
                                    ibuf_conv_wstrb = {1'b0, i_sl_addr_2_2[1:0]};
                                end
                            endcase
                        end

            // Mini State: I_DOWN_R2L
                        I_DOWN_R2L: begin
                            case (state_cnt)
                                5'd0: begin
                                    ibuf_di_revert[0] = 1'b1;
                                    ibuf_do_revert[0] = 1'b1;
                                    ibuf_enb[0] = 1'b1;
                                    ibuf_ld_wrn[0] = 1'b1;
                                    ibuf_bank_sel[1:0] = 2'd3;
                                    ibuf_conv_wstrb = {1'b0, ~i_dr2l_addr_0[1:0]};
                                end

                                5'd1: begin
                                    ibuf_di_revert[0] = 1'b1;
                                    ibuf_do_revert[0] = 1'b1;
                                    ibuf_enb[0] = 1'b1;
                                    ibuf_ld_wrn[0] = 1'b1;
                                    ibuf_bank_sel[1:0] = 2'd3;
                                    ibuf_conv_wstrb = {1'b0, ~i_dr2l_addr_0[1:0]} + 3'd3;
                                end

                                5'd2: begin
                                    ibuf_di_revert[1] = 1'b1;
                                    ibuf_do_revert[1] = 1'b1;
                                    ibuf_enb[1] = 1'b1;
                                    ibuf_ld_wrn[1] = 1'b1;
                                    ibuf_bank_sel[3:2] = 2'd3;
                                    ibuf_conv_wstrb = {1'b0, ~i_dr2l_addr_1[1:0]};
                                end

                                5'd3: begin
                                    ibuf_di_revert[1] = 1'b1;
                                    ibuf_do_revert[1] = 1'b1;
                                    ibuf_enb[1] = 1'b1;
                                    ibuf_ld_wrn[1] = 1'b1;
                                    ibuf_bank_sel[3:2] = 2'd3;
                                    ibuf_conv_wstrb = {1'b0, ~i_dr2l_addr_1[1:0]} + 3'd3;
                                end

                                5'd4: begin
                                    ibuf_di_revert[2] = 1'b1;
                                    ibuf_do_revert[2] = 1'b1;
                                    ibuf_enb[2] = 1'b1;
                                    ibuf_ld_wrn[2] = 1'b1;
                                    ibuf_bank_sel[5:4] = 2'd3;
                                    ibuf_conv_wstrb = {1'b0, ~i_dr2l_addr_2[1:0]};
                                end

                                5'd5: begin
                                    ibuf_di_revert[2] = 1'b1;
                                    ibuf_do_revert[2] = 1'b1;
                                    ibuf_enb[2] = 1'b1;
                                    ibuf_ld_wrn[2] = 1'b1;
                                    ibuf_bank_sel[5:4] = 2'd3;
                                    ibuf_conv_wstrb = {1'b0, ~i_dr2l_addr_2[1:0]} + 3'd3;
                                end
                            endcase
                        end

            // Mini State: I_SHIFT_RIGHT
                        I_SHIFT_RIGHT: begin
                            case (state_cnt)
                                5'd0: begin
                                    ibuf_di_revert[0] = 1'b1;
                                    ibuf_enb[0] = 1'b1;
                                    ibuf_ld_wrn[0] = 1'b1;
                                    ibuf_bank_sel[1:0] = 2'd1;
                                    ibuf_conv_wstrb = {1'b0, ~i_sr_addr_0_0[1:0]};
                                end

                                5'd1: begin
                                    ibuf_di_revert[0] = 1'b1;
                                    ibuf_enb[0] = 1'b1;
                                    ibuf_ld_wrn[0] = 1'b1;
                                    ibuf_bank_sel[1:0] = 2'd2;
                                    ibuf_conv_wstrb = {1'b0, ~i_sr_addr_0_1[1:0]};
                                end

                                5'd2: begin
                                    ibuf_di_revert[0] = 1'b1;
                                    ibuf_enb[0] = 1'b1;
                                    ibuf_ld_wrn[0] = 1'b1;
                                    ibuf_bank_sel[1:0] = 2'd3;
                                    ibuf_conv_wstrb = {1'b0, ~i_sr_addr_0_2[1:0]};
                                end

                                5'd3: begin
                                    ibuf_di_revert[1] = 1'b1;
                                    ibuf_enb[1] = 1'b1;
                                    ibuf_ld_wrn[1] = 1'b1;
                                    ibuf_bank_sel[3:2] = 2'd1;
                                    ibuf_conv_wstrb = {1'b0, ~i_sr_addr_1_0[1:0]};
                                end

                                5'd4: begin
                                    ibuf_di_revert[1] = 1'b1;
                                    ibuf_enb[1] = 1'b1;
                                    ibuf_ld_wrn[1] = 1'b1;
                                    ibuf_bank_sel[3:2] = 2'd2;
                                    ibuf_conv_wstrb = {1'b0, ~i_sr_addr_1_1[1:0]};
                                end

                                5'd5: begin
                                    ibuf_di_revert[1] = 1'b1;
                                    ibuf_enb[1] = 1'b1;
                                    ibuf_ld_wrn[1] = 1'b1;
                                    ibuf_bank_sel[3:2] = 2'd3;
                                    ibuf_conv_wstrb = {1'b0, ~i_sr_addr_1_2[1:0]};
                                end

                                5'd6: begin
                                    ibuf_di_revert[2] = 1'b1;
                                    ibuf_enb[2] = 1'b1;
                                    ibuf_ld_wrn[2] = 1'b1;
                                    ibuf_bank_sel[5:4] = 2'd1;
                                    ibuf_conv_wstrb = {1'b0, ~i_sr_addr_2_0[1:0]};
                                end

                                5'd7: begin
                                    ibuf_di_revert[2] = 1'b1;
                                    ibuf_enb[2] = 1'b1;
                                    ibuf_ld_wrn[2] = 1'b1;
                                    ibuf_bank_sel[5:4] = 2'd2;
                                    ibuf_conv_wstrb = {1'b0, ~i_sr_addr_2_1[1:0]};
                                end

                                5'd8: begin
                                    ibuf_di_revert[2] = 1'b1;
                                    ibuf_enb[2] = 1'b1;
                                    ibuf_ld_wrn[2] = 1'b1;
                                    ibuf_bank_sel[5:4] = 2'd3;
                                    ibuf_conv_wstrb = {1'b0, ~i_sr_addr_2_2[1:0]};
                                end
                            endcase
                        end

            // Mini State: I_DOWN_L2R
                        I_DOWN_L2R: begin
                            case (state_cnt)
                                5'd0: begin
                                    ibuf_enb[0] = 1'b1;
                                    ibuf_ld_wrn[0] = 1'b1;
                                    ibuf_bank_sel[1:0] = 2'd3;
                                    ibuf_conv_wstrb = {1'b0, i_dl2r_addr_0[1:0]};
                                end

                                5'd1: begin
                                    ibuf_enb[0] = 1'b1;
                                    ibuf_ld_wrn[0] = 1'b1;
                                    ibuf_bank_sel[1:0] = 2'd3;
                                    ibuf_conv_wstrb = {1'b0, i_dl2r_addr_0[1:0]} + 3'd3;
                                end

                                5'd2: begin
                                    ibuf_enb[1] = 1'b1;
                                    ibuf_ld_wrn[1] = 1'b1;
                                    ibuf_bank_sel[3:2] = 2'd3;
                                    ibuf_conv_wstrb = {1'b0, i_dl2r_addr_1[1:0]};
                                end

                                5'd3: begin
                                    ibuf_enb[1] = 1'b1;
                                    ibuf_ld_wrn[1] = 1'b1;
                                    ibuf_bank_sel[3:2] = 2'd3;
                                    ibuf_conv_wstrb = {1'b0, i_dl2r_addr_1[1:0]} + 3'd3;
                                end

                                5'd4: begin
                                    ibuf_enb[2] = 1'b1;
                                    ibuf_ld_wrn[2] = 1'b1;
                                    ibuf_bank_sel[5:4] = 2'd3;
                                    ibuf_conv_wstrb = {1'b0, i_dl2r_addr_2[1:0]};
                                end

                                5'd5: begin
                                    ibuf_enb[2] = 1'b1;
                                    ibuf_ld_wrn[2] = 1'b1;
                                    ibuf_bank_sel[5:4] = 2'd3;
                                    ibuf_conv_wstrb = {1'b0, i_dl2r_addr_2[1:0]} + 3'd3;
                                end
                            endcase
                        end

            // Mini State: I_FINISH_L
                        // I_FINISH_L: 

            // Mini State: I_FINISH_R
                        // I_FINISH_R: 
                        endcase 
                
            // Nothing!!!!   
                        end        
                    end 
                    // else 
                    // begin
                    //     mem_renb    = 1;
                    // end

                    case (RDATA_imini_state)
            // Mini State: I_START
                        I_START: begin // Read 9 Input Feature Map values
                            case (state_cnt)
                                5'd 0: mem_raddr = i_addr_0_0;
                                5'd 1: mem_raddr = i_addr_0_0 + 4;
                                5'd 2: mem_raddr = i_addr_0_1;
                                5'd 3: mem_raddr = i_addr_0_1 + 4;
                                5'd 4: mem_raddr = i_addr_0_2;
                                5'd 5: mem_raddr = i_addr_0_2 + 4;
                                5'd 6: mem_raddr = i_addr_1_0;
                                5'd 7: mem_raddr = i_addr_1_0 + 4;
                                5'd 8: mem_raddr = i_addr_1_1;
                                5'd 9: mem_raddr = i_addr_1_1 + 4;
                                5'd10: mem_raddr = i_addr_1_2;
                                5'd11: mem_raddr = i_addr_1_2 + 4;
                                5'd12: mem_raddr = i_addr_2_0;
                                5'd13: mem_raddr = i_addr_2_0 + 4;
                                5'd14: mem_raddr = i_addr_2_1;
                                5'd15: mem_raddr = i_addr_2_1 + 4;
                                5'd16: mem_raddr = i_addr_2_2;
                                5'd17: mem_raddr = i_addr_2_2 + 4;
                            endcase
                        end

            // Mini State: I_SHIFT_LEFT
                        I_SHIFT_LEFT: begin
                            case (state_cnt)
                                5'd0: mem_raddr = i_sl_addr_0_0;
                                5'd1: mem_raddr = i_sl_addr_0_1;
                                5'd2: mem_raddr = i_sl_addr_0_2;
                                5'd3: mem_raddr = i_sl_addr_1_0;
                                5'd4: mem_raddr = i_sl_addr_1_1;
                                5'd5: mem_raddr = i_sl_addr_1_2;
                                5'd6: mem_raddr = i_sl_addr_2_0;
                                5'd7: mem_raddr = i_sl_addr_2_1;
                                5'd8: mem_raddr = i_sl_addr_2_2;
                            endcase
                        end

            // Mini State: I_DOWN_R2L
                        I_DOWN_R2L: begin
                            case (state_cnt)
                                5'd0: mem_raddr = i_dr2l_addr_0;
                                5'd1: mem_raddr = i_dr2l_addr_0 - 4;
                                5'd2: mem_raddr = i_dr2l_addr_1;
                                5'd3: mem_raddr = i_dr2l_addr_1 - 4;
                                5'd4: mem_raddr = i_dr2l_addr_2;
                                5'd5: mem_raddr = i_dr2l_addr_2 - 4;
                            endcase
                        end

            // Mini State: I_SHIFT_RIGHT
                        I_SHIFT_RIGHT: begin
                            case (state_cnt)
                                5'd0: mem_raddr   = i_sr_addr_0_0;
                                5'd1: mem_raddr   = i_sr_addr_0_1;
                                5'd2: mem_raddr   = i_sr_addr_0_2;
                                5'd3: mem_raddr   = i_sr_addr_1_0;
                                5'd4: mem_raddr   = i_sr_addr_1_1;
                                5'd5: mem_raddr   = i_sr_addr_1_2;
                                5'd6: mem_raddr   = i_sr_addr_2_0;
                                5'd7: mem_raddr   = i_sr_addr_2_1;
                                5'd8: mem_raddr   = i_sr_addr_2_2;
                            endcase
                        end

            // Mini State: I_DOWN_L2R
                        I_DOWN_L2R: begin
                            case (state_cnt)
                                5'd0: mem_raddr   = i_dl2r_addr_0;
                                5'd1: mem_raddr   = i_dl2r_addr_0 + 4;
                                5'd2: mem_raddr   = i_dl2r_addr_1;
                                5'd3: mem_raddr   = i_dl2r_addr_1 + 4;
                                5'd4: mem_raddr   = i_dl2r_addr_2;
                                5'd5: mem_raddr   = i_dl2r_addr_2 + 4;
                            endcase
                        end

            // Mini State: I_FINISH_L
                        // I_FINISH_L:

            // Mini State: I_FINISH_R
                        // I_FINISH_R: 
                    endcase 
                
            // Nothing!!!!   
                    end     


        // State: G_ILOAD               
                G_ILOAD: begin
                    ibuf_enb    = 3'b111;
                    ibuf_ld_wrn = 3'b000;
                    case (RDATA_imini_state) 
            // Mini State: I_START
                        I_START: 
                        case(state_cnt)
                            5'd0: begin
                                pu_matrix_conv_dir = NON;
                                idemux_sel = 0;
                                {ireg_enb[0], ireg_enb[3], ireg_enb[6]} = 3'b111;
                            end

                            5'd1: begin
                                pu_matrix_conv_dir = NON;
                                idemux_sel = 1;
                                {ireg_enb[1], ireg_enb[4], ireg_enb[7]} = 3'b111;
                            end

                            5'd2: begin
                                pu_matrix_conv_dir = NON;
                                idemux_sel = 2;
                                {ireg_enb[2], ireg_enb[5], ireg_enb[8]} = 3'b111;
                            end
                        endcase

            // Mini State: I_SHIFT_LEFT 
                        I_SHIFT_LEFT: begin
                            pu_matrix_conv_dir = LEFT;
                            idemux_sel = 0;
                            ireg_enb = 9'b111111111;
                        end 

            // Mini State: I_DOWN_R2L
                        I_DOWN_R2L: begin
                            pu_matrix_conv_dir = DOWN;
                            idemux_sel = 0;
                            ireg_enb = 9'b111111111;
                            ibuf_di_revert = 3'b111;
                            ibuf_do_revert = 3'b111;
                            ibuf_conv_se_load = (stride_height == 2);
                            ibuf_conv_fi_load = (stride_cnt == stride_height - 1);
                        end 

            // Mini State: I_SHIFT_RIGHT
                        I_SHIFT_RIGHT: begin
                            pu_matrix_conv_dir = RIGHT;
                            idemux_sel = 0;
                            ireg_enb = 9'b111111111;
                        end 

            // Mini State: I_DOWN_L2R
                        I_DOWN_L2R: begin
                            pu_matrix_conv_dir = DOWN;
                            idemux_sel = 0;
                            ireg_enb = 9'b111111111;
                            ibuf_conv_se_load = (stride_height == 2);
                            ibuf_conv_fi_load = (stride_cnt == stride_height - 1);
                        end 

            // Mini State: I_FINISH_L
                        // I_FINISH_L:

            // Mini State: I_FINISH_R
                        // I_FINISH_R:
                    endcase
                end

        // State: G_WAIT           
                G_WAIT: begin
                    RDATA_rdy = 1;
                end       

        // State: G_FINISH   
                G_FINISH: begin
                    RDATA_fin = 1;
                end 
            endcase 
            end

/* FULLY-CONNECTED LAYER */
// Input-Based Computation FSM
            DENSE: begin
               case (RDATA_gstate)
        // State: G_START
                    // G_START:

        // State: G_WREAD
                    G_WREAD: begin
                        mem_renb = 1;
                        if (read_mem_state) begin
                            if (mem_read_ready) begin
                                mem_renb = 0;
                                case (state_cnt)
                                    4'd 0: begin
                                        wbuf_enb[0]         = 1;
                                        wbuf_ld_wrn[0]      = 1;
                                        wbuf_bank_sel[1:0]  = 1;
                                        wbuf_wstrb[1:0]     = kw_addr_0[1:0];
                                    end

                                    4'd 1: begin
                                        wbuf_enb[0]         = 1;
                                        wbuf_ld_wrn[0]      = 1;
                                        wbuf_bank_sel[1:0]  = 2;
                                        wbuf_wstrb[1:0]     = kw_addr_0[1:0];
                                    end

                                    4'd 2: begin
                                        wbuf_enb[0]         = 1;
                                        wbuf_ld_wrn[0]      = 1;
                                        wbuf_bank_sel[1:0]  = 3;
                                        wbuf_wstrb[1:0]     = kw_addr_0[1:0];
                                    end

                                    4'd 3: begin
                                        wbuf_enb[1]         = 1;
                                        wbuf_ld_wrn[1]      = 1;
                                        wbuf_bank_sel[3:2]  = 1;
                                        wbuf_wstrb[3:2]     = kw_addr_1[1:0];
                                    end

                                    4'd 4: begin
                                        wbuf_enb[1]         = 1;
                                        wbuf_ld_wrn[1]      = 1;
                                        wbuf_bank_sel[3:2]  = 2;
                                        wbuf_wstrb[3:2]     = kw_addr_1[1:0];
                                    end

                                    4'd 5: begin
                                        wbuf_enb[1]         = 1;
                                        wbuf_ld_wrn[1]      = 1;
                                        wbuf_bank_sel[3:2]  = 3;
                                        wbuf_wstrb[3:2]     = kw_addr_1[1:0];
                                    end

                                    4'd 6: begin
                                        wbuf_enb[2]         = 1;
                                        wbuf_ld_wrn[2]      = 1;
                                        wbuf_bank_sel[5:4]  = 1;
                                        wbuf_wstrb[5:4]     = kw_addr_2[1:0];
                                    end

                                    4'd 7: begin
                                        wbuf_enb[2]         = 1;
                                        wbuf_ld_wrn[2]      = 1;
                                        wbuf_bank_sel[5:4]  = 2;
                                        wbuf_wstrb[5:4]     = kw_addr_2[1:0];
                                    end

                                    4'd 8: begin
                                        wbuf_enb[2]         = 1;
                                        wbuf_ld_wrn[2]      = 1;
                                        wbuf_bank_sel[5:4]  = 3;
                                        wbuf_wstrb[5:4]     = kw_addr_2[1:0];
                                    end
                                endcase
                            end
                        end 
                           
                            case (state_cnt)
                                4'd 0: mem_raddr = kw_addr_0;
                                4'd 1: mem_raddr = kw_addr_0 + 4;
                                4'd 2: mem_raddr = kw_addr_0 + 8;
                                4'd 3: mem_raddr = kw_addr_1;
                                4'd 4: mem_raddr = kw_addr_1 + 4;
                                4'd 5: mem_raddr = kw_addr_1 + 8;
                                4'd 6: mem_raddr = kw_addr_2;
                                4'd 7: mem_raddr = kw_addr_2 + 4;
                                4'd 8: mem_raddr = kw_addr_2 + 8;
                            endcase

                    end

        // State: G_WLOAD
                    G_WLOAD: begin
                        wbuf_enb    = 3'b111;
                        wbuf_ld_wrn = 3'b000;
                        case (state_cnt)
                            4'd0: begin
                                wdemux_sel = 0;
                                wreg_enb[2:0] = 3'b111;
                            end

                            4'd1: begin
                                wdemux_sel = 1;
                                wreg_enb[5:3] = 3'b111;
                            end

                            4'd2: begin
                                wdemux_sel = 2;
                                wreg_enb[8:6] = 3'b111;
                            end
                        endcase
                    end

        // State: G_BREAD
                    G_BREAD: begin
                        mem_renb    = 1;
                        if (read_mem_state) begin
                            if (mem_read_ready) begin
                                mem_renb    = 0;
                                case (state_cnt)
                                    4'd0: begin
                                        bpbuf_enb[0]    = 1;
                                        bpbuf_ld_wrn[0] = 1;
                                    end
                                        
                                    4'd1: begin
                                        bpbuf_enb[1]    = 1;
                                        bpbuf_ld_wrn[1] = 1;
                                    end
                                        
                                    4'd2: begin
                                        bpbuf_enb[2]    = 1;
                                        bpbuf_ld_wrn[2] = 1;
                                    end
                                endcase
                            end
                        end 

                            case (state_cnt)
                                4'd0: mem_raddr   = b_addr_0;
                                4'd1: mem_raddr   = b_addr_1;
                                4'd2: mem_raddr   = b_addr_2; 
                            endcase
                        
                    end

    // State: G_PSREAD
                    G_PSREAD: begin
                        mem_renb    = 1;
                        if (read_mem_state) begin
                            if (mem_read_ready) begin
                                mem_renb    = 0;
                                case (state_cnt)
                                    4'd0: begin
                                        bpbuf_enb[0]    = 1;
                                        bpbuf_ld_wrn[0] = 1;
                                    end

                                    4'd1: begin
                                        bpbuf_enb[1]    = 1;
                                        bpbuf_ld_wrn[1] = 1;
                                    end

                                    4'd2: begin
                                        bpbuf_enb[2]    = 1;
                                        bpbuf_ld_wrn[2] = 1;
                                    end
                                endcase
                            end
                        end 
                            
                            case (state_cnt)
                                4'd0: mem_raddr   = ps_addr_0; 
                                4'd1: mem_raddr   = ps_addr_0 + 4; 
                                4'd2: mem_raddr   = ps_addr_0 + 8; 
                            endcase

                    end
    // State: G_BPSLOAD
                    G_BPSLOAD: begin
                        bpbuf_enb           = 3'b111;
                        bpbuf_ld_wrn        = 3'b000;

                        acc_matrix_enb      = 1;
                        acc_matrix_bps_load = 1;
                    end

    // State: G_IREAD
                    G_IREAD: begin
                        mem_renb = 1;
                        if (read_mem_state) begin
                            if (mem_read_ready) begin
                                mem_renb = 0;
                                case (state_cnt)
                                    4'd 0: begin
                                        ibuf_enb[0]         = 1;
                                        ibuf_ld_wrn[0]      = 1;
                                        ibuf_bank_sel[1:0]  = 1;
                                        ibuf_dens_wstrb     = kw_addr_0[1:0];
                                    end

                                    4'd 1: begin
                                        ibuf_enb[0]         = 1;
                                        ibuf_ld_wrn[0]      = 1;
                                        ibuf_bank_sel[1:0]  = 2;
                                        ibuf_dens_wstrb     = kw_addr_0[1:0];
                                    end

                                    4'd 2: begin
                                        ibuf_enb[0]         = 1;
                                        ibuf_ld_wrn[0]      = 1;
                                        ibuf_bank_sel[1:0]  = 3;
                                        ibuf_dens_wstrb     = kw_addr_0[1:0];
                                    end
                                endcase
                            end
                        end 
                            
                            case (state_cnt)
                                4'd 0: mem_raddr = i_addr_0_0;
                                4'd 1: mem_raddr = i_addr_0_0 + 4;
                                4'd 2: mem_raddr = i_addr_0_0 + 8;
                            endcase

                    end
                
    // State: G_ILOAD
                    G_ILOAD: begin
                        ibuf_enb[0]    = 1;
                        ibuf_ld_wrn[0] = 0;
                        case(state_cnt)
                            5'd0: begin
                                pu_matrix_conv_dir = NON;
                                idemux_sel = 0;
                                ireg_enb[0] = 1;
                            end

                            5'd1: begin
                                pu_matrix_conv_dir = NON;
                                idemux_sel = 1;
                                ireg_enb[1] = 1;
                            end

                            5'd2: begin
                                pu_matrix_conv_dir = NON;
                                idemux_sel = 2;
                                ireg_enb[2] = 1;
                            end
                        endcase
                    end

    // State: G_WAIT
                    G_WAIT: begin
                        RDATA_rdy = 1;
                    end  

    // State: G_FINISH
                    G_FINISH: begin
                        RDATA_fin = 1;
                    end 

                endcase 
            end
/*****************************/

/* MIXED LAYER */
// No-Comp Computation FSM
            MIXED: begin
            case (RDATA_gstate)
        // State: G_START
                // G_START:           

        // State: G_WREAD
                G_WREAD: begin
                    mem_renb = 1;
                    if (read_mem_state) begin
                        if (mem_read_ready) begin
                            mem_renb = 0;
                            // Ctrl Sigs
                            case (state_cnt)
                                4'd0: begin
                                    wbuf_enb[0]         = 1;
                                    wbuf_ld_wrn[0]      = 1;
                                    wbuf_bank_sel[1:0]  = 1;
                                    case (RDATA_wmini_state)
                                        W_READ_0: wbuf_wstrb[1:0] = kw_addr_0_0[1:0];
                                        W_READ_1: wbuf_wstrb[1:0] = kw_addr_0_1[1:0];
                                        W_READ_2: wbuf_wstrb[1:0] = kw_addr_0_2[1:0];
                                    endcase
                                end

                                4'd1: begin
                                    wbuf_enb[0]         = 1;
                                    wbuf_ld_wrn[0]      = 1;
                                    wbuf_bank_sel[1:0]  = 2;
                                    case (RDATA_wmini_state)
                                        W_READ_0: wbuf_wstrb[1:0] = kw_addr_0_0[1:0];
                                        W_READ_1: wbuf_wstrb[1:0] = kw_addr_0_1[1:0];
                                        W_READ_2: wbuf_wstrb[1:0] = kw_addr_0_2[1:0];
                                    endcase
                                end

                                4'd2: begin
                                    wbuf_enb[0]         = 1;
                                    wbuf_ld_wrn[0]      = 1;
                                    wbuf_bank_sel[1:0]  = 3;
                                    case (RDATA_wmini_state)
                                        W_READ_0: wbuf_wstrb[1:0] = kw_addr_0_0[1:0];
                                        W_READ_1: wbuf_wstrb[1:0] = kw_addr_0_1[1:0]; 
                                        W_READ_2: wbuf_wstrb[1:0] = kw_addr_0_2[1:0]; 
                                    endcase
                                end

                                4'd3: begin
                                    wbuf_enb[1]         = 1;
                                    wbuf_ld_wrn[1]      = 1;
                                    wbuf_bank_sel[3:2]  = 1;
                                    case (RDATA_wmini_state)
                                        W_READ_0: wbuf_wstrb[3:2] = kw_addr_1_0[1:0];
                                        W_READ_1: wbuf_wstrb[3:2] = kw_addr_1_1[1:0];
                                        W_READ_2: wbuf_wstrb[3:2] = kw_addr_1_2[1:0];
                                    endcase
                                end

                                4'd4: begin
                                    wbuf_enb[1]         = 1;
                                    wbuf_ld_wrn[1]      = 1;
                                    wbuf_bank_sel[3:2]  = 2;
                                    case (RDATA_wmini_state)
                                        W_READ_0: wbuf_wstrb[3:2] = kw_addr_1_0[1:0];
                                        W_READ_1: wbuf_wstrb[3:2] = kw_addr_1_1[1:0];
                                        W_READ_2: wbuf_wstrb[3:2] = kw_addr_1_2[1:0];
                                    endcase
                                end

                                4'd5: begin
                                    wbuf_enb[1]         = 1;
                                    wbuf_ld_wrn[1]      = 1;
                                    wbuf_bank_sel[3:2]  = 3;
                                    case (RDATA_wmini_state)
                                        W_READ_0: wbuf_wstrb[3:2] = kw_addr_1_0[1:0];
                                        W_READ_1: wbuf_wstrb[3:2] = kw_addr_1_1[1:0];
                                        W_READ_2: wbuf_wstrb[3:2] = kw_addr_1_2[1:0];
                                    endcase
                                end

                                4'd6: begin
                                    wbuf_enb[2]         = 1;
                                    wbuf_ld_wrn[2]      = 1;
                                    wbuf_bank_sel[5:4]  = 1;
                                    case (RDATA_wmini_state)
                                        W_READ_0: wbuf_wstrb[5:4] = kw_addr_2_0[1:0];
                                        W_READ_1: wbuf_wstrb[5:4] = kw_addr_2_1[1:0];
                                        W_READ_2: wbuf_wstrb[5:4] = kw_addr_2_2[1:0];
                                    endcase
                                end

                                4'd7: begin
                                    wbuf_enb[2]         = 1;
                                    wbuf_ld_wrn[2]      = 1;
                                    wbuf_bank_sel[5:4]  = 2;
                                    case (RDATA_wmini_state)
                                        W_READ_0: wbuf_wstrb[5:4] = kw_addr_2_0[1:0];
                                        W_READ_1: wbuf_wstrb[5:4] = kw_addr_2_1[1:0];
                                        W_READ_2: wbuf_wstrb[5:4] = kw_addr_2_2[1:0];
                                    endcase
                                end

                                4'd8: begin
                                    wbuf_enb[2]         = 1;
                                    wbuf_ld_wrn[2]      = 1;
                                    wbuf_bank_sel[5:4]  = 3;
                                    case (RDATA_wmini_state)
                                        W_READ_0: wbuf_wstrb[5:4] = kw_addr_2_0[1:0];
                                        W_READ_1: wbuf_wstrb[5:4] = kw_addr_2_1[1:0];
                                        W_READ_2: wbuf_wstrb[5:4] = kw_addr_2_2[1:0];
                                    endcase
                                end
                            endcase
                        end
                    end
                    // else begin
                    //     mem_renb = 1;
                    // end

                        case (state_cnt)
                            4'd0: begin
                                case (RDATA_wmini_state)
                                    W_READ_0: mem_raddr       = kw_addr_0_0;
                                    W_READ_1: mem_raddr       = kw_addr_0_1; 
                                    W_READ_2: mem_raddr       = kw_addr_0_2;  
                                endcase
                            end

                            4'd1: begin
                                case (RDATA_wmini_state)
                                    W_READ_0: mem_raddr       = kw_addr_0_0 + 4;
                                    W_READ_1: mem_raddr       = kw_addr_0_1 + 4;
                                    W_READ_2: mem_raddr       = kw_addr_0_2 + 4;
                                endcase
                            end

                            4'd2: begin
                                case (RDATA_wmini_state)
                                    W_READ_0: mem_raddr       = kw_addr_0_0 + 8;
                                    W_READ_1: mem_raddr       = kw_addr_0_1 + 8;
                                    W_READ_2: mem_raddr       = kw_addr_0_2 + 8;
                                endcase
                            end

                            4'd3: begin
                                case (RDATA_wmini_state)
                                    W_READ_0: mem_raddr       = kw_addr_1_0;
                                    W_READ_1: mem_raddr       = kw_addr_1_1; 
                                    W_READ_2: mem_raddr       = kw_addr_1_2;  
                                endcase
                            end

                            4'd4: begin
                                case (RDATA_wmini_state)
                                    W_READ_0: mem_raddr       = kw_addr_1_0 + 4;
                                    W_READ_1: mem_raddr       = kw_addr_1_1 + 4;
                                    W_READ_2: mem_raddr       = kw_addr_1_2 + 4;
                                endcase
                            end

                            4'd5: begin
                                case (RDATA_wmini_state)
                                    W_READ_0: mem_raddr       = kw_addr_1_0 + 8;
                                    W_READ_1: mem_raddr       = kw_addr_1_1 + 8;
                                    W_READ_2: mem_raddr       = kw_addr_1_2 + 8;
                                endcase
                            end

                            4'd6: begin
                                case (RDATA_wmini_state)
                                    W_READ_0: mem_raddr       = kw_addr_2_0;
                                    W_READ_1: mem_raddr       = kw_addr_2_1; 
                                    W_READ_2: mem_raddr       = kw_addr_2_2;  
                                endcase
                            end

                            4'd7: begin
                                case (RDATA_wmini_state)
                                    W_READ_0: mem_raddr       = kw_addr_2_0 + 4;
                                    W_READ_1: mem_raddr       = kw_addr_2_1 + 4;
                                    W_READ_2: mem_raddr       = kw_addr_2_2 + 4;
                                endcase
                            end

                            4'd8: begin
                                case (RDATA_wmini_state)
                                    W_READ_0: mem_raddr       = kw_addr_2_0 + 8;
                                    W_READ_1: mem_raddr       = kw_addr_2_1 + 8;
                                    W_READ_2: mem_raddr       = kw_addr_2_2 + 8;
                                endcase
                            end
                        endcase
                end

        // State: G_WLOAD
                G_WLOAD: begin
                    wbuf_enb    = 3'b111;
                    wbuf_ld_wrn = 3'b000;
                    case (state_cnt)
                        4'd0: begin
                            wdemux_sel = 0;
                            case (RDATA_wmini_state)
                                W_LOAD_0: wreg_enb[ 2: 0] = 3'b111;
                                W_LOAD_1: wreg_enb[11: 9] = 3'b111;
                                W_LOAD_2: wreg_enb[20:18] = 3'b111;
                            endcase
                        end

                        4'd1: begin
                            wdemux_sel = 1;
                            case (RDATA_wmini_state)
                                W_LOAD_0: wreg_enb[ 5: 3] = 3'b111;
                                W_LOAD_1: wreg_enb[14:12] = 3'b111;
                                W_LOAD_2: wreg_enb[23:21] = 3'b111;
                            endcase
                        end

                        4'd2: begin
                            wdemux_sel = 2;
                            case (RDATA_wmini_state)
                                W_LOAD_0: wreg_enb[ 8: 6] = 3'b111;
                                W_LOAD_1: wreg_enb[17:15] = 3'b111;
                                W_LOAD_2: wreg_enb[26:24] = 3'b111;
                            endcase
                        end
                    endcase
                end

        // State: G_BREAD
                G_BREAD: begin
                    mem_renb    = 1;
                    if (read_mem_state) begin
                        if (mem_read_ready) begin
                            mem_renb    = 0;
                            // Ctrl Sigs
                            case (state_cnt)
                                4'd0: begin
                                    bpbuf_enb[0]    = 1;
                                    bpbuf_ld_wrn[0] = 1;
                                end
                                    
                                4'd1: begin
                                    bpbuf_enb[1]    = 1;
                                    bpbuf_ld_wrn[1] = 1;
                                end
                                    
                                4'd2: begin
                                    bpbuf_enb[2]    = 1;
                                    bpbuf_ld_wrn[2] = 1;
                                end
                            endcase

                        end
                    end 
                    // else begin
                    //     mem_renb    = 1;
                    // end

                    case (state_cnt)
                        4'd0: mem_raddr   = b_addr_0;
                        4'd1: mem_raddr   = b_addr_1;
                        4'd2: mem_raddr   = b_addr_2; 
                    endcase
                end

        // State: G_PSREAD
                G_PSREAD: begin
                    mem_renb    = 1;
                    if (read_mem_state) begin
                        if (mem_read_ready) begin 
                            mem_renb    = 0;
                            case (state_cnt)
                                4'd0: begin
                                    bpbuf_enb[0]    = 1;
                                    bpbuf_ld_wrn[0] = 1;
                                end

                                4'd1: begin
                                    bpbuf_enb[1]    = 1;
                                    bpbuf_ld_wrn[1] = 1;
                                end

                                4'd2: begin
                                    bpbuf_enb[2]    = 1;
                                    bpbuf_ld_wrn[2] = 1;
                                end
                            endcase
                        end
                    end 
                    // else begin
                    //     begin 
                    //         mem_renb    = 1;
                    //     end
                    // end

                        case (state_cnt)
                            4'd0: mem_raddr   = ps_addr_0; 
                            4'd1: mem_raddr   = ps_addr_1; 
                            4'd2: mem_raddr   = ps_addr_2; 
                        endcase
                end

        // State: G_BPSLOAD
                G_BPSLOAD: begin
                    bpbuf_enb           = 3'b111;
                    bpbuf_ld_wrn        = 3'b000;

                    acc_matrix_enb      = 1;
                    acc_matrix_bps_load = 1;
                end
                        
        // State: G_IREAD
                G_IREAD: begin // Load Input Feature Map 
                    mem_renb    = 1;
                    if (read_mem_state) begin  
                        if (mem_read_ready) begin
                            mem_renb    = 0;
                        case (RDATA_imini_state)
            // Mini State: I_START
                        I_START: begin// Read 9 Input Feature Map values
                            case (state_cnt)
                                5'd 0: begin
                                    ibuf_enb[0] = 1'b1;
                                    ibuf_ld_wrn[0] = 1'b1;
                                    ibuf_bank_sel[1:0] = 2'd1;
                                    ibuf_conv_wstrb = {1'b0, i_addr_0_0[1:0]};
                                end

                                5'd 1: begin
                                    ibuf_enb[0] = 1'b1;
                                    ibuf_ld_wrn[0] = 1'b1;
                                    ibuf_bank_sel[1:0] = 2'd1;
                                    ibuf_conv_wstrb = {1'b0, i_addr_0_0[1:0]} + 3'd3;
                                end 

                                5'd 2: begin
                                    ibuf_enb[0] = 1'b1;
                                    ibuf_ld_wrn[0] = 1'b1;
                                    ibuf_bank_sel[1:0] = 2'd2;
                                    ibuf_conv_wstrb = {1'b0, i_addr_0_1[1:0]};
                                end

                                5'd 3: begin
                                    ibuf_enb[0] = 1'b1;
                                    ibuf_ld_wrn[0] = 1'b1;
                                    ibuf_bank_sel[1:0] = 2'd2;
                                    ibuf_conv_wstrb = {1'b0, i_addr_0_1[1:0]} + 3'd3;
                                end 

                                5'd 4: begin
                                    ibuf_enb[0] = 1'b1;
                                    ibuf_ld_wrn[0] = 1'b1;
                                    ibuf_bank_sel[1:0] = 2'd3;
                                    ibuf_conv_wstrb = {1'b0, i_addr_0_2[1:0]};
                                end

                                5'd 5: begin
                                    ibuf_enb[0] = 1'b1;
                                    ibuf_ld_wrn[0] = 1'b1;
                                    ibuf_bank_sel[1:0] = 2'd3;
                                    ibuf_conv_wstrb = {1'b0, i_addr_0_2[1:0]} + 3'd3;
                                end 

                                5'd 6: begin
                                    ibuf_enb[1] = 1'b1;
                                    ibuf_ld_wrn[1] = 1'b1;
                                    ibuf_bank_sel[3:2] = 2'd1;
                                    ibuf_conv_wstrb = {1'b0, i_addr_1_0[1:0]};
                                end

                                5'd 7: begin
                                    ibuf_enb[1] = 1'b1;
                                    ibuf_ld_wrn[1] = 1'b1;
                                    ibuf_bank_sel[3:2] = 2'd1;
                                    ibuf_conv_wstrb = {1'b0, i_addr_1_0[1:0]} + 3'd3;
                                end 

                                5'd 8: begin
                                    ibuf_enb[1] = 1'b1;
                                    ibuf_ld_wrn[1] = 1'b1;
                                    ibuf_bank_sel[3:2] = 2'd2;
                                    ibuf_conv_wstrb = {1'b0, i_addr_1_1[1:0]};
                                end

                                5'd 9: begin
                                    ibuf_enb[1] = 1'b1;
                                    ibuf_ld_wrn[1] = 1'b1;
                                    ibuf_bank_sel[3:2] = 2'd2;
                                    ibuf_conv_wstrb = {1'b0, i_addr_1_1[1:0]} + 3'd3;
                                end 

                                5'd10: begin
                                    ibuf_enb[1] = 1'b1;
                                    ibuf_ld_wrn[1] = 1'b1;
                                    ibuf_bank_sel[3:2] = 2'd3;
                                    ibuf_conv_wstrb = {1'b0, i_addr_1_2[1:0]};
                                end

                                5'd11: begin
                                    ibuf_enb[1] = 1'b1;
                                    ibuf_ld_wrn[1] = 1'b1;
                                    ibuf_bank_sel[3:2] = 2'd3;
                                    ibuf_conv_wstrb = {1'b0, i_addr_1_2[1:0]} + 3'd3;
                                end 

                                5'd12: begin
                                    ibuf_enb[2] = 1'b1;
                                    ibuf_ld_wrn[2] = 1'b1;
                                    ibuf_bank_sel[5:4] = 2'd1;
                                    ibuf_conv_wstrb = {1'b0, i_addr_2_0[1:0]};
                                end

                                5'd13: begin
                                    ibuf_enb[2] = 1'b1;
                                    ibuf_ld_wrn[2] = 1'b1;
                                    ibuf_bank_sel[5:4] = 2'd1;
                                    ibuf_conv_wstrb = {1'b0, i_addr_2_0[1:0]} + 3'd3;
                                end 

                                5'd14: begin
                                    ibuf_enb[2] = 1'b1;
                                    ibuf_ld_wrn[2] = 1'b1;
                                    ibuf_bank_sel[5:4] = 2'd2;
                                    ibuf_conv_wstrb = {1'b0, i_addr_2_1[1:0]};
                                end

                                5'd15: begin
                                    ibuf_enb[2] = 1'b1;
                                    ibuf_ld_wrn[2] = 1'b1;
                                    ibuf_bank_sel[5:4] = 2'd2;
                                    ibuf_conv_wstrb = {1'b0, i_addr_2_1[1:0]} + 3'd3;
                                end 

                                5'd16: begin
                                    ibuf_enb[2] = 1'b1;
                                    ibuf_ld_wrn[2] = 1'b1;
                                    ibuf_bank_sel[5:4] = 2'd3;
                                    ibuf_conv_wstrb = {1'b0, i_addr_2_2[1:0]};
                                end

                                5'd17: begin
                                    ibuf_enb[2] = 1'b1;
                                    ibuf_ld_wrn[2] = 1'b1;
                                    ibuf_bank_sel[5:4] = 2'd3;
                                    ibuf_conv_wstrb = {1'b0, i_addr_2_2[1:0]} + 3'd3;
                                end 
                            endcase
                        end

            // Mini State: I_SHIFT_LEFT
                        I_SHIFT_LEFT: begin
                            case (state_cnt)
                                5'd0: begin
                                    ibuf_enb[0] = 1'b1;
                                    ibuf_ld_wrn[0] = 1'b1;
                                    ibuf_bank_sel[1:0] = 2'd1;
                                    ibuf_conv_wstrb = {1'b0, i_sl_addr_0_0[1:0]};
                                end

                                5'd1: begin
                                    ibuf_enb[0] = 1'b1;
                                    ibuf_ld_wrn[0] = 1'b1;
                                    ibuf_bank_sel[1:0] = 2'd2;
                                    ibuf_conv_wstrb = {1'b0, i_sl_addr_0_1[1:0]};
                                end

                                5'd2: begin
                                    ibuf_enb[0] = 1'b1;
                                    ibuf_ld_wrn[0] = 1'b1;
                                    ibuf_bank_sel[1:0] = 2'd3;
                                    ibuf_conv_wstrb = {1'b0, i_sl_addr_0_2[1:0]};
                                end

                                5'd3: begin
                                    ibuf_enb[1] = 1'b1;
                                    ibuf_ld_wrn[1] = 1'b1;
                                    ibuf_bank_sel[3:2] = 2'd1;
                                    ibuf_conv_wstrb = {1'b0, i_sl_addr_1_0[1:0]};
                                end

                                5'd4: begin
                                    ibuf_enb[1] = 1'b1;
                                    ibuf_ld_wrn[1] = 1'b1;
                                    ibuf_bank_sel[3:2] = 2'd2;
                                    ibuf_conv_wstrb = {1'b0, i_sl_addr_1_1[1:0]};
                                end

                                5'd5: begin
                                    ibuf_enb[1] = 1'b1;
                                    ibuf_ld_wrn[1] = 1'b1;
                                    ibuf_bank_sel[3:2] = 2'd3;
                                    ibuf_conv_wstrb = {1'b0, i_sl_addr_1_2[1:0]};
                                end

                                5'd6: begin
                                    ibuf_enb[2] = 1'b1;
                                    ibuf_ld_wrn[2] = 1'b1;
                                    ibuf_bank_sel[5:4] = 2'd1;
                                    ibuf_conv_wstrb = {1'b0, i_sl_addr_2_0[1:0]};
                                end

                                5'd7: begin
                                    ibuf_enb[2] = 1'b1;
                                    ibuf_ld_wrn[2] = 1'b1;
                                    ibuf_bank_sel[5:4] = 2'd2;
                                    ibuf_conv_wstrb = {1'b0, i_sl_addr_2_1[1:0]};
                                end

                                5'd8: begin
                                    ibuf_enb[2] = 1'b1;
                                    ibuf_ld_wrn[2] = 1'b1;
                                    ibuf_bank_sel[5:4] = 2'd3;
                                    ibuf_conv_wstrb = {1'b0, i_sl_addr_2_2[1:0]};
                                end
                            endcase
                        end

            // Mini State: I_DOWN_R2L
                        I_DOWN_R2L: begin
                            case (state_cnt)
                                5'd0: begin
                                    ibuf_di_revert[0] = 1'b1;
                                    ibuf_do_revert[0] = 1'b1;
                                    ibuf_enb[0] = 1'b1;
                                    ibuf_ld_wrn[0] = 1'b1;
                                    ibuf_bank_sel[1:0] = 2'd3;
                                    ibuf_conv_wstrb = {1'b0, ~i_dr2l_addr_0[1:0]};
                                end

                                5'd1: begin
                                    ibuf_di_revert[0] = 1'b1;
                                    ibuf_do_revert[0] = 1'b1;
                                    ibuf_enb[0] = 1'b1;
                                    ibuf_ld_wrn[0] = 1'b1;
                                    ibuf_bank_sel[1:0] = 2'd3;
                                    ibuf_conv_wstrb = {1'b0, ~i_dr2l_addr_0[1:0]} + 3'd3;
                                end

                                5'd2: begin
                                    ibuf_di_revert[1] = 1'b1;
                                    ibuf_do_revert[1] = 1'b1;
                                    ibuf_enb[1] = 1'b1;
                                    ibuf_ld_wrn[1] = 1'b1;
                                    ibuf_bank_sel[3:2] = 2'd3;
                                    ibuf_conv_wstrb = {1'b0, ~i_dr2l_addr_1[1:0]};
                                end

                                5'd3: begin
                                    ibuf_di_revert[1] = 1'b1;
                                    ibuf_do_revert[1] = 1'b1;
                                    ibuf_enb[1] = 1'b1;
                                    ibuf_ld_wrn[1] = 1'b1;
                                    ibuf_bank_sel[3:2] = 2'd3;
                                    ibuf_conv_wstrb = {1'b0, ~i_dr2l_addr_1[1:0]} + 3'd3;
                                end

                                5'd4: begin
                                    ibuf_di_revert[2] = 1'b1;
                                    ibuf_do_revert[2] = 1'b1;
                                    ibuf_enb[2] = 1'b1;
                                    ibuf_ld_wrn[2] = 1'b1;
                                    ibuf_bank_sel[5:4] = 2'd3;
                                    ibuf_conv_wstrb = {1'b0, ~i_dr2l_addr_2[1:0]};
                                end

                                5'd5: begin
                                    ibuf_di_revert[2] = 1'b1;
                                    ibuf_do_revert[2] = 1'b1;
                                    ibuf_enb[2] = 1'b1;
                                    ibuf_ld_wrn[2] = 1'b1;
                                    ibuf_bank_sel[5:4] = 2'd3;
                                    ibuf_conv_wstrb = {1'b0, ~i_dr2l_addr_2[1:0]} + 3'd3;
                                end
                            endcase
                        end

            // Mini State: I_SHIFT_RIGHT
                        I_SHIFT_RIGHT: begin
                            case (state_cnt)
                                5'd0: begin
                                    ibuf_di_revert[0] = 1'b1;
                                    ibuf_enb[0] = 1'b1;
                                    ibuf_ld_wrn[0] = 1'b1;
                                    ibuf_bank_sel[1:0] = 2'd1;
                                    ibuf_conv_wstrb = {1'b0, ~i_sr_addr_0_0[1:0]};
                                end

                                5'd1: begin
                                    ibuf_di_revert[0] = 1'b1;
                                    ibuf_enb[0] = 1'b1;
                                    ibuf_ld_wrn[0] = 1'b1;
                                    ibuf_bank_sel[1:0] = 2'd2;
                                    ibuf_conv_wstrb = {1'b0, ~i_sr_addr_0_1[1:0]};
                                end

                                5'd2: begin
                                    ibuf_di_revert[0] = 1'b1;
                                    ibuf_enb[0] = 1'b1;
                                    ibuf_ld_wrn[0] = 1'b1;
                                    ibuf_bank_sel[1:0] = 2'd3;
                                    ibuf_conv_wstrb = {1'b0, ~i_sr_addr_0_2[1:0]};
                                end

                                5'd3: begin
                                    ibuf_di_revert[1] = 1'b1;
                                    ibuf_enb[1] = 1'b1;
                                    ibuf_ld_wrn[1] = 1'b1;
                                    ibuf_bank_sel[3:2] = 2'd1;
                                    ibuf_conv_wstrb = {1'b0, ~i_sr_addr_1_0[1:0]};
                                end

                                5'd4: begin
                                    ibuf_di_revert[1] = 1'b1;
                                    ibuf_enb[1] = 1'b1;
                                    ibuf_ld_wrn[1] = 1'b1;
                                    ibuf_bank_sel[3:2] = 2'd2;
                                    ibuf_conv_wstrb = {1'b0, ~i_sr_addr_1_1[1:0]};
                                end

                                5'd5: begin
                                    ibuf_di_revert[1] = 1'b1;
                                    ibuf_enb[1] = 1'b1;
                                    ibuf_ld_wrn[1] = 1'b1;
                                    ibuf_bank_sel[3:2] = 2'd3;
                                    ibuf_conv_wstrb = {1'b0, ~i_sr_addr_1_2[1:0]};
                                end

                                5'd6: begin
                                    ibuf_di_revert[2] = 1'b1;
                                    ibuf_enb[2] = 1'b1;
                                    ibuf_ld_wrn[2] = 1'b1;
                                    ibuf_bank_sel[5:4] = 2'd1;
                                    ibuf_conv_wstrb = {1'b0, ~i_sr_addr_2_0[1:0]};
                                end

                                5'd7: begin
                                    ibuf_di_revert[2] = 1'b1;
                                    ibuf_enb[2] = 1'b1;
                                    ibuf_ld_wrn[2] = 1'b1;
                                    ibuf_bank_sel[5:4] = 2'd2;
                                    ibuf_conv_wstrb = {1'b0, ~i_sr_addr_2_1[1:0]};
                                end

                                5'd8: begin
                                    ibuf_di_revert[2] = 1'b1;
                                    ibuf_enb[2] = 1'b1;
                                    ibuf_ld_wrn[2] = 1'b1;
                                    ibuf_bank_sel[5:4] = 2'd3;
                                    ibuf_conv_wstrb = {1'b0, ~i_sr_addr_2_2[1:0]};
                                end
                            endcase
                        end

            // Mini State: I_DOWN_L2R
                        I_DOWN_L2R: begin
                            case (state_cnt)
                                5'd0: begin
                                    ibuf_enb[0] = 1'b1;
                                    ibuf_ld_wrn[0] = 1'b1;
                                    ibuf_bank_sel[1:0] = 2'd3;
                                    ibuf_conv_wstrb = {1'b0, i_dl2r_addr_0[1:0]};
                                end

                                5'd1: begin
                                    ibuf_enb[0] = 1'b1;
                                    ibuf_ld_wrn[0] = 1'b1;
                                    ibuf_bank_sel[1:0] = 2'd3;
                                    ibuf_conv_wstrb = {1'b0, i_dl2r_addr_0[1:0]} + 3'd3;
                                end

                                5'd2: begin
                                    ibuf_enb[1] = 1'b1;
                                    ibuf_ld_wrn[1] = 1'b1;
                                    ibuf_bank_sel[3:2] = 2'd3;
                                    ibuf_conv_wstrb = {1'b0, i_dl2r_addr_1[1:0]};
                                end

                                5'd3: begin
                                    ibuf_enb[1] = 1'b1;
                                    ibuf_ld_wrn[1] = 1'b1;
                                    ibuf_bank_sel[3:2] = 2'd3;
                                    ibuf_conv_wstrb = {1'b0, i_dl2r_addr_1[1:0]} + 3'd3;
                                end

                                5'd4: begin
                                    ibuf_enb[2] = 1'b1;
                                    ibuf_ld_wrn[2] = 1'b1;
                                    ibuf_bank_sel[5:4] = 2'd3;
                                    ibuf_conv_wstrb = {1'b0, i_dl2r_addr_2[1:0]};
                                end

                                5'd5: begin
                                    ibuf_enb[2] = 1'b1;
                                    ibuf_ld_wrn[2] = 1'b1;
                                    ibuf_bank_sel[5:4] = 2'd3;
                                    ibuf_conv_wstrb = {1'b0, i_dl2r_addr_2[1:0]} + 3'd3;
                                end
                            endcase
                        end

            // Mini State: I_FINISH_L
                        // I_FINISH_L: 

            // Mini State: I_FINISH_R
                        // I_FINISH_R: 
                        endcase 
                
            // Nothing!!!!   
                        end        
                    end 
                    // else 
                    // begin
                    //     mem_renb    = 1;
                    // end

                    case (RDATA_imini_state)
            // Mini State: I_START
                        I_START: begin // Read 9 Input Feature Map values
                            case (state_cnt)
                                5'd 0: mem_raddr = i_addr_0_0;
                                5'd 1: mem_raddr = i_addr_0_0 + 4;
                                5'd 2: mem_raddr = i_addr_0_1;
                                5'd 3: mem_raddr = i_addr_0_1 + 4;
                                5'd 4: mem_raddr = i_addr_0_2;
                                5'd 5: mem_raddr = i_addr_0_2 + 4;
                                5'd 6: mem_raddr = i_addr_1_0;
                                5'd 7: mem_raddr = i_addr_1_0 + 4;
                                5'd 8: mem_raddr = i_addr_1_1;
                                5'd 9: mem_raddr = i_addr_1_1 + 4;
                                5'd10: mem_raddr = i_addr_1_2;
                                5'd11: mem_raddr = i_addr_1_2 + 4;
                                5'd12: mem_raddr = i_addr_2_0;
                                5'd13: mem_raddr = i_addr_2_0 + 4;
                                5'd14: mem_raddr = i_addr_2_1;
                                5'd15: mem_raddr = i_addr_2_1 + 4;
                                5'd16: mem_raddr = i_addr_2_2;
                                5'd17: mem_raddr = i_addr_2_2 + 4;
                            endcase
                        end

            // Mini State: I_SHIFT_LEFT
                        I_SHIFT_LEFT: begin
                            case (state_cnt)
                                5'd0: mem_raddr = i_sl_addr_0_0;
                                5'd1: mem_raddr = i_sl_addr_0_1;
                                5'd2: mem_raddr = i_sl_addr_0_2;
                                5'd3: mem_raddr = i_sl_addr_1_0;
                                5'd4: mem_raddr = i_sl_addr_1_1;
                                5'd5: mem_raddr = i_sl_addr_1_2;
                                5'd6: mem_raddr = i_sl_addr_2_0;
                                5'd7: mem_raddr = i_sl_addr_2_1;
                                5'd8: mem_raddr = i_sl_addr_2_2;
                            endcase
                        end

            // Mini State: I_DOWN_R2L
                        I_DOWN_R2L: begin
                            case (state_cnt)
                                5'd0: mem_raddr = i_dr2l_addr_0;
                                5'd1: mem_raddr = i_dr2l_addr_0 - 4;
                                5'd2: mem_raddr = i_dr2l_addr_1;
                                5'd3: mem_raddr = i_dr2l_addr_1 - 4;
                                5'd4: mem_raddr = i_dr2l_addr_2;
                                5'd5: mem_raddr = i_dr2l_addr_2 - 4;
                            endcase
                        end

            // Mini State: I_SHIFT_RIGHT
                        I_SHIFT_RIGHT: begin
                            case (state_cnt)
                                5'd0: mem_raddr   = i_sr_addr_0_0;
                                5'd1: mem_raddr   = i_sr_addr_0_1;
                                5'd2: mem_raddr   = i_sr_addr_0_2;
                                5'd3: mem_raddr   = i_sr_addr_1_0;
                                5'd4: mem_raddr   = i_sr_addr_1_1;
                                5'd5: mem_raddr   = i_sr_addr_1_2;
                                5'd6: mem_raddr   = i_sr_addr_2_0;
                                5'd7: mem_raddr   = i_sr_addr_2_1;
                                5'd8: mem_raddr   = i_sr_addr_2_2;
                            endcase
                        end

            // Mini State: I_DOWN_L2R
                        I_DOWN_L2R: begin
                            case (state_cnt)
                                5'd0: mem_raddr   = i_dl2r_addr_0;
                                5'd1: mem_raddr   = i_dl2r_addr_0 + 4;
                                5'd2: mem_raddr   = i_dl2r_addr_1;
                                5'd3: mem_raddr   = i_dl2r_addr_1 + 4;
                                5'd4: mem_raddr   = i_dl2r_addr_2;
                                5'd5: mem_raddr   = i_dl2r_addr_2 + 4;
                            endcase
                        end

            // Mini State: I_FINISH_L
                        // I_FINISH_L:

            // Mini State: I_FINISH_R
                        // I_FINISH_R: 
                    endcase 
                
            // Nothing!!!!   
                    end     


        // State: G_ILOAD               
                G_ILOAD: begin
                    ibuf_enb    = 3'b111;
                    ibuf_ld_wrn = 3'b000;
                    case (RDATA_imini_state) 
            // Mini State: I_START
                        I_START: 
                        case(state_cnt)
                            5'd0: begin
                                pu_matrix_conv_dir = NON;
                                idemux_sel = 0;
                                {ireg_enb[0], ireg_enb[3], ireg_enb[6]} = 3'b111;
                            end

                            5'd1: begin
                                pu_matrix_conv_dir = NON;
                                idemux_sel = 1;
                                {ireg_enb[1], ireg_enb[4], ireg_enb[7]} = 3'b111;
                            end

                            5'd2: begin
                                pu_matrix_conv_dir = NON;
                                idemux_sel = 2;
                                {ireg_enb[2], ireg_enb[5], ireg_enb[8]} = 3'b111;
                            end
                        endcase

            // Mini State: I_SHIFT_LEFT 
                        I_SHIFT_LEFT: begin
                            pu_matrix_conv_dir = LEFT;
                            idemux_sel = 0;
                            ireg_enb = 9'b111111111;
                        end 

            // Mini State: I_DOWN_R2L
                        I_DOWN_R2L: begin
                            pu_matrix_conv_dir = DOWN;
                            idemux_sel = 0;
                            ireg_enb = 9'b111111111;
                            ibuf_di_revert = 3'b111;
                            ibuf_do_revert = 3'b111;
                            ibuf_conv_se_load = (stride_height == 2);
                            ibuf_conv_fi_load = (stride_cnt == stride_height - 1);
                        end 

            // Mini State: I_SHIFT_RIGHT
                        I_SHIFT_RIGHT: begin
                            pu_matrix_conv_dir = RIGHT;
                            idemux_sel = 0;
                            ireg_enb = 9'b111111111;
                        end 

            // Mini State: I_DOWN_L2R
                        I_DOWN_L2R: begin
                            pu_matrix_conv_dir = DOWN;
                            idemux_sel = 0;
                            ireg_enb = 9'b111111111;
                            ibuf_conv_se_load = (stride_height == 2);
                            ibuf_conv_fi_load = (stride_cnt == stride_height - 1);
                        end 

            // Mini State: I_FINISH_L
                        // I_FINISH_L:

            // Mini State: I_FINISH_R
                        // I_FINISH_R:
                    endcase
                end

        // State: G_WAIT           
                G_WAIT: begin
                    RDATA_rdy = 1;
                end       

        // State: G_FINISH   
                G_FINISH: begin
                    RDATA_fin = 1;
                end 
            endcase 
            end
/*********************/
        endcase
    end

    /* Special Counter for Skip-Load logic */
    always @(*) begin
        sp_init_ictn_0 = 0;
        if (ibuf_0_valid[0]) begin
            sp_init_ictn_0 = 1;
            if (ibuf_0_valid[1]) begin
                sp_init_ictn_0 = 2;
                if (ibuf_0_valid[2]) begin
                    sp_init_ictn_0 = 3;
                    if (ibuf_1_valid[0]) begin
                        sp_init_ictn_0 = 4;
                        if ((ibuf_1_valid[1])) begin
                            sp_init_ictn_0 = 5;
                            if (ibuf_1_valid[2]) begin
                                sp_init_ictn_0 = 6;
                                if (ibuf_2_valid[0]) begin
                                    sp_init_ictn_0 = 7;
                                    if (ibuf_2_valid[1]) begin
                                        sp_init_ictn_0 = 8;
                                        if (ibuf_2_valid[2]) begin
                                            sp_init_ictn_0 = 9;
                                        end 
                                    end 
                                end 
                            end 
                        end 
                    end 
                end 
            end  
        end
    end

    always @(*) begin
        sp_init_ictn_1 = 0;
        if (ibuf_0_nxt_valid[0]) begin
            sp_init_ictn_1 = 1;
            if (ibuf_0_nxt_valid[1]) begin
                sp_init_ictn_1 = 2;
                if (ibuf_0_nxt_valid[2]) begin
                    sp_init_ictn_1 = 3;
                    if (ibuf_1_nxt_valid[0]) begin
                        sp_init_ictn_1 = 4;
                        if ((ibuf_1_nxt_valid[1])) begin
                            sp_init_ictn_1 = 5;
                            if (ibuf_1_nxt_valid[2]) begin
                                sp_init_ictn_1 = 6;
                                if (ibuf_2_nxt_valid[0]) begin
                                    sp_init_ictn_1 = 7;
                                    if (ibuf_2_nxt_valid[1]) begin
                                        sp_init_ictn_1 = 8;
                                        if (ibuf_2_nxt_valid[2]) begin
                                            sp_init_ictn_1 = 9;
                                        end 
                                    end 
                                end 
                            end 
                        end 
                    end 
                end 
            end  
        end
    end

    always @(*) begin
        sp_run_ictn = 0;
        case (state_cnt)
            5'd 0: begin
                sp_run_ictn = 1;
                if (ibuf_0_valid[1]) begin
                    sp_run_ictn = 2;
                    if (ibuf_0_valid[2]) begin
                        sp_run_ictn = 3;
                        if (ibuf_1_valid[0]) begin
                            sp_run_ictn = 4;
                            if (ibuf_1_valid[1]) begin
                                sp_run_ictn = 5;
                                if (ibuf_1_valid[2]) begin
                                    sp_run_ictn = 6;
                                    if (ibuf_2_valid[0]) begin
                                        sp_run_ictn = 7;
                                        if (ibuf_2_valid[1]) begin
                                            sp_run_ictn = 8;
                                            if (ibuf_2_valid[2]) begin
                                                sp_run_ictn = 9;
                                            end 
                                        end 
                                    end 
                                end  
                            end
                        end
                    end
                end
            end

            5'd 1: begin
                sp_run_ictn = 2;
                if (ibuf_0_valid[2]) begin
                    sp_run_ictn = 3;
                    if (ibuf_1_valid[0]) begin
                        sp_run_ictn = 4;
                        if (ibuf_1_valid[1]) begin
                            sp_run_ictn = 5;
                            if (ibuf_1_valid[2]) begin
                                sp_run_ictn = 6;
                                if (ibuf_2_valid[0]) begin
                                    sp_run_ictn = 7;
                                    if (ibuf_2_valid[1]) begin
                                        sp_run_ictn = 8;
                                        if (ibuf_2_valid[2]) begin
                                            sp_run_ictn = 9;
                                        end 
                                    end 
                                end 
                            end  
                        end
                    end
                end
            end

            5'd 2: begin
                sp_run_ictn = 3;
                if (ibuf_1_valid[0]) begin
                    sp_run_ictn = 4;
                    if (ibuf_1_valid[1]) begin
                        sp_run_ictn = 5;
                        if (ibuf_1_valid[2]) begin
                            sp_run_ictn = 6;
                            if (ibuf_2_valid[0]) begin
                                sp_run_ictn = 7;
                                if (ibuf_2_valid[1]) begin
                                    sp_run_ictn = 8;
                                    if (ibuf_2_valid[2]) begin
                                        sp_run_ictn = 9;
                                    end 
                                end 
                            end 
                        end  
                    end
                end
            end 

            5'd 3: begin
                sp_run_ictn = 4;
                if (ibuf_1_valid[1]) begin
                    sp_run_ictn = 5;
                    if (ibuf_1_valid[2]) begin
                        sp_run_ictn = 6;
                        if (ibuf_2_valid[0]) begin
                            sp_run_ictn = 7;
                            if (ibuf_2_valid[1]) begin
                                sp_run_ictn = 8;
                                if (ibuf_2_valid[2]) begin
                                    sp_run_ictn = 9;
                                end 
                            end 
                        end 
                    end  
                end
            end

            5'd 4: begin
                sp_run_ictn = 5;
                if (ibuf_1_valid[2]) begin
                    sp_run_ictn = 6;
                    if (ibuf_2_valid[0]) begin
                        sp_run_ictn = 7;
                        if (ibuf_2_valid[1]) begin
                            sp_run_ictn = 8;
                            if (ibuf_2_valid[2]) begin
                                sp_run_ictn = 9;
                            end 
                        end 
                    end 
                end  
            end

            5'd 5: begin
                sp_run_ictn = 6;
                if (ibuf_2_valid[0]) begin
                    sp_run_ictn = 7;
                    if (ibuf_2_valid[1]) begin
                        sp_run_ictn = 8;
                        if (ibuf_2_valid[2]) begin
                            sp_run_ictn = 9;
                        end 
                    end 
                end 
            end

            5'd 6: begin
                sp_run_ictn = 7;
                if (ibuf_2_valid[1]) begin
                    sp_run_ictn = 8;
                    if (ibuf_2_valid[2]) begin
                        sp_run_ictn = 9;
                    end 
                end 
            end 

            5'd 7: begin
                sp_run_ictn = 8;
                if (ibuf_2_valid[2]) begin
                    sp_run_ictn = 9;
                end 
            end

            5'd 8: begin
                sp_run_ictn = 9;
            end
        endcase
    end

    /* Pipeline Flop */
    always @(posedge clk) begin
        if (!resetn) begin
            RDATA_is_out_fin    <= 0;
            RDATA_ps_addr       <= 0;
            RDATA_o_addr        <= 0;
            RDATA_o_quant_sel   <= 0;
        end else if (RDATA_reg_enb) begin
            RDATA_is_out_fin    <= is_out_fin;
            RDATA_ps_addr       <= inter_ps_addr;
            RDATA_o_addr        <= inter_o_addr;
            RDATA_o_quant_sel   <= inter_o_quant_sel;
        end
    end

endmodule