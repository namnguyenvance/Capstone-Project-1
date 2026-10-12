`default_nettype none

// Milestone A0 only: no SoC, firmware, UART, memory or accelerators.
module zcu106_smoke_top (
    input wire clk_p,
    input wire clk_n,
    input wire reset, // CPU_RESET: active high
    output wire led  // GPIO_LED_0_LS: active high
);
    wire clk_input;
    wire clk;
    IBUFDS clock_input (.I(clk_p), .IB(clk_n), .O(clk_input));
    BUFG clock_global (.I(clk_input), .O(clk));

    // FPGA configuration INIT holds reset initially. Button assertion is
    // asynchronous; release is synchronized to the raw board clock.
    (* ASYNC_REG = "TRUE" *) reg [1:0] reset_sync = 2'b11;
    always @(posedge clk or posedge reset) begin
        if (reset)
            reset_sync <= 2'b11;
        else
            reset_sync <= {reset_sync[0], 1'b0};
    end

    reg [27:0] heartbeat = 28'd0;
    always @(posedge clk) begin
        if (reset_sync[1])
            heartbeat <= 28'd0;
        else
            heartbeat <= heartbeat + 28'd1;
    end
    // At 300 MHz: 0.447392 s per half-period, 1.117587 Hz full cycle.
    assign led = heartbeat[27];
endmodule

`default_nettype wire
