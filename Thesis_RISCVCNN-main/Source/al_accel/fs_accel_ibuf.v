module fs_accel_ibuf (
    // Config Sigs
    input   [ 3:0] cfg_layer_typ,

    // Data Sigs
    input   [31:0] ibuf_di,
    input   [ 7:0] ibuf_init,

    output reg [ 7:0] ibuf_do_0,
    output reg [ 7:0] ibuf_do_1,
    output reg [ 7:0] ibuf_do_2,

    // Feedback Sigs
    output reg [ 2:0] ibuf_valid,
    output reg [ 2:0] ibuf_nxt_valid,

    // Ctrl Sigs
    input          ibuf_di_revert,
    input          ibuf_do_revert,
    input          ibuf_ld_wrn,
    input   [ 1:0] ibuf_bank_sel,

    input   [ 2:0] ibuf_conv_wstrb,
    input          ibuf_conv_fi_load,
    input          ibuf_conv_se_load,

    input   [ 1:0] ibuf_dens_wstrb,
    // Mandatory Sigs
    input   enb,
    input   clk,
    input   resetn
);
    // Layer Param
    localparam 
        CONV    = 4'd 0,
        DENSE   = 4'd 1,
        MIXED   = 4'd 2;

    wire [31:0] ibuf_cor_di;
    assign ibuf_cor_di = ibuf_di_revert ? {ibuf_di[7:0], ibuf_di[15:8], ibuf_di[23:16], ibuf_di[31:24]} : ibuf_di;

// Logic of Input Buffer

    reg [6*8 - 1:0] buf_b0_data;
    reg [6*8 - 1:0] buf_b1_data;
    reg [6*8 - 1:0] buf_b2_data;
    reg [6   - 1:0] buf_b0_valid;
    reg [6   - 1:0] buf_b1_valid;
    reg [6   - 1:0] buf_b2_valid;

    always @(posedge clk) begin
        if (!resetn) begin
            buf_b0_data <= 0;
            buf_b0_valid <= 0;

            buf_b1_data <= 0;
            buf_b1_valid <= 0;

            buf_b2_data <= 0;
            buf_b2_valid <= 0;
        end 
        else if (enb) begin
            if (ibuf_ld_wrn) begin
                case (cfg_layer_typ)
                CONV: begin
                    case (ibuf_bank_sel) 
                        2'd1: begin
                        case (ibuf_conv_wstrb)
                            3'd0: begin 
                                buf_b0_data [31: 0] <= ibuf_cor_di[31: 0];
                                buf_b0_valid[ 3: 0] <= 4'b1111;

                                buf_b0_data [47:32] <= {2{ibuf_init}};
                                buf_b0_valid[ 5: 4] <= 2'b00;
                            end

                            3'd1: begin
                                buf_b0_data [23: 0] <= ibuf_cor_di[31: 8];
                                buf_b0_valid[ 2: 0] <= 3'b111;

                                buf_b0_data [47:24] <= {3{ibuf_init}};
                                buf_b0_valid[ 5: 3] <= 3'b000;
                            end

                            3'd2: begin
                                buf_b0_data [15: 0] <= ibuf_cor_di[31:16];
                                buf_b0_valid[ 1: 0] <= 2'b11;

                                buf_b0_data [47:16] <= {4{ibuf_init}};
                                buf_b0_valid[ 5: 2] <= 4'b0000;
                            end

                            3'd3: begin
                                buf_b0_data [ 7: 0] <= ibuf_cor_di[31:24];
                                buf_b0_valid[ 0: 0] <= 1'b1;
                                
                                buf_b0_data [47: 8] <= {5{ibuf_init}};
                                buf_b0_valid[ 5: 1] <= 5'b00000;
                            end

                            3'd5: begin
                                buf_b0_data [47:16] <= ibuf_cor_di[31: 0];
                                buf_b0_valid[ 5: 2] <= 4'b1111;
                            end

                            3'd6: begin
                                buf_b0_data [39: 8] <= ibuf_cor_di[31: 0];
                                buf_b0_valid[ 4: 1] <= 4'b1111;
                            end
                        endcase
                        end

                        2'd2: begin
                        case (ibuf_conv_wstrb)
                            3'd0: begin 
                                buf_b1_data [31: 0] <= ibuf_cor_di[31: 0];
                                buf_b1_valid[ 3: 0] <= 4'b1111;

                                buf_b1_data [47:32] <= {2{ibuf_init}};
                                buf_b1_valid[ 5: 4] <= 2'b00;
                            end

                            3'd1: begin
                                buf_b1_data [23: 0] <= ibuf_cor_di[31: 8];
                                buf_b1_valid[ 2: 0] <= 3'b111;

                                buf_b1_data [47:24] <= {3{ibuf_init}};
                                buf_b1_valid[ 5: 3] <= 3'b000;
                            end

                            3'd2: begin
                                buf_b1_data [15: 0] <= ibuf_cor_di[31:16];
                                buf_b1_valid[ 1: 0] <= 2'b11;

                                buf_b1_data [47:16] <= {4{ibuf_init}};
                                buf_b1_valid[ 5: 2] <= 4'b0000;
                            end

                            3'd3: begin
                                buf_b1_data [ 7: 0] <= ibuf_cor_di[31:24];
                                buf_b1_valid[ 0: 0] <= 1'b1;

                                buf_b1_data [47: 8] <= {5{ibuf_init}};
                                buf_b1_valid[ 5: 1] <= 5'b00000;
                            end

                            3'd5: begin
                                buf_b1_data [47:16] <= ibuf_cor_di[31: 0];
                                buf_b1_valid[ 5: 2] <= 4'b1111;
                            end

                            3'd6: begin
                                buf_b1_data [39: 8] <= ibuf_cor_di[31: 0];
                                buf_b1_valid[ 4: 1] <= 4'b1111;
                            end
                        endcase
                        end

                        2'd3: begin
                        case (ibuf_conv_wstrb)
                            3'd0: begin 
                                buf_b2_data [31: 0] <= ibuf_cor_di[31: 0];
                                buf_b2_valid[ 3: 0] <= 4'b1111;

                                buf_b2_data [47:32] <= {2{ibuf_init}};
                                buf_b2_valid[ 5: 4] <= 2'b00;
                            end

                            3'd1: begin
                                buf_b2_data [23: 0] <= ibuf_cor_di[31: 8];
                                buf_b2_valid[ 2: 0] <= 3'b111;

                                buf_b2_data [47:24] <= {3{ibuf_init}};
                                buf_b2_valid[ 5: 3] <= 3'b000;
                            end

                            3'd2: begin
                                buf_b2_data [15: 0] <= ibuf_cor_di[31:16];
                                buf_b2_valid[ 1: 0] <= 2'b11;

                                buf_b2_data [47:16] <= {4{ibuf_init}};
                                buf_b2_valid[ 5: 2] <= 4'b0000;
                            end

                            3'd3: begin
                                buf_b2_data [ 7: 0] <= ibuf_cor_di[31:24];
                                buf_b2_valid[ 0: 0] <= 1'b1;

                                buf_b2_data [47: 8] <= {5{ibuf_init}};
                                buf_b2_valid[ 5: 1] <= 5'b00000;
                            end

                            3'd5: begin
                                buf_b2_data [47:16] <= ibuf_cor_di[31: 0];
                                buf_b2_valid[ 5: 2] <= 4'b1111;
                            end

                            3'd6: begin
                                buf_b2_data [39: 8] <= ibuf_cor_di[31: 0];
                                buf_b2_valid[ 4: 1] <= 4'b1111;
                            end
                        endcase
                        end
                    endcase
                end 

                DENSE: begin
                    case (ibuf_bank_sel)
                        2'd1: 
                        case (ibuf_dens_wstrb)
                            2'd 0: begin
                                buf_b0_data[23: 0] <= ibuf_cor_di[23: 0];
                                buf_b1_data[ 7: 0] <= ibuf_cor_di[31:24];
                            end

                            2'd 1: begin
                                buf_b0_data[23: 0] <= ibuf_cor_di[31: 8];
                            end

                            2'd 2: begin
                                buf_b0_data[15: 0] <= ibuf_cor_di[31:16];
                            end

                            2'd 3: begin
                                buf_b0_data[ 7: 0] <= ibuf_cor_di[31:24];
                            end
                        endcase

                        2'd2: 
                        case (ibuf_dens_wstrb)
                            2'd 0: begin
                                buf_b1_data[23 : 8] <= ibuf_cor_di[15: 0];
                                buf_b2_data[15 : 0] <= ibuf_cor_di[31:16];
                            end

                            2'd 1: begin
                                buf_b1_data[23 : 0] <= ibuf_cor_di[23: 0];
                                buf_b2_data[ 7 : 0] <= ibuf_cor_di[31:24];
                            end

                            2'd 2: begin
                                buf_b0_data[23 :16] <= ibuf_cor_di[ 7: 0];
                                buf_b1_data[23 : 0] <= ibuf_cor_di[31: 8];
                            end

                            2'd 3: begin
                                buf_b0_data[23 : 8] <= ibuf_cor_di[15: 0];
                                buf_b1_data[15 : 0] <= ibuf_cor_di[31:16];
                            end
                        endcase

                        2'd3: 
                        case (ibuf_dens_wstrb)
                            2'd 0: begin
                                buf_b2_data[23:16] <= ibuf_cor_di[ 7: 0];
                            end

                            2'd 1: begin
                                buf_b2_data[23: 8] <= ibuf_cor_di[15: 0];
                            end

                            2'd 2: begin
                                buf_b2_data[23: 0] <= ibuf_cor_di[23: 0];
                            end

                            2'd 3: begin
                                buf_b1_data[23:16] <= ibuf_cor_di[ 7: 0];
                                buf_b2_data[23: 0] <= ibuf_cor_di[31: 8];
                            end
                        endcase
                    endcase
                end

                MIXED: begin
                    case (ibuf_bank_sel) 
                        2'd1: begin
                        case (ibuf_conv_wstrb)
                            3'd0: begin 
                                buf_b0_data [31: 0] <= ibuf_cor_di[31: 0];
                                buf_b0_valid[ 3: 0] <= 4'b1111;

                                buf_b0_data [47:32] <= {2{ibuf_init}};
                                buf_b0_valid[ 5: 4] <= 2'b00;
                            end

                            3'd1: begin
                                buf_b0_data [23: 0] <= ibuf_cor_di[31: 8];
                                buf_b0_valid[ 2: 0] <= 3'b111;

                                buf_b0_data [47:24] <= {3{ibuf_init}};
                                buf_b0_valid[ 5: 3] <= 3'b000;
                            end

                            3'd2: begin
                                buf_b0_data [15: 0] <= ibuf_cor_di[31:16];
                                buf_b0_valid[ 1: 0] <= 2'b11;

                                buf_b0_data [47:16] <= {4{ibuf_init}};
                                buf_b0_valid[ 5: 2] <= 4'b0000;
                            end

                            3'd3: begin
                                buf_b0_data [ 7: 0] <= ibuf_cor_di[31:24];
                                buf_b0_valid[ 0: 0] <= 1'b1;
                                
                                buf_b0_data [47: 8] <= {5{ibuf_init}};
                                buf_b0_valid[ 5: 1] <= 5'b00000;
                            end

                            3'd5: begin
                                buf_b0_data [47:16] <= ibuf_cor_di[31: 0];
                                buf_b0_valid[ 5: 2] <= 4'b1111;
                            end

                            3'd6: begin
                                buf_b0_data [39: 8] <= ibuf_cor_di[31: 0];
                                buf_b0_valid[ 4: 1] <= 4'b1111;
                            end
                        endcase
                        end

                        2'd2: begin
                        case (ibuf_conv_wstrb)
                            3'd0: begin 
                                buf_b1_data [31: 0] <= ibuf_cor_di[31: 0];
                                buf_b1_valid[ 3: 0] <= 4'b1111;

                                buf_b1_data [47:32] <= {2{ibuf_init}};
                                buf_b1_valid[ 5: 4] <= 2'b00;
                            end

                            3'd1: begin
                                buf_b1_data [23: 0] <= ibuf_cor_di[31: 8];
                                buf_b1_valid[ 2: 0] <= 3'b111;

                                buf_b1_data [47:24] <= {3{ibuf_init}};
                                buf_b1_valid[ 5: 3] <= 3'b000;
                            end

                            3'd2: begin
                                buf_b1_data [15: 0] <= ibuf_cor_di[31:16];
                                buf_b1_valid[ 1: 0] <= 2'b11;

                                buf_b1_data [47:16] <= {4{ibuf_init}};
                                buf_b1_valid[ 5: 2] <= 4'b0000;
                            end

                            3'd3: begin
                                buf_b1_data [ 7: 0] <= ibuf_cor_di[31:24];
                                buf_b1_valid[ 0: 0] <= 1'b1;

                                buf_b1_data [47: 8] <= {5{ibuf_init}};
                                buf_b1_valid[ 5: 1] <= 5'b00000;
                            end

                            3'd5: begin
                                buf_b1_data [47:16] <= ibuf_cor_di[31: 0];
                                buf_b1_valid[ 5: 2] <= 4'b1111;
                            end

                            3'd6: begin
                                buf_b1_data [39: 8] <= ibuf_cor_di[31: 0];
                                buf_b1_valid[ 4: 1] <= 4'b1111;
                            end
                        endcase
                        end

                        2'd3: begin
                        case (ibuf_conv_wstrb)
                            3'd0: begin 
                                buf_b2_data [31: 0] <= ibuf_cor_di[31: 0];
                                buf_b2_valid[ 3: 0] <= 4'b1111;

                                buf_b2_data [47:32] <= {2{ibuf_init}};
                                buf_b2_valid[ 5: 4] <= 2'b00;
                            end

                            3'd1: begin
                                buf_b2_data [23: 0] <= ibuf_cor_di[31: 8];
                                buf_b2_valid[ 2: 0] <= 3'b111;

                                buf_b2_data [47:24] <= {3{ibuf_init}};
                                buf_b2_valid[ 5: 3] <= 3'b000;
                            end

                            3'd2: begin
                                buf_b2_data [15: 0] <= ibuf_cor_di[31:16];
                                buf_b2_valid[ 1: 0] <= 2'b11;

                                buf_b2_data [47:16] <= {4{ibuf_init}};
                                buf_b2_valid[ 5: 2] <= 4'b0000;
                            end

                            3'd3: begin
                                buf_b2_data [ 7: 0] <= ibuf_cor_di[31:24];
                                buf_b2_valid[ 0: 0] <= 1'b1;

                                buf_b2_data [47: 8] <= {5{ibuf_init}};
                                buf_b2_valid[ 5: 1] <= 5'b00000;
                            end

                            3'd5: begin
                                buf_b2_data [47:16] <= ibuf_cor_di[31: 0];
                                buf_b2_valid[ 5: 2] <= 4'b1111;
                            end

                            3'd6: begin
                                buf_b2_data [39: 8] <= ibuf_cor_di[31: 0];
                                buf_b2_valid[ 4: 1] <= 4'b1111;
                            end
                        endcase
                        end
                    endcase
                end 
                endcase
            end 
            else begin
                case (cfg_layer_typ)
                CONV: begin 
                    if (ibuf_conv_se_load) begin
                        if (ibuf_conv_fi_load) begin
                            buf_b0_data[ 47:  0] <= {6{ibuf_init}};
                            buf_b0_valid[ 5:  0] <= 0;

                            buf_b1_data[ 23:  0] <= buf_b1_data[ 47: 24];
                            buf_b1_valid[ 2:  0] <= buf_b1_valid[ 5:  3];

                            buf_b1_data[ 47: 24] <= {3{ibuf_init}};
                            buf_b1_valid[ 5:  3] <= 0;

                            buf_b2_data[ 23:  0] <= buf_b2_data[ 47: 24];
                            buf_b2_valid[ 2:  0] <= buf_b2_valid[ 5:  3];

                            buf_b2_data[ 47: 24] <= {3{ibuf_init}};
                            buf_b2_valid[ 5:  3] <= 0;
                        end else begin
                            buf_b0_data[ 47:  0] <= {6{ibuf_init}};
                            buf_b0_valid[ 5:  0] <= 0;

                            buf_b1_data[ 47: 24] <= buf_b2_data[ 47: 24];
                            buf_b1_valid[ 5:  3] <= buf_b2_valid[ 5:  3];

                            buf_b1_data[ 23:  0] <= {3{ibuf_init}};
                            buf_b1_valid[ 2:  0] <= 0;

                            buf_b2_data[ 47:  0] <= {6{ibuf_init}};
                            buf_b2_valid[ 5:  0] <= 0;

                            // buf_b1_data[ 47:  0] <= buf_b2_data[ 47:  0];
                            // buf_b1_valid[ 5:  0] <= buf_b2_valid[ 5:  0];

                            // buf_b2_data[ 47:  0] <= {6{ibuf_init}};
                            // buf_b2_valid[ 5:  0] <= 0;

                            // buf_b1_data[ 23:  0] <= buf_b1_data[ 47: 24];
                            // buf_b1_valid[ 2:  0] <= buf_b1_valid[ 5:  3];

                            // buf_b1_data[ 47: 24] <= {3{ibuf_init}};
                            // buf_b1_valid[ 5:  3] <= 0;

                            // buf_b2_data[ 23:  0] <= buf_b2_data[ 47: 24];
                            // buf_b2_valid[ 2:  0] <= buf_b2_valid[ 5:  3];

                            // buf_b2_data[ 47: 24] <= {3{ibuf_init}};
                            // buf_b2_valid[ 5:  3] <= 0;
                        end
                    end 
                    else begin
                        if (ibuf_conv_fi_load) begin
                            buf_b0_data[ 47:  0] <= {6{ibuf_init}};
                            buf_b0_valid[ 5:  0] <= 0;

                            buf_b1_data[ 47:  0] <= {6{ibuf_init}};
                            buf_b1_valid[ 5:  0] <= 0;

                            buf_b2_data[ 23:  0] <= buf_b2_data[ 47: 24];
                            buf_b2_valid[ 2:  0] <= buf_b2_valid[ 5:  3];

                            buf_b2_data[ 47: 24] <= {3{ibuf_init}};
                            buf_b2_valid[ 5:  3] <= 0;
                        end else begin
                            buf_b0_data[ 39:  0] <= buf_b0_data[ 47:  8];
                            buf_b0_data[ 47: 40] <= ibuf_init;
                            buf_b0_valid[ 4:  0] <= buf_b0_valid[ 5:  1];
                            buf_b0_valid[ 5:  5] <= 1'b0;

                            buf_b1_data[ 39:  0] <= buf_b1_data[ 47:  8];
                            buf_b1_data[ 47: 40] <= ibuf_init;
                            buf_b1_valid[ 4:  0] <= buf_b1_valid[ 5:  1];
                            buf_b1_valid[ 5:  5] <= 1'b0;

                            buf_b2_data[ 39:  0] <= buf_b2_data[ 47:  8];
                            buf_b2_data[ 47: 40] <= ibuf_init;
                            buf_b2_valid[ 4:  0] <= buf_b2_valid[ 5:  1];
                            buf_b2_valid[ 5:  5] <= 1'b0;
                        end
                    end
                end 

                DENSE: begin
                    buf_b0_data[15: 0] <= buf_b0_data[23: 8];
                    buf_b0_data[23:16] <= ibuf_init; 

                    buf_b1_data[15: 0] <= buf_b1_data[23: 8];
                    buf_b1_data[23:16] <= ibuf_init; 

                    buf_b2_data[15: 0] <= buf_b2_data[23: 8];
                    buf_b2_data[23:16] <= ibuf_init; 
                end

                MIXED: begin 
                    if (ibuf_conv_se_load) begin
                        if (ibuf_conv_fi_load) begin
                            buf_b0_data[ 47:  0] <= {6{ibuf_init}};
                            buf_b0_valid[ 5:  0] <= 0;

                            buf_b1_data[ 23:  0] <= buf_b1_data[ 47: 24];
                            buf_b1_valid[ 2:  0] <= buf_b1_valid[ 5:  3];

                            buf_b1_data[ 47: 24] <= {3{ibuf_init}};
                            buf_b1_valid[ 5:  3] <= 0;

                            buf_b2_data[ 23:  0] <= buf_b2_data[ 47: 24];
                            buf_b2_valid[ 2:  0] <= buf_b2_valid[ 5:  3];

                            buf_b2_data[ 47: 24] <= {3{ibuf_init}};
                            buf_b2_valid[ 5:  3] <= 0;
                        end else begin
                            buf_b0_data[ 47:  0] <= {6{ibuf_init}};
                            buf_b0_valid[ 5:  0] <= 0;

                            buf_b1_data[ 47: 24] <= buf_b2_data[ 47: 24];
                            buf_b1_valid[ 5:  3] <= buf_b2_valid[ 5:  3];

                            buf_b1_data[ 23:  0] <= {3{ibuf_init}};
                            buf_b1_valid[ 2:  0] <= 0;

                            buf_b2_data[ 47:  0] <= {6{ibuf_init}};
                            buf_b2_valid[ 5:  0] <= 0;

                            // buf_b1_data[ 47:  0] <= buf_b2_data[ 47:  0];
                            // buf_b1_valid[ 5:  0] <= buf_b2_valid[ 5:  0];

                            // buf_b2_data[ 47:  0] <= {6{ibuf_init}};
                            // buf_b2_valid[ 5:  0] <= 0;

                            // buf_b1_data[ 23:  0] <= buf_b1_data[ 47: 24];
                            // buf_b1_valid[ 2:  0] <= buf_b1_valid[ 5:  3];

                            // buf_b1_data[ 47: 24] <= {3{ibuf_init}};
                            // buf_b1_valid[ 5:  3] <= 0;

                            // buf_b2_data[ 23:  0] <= buf_b2_data[ 47: 24];
                            // buf_b2_valid[ 2:  0] <= buf_b2_valid[ 5:  3];

                            // buf_b2_data[ 47: 24] <= {3{ibuf_init}};
                            // buf_b2_valid[ 5:  3] <= 0;
                        end
                    end 
                    else begin
                        if (ibuf_conv_fi_load) begin
                            buf_b0_data[ 47:  0] <= {6{ibuf_init}};
                            buf_b0_valid[ 5:  0] <= 0;

                            buf_b1_data[ 47:  0] <= {6{ibuf_init}};
                            buf_b1_valid[ 5:  0] <= 0;

                            buf_b2_data[ 23:  0] <= buf_b2_data[ 47: 24];
                            buf_b2_valid[ 2:  0] <= buf_b2_valid[ 5:  3];

                            buf_b2_data[ 47: 24] <= {3{ibuf_init}};
                            buf_b2_valid[ 5:  3] <= 0;
                        end else begin
                            buf_b0_data[ 39:  0] <= buf_b0_data[ 47:  8];
                            buf_b0_data[ 47: 40] <= ibuf_init;
                            buf_b0_valid[ 4:  0] <= buf_b0_valid[ 5:  1];
                            buf_b0_valid[ 5:  5] <= 1'b0;

                            buf_b1_data[ 39:  0] <= buf_b1_data[ 47:  8];
                            buf_b1_data[ 47: 40] <= ibuf_init;
                            buf_b1_valid[ 4:  0] <= buf_b1_valid[ 5:  1];
                            buf_b1_valid[ 5:  5] <= 1'b0;

                            buf_b2_data[ 39:  0] <= buf_b2_data[ 47:  8];
                            buf_b2_data[ 47: 40] <= ibuf_init;
                            buf_b2_valid[ 4:  0] <= buf_b2_valid[ 5:  1];
                            buf_b2_valid[ 5:  5] <= 1'b0;
                        end
                    end
                end 
                endcase
            end
        end
    end

    always @(*) begin
        ibuf_do_0 = 0;
        ibuf_do_1 = 0;
        ibuf_do_2 = 0;
        ibuf_valid      = 0;
        ibuf_nxt_valid  = 0;
        case (cfg_layer_typ)
            CONV: begin 
                if (ibuf_conv_se_load || ibuf_conv_fi_load) begin
                    if (ibuf_do_revert) begin
                        ibuf_do_0  = buf_b2_data[23:16];
                        ibuf_do_1  = buf_b2_data[15: 8];
                        ibuf_do_2  = buf_b2_data[ 7: 0];
                        ibuf_valid = {buf_b2_valid[0], buf_b2_valid[1], buf_b2_valid[2]};
                    end
                    else begin
                        ibuf_do_0  = buf_b2_data[ 7: 0];
                        ibuf_do_1  = buf_b2_data[15: 8];
                        ibuf_do_2  = buf_b2_data[23:16];
                        ibuf_valid = buf_b2_valid[2:0];   
                    end
                end 
                else begin
                    ibuf_do_0  = buf_b0_data[7:0];
                    ibuf_do_1  = buf_b1_data[7:0];
                    ibuf_do_2  = buf_b2_data[7:0];
                    ibuf_valid      = {buf_b2_valid[0], buf_b1_valid[0], buf_b0_valid[0]};
                    ibuf_nxt_valid  = {buf_b2_valid[1], buf_b1_valid[1], buf_b0_valid[1]};
                end
            end 

            DENSE: begin
                ibuf_do_0 = buf_b0_data[7:0];
                ibuf_do_1 = buf_b1_data[7:0];
                ibuf_do_2 = buf_b2_data[7:0];
                // ibuf_valid = 3'b 111;
            end

            MIXED: begin 
                if (ibuf_conv_se_load || ibuf_conv_fi_load) begin
                    if (ibuf_do_revert) begin
                        ibuf_do_0  = buf_b2_data[23:16];
                        ibuf_do_1  = buf_b2_data[15: 8];
                        ibuf_do_2  = buf_b2_data[ 7: 0];
                        ibuf_valid = {buf_b2_valid[0], buf_b2_valid[1], buf_b2_valid[2]};
                    end
                    else begin
                        ibuf_do_0  = buf_b2_data[ 7: 0];
                        ibuf_do_1  = buf_b2_data[15: 8];
                        ibuf_do_2  = buf_b2_data[23:16];
                        ibuf_valid = buf_b2_valid[2:0];   
                    end
                end 
                else begin
                    ibuf_do_0  = buf_b0_data[7:0];
                    ibuf_do_1  = buf_b1_data[7:0];
                    ibuf_do_2  = buf_b2_data[7:0];
                    ibuf_valid      = {buf_b2_valid[0], buf_b1_valid[0], buf_b0_valid[0]};
                    ibuf_nxt_valid  = {buf_b2_valid[1], buf_b1_valid[1], buf_b0_valid[1]};
                end
            end 
        endcase        
    end
endmodule