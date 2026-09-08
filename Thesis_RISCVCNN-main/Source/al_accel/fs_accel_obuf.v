module fs_accel_obuf (
    // Data Sigs
    input   [31:0] obuf_di,   

    output  [31:0] obuf_do,

    // Ctrl Sigs
    input          obuf_ld_wrn,

    // Mandatory Sigs
    input   enb,
    input   clk,
    input   resetn
);
    reg [31:0] buf_data;

    always @(posedge clk) begin
        if (!resetn) 
            buf_data <= 0;
        else if (enb) begin
            if (obuf_ld_wrn) begin
                buf_data[31:0] <= obuf_di;
            end 

        end
    end
    assign obuf_do = buf_data[31:0];

endmodule
