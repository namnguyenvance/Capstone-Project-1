module fs_accel_bpbuf (
    // Data Sigs
    input   [31:0] bpbuf_di,
    output  [31:0] bpbuf_do,
    input          bpbuf_ld_wrn,

    // Mandatory Sigs
    input   enb,
    input   clk,
    input   resetn
);
    reg [31:0] buf_data;

    always @(posedge clk) begin
        if (!resetn) 
            buf_data <= 0;
        else 
        if (enb) begin
            if (bpbuf_ld_wrn) begin
                buf_data[31:0] <= bpbuf_di;
            end
        end
    end

    assign bpbuf_do = buf_data[31:0];

endmodule
