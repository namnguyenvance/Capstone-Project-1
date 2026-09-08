`timescale 1 ns / 1 ps

`define TIME_TO_REPEAT 1

module al_accel_wbuf_tb;
    // Ctrl Signal Setting
    reg clk;
	always #5 clk = (clk === 1'b0); 

    reg resetn;
    initial begin
        resetn = 1'b0;
        #50 
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
        enb = 1'b1;
    end 

    // Input Signal Setting
    reg [31: 0] wbuf_di;
    reg [ 1: 0] wbuf_wstrb;
    reg         wbuf_ld_wrn;
    initial begin
        #50 
        wbuf_di     = 32'h5876063e;
        wbuf_wstrb  = 2'd3;
        wbuf_ld_wrn = 1'd1;
        #20
        wbuf_ld_wrn = 1'd0;
        #10
        wbuf_di     = 32'haabb7788;
        wbuf_wstrb  = 3'd7;
        wbuf_ld_wrn = 2'd1;
        #20
        wbuf_ld_wrn = 1'd0;
    end

    wire [7:0] wbuf_do_0, wbuf_do_1, wbuf_do_2;

    al_accel_wbuf uut (
        .wbuf_di    (wbuf_di),
        .wbuf_init  (8'd0),
        .wbuf_do_0  (wbuf_do_0),
        .wbuf_do_1  (wbuf_do_1),
        .wbuf_do_2  (wbuf_do_2),
        .wbuf_wstrb (wbuf_wstrb),
        .wbuf_ld_wrn(wbuf_ld_wrn),

        .enb    (enb),
        .clk    (clk),
        .resetn (resetn)
    );

    // Debug Info
    initial begin
        $dumpfile("out_log/al_accel_wbuf_tb.vcd");
        $dumpvars(0, al_accel_wbuf_tb);

        repeat (`TIME_TO_REPEAT) begin
			repeat (1000) @(posedge clk);
		end
		$finish;
    end
endmodule