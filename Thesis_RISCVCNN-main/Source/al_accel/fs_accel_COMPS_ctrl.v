module fs_accel_COMPS_ctrl (
/* Config Sigs */
    input [ 3:0]  cfg_layer_typ,

/* Output Control Sigs */
    // Processing Matrix Ctrl
    output reg [ 8:0] pu_enb,

    // Accumulate Matrix Ctrl
    output reg          acc_matrix_enb,
    output reg          acc_matrix_bps_write,
    output reg          acc_matrix_inter_sum_write,

    // Pipeline Stage Ctrl
    output reg          COMPS_fin,
    output reg          COMPS_rdy,
    output reg          COMPS_start,
    output reg          COMPS_is_out_fin,
    output reg [31:0]   COMPS_ps_addr,
    output reg [31:0]   COMPS_o_addr,
    output reg [ 3:0]   COMPS_o_quant_sel,

/* Feedback Control Sigs */
    // Processing Matrix
    input         pu_matrix_rdy,

    // RDATA Controller
    input        RDATA_fin,
    input        RDATA_rdy, 
    input        RDATA_is_out_fin,
    input [31:0] RDATA_ps_addr,
    input [31:0] RDATA_o_addr,
    input [ 3:0] RDATA_o_quant_sel,


    // POOL Controller
    input        POOL_rdy,
    input        POOL_start,

    // WBACK Controller
    input       WBACK_rdy,
    input       WBACK_start,

/* Mandatory Sigs */
    input enb,
    input clk,
    input resetn
);
/*  ALL Param Definition */
    // Layer Param
    localparam 
        CONV    = 4'd 0,
        DENSE   = 4'd 1,
        MIXED    = 4'd 2;

    // State Param
    localparam
        G_START   = 3'd 0,
        G_MAC_ENB = 3'd 1,
        G_ACC_ENB = 3'd 2,
        G_WAIT    = 3'd 3,
        G_FINISH  = 3'd 4;

/*  ALL Signal Definition */
    // State Define 
    reg [ 2:0] COMPS_gstate;

    // State Counter
    reg        is_first_cycle;

/* Internal Sigs */
    wire COMPS_reg_enb;
    assign COMPS_reg_enb = (RDATA_rdy || RDATA_fin) && COMPS_rdy && (POOL_rdy || POOL_start) && (WBACK_rdy || WBACK_start) & enb;

/* FSM Transition */
    always @(posedge clk) begin
        if (!resetn) begin
            COMPS_gstate <= G_START;
            is_first_cycle <= 0;
        end 
        else if (enb) begin
            case (cfg_layer_typ)
/* CONVOLUTIONAL LAYER */
// Kernel-Based Computation FSM
                CONV: begin
                    case (COMPS_gstate)
                        G_START: begin
                            if ((RDATA_rdy || RDATA_fin) && WBACK_start && POOL_start) begin
                                COMPS_gstate <= G_MAC_ENB;
                                is_first_cycle <= 1;
                            end
                        end

                        G_MAC_ENB: begin
                            if (pu_matrix_rdy) 
                                COMPS_gstate <= G_ACC_ENB;
                            is_first_cycle <= 0;
                        end

                        G_ACC_ENB: begin
                            COMPS_gstate <= G_WAIT;
                            is_first_cycle <= 0;
                        end

                        G_WAIT: begin
                            if ((RDATA_rdy || RDATA_fin) && COMPS_rdy && (POOL_rdy || POOL_start) && (WBACK_rdy || WBACK_start)) begin
                                if (RDATA_fin) 
                                    COMPS_gstate <= G_FINISH;
                                else begin
                                    COMPS_gstate <= G_MAC_ENB;
                                    is_first_cycle <= 1;
                                end
                            end
                        end

                        G_FINISH: begin

                        end
                    endcase
                end

/*** FULLY-CONNECTED LAYER ***/
// Input-Based Computation FSM
                DENSE:  begin
                    case (COMPS_gstate)
                        G_START: begin
                            if ((RDATA_rdy || RDATA_fin) && WBACK_start && POOL_start) begin
                                COMPS_gstate <= G_MAC_ENB;
                                is_first_cycle <= 1;
                            end
                        end

                        G_MAC_ENB: begin
                            if (pu_matrix_rdy) 
                                COMPS_gstate <= G_ACC_ENB;
                            is_first_cycle <= 0;
                        end

                        G_ACC_ENB: begin
                            COMPS_gstate <= G_WAIT;
                            is_first_cycle <= 0;
                        end

                        G_WAIT: begin
                            if ((RDATA_rdy || RDATA_fin) && COMPS_rdy && (POOL_rdy || POOL_start) && (WBACK_rdy || WBACK_start)) begin
                                if (RDATA_fin) 
                                    COMPS_gstate <= G_FINISH;
                                else begin
                                    COMPS_gstate <= G_MAC_ENB;
                                    is_first_cycle <= 1;
                                end
                            end
                        end

                        G_FINISH: begin

                        end
                    endcase
                end
/*****************************/

/*** MIXED LAYER ***/
// No-Comp Computation FSM
                MIXED: begin
                    case (COMPS_gstate)
                        G_START: begin
                            if ((RDATA_rdy || RDATA_fin) && WBACK_start && POOL_start) begin
                                COMPS_gstate <= G_MAC_ENB;
                                is_first_cycle <= 1;
                            end
                        end

                        G_MAC_ENB: begin
                            if (pu_matrix_rdy) 
                                COMPS_gstate <= G_ACC_ENB;
                            is_first_cycle <= 0;
                        end

                        G_ACC_ENB: begin
                            COMPS_gstate <= G_WAIT;
                            is_first_cycle <= 0;
                        end

                        G_WAIT: begin
                            if ((RDATA_rdy || RDATA_fin) && COMPS_rdy && (POOL_rdy || POOL_start) && (WBACK_rdy || WBACK_start)) begin
                                if (RDATA_fin) 
                                    COMPS_gstate <= G_FINISH;
                                else begin
                                    COMPS_gstate <= G_MAC_ENB;
                                    is_first_cycle <= 1;
                                end
                            end
                        end

                        G_FINISH: begin

                        end
                    endcase
                end
/*********************/
            endcase
        end
    end
    
    /* FSM Behaviors */
    always @(*) begin
        pu_enb = 0;

        acc_matrix_enb = 0;
        acc_matrix_bps_write = 0;
        acc_matrix_inter_sum_write = 0;

        COMPS_fin = 0;
        COMPS_rdy = 0;
        COMPS_start = 0;

        case (cfg_layer_typ)

/* CONVOLUTIONAL LAYER */
// Kernel-Based Computation FSM
            CONV: begin
                case (COMPS_gstate)
                    G_START: begin
                        COMPS_start = 1;
                    end

                    G_MAC_ENB: begin
                        pu_enb = 9'b 111_111_111;
                        if (is_first_cycle) begin
                            acc_matrix_enb = 1;
                            acc_matrix_bps_write = 1; 
                        end
                    end

                    G_ACC_ENB: begin
                        acc_matrix_enb = 1;
                        acc_matrix_inter_sum_write = 1;
                    end

                    G_WAIT: begin
                        COMPS_rdy = 1;
                    end

                    G_FINISH: begin
                        COMPS_fin = 1;
                    end
                endcase
            end

/*** FULLY-CONNECTED LAYER ***/
// Input-Based Computation FSM
            DENSE: begin
                case (COMPS_gstate)
                    G_START: begin
                        COMPS_start = 1;
                    end

                    G_MAC_ENB: begin
                        pu_enb = 9'b 000_000_111;
                        if (is_first_cycle) begin
                            acc_matrix_enb = 1;
                            acc_matrix_bps_write = 1; 
                        end
                    end

                    G_ACC_ENB: begin
                        acc_matrix_enb = 1;
                        acc_matrix_inter_sum_write = 1;
                    end

                    G_WAIT: begin
                        COMPS_rdy = 1;
                    end

                    G_FINISH: begin
                        COMPS_fin = 1;
                    end
                endcase
            end
/*****************************/

/*** MIXED LAYER ***/
// No-Comp Computation FSM
            MIXED: begin
                case (COMPS_gstate)
                    G_START: begin
                        COMPS_start = 1;
                    end

                    G_MAC_ENB: begin
                        pu_enb = 9'b 111_111_111;
                        if (is_first_cycle) begin
                            acc_matrix_enb = 1;
                            acc_matrix_bps_write = 1; 
                        end
                    end

                    G_ACC_ENB: begin
                        acc_matrix_enb = 1;
                        acc_matrix_inter_sum_write = 1;
                    end

                    G_WAIT: begin
                        COMPS_rdy = 1;
                    end

                    G_FINISH: begin
                        COMPS_fin = 1;
                    end
                endcase
            end
/*********************/
        endcase
    end

    /* Pipeline Flop */
    always @(posedge clk) begin
        if (!resetn) begin
            COMPS_is_out_fin    <= 0;
            COMPS_ps_addr       <= 0;
            COMPS_o_addr        <= 0;
            COMPS_o_quant_sel   <= 0;
        end 
        else if (COMPS_reg_enb) begin
            COMPS_is_out_fin    <= RDATA_is_out_fin;
            COMPS_ps_addr       <= RDATA_ps_addr;
            COMPS_o_addr        <= RDATA_o_addr;
            COMPS_o_quant_sel   <= RDATA_o_quant_sel;
        end
    end
endmodule