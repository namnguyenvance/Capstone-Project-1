`timescale 1ns/1ps

module al_accel_elw_unit_tb;

    // Clock and reset signals
    reg clk;
    reg resetn;

    // Data signals
    reg [31:0] elew_di_0_0, elew_di_0_1, elew_di_0_2;
    reg [7:0] elew_di_1_0, elew_di_1_1, elew_di_1_2;

    wire [7:0] elew_do_0_0, elew_do_0_1, elew_do_0_2;
    wire [7:0] elew_do_1;

    // Config signals
    reg [31:0] elew_quant_muler_0, elew_quant_muler_1, elew_quant_muler_2;
    reg [7:0] elew_quant_rshift_0, elew_quant_rshift_1, elew_quant_rshift_2;
    reg [31:0] elew_output_offset;
    reg [3:0] elew_act_func_typ;

    // Control signals
    reg quant_act_func_enb_0, quant_act_func_enb_1, quant_act_func_enb_2;
    wire quant_act_func_rdy_0, quant_act_func_rdy_1, quant_act_func_rdy_2;
    reg cp_clr, cp2h_enb, cp2w_enb, cp_enb;

    // Instantiate the DUT (Device Under Test)
    al_accel_elw_unit dut (
        .elew_di_0_0(elew_di_0_0),
        .elew_di_0_1(elew_di_0_1),
        .elew_di_0_2(elew_di_0_2),
        .elew_di_1_0(elew_di_1_0),
        .elew_di_1_1(elew_di_1_1),
        .elew_di_1_2(elew_di_1_2),
        .elew_do_0_0(elew_do_0_0),
        .elew_do_0_1(elew_do_0_1),
        .elew_do_0_2(elew_do_0_2),
        .elew_do_1(elew_do_1),
        .elew_quant_muler_0(elew_quant_muler_0),
        .elew_quant_muler_1(elew_quant_muler_1),
        .elew_quant_muler_2(elew_quant_muler_2),
        .elew_quant_rshift_0(elew_quant_rshift_0),
        .elew_quant_rshift_1(elew_quant_rshift_1),
        .elew_quant_rshift_2(elew_quant_rshift_2),
        .elew_output_offset(elew_output_offset),
        .elew_act_func_typ(elew_act_func_typ),
        .quant_act_func_enb_0(quant_act_func_enb_0),
        .quant_act_func_enb_1(quant_act_func_enb_1),
        .quant_act_func_enb_2(quant_act_func_enb_2),
        .quant_act_func_rdy_0(quant_act_func_rdy_0),
        .quant_act_func_rdy_1(quant_act_func_rdy_1),
        .quant_act_func_rdy_2(quant_act_func_rdy_2),
        .cp_clr(cp_clr),
        .cp2h_enb(cp2h_enb),
        .cp2w_enb(cp2w_enb),
        .cp_enb(cp_enb),
        .clk(clk),
        .resetn(resetn)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns clock period
    end

    // Reset logic
    initial begin
        resetn = 0;
        quant_act_func_enb_0 = 0;
        quant_act_func_enb_1 = 0;
        quant_act_func_enb_2 = 0;
        #20 resetn = 1; // Release reset after 20ns
    end

    // Test Quantize and Activation Function Unit
    initial begin
        // Initialize inputs
        elew_di_0_0 = 32'd4581; // Example input data
        elew_di_0_1 = 32'h00020000;
        elew_di_0_2 = 32'h00030000;

        elew_quant_muler_0 = 32'd2039693188; // Example multiplier
        elew_quant_muler_1 = 32'h19921576;
        elew_quant_muler_2 = 32'h19921576;

        elew_quant_rshift_0 = 8'd8; // Example right shift
        elew_quant_rshift_1 = 8'd7;
        elew_quant_rshift_2 = 8'd7;

        elew_output_offset = 32'h00000000; // Example output offset

        elew_act_func_typ = 4'd0; // Example activation function type

        #50;
        quant_act_func_enb_0 = 1;
        quant_act_func_enb_1 = 1;
        quant_act_func_enb_2 = 1;

        // Wait for ready signals
        wait(quant_act_func_rdy_0 && quant_act_func_rdy_1 && quant_act_func_rdy_2);

        // Observe outputs
        #10;
        $display("Quantize Output 0: %0d", elew_do_0_0);
        $display("Quantize Output 1: %0d", elew_do_0_1);
        $display("Quantize Output 2: %0d", elew_do_0_2);
    end

    // Test Compare Unit for Max Pooling
    initial begin
        // Wait for Quantize tests to complete
        #100;

        // Initialize inputs for Compare Unit
        elew_di_1_0 = 8'd10; // Example input data
        elew_di_1_1 = 8'd20;
        elew_di_1_2 = 8'd15;

        cp_clr = 0;
        cp2h_enb = 1;
        cp2w_enb = 1;
        cp_enb = 1;

        // Observe output
        #10;
        $display("Max Pooling Output: %d", elew_do_1);
    end

    // End simulation
    initial begin
        $dumpfile("accel_vcd/al_accel_elw_unit_tb.vcd");
        $dumpvars(0, al_accel_elw_unit_tb);
        #200;
        $finish;
    end

endmodule
