module fs_accel_wreg(
    input   [7:0] wreg_di_0,
    input   [7:0] wreg_di_1,
    input   [7:0] wreg_di_2,

    output  [7:0] wreg_do_0,
    output  [7:0] wreg_do_1,
    output  [7:0] wreg_do_2,

    // Ctrl Sigs
    input   enb,
    input   clk,
    input   resetn
);

    reg     [7:0] wdata_0;
    reg     [7:0] wdata_1;
    reg     [7:0] wdata_2;
    always @(posedge clk) begin
        if (!resetn) begin
            wdata_0 <= 0;
            wdata_1 <= 0;
            wdata_2 <= 0;
        end else if (enb) begin
            wdata_0 <= wreg_di_0;
            wdata_1 <= wreg_di_1;
            wdata_2 <= wreg_di_2;
        end
    end
    assign wreg_do_0 = wdata_0;
    assign wreg_do_1 = wdata_1;
    assign wreg_do_2 = wdata_2;

endmodule