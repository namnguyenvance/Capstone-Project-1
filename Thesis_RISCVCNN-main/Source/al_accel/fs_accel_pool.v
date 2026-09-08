module fs_accel_pool (
    // Data Input
    input signed [7:0] pool_di,  

    // Selection Signals
    input [3:0] sel_demux,       
    input [3:0] sel_mux, 
    input mpbuf_ld_wrn,      

    // Ctrl Signals
    input buf_enb,
    input cp_enb,
    input clk,                    
    input resetn,                 

    // Data Output
    output reg signed [7:0] pool_do   
);

    // Internal Signals
    wire signed [7:0] buf_data;    
    wire signed [7:0] demux_out_0, demux_out_1, demux_out_2, demux_out_3, demux_out_4, demux_out_5, demux_out_6, demux_out_7, demux_out_8, demux_out_9, demux_out_10, demux_out_11, demux_out_12;
    wire signed [7:0] cp_out_0, cp_out_1, cp_out_2, cp_out_3, cp_out_4, cp_out_5, cp_out_6, cp_out_7, cp_out_8, cp_out_9, cp_out_10, cp_out_11, cp_out_12;

    // Khối Buffer
    fs_accel_mpbuf buffer (
        .mpbuf_di(pool_di),      
        .mpbuf_do(buf_data),      
        .mpbuf_ld_wrn(mpbuf_ld_wrn),      
        .enb(buf_enb),                
        .clk(clk),                
        .resetn(resetn)           
    );

    // Khối Demux
    fs_accel_mpdemux demux (
        .din(buf_data),          
        .sel(sel_demux), 
        .resetn(resetn),          
        .do_0(demux_out_0),       
        .do_1(demux_out_1),       
        .do_2(demux_out_2),       
        .do_3(demux_out_3),        
        .do_4(demux_out_4),       
        .do_5(demux_out_5),        
        .do_6(demux_out_6),       
        .do_7(demux_out_7),       
        .do_8(demux_out_8),       
        .do_9(demux_out_9),       
        .do_10(demux_out_10),
        .do_11(demux_out_11),     
        .do_12(demux_out_12)      
    );

    fs_accel_cp cp_0 (
        .cp_di(demux_out_0),      
        .cp_do(cp_out_0),          
        .enb(cp_enb),                 
        .clk(clk),                 
        .resetn(resetn)           
    );

    fs_accel_cp cp_1 (
        .cp_di(demux_out_1),
        .cp_do(cp_out_1),
        .enb(cp_enb),
        .clk(clk),
        .resetn(resetn)
    );

    fs_accel_cp cp_2 (
        .cp_di(demux_out_2),
        .cp_do(cp_out_2),
        .enb(cp_enb),
        .clk(clk),
        .resetn(resetn)
    );

    fs_accel_cp cp_3 (
        .cp_di(demux_out_3),
        .cp_do(cp_out_3),
        .enb(cp_enb),
        .clk(clk),
        .resetn(resetn)
    );

    fs_accel_cp cp_4 (
        .cp_di(demux_out_4),
        .cp_do(cp_out_4),
        .enb(cp_enb),
        .clk(clk),
        .resetn(resetn)
    );

    fs_accel_cp cp_5 (
        .cp_di(demux_out_5),
        .cp_do(cp_out_5),
        .enb(cp_enb),
        .clk(clk),
        .resetn(resetn)
    );

    fs_accel_cp cp_6 (
        .cp_di(demux_out_6),
        .cp_do(cp_out_6),
        .enb(cp_enb),
        .clk(clk),
        .resetn(resetn)
    );

    fs_accel_cp cp_7 (
        .cp_di(demux_out_7),
        .cp_do(cp_out_7),
        .enb(cp_enb),
        .clk(clk),
        .resetn(resetn)
    );

    fs_accel_cp cp_8 (
        .cp_di(demux_out_8),
        .cp_do(cp_out_8),
        .enb(cp_enb),
        .clk(clk),
        .resetn(resetn)
    );

    fs_accel_cp cp_9 (
        .cp_di(demux_out_9),
        .cp_do(cp_out_9),
        .enb(cp_enb),
        .clk(clk),
        .resetn(resetn)
    );

    fs_accel_cp cp_10 (
        .cp_di(demux_out_10),
        .cp_do(cp_out_10),
        .enb(cp_enb),
        .clk(clk),
        .resetn(resetn)
    );

    fs_accel_cp cp_11 (
        .cp_di(demux_out_11),
        .cp_do(cp_out_11),
        .enb(cp_enb),
        .clk(clk),
        .resetn(resetn)
    );

    fs_accel_cp cp_12 (
        .cp_di(demux_out_12),
        .cp_do(cp_out_12),
        .enb(cp_enb),
        .clk(clk),
        .resetn(resetn)
    );

    always @(*) begin
        case (sel_mux)
            4'b0000: pool_do = cp_out_0;
            4'b0001: pool_do = cp_out_1;
            4'b0010: pool_do = cp_out_2;
            4'b0011: pool_do = cp_out_3;
            4'b0100: pool_do = cp_out_4;
            4'b0101: pool_do = cp_out_5;
            4'b0110: pool_do = cp_out_6;
            4'b0111: pool_do = cp_out_7;
            4'b1000: pool_do = cp_out_8;
            4'b1001: pool_do = cp_out_9;
            4'b1010: pool_do = cp_out_10;
            4'b1011: pool_do = cp_out_11;
            4'b1100: pool_do = cp_out_12;
            default: pool_do = 8'b0; 
        endcase
    end

endmodule
