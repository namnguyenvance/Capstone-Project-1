module fs_accel_ireg(
    input   [7:0] ireg_di_0,
    input   [7:0] ireg_di_1,
    input   [7:0] ireg_di_2,

    output  [7:0] ireg_do_0,
    output  [7:0] ireg_do_1,
    output  [7:0] ireg_do_2,

    // Ctrl Sigs
    input   enb,
    input   clk,
    input   resetn
);

    reg     [7:0] idata_0;
    reg     [7:0] idata_1;
    reg     [7:0] idata_2;
    always @(posedge clk) begin
        if (!resetn) begin
            idata_0 <= 0;
            idata_1 <= 0;
            idata_2 <= 0;
        end 
        else if (enb) begin
            idata_0 <= ireg_di_0;
            idata_1 <= ireg_di_1;
            idata_2 <= ireg_di_2;
        end
    end
    assign ireg_do_0 = idata_0;
    assign ireg_do_1 = idata_1;
    assign ireg_do_2 = idata_2;

endmodule