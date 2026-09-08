`timescale 1 ns / 1 ps

`define TIME_TO_REPEAT 1

module al_accel_config_regs_tb;
    // Ctrl Signal Setting
    reg clk;
	always #5 clk = (clk === 1'b0); 

    reg resetn;
    initial begin
        resetn = 1'b0;
        #48
        resetn = 1'b1;
    end

    reg config_wen;
    initial begin   
        config_wen = 1'b1;
        // #58
        // config_wen = 1'b0;
        // #10
        // config_wen = 1'b1;
    end 

    // Input Signal Setting
    reg [31:0] config_data;
    reg [ 3:0] config_sel;
    initial begin
        #48
        config_data = $random; config_sel = 0;
        #10
        config_data = $random; config_sel = 1;
        #10
        config_data = $random; config_sel = 2;
        #10
        config_data = $random; config_sel = 3;
        #10
        config_data = $random; config_sel = 4;
        #10
        config_data = $random; config_sel = 5;
        #10
        config_data = $random; config_sel = 6;
        #10
        config_data = $random; config_sel = 7;
        #10
        config_data = $random; config_sel = 8;
        #10
        config_data = $random; config_sel = 9;
        #10
        config_data = $random; config_sel = 10;
    end

    al_accel_config_regs uut (
        .config_data (config_data),
        .config_sel  (config_sel),
        .config_wen  (config_wen),

        .clk    (clk),
        .resetn (resetn)
    );

    // Debug Info
    initial begin
        $dumpfile("out_log/al_accel_config_regs_tb.vcd");
        $dumpvars(0, al_accel_config_regs_tb);

        repeat (`TIME_TO_REPEAT) begin
			repeat (1000) @(posedge clk);
		end
		$finish;
    end
endmodule