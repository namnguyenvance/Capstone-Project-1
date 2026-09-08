module al_accel_lpureg(
    input   [7:0] lpureg_di_0,
    input   [7:0] lpureg_di_1,
    input   [7:0] lpureg_di_2,

    output  [7:0] lpureg_do_0,
    output  [7:0] lpureg_do_1,
    output  [7:0] lpureg_do_2,

    // Ctrl Sigs
    input   lpureg_ld_wrn,

    input   enb,
    input   clk,
    input   resetn
);

    reg     [7:0] ldata_0;
    reg     [7:0] ldata_1;
    reg     [7:0] ldata_2;
    always @(posedge clk) begin
        if (!resetn) begin
            ldata_0 <= 0;
            ldata_1 <= 0;
            ldata_2 <= 0;
        end 
        else if (enb) begin
            if (lpureg_ld_wrn) begin
                ldata_0 <= lpureg_di_0;
                ldata_1 <= lpureg_di_1;
                ldata_2 <= lpureg_di_2;
            end
        end
    end
    assign lpureg_do_0 = ldata_0;
    assign lpureg_do_1 = ldata_1;
    assign lpureg_do_2 = ldata_2;


endmodule