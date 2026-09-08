`timescale 1 ns / 1 ps

`define TIME_TO_REPEAT 1

module al_accel_wreg_tb;
    // Ctrl Signal Setting
    reg clk;
	always #5 clk = (clk === 1'b0); 

    reg resetn;
    initial begin
        resetn = 1'b0;
        #48
        resetn = 1'b1;
    end

    reg enb;
    initial begin   
        enb = 1'b1;
        #58
        enb = 1'b0;
        #10
        enb = 1'b1;
    end 

    // Input Signal Setting
    reg [7:0] wreg_di_0, wreg_di_1, wreg_di_2;
    initial begin
        #48
        wreg_di_0 = $random; wreg_di_1 = $random; wreg_di_2 = $random;
        #35
        wreg_di_0 = $random; wreg_di_1 = $random; wreg_di_2 = $random;
        #15
        wreg_di_0 = $random; wreg_di_1 = $random; wreg_di_2 = $random;
    end

    al_accel_wreg uut (
        .wreg_di_0  (wreg_di_0),
        .wreg_di_1  (wreg_di_1),
        .wreg_di_2  (wreg_di_2),

        .enb    (enb),
        .clk    (clk),
        .resetn (resetn)
    );

    // Debug Info
    initial begin
        $dumpfile("out_log/al_accel_wreg_tb.vcd");
        $dumpvars(0, al_accel_wreg_tb);

        repeat (`TIME_TO_REPEAT) begin
			repeat (1000) @(posedge clk);
		end
		$finish;
    end
endmodule