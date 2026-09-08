`timescale 1ns/1ps

module al_accel_pu_tb;

    reg clk;
    reg resetn;
    reg enb;

    // Inputs
    reg  signed [7:0] pu_idi_0, pu_idi_1, pu_idi_2;
    reg  signed [7:0] pu_idi_3, pu_idi_4, pu_idi_5;
    reg  signed [7:0] pu_idi_6, pu_idi_7, pu_idi_8;

    reg  signed [7:0] pu_input_offset;

    reg  signed [7:0] pu_wdi_0_0, pu_wdi_0_1, pu_wdi_0_2;
    reg  signed [7:0] pu_wdi_1_0, pu_wdi_1_1, pu_wdi_1_2;
    reg  signed [7:0] pu_wdi_2_0, pu_wdi_2_1, pu_wdi_2_2;

    // Outputs
    wire signed [31:0] pu_odo;
    wire rdy;

    // DUT
    al_accel_pu dut (
        .pu_idi_0(pu_idi_0), .pu_idi_1(pu_idi_1), .pu_idi_2(pu_idi_2),
        .pu_idi_3(pu_idi_3), .pu_idi_4(pu_idi_4), .pu_idi_5(pu_idi_5),
        .pu_idi_6(pu_idi_6), .pu_idi_7(pu_idi_7), .pu_idi_8(pu_idi_8),
        .pu_input_offset(pu_input_offset),
        .pu_wdi_0_0(pu_wdi_0_0), .pu_wdi_0_1(pu_wdi_0_1), .pu_wdi_0_2(pu_wdi_0_2),
        .pu_wdi_1_0(pu_wdi_1_0), .pu_wdi_1_1(pu_wdi_1_1), .pu_wdi_1_2(pu_wdi_1_2),
        .pu_wdi_2_0(pu_wdi_2_0), .pu_wdi_2_1(pu_wdi_2_1), .pu_wdi_2_2(pu_wdi_2_2),
        .pu_odo(pu_odo),
        .rdy(rdy),
        .clk(clk),
        .resetn(resetn),
        .enb(enb)
    );

    // Clock 100MHz
    initial clk = 0;
    always #5 clk = ~clk;

    // Task to run one test
    task run_test(
        input signed [7:0] offset,
        input signed [7:0] w[0:8],
        input [127:0] name
    );
        begin
            // Inputs 1..9
            pu_idi_0=1; pu_idi_1=2; pu_idi_2=3;
            pu_idi_3=4; pu_idi_4=5; pu_idi_5=6;
            pu_idi_6=7; pu_idi_7=8; pu_idi_8=9;

            pu_input_offset = offset;

            pu_wdi_0_0=w[0]; pu_wdi_0_1=w[1]; pu_wdi_0_2=w[2];
            pu_wdi_1_0=w[3]; pu_wdi_1_1=w[4]; pu_wdi_1_2=w[5];
            pu_wdi_2_0=w[6]; pu_wdi_2_1=w[7]; pu_wdi_2_2=w[8];

            // One cycle enable
            @(negedge clk);
            enb = 1;
            @(negedge clk);
            enb = 0;

            // Wait for result
            @(posedge clk);
            if (rdy) begin
                $display("[%s] Offset=%0d => PU sum = %0d",
                         name, offset, pu_odo);
            end
            @(posedge clk);
        end
    endtask

    // Main stimulus
    initial begin
        integer i;
        reg signed [7:0] weights [0:8];

        // Init
        enb = 0;
        resetn = 0;
        #20 resetn = 1;

        // Test 1: all weights = 1
        for (i=0;i<9;i=i+1) weights[i]=1;
        run_test(0, weights, "All weights=1, offset=0");

        // Test 2: all weights = 1, offset=1
        run_test(1, weights, "All weights=1, offset=1");

        // Test 3: weights = 1..9
        for (i=0;i<9;i=i+1) weights[i]=i+1;
        run_test(0, weights, "Weights=1..9, offset=0");

        // Test 4: mixed signed weights
        weights[0]=1;  weights[1]=-1; weights[2]=2;
        weights[3]=-2; weights[4]=3;  weights[5]=-3;
        weights[6]=4;  weights[7]=-4; weights[8]=5;
        run_test(2, weights, "Mixed signed, offset=2");

        // Test 5: random weights
        for (i=0;i<9;i=i+1) weights[i]=$random;
        run_test(-1, weights, "Random weights, offset=-1");

        // Test 6: all weights = 0
        for (i=0;i<9;i=i+1) weights[i]=0;
        run_test(0, weights, "All weights=0");

        #50 $finish;
    end

    // Dump VCD for GTKWave
    initial begin
        $dumpfile("tb_al_accel_pu.vcd");
        $dumpvars(0, tb_al_accel_pu);
    end

endmodule
