`timescale 1ns/1ps

module al_accel_quant_tb;

    // DUT signals
    reg         clk;
    reg         resetn;
    reg         enb;
    reg [31:0]  quant_muler;
    reg [31:0]  quant_di;
    reg [7:0]   quant_rshift;
    wire [31:0] quant_do;
    wire        quant_rdy;

    // Instantiate DUT
    al_accel_quant dut (
        .clk(clk),
        .resetn(resetn),
        .enb(enb),
        .quant_muler(quant_muler),
        .quant_di(quant_di),
        .quant_rshift(quant_rshift),
        .quant_do(quant_do),
        .quant_rdy(quant_rdy)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk; // 100MHz clock

    // Stimulus
    initial begin
        // Initialize
        resetn = 0;
        enb = 0;
        quant_muler = 0;
        quant_di = 0;
        quant_rshift = 0;

        // Apply reset
        #20;
        resetn = 1;

        // Apply input
        #10;
        quant_muler = 32'd2039693188; // 0x797F66A4
        quant_di    = 32'd4581;
        quant_rshift = 8;
        #10;
        enb = 1;


        // Wait for result
        wait(quant_rdy == 1);
        enb = 0;
        // Display result
        #10;
        $display("[TEST] quant_do = %0d ", quant_do );
        $finish;
    end

    // Debug Info
    initial begin
        $dumpfile("accel_vcd/al_accel_quant_tb.vcd");
        $dumpvars(0, al_accel_quant_tb);
    end

endmodule
