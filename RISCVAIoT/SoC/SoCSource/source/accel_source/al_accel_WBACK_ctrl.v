module al_accel_WBACK_ctrl (
/* Config Sigs */
    // Layer Info
    input [ 3:0]  cfg_layer_typ,

    // Pre-Cal Config Signals
    input [15:0]  output2D_size, // = ofm_widht * ofm_height

/* Output Control Sigs */
    // SoC Write Data Ctrl
    output reg [31:0]   mem_waddr,
    output reg [ 3:0]   mem_wstrb,
    output reg          mem_wenb_0,
    output reg          mem_wenb_1,
    output reg          mem_wenb_2,

    // Element-Wise Unit Ctrl
    output reg [ 2:0]   quant_act_func_enb,

    // Output Buffer Ctrl
    output reg [ 2:0]   obuf_enb,
    output reg [ 2:0]   obuf_ld_wrn,

    // Pipeline Stage Ctrl
    output reg          WBACK_fin,
    output reg          WBACK_rdy,
    output reg          WBACK_start,
    output              WBACK_is_out_fin,
    output     [31:0]   WBACK_ps_addr,    
    output     [31:0]   WBACK_o_addr,
    output     [ 3:0]   WBACK_o_quant_sel,

/* Feedback Control Sigs */
    // SoC Sig
    input        mem_write_ready,

    // Element-Wise Unit Ctrl
    input [ 2:0] quant_act_func_rdy,

    // RDATA Controller
    input        RDATA_rdy,
    input        RDATA_fin,
    input        RDATA_is_out_fin,
    input [31:0] RDATA_o_addr,

    // COMPS Controller
    input        COMPS_fin,
    input        COMPS_rdy, 
    input        COMPS_start,
    input        COMPS_is_out_fin,
    input [31:0] COMPS_o_addr,
    input [31:0] COMPS_ps_addr,
    input [ 3:0] COMPS_o_quant_sel,

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
        POOL    = 4'd 2;

    // State Param
    localparam
        G_START         = 3'd 0,
        G_QUANT_OR_LOAD = 3'd 1,
        G_LOAD          = 3'd 2,
        G_WRITE         = 3'd 3,
        G_WAIT          = 3'd 4,
        G_FINISH        = 3'd 5;

/*  ALL Signal Definition */
    // State Define 
    reg [ 2:0] WBACK_gstate;

    assign WBACK_is_out_fin     = (cfg_layer_typ == POOL) ? RDATA_is_out_fin : COMPS_is_out_fin ;
    assign WBACK_o_addr         = (cfg_layer_typ == POOL) ? RDATA_o_addr     : COMPS_o_addr     ;
    assign WBACK_o_quant_sel    = COMPS_o_quant_sel;
    assign WBACK_ps_addr        = COMPS_ps_addr;

    // State Counter
    reg [ 1:0] state_cnt;

    reg write_mem_state;

/* Internal Sigs */
    wire   WBACK_reg_enb;
    assign WBACK_reg_enb = (RDATA_rdy || RDATA_fin) && (COMPS_rdy || COMPS_fin) && WBACK_rdy & enb;

    wire [31: 0] o_addr_0, o_addr_1, o_addr_2;
    assign o_addr_0 = WBACK_o_addr;
    assign o_addr_1 = o_addr_0 + output2D_size;
    assign o_addr_2 = o_addr_1 + output2D_size;

    wire [31: 0] ps_addr_0, ps_addr_1, ps_addr_2;
    assign ps_addr_0 = WBACK_ps_addr;
    assign ps_addr_1[ 1:0] = ps_addr_0[ 1:0];
    assign ps_addr_1[31:2] = ps_addr_0[31:2] + output2D_size;
    assign ps_addr_2[ 1:0] = ps_addr_1[ 1:0];
    assign ps_addr_2[31:2] = ps_addr_1[31:2] + output2D_size; 

    wire quant_rdy;
    assign quant_rdy = quant_act_func_rdy[0] | quant_act_func_rdy[1] | quant_act_func_rdy[2];

    reg [1:0] addr_strb;
    reg [3:0] out_wstrb;
    always @(*) begin
        case (addr_strb)
            2'd 0: out_wstrb = 4'b 0001;
            2'd 1: out_wstrb = 4'b 0010;
            2'd 2: out_wstrb = 4'b 0100;
            2'd 3: out_wstrb = 4'b 1000;
        endcase
    end

/* FSM Transition */
    always @(posedge clk) begin
        if (!resetn) begin
            WBACK_gstate <= G_START;

            state_cnt <= 0;
            write_mem_state <= 0;
        end 
        else if (enb) begin
            case (cfg_layer_typ)
            
/* CONVOLUTIONAL LAYER */
// Kernel-Based Computation FSM
                CONV: begin
                    case (WBACK_gstate)
                        G_START: begin
                            if ((RDATA_rdy || RDATA_fin) && (COMPS_rdy || COMPS_fin)) begin
                                WBACK_gstate <= G_QUANT_OR_LOAD;
                            end
                        end

                        G_QUANT_OR_LOAD: begin
                            if (WBACK_is_out_fin) begin
                                if (quant_rdy)
                                    WBACK_gstate <= G_LOAD;
                            end else begin
                                WBACK_gstate <= G_WRITE;
                            end
                        end

                        G_LOAD: begin
                            WBACK_gstate <= G_WRITE;
                        end

                        G_WRITE: begin
                            // if (state_cnt >= 3 - 1) 
                            //     state_cnt <= 0;
                            // else
                            //     state_cnt <= state_cnt + 1;

                            // if (state_cnt >= 3 - 1) begin
                            //     WBACK_gstate <= G_WAIT;
                            // end

                            if (state_cnt >= 3 - 1 && write_mem_state) begin
                                if (mem_write_ready)
                                    WBACK_gstate <= G_WAIT;
                            end

                            if (write_mem_state) begin
                                if (mem_write_ready) begin
                                     if (state_cnt >= 3 - 1) 
                                        state_cnt <= 0;
                                    else
                                        state_cnt <= state_cnt + 1;
                                    write_mem_state <= ~write_mem_state;
                                end
                            end else begin
                                write_mem_state <= ~write_mem_state;
                            end
                        end

                        G_WAIT: begin
                            if ((RDATA_rdy || RDATA_fin) && (COMPS_rdy || COMPS_fin) && WBACK_rdy) begin
                                if (COMPS_fin) 
                                    WBACK_gstate <= G_FINISH;
                                else begin
                                    WBACK_gstate <= G_QUANT_OR_LOAD;
                                end
                            end
                        end

                        G_FINISH: begin
                            
                        end
                    endcase
                end

/*** FULLY-CONNECTED LAYER ***/
// Input-Based Computation FSM
                DENSE: begin
                    case (WBACK_gstate)
                        G_START: begin
                            if ((RDATA_rdy || RDATA_fin) && (COMPS_rdy || COMPS_fin)) begin
                                WBACK_gstate <= G_QUANT_OR_LOAD;
                            end
                        end

                        G_QUANT_OR_LOAD: begin
                            if (WBACK_is_out_fin) begin
                                if (quant_rdy)
                                    WBACK_gstate <= G_LOAD;
                            end else begin
                                WBACK_gstate <= G_WRITE;
                            end
                        end

                        G_LOAD: begin
                            WBACK_gstate <= G_WRITE;
                        end

                        G_WRITE: begin
                            // if (state_cnt >= 3 - 1) 
                            //     state_cnt <= 0;
                            // else
                            //     state_cnt <= state_cnt + 1;

                            // if (state_cnt >= 3 - 1) begin
                            //     WBACK_gstate <= G_WAIT;
                            // end

                            if (state_cnt >= 3 - 1 && write_mem_state) begin
                                if (mem_write_ready)
                                    WBACK_gstate <= G_WAIT;
                            end

                            if (write_mem_state) begin
                                if (mem_write_ready) begin
                                     if (state_cnt >= 3 - 1) 
                                        state_cnt <= 0;
                                    else
                                        state_cnt <= state_cnt + 1;
                                    write_mem_state <= ~write_mem_state;
                                end
                            end else begin
                                write_mem_state <= ~write_mem_state;
                            end
                        end

                        G_WAIT: begin
                            if ((RDATA_rdy || RDATA_fin) && (COMPS_rdy || COMPS_fin) && WBACK_rdy) begin
                                if (COMPS_fin) 
                                    WBACK_gstate <= G_FINISH;
                                else begin
                                    WBACK_gstate <= G_QUANT_OR_LOAD;
                                end
                            end
                        end

                        G_FINISH: begin
                            
                        end
                    endcase
                end

/*****************************/

/*** POOLING LAYER ***/
// No-Comp Computation FSM
                POOL: begin
                    case (WBACK_gstate)
                        G_START: begin
                            if (RDATA_rdy || RDATA_fin) begin
                                WBACK_gstate <= G_LOAD;
                            end
                        end

                        G_LOAD: begin
                            WBACK_gstate <= G_WRITE;
                        end

                        G_WRITE: begin
                            // WBACK_gstate <= G_WAIT;

                            if (write_mem_state) begin
                                if (mem_write_ready)
                                    WBACK_gstate <= G_WAIT;
                            end

                            if (write_mem_state) begin
                                if (mem_write_ready) begin
                                    write_mem_state <= ~write_mem_state;
                                end
                            end else begin
                                write_mem_state <= ~write_mem_state;
                            end
                        end

                        G_WAIT: begin
                            if ((RDATA_rdy || RDATA_fin) && WBACK_rdy) begin
                                if (RDATA_fin) 
                                    WBACK_gstate <= G_FINISH;
                                else begin
                                    WBACK_gstate <= G_LOAD;
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
        mem_waddr = 0;
        mem_wenb_0 = 0;
        mem_wenb_1 = 0;
        mem_wenb_2 = 0;
        mem_wstrb = 0;

        quant_act_func_enb = 0;

        obuf_enb    = 0;
        obuf_ld_wrn = 0;

        WBACK_start = 0;
        WBACK_fin = 0;
        WBACK_rdy = 0;

        addr_strb = 0;
        case (cfg_layer_typ)

/* CONVOLUTIONAL LAYER */
// Kernel-Based Computation FSM
            CONV: begin
                case (WBACK_gstate)
                    G_START: begin
                        WBACK_start = 1;
                    end

                    G_QUANT_OR_LOAD: begin
                        if (WBACK_is_out_fin) begin
                            quant_act_func_enb = 3'b 111;
                        end else begin
                            obuf_enb    = 3'b 111;
                            obuf_ld_wrn = 3'b 111;
                        end
                    end

                    G_LOAD: begin
                        obuf_enb    = 3'b 111;
                        obuf_ld_wrn = 3'b 111;
                    end

                    G_WRITE: begin
                        if (WBACK_is_out_fin) begin
                            mem_wstrb = out_wstrb;
                            case (state_cnt)
                                2'd 0: begin
                                    mem_waddr = o_addr_0;
                                    addr_strb = o_addr_0[1:0];
                                    mem_wenb_0 = 1;
                                end

                                2'd 1: begin
                                    mem_waddr = o_addr_1;
                                    addr_strb = o_addr_1[1:0];
                                    mem_wenb_1 = 1;
                                end

                                2'd 2: begin
                                    mem_waddr = o_addr_2;
                                    addr_strb = o_addr_2[1:0];
                                    mem_wenb_2 = 1;
                                end
                            endcase
                        end
                        else begin 
                            mem_wstrb = 4'b 1111;
                            case (state_cnt)
                                2'd 0: begin
                                    mem_waddr = ps_addr_0;
                                    mem_wenb_0 = 1;
                                end
                                2'd 1: begin
                                    mem_waddr = ps_addr_1;
                                    mem_wenb_1 = 1;
                                end

                                2'd 2: begin
                                    mem_waddr = ps_addr_2;
                                    mem_wenb_2 = 1;
                                end
                            endcase
                        end

                        if (write_mem_state) begin
                            if (mem_write_ready) begin
                                mem_wenb_0 = 0;
                                mem_wenb_1 = 0;
                                mem_wenb_2 = 0;
                            end
                        end 
                    end

                    G_WAIT: begin
                        WBACK_rdy = 1;
                    end

                    G_FINISH: begin
                        WBACK_fin = 1;
                    end
                endcase
            end

/*** FULLY-CONNECTED LAYER ***/
// Input-Based Computation FSM
            DENSE: begin
                case (WBACK_gstate)
                    G_START: begin
                        WBACK_start = 1;
                    end

                    G_QUANT_OR_LOAD: begin
                        if (WBACK_is_out_fin) begin
                            quant_act_func_enb = 3'b 111;
                        end else begin
                            obuf_enb    = 3'b 111;
                            obuf_ld_wrn = 3'b 111;
                        end
                    end

                    G_LOAD: begin
                        obuf_enb    = 3'b 111;
                        obuf_ld_wrn = 3'b 111;
                    end

                    G_WRITE: begin
                        if (WBACK_is_out_fin) begin
                            mem_wstrb = out_wstrb;
                            case (state_cnt)
                                2'd 0: begin
                                    mem_waddr = o_addr_0;
                                    addr_strb = o_addr_0[1:0];
                                    mem_wenb_0 = 1;
                                end

                                2'd 1: begin
                                    mem_waddr = o_addr_0 + 1;
                                    addr_strb = o_addr_0[1:0] + 2'b 01;
                                    mem_wenb_1 = 1;
                                end

                                2'd 2: begin
                                    mem_waddr = o_addr_0 + 2;
                                    addr_strb = o_addr_0[1:0] + 2'b 10;
                                    mem_wenb_2 = 1;
                                end
                            endcase
                        end
                        else begin 
                            mem_wstrb = 4'b 1111;
                            case (state_cnt)
                                2'd 0: begin
                                    mem_waddr = ps_addr_0;
                                    mem_wenb_0 = 1;
                                end
                                2'd 1: begin
                                    mem_waddr = ps_addr_0 + 4;
                                    mem_wenb_1 = 1;
                                end

                                2'd 2: begin
                                    mem_waddr = ps_addr_0 + 8;
                                    mem_wenb_2 = 1;
                                end
                            endcase
                        end

                        if (write_mem_state) begin
                            if (mem_write_ready) begin
                                mem_wenb_0 = 0;
                                mem_wenb_1 = 0;
                                mem_wenb_2 = 0;
                            end
                        end 
                    end

                    G_WAIT: begin
                        WBACK_rdy = 1;
                    end

                    G_FINISH: begin
                        WBACK_fin = 1;
                    end
                endcase
            end
/*****************************/

/*** POOLING LAYER ***/
// No-Comp Computation FSM
            POOL: begin
                case (WBACK_gstate)
                    G_START: begin
                        WBACK_start = 1;
                    end

                    G_LOAD: begin
                        obuf_enb    = 3'b 001;
                        obuf_ld_wrn = 3'b 001;
                    end

                    G_WRITE: begin
                        mem_wstrb = out_wstrb;

                        mem_waddr = o_addr_0;
                        addr_strb = o_addr_0[1:0];
                        mem_wenb_0 = 1;

                        if (write_mem_state) begin
                            if (mem_write_ready) begin
                                mem_wenb_0 = 0;
                            end
                        end 
                    end

                    G_WAIT: begin
                        WBACK_rdy = 1;
                    end

                    G_FINISH: begin
                        WBACK_fin = 1;
                    end
                endcase
            end
/*********************/
        endcase
    end
endmodule
