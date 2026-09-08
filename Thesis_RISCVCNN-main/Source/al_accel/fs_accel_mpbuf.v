module fs_accel_mpbuf (
    // Data Sigs
    input   signed  [7:0] mpbuf_di,   
    output  signed  [7:0] mpbuf_do,

    // Ctrl Sigs
    input          mpbuf_ld_wrn,

    // Mandatory Sigs
    input   enb,
    input   clk,
    input   resetn
);
    reg [7:0] buf_data; 

    always @(posedge clk) begin
        if (!resetn) 
            buf_data <= 0;
        else if (enb) begin
            if (mpbuf_ld_wrn) begin
                buf_data <= mpbuf_di; 
            end 
        end
    end

    assign mpbuf_do = buf_data; 

endmodule
