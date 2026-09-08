`timescale 1 ns / 1 ps

`define TIME_TO_REPEAT 1

module al_accel_cp_unit_tb;
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
        #62
        enb = 1'b0;
        #10
        enb = 1'b1;
    end 

    reg cp_clr;
    initial begin   
        cp_clr = 1'b0;
        #82
        cp_clr = 1'b1;
        #20
        cp_clr = 1'b0;
        #60
        cp_clr = 1'b1;
        #30
        cp_clr = 1'b0;
    end 

    // Input Signal Setting
    reg [7:0] cp_di;
    initial begin
        #42
        cp_di = $random; 
        #10 
        cp_di = $random; 
        #10 
        cp_di = $random; 
        #10 
        cp_di = $random; 
        #10 
        cp_di = $random; 
        #10 
        cp_di = $random; 
        #10 
        cp_di = $random; 
        #10 
        cp_di = $random; 
        #10 
        cp_di = $random; 
        #10 
        cp_di = $random; 
        #10 
        cp_di = $random; 
        #10 
        cp_di = $random; 
        #10 
        cp_di = $random; 
        #10 
        cp_di = $random; 
        #10 
        cp_di = $random; 
    end

    al_accel_cp_unit uut (
        .cp_di  (cp_di),

        .cp_clr (cp_clr),

        .enb    (enb),
        .clk    (clk),
        .resetn (resetn)
    );

    // Debug Info
    initial begin
        $dumpfile("out_log/al_accel_cp_unit_tb.vcd");
        $dumpvars(0, al_accel_cp_unit_tb);

        repeat (`TIME_TO_REPEAT) begin
			repeat (1000) @(posedge clk);
		end
		$finish;
    end
endmodule