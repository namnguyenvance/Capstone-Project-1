module fs_accel_wbuf (
    // Data Sigs
    input   [31:0] wbuf_di,
    input   [ 7:0] wbuf_init,

    output  [ 7:0] wbuf_do_0,
    output  [ 7:0] wbuf_do_1,
    output  [ 7:0] wbuf_do_2,

    // Ctrl Sigs
    input   [ 1:0] wbuf_wstrb,
    input          wbuf_ld_wrn,
    input   [ 1:0] wbuf_bank_sel,

    // Mandatory Sigs
    input   enb,
    input   clk,
    input   resetn
);
    // reg [12*8 - 1:0] buf_data;
    reg [9*8 - 1:0] buf_data;

    always @(posedge clk) begin
        if (!resetn) 
            buf_data <= 0;
        else if (enb) begin
            if (wbuf_ld_wrn) begin
                case (wbuf_bank_sel)
                    2'd1: begin
                    case (wbuf_wstrb) 
                        2'd0: buf_data[31: 0] <= wbuf_di[31: 0];    // 32 bits
                        2'd1: buf_data[23: 0] <= wbuf_di[31: 8];    // 24 bits
                        2'd2: buf_data[15: 0] <= wbuf_di[31:16];    // 16 bits
                        2'd3: buf_data[ 7: 0] <= wbuf_di[31:24];    // 8 bits
                    endcase
                    end

                    2'd2: begin
                    case (wbuf_wstrb)
                        2'd0: buf_data[63:32] <= wbuf_di[31: 0];
                        2'd1: buf_data[55:24] <= wbuf_di[31: 0];
                        2'd2: buf_data[47:16] <= wbuf_di[31: 0];
                        2'd3: buf_data[39: 8] <= wbuf_di[31: 0];
                    endcase
                    end

                    2'd3: begin
                    case (wbuf_wstrb)
                        2'd0: buf_data[71:64] <= wbuf_di[ 7: 0];    // 8 bits
                        2'd1: buf_data[71:56] <= wbuf_di[15: 0];    // 16 bits
                        2'd2: buf_data[71:48] <= wbuf_di[23: 0];    // 24 bits
                        2'd3: buf_data[71:40] <= wbuf_di[31: 0];    // 32 bits
                    endcase
                    end
                endcase
            end else begin
                buf_data[63: 0] <= buf_data[71: 8];
                buf_data[71:64] <= wbuf_init;
            end
        end
    end

    assign wbuf_do_0 = buf_data[ 7: 0];
    assign wbuf_do_1 = buf_data[31:24];
    assign wbuf_do_2 = buf_data[55:48];

endmodule