module fs_accel_wdemux(
    input   [7:0] wdemux_di_0,
    input   [7:0] wdemux_di_1,
    input   [7:0] wdemux_di_2,

    output reg  [7:0] wdemux_do_0_0,
    output reg  [7:0] wdemux_do_0_1,
    output reg  [7:0] wdemux_do_0_2,
    output reg  [7:0] wdemux_do_1_0,
    output reg  [7:0] wdemux_do_1_1,
    output reg  [7:0] wdemux_do_1_2,
    output reg  [7:0] wdemux_do_2_0,
    output reg  [7:0] wdemux_do_2_1,
    output reg  [7:0] wdemux_do_2_2,

    input   [1:0] wdemux_sel
);

    always @(*) begin
        wdemux_do_0_0 = 8'd0;
        wdemux_do_0_1 = 8'd0;
        wdemux_do_0_2 = 8'd0;
        wdemux_do_1_0 = 8'd0;
        wdemux_do_1_1 = 8'd0;
        wdemux_do_1_2 = 8'd0;
        wdemux_do_2_0 = 8'd0;
        wdemux_do_2_1 = 8'd0;
        wdemux_do_2_2 = 8'd0;
        case (wdemux_sel)
            2'd0: begin
                wdemux_do_0_0 = wdemux_di_0;
                wdemux_do_0_1 = wdemux_di_1;
                wdemux_do_0_2 = wdemux_di_2;
            end

            2'd1: begin
                wdemux_do_1_0 = wdemux_di_0;
                wdemux_do_1_1 = wdemux_di_1;
                wdemux_do_1_2 = wdemux_di_2;
            end

            2'd2: begin
                wdemux_do_2_0 = wdemux_di_0;
                wdemux_do_2_1 = wdemux_di_1;
                wdemux_do_2_2 = wdemux_di_2;
            end
        endcase
    end

endmodule

    // output reg  [7:0] wdemux_do_0_0_0,
    // output reg  [7:0] wdemux_do_0_0_1,
    // output reg  [7:0] wdemux_do_0_0_2,
    // output reg  [7:0] wdemux_do_0_1_0,
    // output reg  [7:0] wdemux_do_0_1_1,
    // output reg  [7:0] wdemux_do_0_1_2,
    // output reg  [7:0] wdemux_do_0_2_0,
    // output reg  [7:0] wdemux_do_0_2_1,
    // output reg  [7:0] wdemux_do_0_2_2,

    // output reg  [7:0] wdemux_do_1_0_0,
    // output reg  [7:0] wdemux_do_1_0_1,
    // output reg  [7:0] wdemux_do_1_0_2,
    // output reg  [7:0] wdemux_do_1_1_0,
    // output reg  [7:0] wdemux_do_1_1_1,
    // output reg  [7:0] wdemux_do_1_1_2,
    // output reg  [7:0] wdemux_do_1_2_0,
    // output reg  [7:0] wdemux_do_1_2_1,
    // output reg  [7:0] wdemux_do_1_2_2,

    // output reg  [7:0] wdemux_do_2_0_0,
    // output reg  [7:0] wdemux_do_2_0_1,
    // output reg  [7:0] wdemux_do_2_0_2,
    // output reg  [7:0] wdemux_do_2_1_0,
    // output reg  [7:0] wdemux_do_2_1_1,
    // output reg  [7:0] wdemux_do_2_1_2,
    // output reg  [7:0] wdemux_do_2_2_0,
    // output reg  [7:0] wdemux_do_2_2_1,
    // output reg  [7:0] wdemux_do_2_2_2,

    // input   [3:0] wdemux_sel

    // always @(*) begin
    //     wdemux_do_0_0_0 = 8'd0;
    //     wdemux_do_0_0_1 = 8'd0;
    //     wdemux_do_0_0_2 = 8'd0;
    //     wdemux_do_0_1_0 = 8'd0;
    //     wdemux_do_0_1_1 = 8'd0;
    //     wdemux_do_0_1_2 = 8'd0;
    //     wdemux_do_0_2_0 = 8'd0;
    //     wdemux_do_0_2_1 = 8'd0;
    //     wdemux_do_0_2_2 = 8'd0;
    //     wdemux_do_1_0_0 = 8'd0;
    //     wdemux_do_1_0_1 = 8'd0;
    //     wdemux_do_1_0_2 = 8'd0;
    //     wdemux_do_1_1_0 = 8'd0;
    //     wdemux_do_1_1_1 = 8'd0;
    //     wdemux_do_1_1_2 = 8'd0;
    //     wdemux_do_1_2_0 = 8'd0;
    //     wdemux_do_1_2_1 = 8'd0;
    //     wdemux_do_1_2_2 = 8'd0;
    //     wdemux_do_2_0_0 = 8'd0;
    //     wdemux_do_2_0_1 = 8'd0;
    //     wdemux_do_2_0_2 = 8'd0;
    //     wdemux_do_2_1_0 = 8'd0;
    //     wdemux_do_2_1_1 = 8'd0;
    //     wdemux_do_2_1_2 = 8'd0;
    //     wdemux_do_2_2_0 = 8'd0;
    //     wdemux_do_2_2_1 = 8'd0;
    //     wdemux_do_2_2_2 = 8'd0;
    //     case (wdemux_sel)      
    //         4'd0: begin
    //             wdemux_do_0_0_0 = wdemux_di_0;
    //             wdemux_do_0_0_1 = wdemux_di_1;
    //             wdemux_do_0_0_2 = wdemux_di_2;
    //         end

    //         4'd1: begin
    //             wdemux_do_0_1_0 = wdemux_di_0;
    //             wdemux_do_0_1_1 = wdemux_di_1;
    //             wdemux_do_0_1_2 = wdemux_di_2;
    //         end

    //         4'd2: begin
    //             wdemux_do_0_2_0 = wdemux_di_0;
    //             wdemux_do_0_2_1 = wdemux_di_1;
    //             wdemux_do_0_2_2 = wdemux_di_2;
    //         end

    //         4'd3: begin
    //             wdemux_do_1_0_0 = wdemux_di_0;
    //             wdemux_do_1_0_1 = wdemux_di_1;
    //             wdemux_do_1_0_2 = wdemux_di_2;
    //         end

    //         4'd4: begin
    //             wdemux_do_1_1_0 = wdemux_di_0;
    //             wdemux_do_1_1_1 = wdemux_di_1;
    //             wdemux_do_1_1_2 = wdemux_di_2;
    //         end

    //         4'd5: begin
    //             wdemux_do_1_2_0 = wdemux_di_0;
    //             wdemux_do_1_2_1 = wdemux_di_1;
    //             wdemux_do_1_2_2 = wdemux_di_2;
    //         end

    //         4'd6: begin
    //             wdemux_do_2_0_0 = wdemux_di_0;
    //             wdemux_do_2_0_1 = wdemux_di_1;
    //             wdemux_do_2_0_2 = wdemux_di_2;
    //         end

    //         4'd7: begin
    //             wdemux_do_2_1_0 = wdemux_di_0;
    //             wdemux_do_2_1_1 = wdemux_di_1;
    //             wdemux_do_2_1_2 = wdemux_di_2;
    //         end

    //         4'd8: begin
    //             wdemux_do_2_2_0 = wdemux_di_0;
    //             wdemux_do_2_2_1 = wdemux_di_1;
    //             wdemux_do_2_2_2 = wdemux_di_2;
    //         end
    //     endcase
    // end