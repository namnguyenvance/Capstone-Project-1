`timescale 1 ns / 1 ps

`define TIME_TO_REPEAT 1

module al_accel_acc_matrix_tb;
    // Ctrl Signal Setting
    reg clk;
	always #5 clk = (clk === 1'b0); 

    reg resetn;
    initial begin
        resetn = 1'b0;
        #52
        resetn = 1'b1;
    end

    reg enb;
    initial begin   
        enb = 1'b1;
    end 

    // Input Signal Setting
    reg [31:0] acc_matrix_bps_0, acc_matrix_bps_1, acc_matrix_bps_2;
    initial begin
        #52
        acc_matrix_bps_0 = {$random} % 1000; acc_matrix_bps_1 = {$random} % 1000; acc_matrix_bps_2 = {$random} % 1000;
        #10
        acc_matrix_bps_0 = {$random} % 1000; acc_matrix_bps_1 = {$random} % 1000; acc_matrix_bps_2 = {$random} % 1000;
        #10
        acc_matrix_bps_0 = {$random} % 1000; acc_matrix_bps_1 = {$random} % 1000; acc_matrix_bps_2 = {$random} % 1000;
        #10
        acc_matrix_bps_0 = {$random} % 1000; acc_matrix_bps_1 = {$random} % 1000; acc_matrix_bps_2 = {$random} % 1000;
        #10
        acc_matrix_bps_0 = {$random} % 1000; acc_matrix_bps_1 = {$random} % 1000; acc_matrix_bps_2 = {$random} % 1000;
    end

    reg [31:0]  acc_matrix_di_0_0_0, acc_matrix_di_0_0_1, acc_matrix_di_0_0_2,
                acc_matrix_di_0_1_0, acc_matrix_di_0_1_1, acc_matrix_di_0_1_2,
                acc_matrix_di_0_2_0, acc_matrix_di_0_2_1, acc_matrix_di_0_2_2,
                acc_matrix_di_1_0_0, acc_matrix_di_1_0_1, acc_matrix_di_1_0_2,
                acc_matrix_di_1_1_0, acc_matrix_di_1_1_1, acc_matrix_di_1_1_2,
                acc_matrix_di_1_2_0, acc_matrix_di_1_2_1, acc_matrix_di_1_2_2,
                acc_matrix_di_2_0_0, acc_matrix_di_2_0_1, acc_matrix_di_2_0_2,
                acc_matrix_di_2_1_0, acc_matrix_di_2_1_1, acc_matrix_di_2_1_2,
                acc_matrix_di_2_2_0, acc_matrix_di_2_2_1, acc_matrix_di_2_2_2;
    initial begin
        #48
        acc_matrix_di_0_0_0 = {$random} % 1000; acc_matrix_di_0_0_1 = {$random} % 1000; acc_matrix_di_0_0_2 = {$random} % 1000;
        acc_matrix_di_0_1_0 = {$random} % 1000; acc_matrix_di_0_1_1 = {$random} % 1000; acc_matrix_di_0_1_2 = {$random} % 1000;
        acc_matrix_di_0_2_0 = {$random} % 1000; acc_matrix_di_0_2_1 = {$random} % 1000; acc_matrix_di_0_2_2 = {$random} % 1000;
        acc_matrix_di_1_0_0 = {$random} % 1000; acc_matrix_di_1_0_1 = {$random} % 1000; acc_matrix_di_1_0_2 = {$random} % 1000;
        acc_matrix_di_1_1_0 = {$random} % 1000; acc_matrix_di_1_1_1 = {$random} % 1000; acc_matrix_di_1_1_2 = {$random} % 1000;
        acc_matrix_di_1_2_0 = {$random} % 1000; acc_matrix_di_1_2_1 = {$random} % 1000; acc_matrix_di_1_2_2 = {$random} % 1000;
        acc_matrix_di_2_0_0 = {$random} % 1000; acc_matrix_di_2_0_1 = {$random} % 1000; acc_matrix_di_2_0_2 = {$random} % 1000;
        acc_matrix_di_2_1_0 = {$random} % 1000; acc_matrix_di_2_1_1 = {$random} % 1000; acc_matrix_di_2_1_2 = {$random} % 1000;
        acc_matrix_di_2_2_0 = {$random} % 1000; acc_matrix_di_2_2_1 = {$random} % 1000; acc_matrix_di_2_2_2 = {$random} % 1000;

        #20
        acc_matrix_di_0_0_0 = {$random} % 1000; acc_matrix_di_0_0_1 = {$random} % 1000; acc_matrix_di_0_0_2 = {$random} % 1000;
        acc_matrix_di_0_1_0 = {$random} % 1000; acc_matrix_di_0_1_1 = {$random} % 1000; acc_matrix_di_0_1_2 = {$random} % 1000;
        acc_matrix_di_0_2_0 = {$random} % 1000; acc_matrix_di_0_2_1 = {$random} % 1000; acc_matrix_di_0_2_2 = {$random} % 1000;
        acc_matrix_di_1_0_0 = {$random} % 1000; acc_matrix_di_1_0_1 = {$random} % 1000; acc_matrix_di_1_0_2 = {$random} % 1000;
        acc_matrix_di_1_1_0 = {$random} % 1000; acc_matrix_di_1_1_1 = {$random} % 1000; acc_matrix_di_1_1_2 = {$random} % 1000;
        acc_matrix_di_1_2_0 = {$random} % 1000; acc_matrix_di_1_2_1 = {$random} % 1000; acc_matrix_di_1_2_2 = {$random} % 1000;
        acc_matrix_di_2_0_0 = {$random} % 1000; acc_matrix_di_2_0_1 = {$random} % 1000; acc_matrix_di_2_0_2 = {$random} % 1000;
        acc_matrix_di_2_1_0 = {$random} % 1000; acc_matrix_di_2_1_1 = {$random} % 1000; acc_matrix_di_2_1_2 = {$random} % 1000;
        acc_matrix_di_2_2_0 = {$random} % 1000; acc_matrix_di_2_2_1 = {$random} % 1000; acc_matrix_di_2_2_2 = {$random} % 1000;
    end

    reg     acc_matrix_bps_load;
    reg     acc_matrix_inter_sum_load;
    initial begin
        acc_matrix_bps_load = 1; acc_matrix_inter_sum_load = 1;
        #68
        acc_matrix_bps_load = 0; acc_matrix_inter_sum_load = 0;
        #20
        acc_matrix_bps_load = 1; acc_matrix_inter_sum_load = 1;
    end

    al_accel_acc_matrix uut (
        .acc_matrix_bps_0  (acc_matrix_bps_0),
        .acc_matrix_bps_1  (acc_matrix_bps_1),
        .acc_matrix_bps_2  (acc_matrix_bps_2),

        .acc_matrix_di_0_0_0 (acc_matrix_di_0_0_0),
        .acc_matrix_di_0_0_1 (acc_matrix_di_0_0_1),
        .acc_matrix_di_0_0_2 (acc_matrix_di_0_0_2),
        .acc_matrix_di_0_1_0 (acc_matrix_di_0_1_0),
        .acc_matrix_di_0_1_1 (acc_matrix_di_0_1_1),
        .acc_matrix_di_0_1_2 (acc_matrix_di_0_1_2),
        .acc_matrix_di_0_2_0 (acc_matrix_di_0_2_0),
        .acc_matrix_di_0_2_1 (acc_matrix_di_0_2_1),
        .acc_matrix_di_0_2_2 (acc_matrix_di_0_2_2),
        .acc_matrix_di_1_0_0 (acc_matrix_di_1_0_0),
        .acc_matrix_di_1_0_1 (acc_matrix_di_1_0_1),
        .acc_matrix_di_1_0_2 (acc_matrix_di_1_0_2),
        .acc_matrix_di_1_1_0 (acc_matrix_di_1_1_0),
        .acc_matrix_di_1_1_1 (acc_matrix_di_1_1_1),
        .acc_matrix_di_1_1_2 (acc_matrix_di_1_1_2),
        .acc_matrix_di_1_2_0 (acc_matrix_di_1_2_0),
        .acc_matrix_di_1_2_1 (acc_matrix_di_1_2_1),
        .acc_matrix_di_1_2_2 (acc_matrix_di_1_2_2),
        .acc_matrix_di_2_0_0 (acc_matrix_di_2_0_0),
        .acc_matrix_di_2_0_1 (acc_matrix_di_2_0_1),
        .acc_matrix_di_2_0_2 (acc_matrix_di_2_0_2),
        .acc_matrix_di_2_1_0 (acc_matrix_di_2_1_0),
        .acc_matrix_di_2_1_1 (acc_matrix_di_2_1_1),
        .acc_matrix_di_2_1_2 (acc_matrix_di_2_1_2),
        .acc_matrix_di_2_2_0 (acc_matrix_di_2_2_0),
        .acc_matrix_di_2_2_1 (acc_matrix_di_2_2_1),
        .acc_matrix_di_2_2_2 (acc_matrix_di_2_2_2),

        .acc_matrix_bps_load        (acc_matrix_bps_load),
        .acc_matrix_inter_sum_load  (acc_matrix_inter_sum_load),

        .enb    (enb),
        .clk    (clk),
        .resetn (resetn)
    );

    // Debug Info
    initial begin
        $dumpfile("out_log/al_accel_acc_matrix_tb.vcd");
        $dumpvars(0, al_accel_acc_matrix_tb);

        repeat (`TIME_TO_REPEAT) begin
			repeat (1000) @(posedge clk);
		end
		$finish;
    end
endmodule