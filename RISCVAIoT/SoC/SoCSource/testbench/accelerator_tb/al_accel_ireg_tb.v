`timescale 1 ns / 1 ps

`define TIME_TO_REPEAT 1

module al_accel_ireg_tb;
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
        // enb = 1'b0;
        // #111;
        // enb = 1'b1;
        // #30;
        // enb = 1'b0;
        // #20;
        enb = 1'b0;
        #58
        enb = 1'b0;
        #10
        enb = 1'b1;
        #10
        enb = 1'b0;
    end 

    // Input Signal Setting
    reg [7:0] ireg_di_0, ireg_di_1, ireg_di_2;
    initial begin
        #48
        ireg_di_0 = $random; ireg_di_1 = $random; ireg_di_2 = $random;
        #10
        ireg_di_0 = $random; ireg_di_1 = $random; ireg_di_2 = $random;
        #10
        ireg_di_0 = $random; ireg_di_1 = $random; ireg_di_2 = $random;
        #10
        ireg_di_0 = $random; ireg_di_1 = $random; ireg_di_2 = $random;
        #10
        ireg_di_0 = $random; ireg_di_1 = $random; ireg_di_2 = $random;
        #10
        ireg_di_0 = $random; ireg_di_1 = $random; ireg_di_2 = $random;
        #10
        ireg_di_0 = $random; ireg_di_1 = $random; ireg_di_2 = $random;
        #10
        ireg_di_0 = $random; ireg_di_1 = $random; ireg_di_2 = $random;
        #10
        ireg_di_0 = $random; ireg_di_1 = $random; ireg_di_2 = $random;
    end

    al_accel_ireg uut (
        .ireg_di_0  (ireg_di_0),
        .ireg_di_1  (ireg_di_1),
        .ireg_di_2  (ireg_di_2),

        .enb    (enb),
        .clk    (clk),
        .resetn (resetn)
    );

    // Debug Info
    initial begin
        $dumpfile("out_log/al_accel_ireg_tb.vcd");
        $dumpvars(0, al_accel_ireg_tb);

        repeat (`TIME_TO_REPEAT) begin
			repeat (1000) @(posedge clk);
		end
		$finish;
    end
endmodule