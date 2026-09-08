module fs_accel_idemux(
    input [7:0] idemux_di_0,
    input [7:0] idemux_di_1,
    input [7:0] idemux_di_2,

    output reg [7:0] idemux_do_0_0,
    output reg [7:0] idemux_do_0_1,
    output reg [7:0] idemux_do_0_2,
    output reg [7:0] idemux_do_1_0,
    output reg [7:0] idemux_do_1_1,
    output reg [7:0] idemux_do_1_2,
    output reg [7:0] idemux_do_2_0,
    output reg [7:0] idemux_do_2_1,
    output reg [7:0] idemux_do_2_2,

    input [1:0] idemux_sel
);

    always @(*) begin
        idemux_do_0_0 = 8'd0;
        idemux_do_0_1 = 8'd0;
        idemux_do_0_2 = 8'd0;
        idemux_do_1_0 = 8'd0;
        idemux_do_1_1 = 8'd0;
        idemux_do_1_2 = 8'd0;
        idemux_do_2_0 = 8'd0;
        idemux_do_2_1 = 8'd0;
        idemux_do_2_2 = 8'd0;
        case (idemux_sel)
            2'd0: begin
                idemux_do_0_0 = idemux_di_0;
                idemux_do_0_1 = idemux_di_1;
                idemux_do_0_2 = idemux_di_2;
            end

            2'd1: begin
                idemux_do_1_0 = idemux_di_0;
                idemux_do_1_1 = idemux_di_1;
                idemux_do_1_2 = idemux_di_2;
            end

            2'd2: begin
                idemux_do_2_0 = idemux_di_0;
                idemux_do_2_1 = idemux_di_1;
                idemux_do_2_2 = idemux_di_2;
            end
        endcase
    end

endmodule