module fs_accel_POOL_ctrl (
    /* Config Sigs */
    input [3:0]         cfg_layer_typ,
    input [15:0]        ofm_width,
    input [15:0]        ofm_pool_width,
    input [15:0]        ofm_pool_height,
    input [31:0]        output2D_pool_size,
    input [31:0]        o_base_addr,

    /* Ouput Control Sigs */
    // Element-Wise Unit Ctrl
    output reg  [2:0]   quant_act_func_enb,
    output      [3:0]   sel_demux,
    output reg  [3:0]   sel_mux,
    output reg          mpbuf_ld_wrn,
    output reg          buf_enb,
    output reg          cp_enb,
    output reg          resetn_pool,
    output reg          pool_ld_wrn,
    output reg          pool_enb,


    // Pipeline Stage Ctrl
    output reg          POOL_fin,
    output reg          POOL_rdy,
    output reg          POOL_start,
    output              POOL_is_out_fin,
    output reg [31:0]   POOL_o_addr,
    output reg [31:0]   POOL_ps_addr,
    output  [3:0]       POOL_o_quant_sel,
    output              POOL_ignore,

    /* Feedback Control Sigs */
    // Element-Wise Unit Ctrl
    input [2:0]         quant_act_func_rdy,

    // RDATA Controller
    input               RDATA_rdy,
    input               RDATA_fin,
    input               RDATA_is_out_fin,
    input [31:0]        RDATA_o_addr,

    // COMPS Controller
    input               COMPS_fin,
    input               COMPS_rdy, 
    input               COMPS_start,
    input               COMPS_is_out_fin,
    input [31:0]        COMPS_o_addr,
    input [31:0]        COMPS_ps_addr,
    input [ 3:0]        COMPS_o_quant_sel,

    // WBACK Controller
    input               WBACK_start,
    input               WBACK_rdy,

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
        MIXED   = 4'd 2;

    localparam
        UP     = 1'b0,
        DOWN   = 1'b1;

    // State Param
    localparam
        G_START         = 3'd 0,
        G_QUANT         = 3'd 7,
        G_LOAD_OR_QUANT = 3'd 1,
        G_LOAD          = 3'd 3,
        G_OPERATE       = 3'd 4,
        G_WAIT          = 3'd 5,
        G_FINISH        = 3'd 6;  
    
    /*  ALL Signal Definition */
    // State Define 
    reg [ 2:0] POOL_gstate;

    /* Internal Sigs */ 
    wire quant_rdy;
    assign quant_rdy = quant_act_func_rdy[0] | quant_act_func_rdy[1] | quant_act_func_rdy[2];

    wire POOL_reg_enb;
    assign POOL_reg_enb = (RDATA_rdy || RDATA_fin) && (COMPS_rdy || COMPS_fin) && POOL_rdy && (WBACK_rdy || WBACK_start) & enb;
 
    assign POOL_is_out_fin = COMPS_is_out_fin;
    assign POOL_o_quant_sel = COMPS_o_quant_sel;

    /* Select the cp Block */
    reg [3:0] cp_block;
    reg is_first_cycle;
    reg [2:0] state_cnt;
    reg [3:0] height_cnt;
    reg ignore_bit_col;
    reg ignore_bit_row;
    reg direction;  // 0: increase || 1: decrease

    assign POOL_ignore = ignore_bit_col | ignore_bit_row;

    /* Output Address */
    wire [3:0] cp_block_size;
    wire [31:0] o_addr;
    reg  [31:0] start_pool_line_addr;
    reg  [31:0] start_pool_chanel_addr;

    assign o_addr = start_pool_line_addr + cp_block;

    assign cp_block_size = ofm_width >> 1;
    assign sel_demux = cp_block;
 
    /* FSM Transition */
    always @(posedge clk) begin
        if(!resetn) begin
            is_first_cycle <= 0  ;
            cp_block <= 0;
            resetn_pool <= 1;
            direction <= 0;
            state_cnt <= 0;
            ignore_bit_col <= 0; 
            ignore_bit_row <= 0;
            height_cnt <= 0;
            POOL_gstate <= G_START;
        end else if(enb) begin
            case (cfg_layer_typ)
/* CONVOLUTIONAL LAYER */
// Kernel-Based Computation FSM
            CONV: begin
                case(POOL_gstate)
                    G_START: begin
                        if((RDATA_rdy || RDATA_fin) && (COMPS_rdy || COMPS_fin) && (WBACK_start || WBACK_rdy)) begin
                                POOL_gstate <= G_LOAD_OR_QUANT;
                        end
                    end
                    G_LOAD_OR_QUANT: begin
                        if(POOL_is_out_fin) begin
                            if(quant_rdy) begin
                                POOL_gstate <= G_WAIT;
                            end
                        end else begin
                            POOL_gstate <= G_WAIT;
                        end
                    end

                    G_WAIT: begin
                        if((RDATA_rdy || RDATA_fin) && (COMPS_rdy || COMPS_fin) && (WBACK_start || WBACK_rdy)) begin
                            if(COMPS_fin) begin
                                POOL_gstate <= G_FINISH;
                            end else begin
                                POOL_gstate <= G_LOAD_OR_QUANT;
                            end
                        end
                    end

                    G_FINISH: begin
                    
                    end 
                endcase
            end 
/*****************************/

/*** FULLY-CONNECTED LAYER ***/
// Input-Based Computation FSM
            DENSE: begin
                case(POOL_gstate)
                    G_START: begin
                        if(RDATA_is_out_fin) begin
                            if((RDATA_rdy || RDATA_fin) && (COMPS_rdy || COMPS_fin) && (WBACK_start || WBACK_rdy)) begin
                                POOL_gstate <= G_LOAD_OR_QUANT;
                            end
                        end
                    end

                    G_LOAD_OR_QUANT: begin
                        if(quant_rdy) begin
                                POOL_gstate <= G_WAIT;
                            end  
                    end

                    G_WAIT: begin
                         if(RDATA_is_out_fin) begin
                            if((RDATA_rdy || RDATA_fin) && (COMPS_rdy || COMPS_fin) && (WBACK_start || WBACK_rdy)) begin
                                if(COMPS_fin) begin
                                    POOL_gstate <= G_FINISH;
                                end else begin
                                    POOL_gstate <= G_LOAD_OR_QUANT;
                                end
                            end
                        end
                    end

                    G_FINISH: begin
                    
                    end 
                endcase
            end 
/*****************************/ 

/*** MIXED LAYER ***/
            MIXED: begin
                case(POOL_gstate)
                    G_START: begin
                        if((RDATA_rdy || RDATA_fin) && (COMPS_rdy || COMPS_fin) && (WBACK_start || WBACK_rdy)) begin
                            POOL_gstate <= G_LOAD_OR_QUANT;
                            is_first_cycle <= 1;
                            start_pool_chanel_addr <= o_base_addr;
                            start_pool_line_addr <= o_base_addr;
                        end
                    end

                    G_LOAD_OR_QUANT: begin
                        if(!resetn_pool) begin
                            resetn_pool <= 1;
                        end
                        if(POOL_is_out_fin) begin
                            if(quant_rdy) begin 
                                if(ignore_bit_row == 1'b1 || ignore_bit_col == 1'b1) begin
                                    POOL_gstate <= G_WAIT;
                                end else begin
                                    POOL_gstate <= G_LOAD;
                                end
                            end 
                        end else begin
                            POOL_gstate <= G_WAIT;
                        end
                        
                    end

                    G_LOAD: begin
                        if(cp_block == 0) begin
                            state_cnt <= state_cnt + 1;
                        end
                        POOL_gstate <= G_OPERATE;
                    end

                    G_OPERATE: begin  
                        POOL_gstate <= G_WAIT;
                    end

                    G_WAIT: begin
                            if((RDATA_rdy || RDATA_fin) && (COMPS_rdy || COMPS_fin) && (WBACK_start || WBACK_rdy)) begin
                                if(COMPS_fin) begin
                                    POOL_gstate <= G_FINISH;
                                end else begin
                                    POOL_gstate <= G_LOAD_OR_QUANT;
                                end

                                // End of two row
                                if(POOL_is_out_fin) begin
                                    if(state_cnt == 3'b100) begin
                                        state_cnt <= 0;
                                        if(resetn_pool) begin
                                            resetn_pool <= 1'b0;
                                        end
                                        if(height_cnt == cp_block_size - 1) begin
                                            height_cnt <= 1'b0;
                                            if(ofm_width[0] == 1'b1) begin
                                                ignore_bit_row <= 1'b1;
                                            end 
                                            start_pool_line_addr <= start_pool_chanel_addr + output2D_pool_size + output2D_pool_size + output2D_pool_size;
                                            start_pool_chanel_addr <= start_pool_chanel_addr + output2D_pool_size + output2D_pool_size + output2D_pool_size;
                                        end else begin
                                            height_cnt <= height_cnt + 1;
                                            start_pool_line_addr <= start_pool_line_addr + ofm_pool_width;
                                        end
                                    end
                                    
                                    if (is_first_cycle) begin
                                        is_first_cycle <= 0;
                                    end else begin
                                        // Update cp-block
                                            if (!direction) begin
                                                if (cp_block == (cp_block_size - 1)) begin
                                                    if(ofm_width[0] == 1'b1 && ignore_bit_col == 1'b0) begin
                                                        ignore_bit_col <= 1'b1;
                                                    end else begin
                                                        ignore_bit_col <= 1'b0;
                                                        direction <= 1; 
                                                    end
                                                end else begin
                                                    cp_block <= cp_block + 1;
                                                end
                                            end else begin
                                                if (cp_block == 0) begin
                                                    direction <= 0; 
                                                end else begin
                                                    cp_block <= cp_block - 1; 
                                                end
                                            end
                                            is_first_cycle <= 1;
                                    end
                                end
                            end
                            
                            // For Odd Size
                            if(ignore_bit_col == 1'b1 && ignore_bit_row == 1'b1) begin
                                cp_block <= 0;
                                is_first_cycle <= 1;
                                direction <= 0;
                                state_cnt <= 0;
                                ignore_bit_col <= 0; 
                                ignore_bit_row <= 0;
                                height_cnt <= 0;
                            end 
                        end

                    G_FINISH: begin
                    
                    end 
                endcase
            end 
            endcase
        end
    end

    /* FSM Behaviors */
    always @(*) begin
        // Pipeline output
        POOL_start = 1'b0;
        POOL_fin = 1'b0;
        POOL_rdy = 1'b0;

        // For Quantize
        quant_act_func_enb = 1'b0;
        
        // For Pooling
        mpbuf_ld_wrn = 1'b0;
        cp_enb = 1'b0;
        buf_enb = 1'b0;
        pool_ld_wrn = 1'b0;
        case(cfg_layer_typ)

/* CONVOLUTIONAL LAYER */
// Kernel-Based Computation FSM
            CONV: begin
                case(POOL_gstate)
                    G_START: begin
                        POOL_start = 1;
                    end

                    G_LOAD_OR_QUANT: begin
                        if(POOL_is_out_fin) begin
                            quant_act_func_enb = 3'b111;
                        end else begin
                            pool_ld_wrn = 1'b1;
                            pool_enb = 1'b1;
                        end 
                    end

                    G_WAIT: begin
                        POOL_rdy = 1;
                    end

                    G_FINISH: begin
                        POOL_fin = 1;
                    end
                endcase
            end

/*** FULLY-CONNECTED LAYER ***/
// Input-Based Computation FSM
            DENSE: begin
                case(POOL_gstate)
                    G_START: begin
                        POOL_start = 1;
                    end

                    G_LOAD_OR_QUANT: begin
                        quant_act_func_enb = 3'b111;
                    end

                    G_WAIT: begin
                        POOL_rdy = 1;
                    end

                    G_FINISH: begin
                        POOL_fin = 1;
                    end
                endcase
            end

/*** MIXED LAYER ***/
       MIXED: begin
                case(POOL_gstate)
                    G_START: begin
                        POOL_start = 1;
                    end

                    G_LOAD_OR_QUANT: begin
                        if(POOL_is_out_fin) begin
                            quant_act_func_enb = 3'b111;
                        end else begin
                            pool_ld_wrn = 1'b1;
                            pool_enb = 1'b1;
                        end
                        
                    end

                    G_LOAD: begin
                        mpbuf_ld_wrn = 1;
                        buf_enb = 1;
                    end

                    G_OPERATE: begin
                        cp_enb = 1;
                    end

                    G_WAIT: begin
                        POOL_rdy = 1;
                    end

                    G_FINISH: begin
                        POOL_fin = 1;
                    end
                endcase
            end
        endcase
    end

    /* Pipeline Flop */
    always @(posedge clk) begin
        if (!resetn) begin
            POOL_o_addr        <= 1'b0;
            POOL_ps_addr       <= 1'b0;
            sel_mux            <= 4'b1111;
        end 
        else if (POOL_reg_enb) begin
            sel_mux        <= cp_block;
            POOL_o_addr    <= (cfg_layer_typ == MIXED && POOL_is_out_fin) ? o_addr : COMPS_o_addr;
            POOL_ps_addr   <= COMPS_ps_addr;
        end
    end

endmodule