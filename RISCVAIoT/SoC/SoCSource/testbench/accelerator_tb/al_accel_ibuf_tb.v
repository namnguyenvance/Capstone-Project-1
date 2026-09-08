`timescale 1 ns / 1 ps

`define TIME_TO_REPEAT 1

module al_accel_ibuf_tb;
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
        enb = 1'b1;
    end 

    // Input Signal Setting
    reg [31: 0] ibuf_di;

    reg         ibuf_di_revert;
    reg [ 2: 0] ibuf_conv_wstrb;
    reg         ibuf_ld_wrn;
    reg [ 1: 0] ibuf_bank_sel;
    reg         ibuf_conv_fi_load;
    reg         ibuf_conv_se_load;
    
    // initial begin
    //     #61
    //     // State: ISTART_0
    //     ibuf_ld_wrn = 1; ibuf_di_revert = 0; ibuf_conv_wstrb = 3'd 0;
    //     ibuf_di = 32'h 165E3709; ibuf_bank_sel = 1; 
    //     ibuf_conv_fi_load = 0;
    //     #10

    //     ibuf_ld_wrn = 1; ibuf_di_revert = 0; ibuf_conv_wstrb = 3'd 0;
    //     ibuf_di = 32'h 5E154E18; ibuf_bank_sel = 2;
    //     ibuf_conv_fi_load = 0;
    //     #10

    //     ibuf_ld_wrn = 1; ibuf_di_revert = 0; ibuf_conv_wstrb = 3'd 0;
    //     ibuf_di = 32'h 553B070D; ibuf_bank_sel = 3;
    //     ibuf_conv_fi_load = 0;
    //     #10 

    //     // State: I_SLOAD
    //     ibuf_ld_wrn = 0; ibuf_di_revert = 0;
    //     ibuf_conv_fi_load = 0;
    //     #10 
    //     ibuf_ld_wrn = 0; ibuf_di_revert = 0;
    //     ibuf_conv_fi_load = 0;
    //     #10 
    //     ibuf_ld_wrn = 0; ibuf_di_revert = 0;
    //     ibuf_conv_fi_load = 0;
    //     #10 

    //     // State: I_SHIFT_LEFT
    //     ibuf_ld_wrn = 0; ibuf_di_revert = 0;
    //     ibuf_conv_fi_load = 0;
    //     #10 

    //     // State: I_SHIFT_LEFT
    //     ibuf_ld_wrn = 1; ibuf_di_revert = 0; ibuf_conv_wstrb = 3'd 0;
    //     ibuf_di = 32'h 09020043; ibuf_bank_sel = 1;
    //     ibuf_conv_fi_load = 0;
    //     #10 
    //     ibuf_ld_wrn = 1; ibuf_di_revert = 0; ibuf_conv_wstrb = 3'd 0;
    //     ibuf_di = 32'h 584E2510; ibuf_bank_sel = 2;
    //     ibuf_conv_fi_load = 0;
    //     #10  
    //     ibuf_ld_wrn = 1; ibuf_di_revert = 0; ibuf_conv_wstrb = 3'd 0;
    //     ibuf_di = 32'h 06612524; ibuf_bank_sel = 3; 
    //     ibuf_conv_fi_load = 0;
    //     #10 

    //     // State: I_SHIFT_LEFT
    //     ibuf_ld_wrn = 0; ibuf_di_revert = 0; 
    //     ibuf_conv_fi_load = 0;
    //     #10 

    //     // State: I_SHIFT_LEFT
    //     ibuf_ld_wrn = 0; ibuf_di_revert = 0;
    //     ibuf_conv_fi_load = 0;
    //     #10 

    //     // State: I_SHIFT_LEFT
    //     ibuf_ld_wrn = 0; ibuf_di_revert = 0;
    //     ibuf_conv_fi_load = 0;
    //     #10 

    //     // State: I_SHIFT_LEFT
    //     ibuf_ld_wrn = 0; ibuf_di_revert = 0;
    //     ibuf_conv_fi_load = 0;
    //     #10

    //     // State: I_DOWN_R2L
    //     ibuf_ld_wrn = 1; ibuf_di_revert = 1; ibuf_conv_wstrb = 3'd 0;
    //     ibuf_di = 32'h 061B3D55; ibuf_bank_sel = 3; 
    //     ibuf_conv_fi_load = 0;
    //     #10 

    //     // State: I_DOWN_R2L
    //     ibuf_ld_wrn = 0; ibuf_di_revert = 1; 
    //     ibuf_conv_fi_load = 1;
    //     #10  

    //     // State: I_SHIFT_RIGHT
    //     ibuf_ld_wrn = 1; ibuf_di_revert = 1; ibuf_conv_wstrb = 3'd 3;
    //     ibuf_di = 32'h 584E2510; ibuf_bank_sel = 1;
    //     ibuf_conv_fi_load = 0;
    //     #10 
    //     ibuf_ld_wrn = 1; ibuf_di_revert = 1; ibuf_conv_wstrb = 3'd 3;
    //     ibuf_di = 32'h 06612524; ibuf_bank_sel = 2;
    //     ibuf_conv_fi_load = 0;
    //     #10 

    //     // State: I_SHIFT_RIGHT
    //     ibuf_ld_wrn = 0; ibuf_di_revert = 1; 
    //     ibuf_conv_fi_load = 0;
    //     #10 

    //     // State: I_SHIFT_RIGHT
    //     ibuf_ld_wrn = 1; ibuf_di_revert = 1; ibuf_conv_wstrb = 3'd 0;
    //     ibuf_di = 32'h 5E154E18; ibuf_bank_sel = 1;
    //     ibuf_conv_fi_load = 0;
    //     #10 
    //     ibuf_ld_wrn = 1; ibuf_di_revert = 1; ibuf_conv_wstrb = 3'd 0;
    //     ibuf_di = 32'h 553B070D; ibuf_bank_sel = 2;
    //     ibuf_conv_fi_load = 0;
    //     #10 
    //     ibuf_ld_wrn = 1; ibuf_di_revert = 1; ibuf_conv_wstrb = 3'd 0;
    //     ibuf_di = 32'h 1B212A26; ibuf_bank_sel = 3;
    //     ibuf_conv_fi_load = 0;
    //     #10 

    //     // State: I_SHIFT_RIGHT
    //     ibuf_ld_wrn = 0; ibuf_di_revert = 1; 
    //     ibuf_conv_fi_load = 0;
    //     #10 

    //     // State: I_SHIFT_RIGHT
    //     ibuf_ld_wrn = 0; ibuf_di_revert = 1; 
    //     ibuf_conv_fi_load = 0;
    //     #10 

    //     // State: I_SHIFT_RIGHT
    //     ibuf_ld_wrn = 0; ibuf_di_revert = 1; 
    //     ibuf_conv_fi_load = 0;
    //     #10 

    //     // State: I_DOWN_L2R
    //     ibuf_ld_wrn = 1; ibuf_di_revert = 0; ibuf_conv_wstrb = 3'd 0;
    //     ibuf_di = 32'h 1B212A26; ibuf_bank_sel = 3;
    //     ibuf_conv_fi_load = 0;
    //     #10 

    //     // State: I_DOWN_L2R
    //     ibuf_ld_wrn = 0; ibuf_di_revert = 0; 
    //     ibuf_conv_fi_load = 1; 
    //     #10  

    //     // State: I_SHIFT_LEFT
    //     ibuf_ld_wrn = 1; ibuf_di_revert = 0; ibuf_conv_wstrb = 3'd 3;
    //     ibuf_di = 32'h 5E154E18; ibuf_bank_sel = 1;
    //     ibuf_conv_fi_load = 0;
    //     #10 
    //     ibuf_ld_wrn = 1; ibuf_di_revert = 0; ibuf_conv_wstrb = 3'd 3;
    //     ibuf_di = 32'h 553B070D; ibuf_bank_sel = 2;
    //     ibuf_conv_fi_load = 0;
    //     #10 

    //     // State: I_SHIFT_LEFT
    //     ibuf_ld_wrn = 0; ibuf_di_revert = 0; 
    //     ibuf_conv_fi_load = 0;
    //     #10 

    //     // State: I_SHIFT_LEFT
    //     ibuf_ld_wrn = 1; ibuf_di_revert = 0; ibuf_conv_wstrb = 3'd 0;
    //     ibuf_di = 32'h 584E2510; ibuf_bank_sel = 1;
    //     ibuf_conv_fi_load = 0;
    //     #10 
    //     ibuf_ld_wrn = 1; ibuf_di_revert = 0; ibuf_conv_wstrb = 3'd 0;
    //     ibuf_di = 32'h 06612524; ibuf_bank_sel = 2;
    //     ibuf_conv_fi_load = 0;
    //     #10 
    //     ibuf_ld_wrn = 1; ibuf_di_revert = 0; ibuf_conv_wstrb = 3'd 0;
    //     ibuf_di = 32'h 061B3D55; ibuf_bank_sel = 3;
    //     ibuf_conv_fi_load = 0;
    //     #10 

    //     // State: I_SHIFT_LEFT
    //     ibuf_ld_wrn = 0; ibuf_di_revert = 0; 
    //     ibuf_conv_fi_load = 0;
    //     #10 

    //     // State: I_SHIFT_LEFT
    //     ibuf_ld_wrn = 0; ibuf_di_revert = 0; 
    //     ibuf_conv_fi_load = 0;
    //     #10 

    //     // State: I_SHIFT_LEFT
    //     ibuf_ld_wrn = 0; ibuf_di_revert = 0; 
    //     ibuf_conv_fi_load = 0;
    //     #10 
    //     ;
    // end

    initial begin
        #61
        // State: I_START
        ibuf_ld_wrn = 1; ibuf_di_revert = 0; ibuf_conv_wstrb = 3'd 0;
        ibuf_di = 32'h E65E3709; ibuf_bank_sel = 1; 
        ibuf_conv_fi_load = 0; ibuf_conv_se_load = 0;
        #10
        uut.buf_b0_data = 48'h EBC9080702A6;

        ibuf_ld_wrn = 1; ibuf_di_revert = 0; ibuf_conv_wstrb = 3'd 0;
        ibuf_di = 32'h 5E154E18; ibuf_bank_sel = 2;
        ibuf_conv_fi_load = 0; ibuf_conv_se_load = 0;
        #10

        ibuf_ld_wrn = 1; ibuf_di_revert = 0; ibuf_conv_wstrb = 3'd 0;
        ibuf_di = 32'h 553B070D; ibuf_bank_sel = 3;
        ibuf_conv_fi_load = 0; ibuf_conv_se_load = 0;
        #10 

        // State: I_START
        ibuf_ld_wrn = 0; ibuf_di_revert = 0;
        ibuf_conv_fi_load = 0; ibuf_conv_se_load = 0;
        #10 
        ibuf_ld_wrn = 0; ibuf_di_revert = 0;
        ibuf_conv_fi_load = 0; ibuf_conv_se_load = 0;
        #10 
        ibuf_ld_wrn = 0; ibuf_di_revert = 0;
        ibuf_conv_fi_load = 0; ibuf_conv_se_load = 0;
        #10 

        // State: I_SHIFT_LEFT
        ibuf_ld_wrn = 0; ibuf_di_revert = 0;
        ibuf_conv_fi_load = 0; ibuf_conv_se_load = 0;
        #10 

        // State: I_SHIFT_LEFT
        ibuf_ld_wrn = 1; ibuf_di_revert = 0; ibuf_conv_wstrb = 3'd 0;
        ibuf_di = 32'h 09020043; ibuf_bank_sel = 1; 
        ibuf_conv_fi_load = 0; ibuf_conv_se_load = 0;
        #10 
        ibuf_ld_wrn = 1; ibuf_di_revert = 0; ibuf_conv_wstrb = 3'd 0;
        ibuf_di = 32'h 584E2510; ibuf_bank_sel = 2;
        ibuf_conv_fi_load = 0; ibuf_conv_se_load = 0;
        #10  
        ibuf_ld_wrn = 1; ibuf_di_revert = 0; ibuf_conv_wstrb = 3'd 0;
        ibuf_di = 32'h 06612524; ibuf_bank_sel = 3; 
        ibuf_conv_fi_load = 0; ibuf_conv_se_load = 0;
        #10 

        // State: I_SHIFT_LEFT
        ibuf_ld_wrn = 0; ibuf_di_revert = 0; 
        ibuf_conv_fi_load = 0; ibuf_conv_se_load = 0;
        #10 

        // State: I_SHIFT_LEFT
        ibuf_ld_wrn = 0; ibuf_di_revert = 0;
        ibuf_conv_fi_load = 0; ibuf_conv_se_load = 0;
        #10 

        // State: I_SHIFT_LEFT
        ibuf_ld_wrn = 0; ibuf_di_revert = 0;
        ibuf_conv_fi_load = 0; ibuf_conv_se_load = 0;
        #10 

        // State: I_SHIFT_LEFT
        ibuf_ld_wrn = 0; ibuf_di_revert = 0;
        ibuf_conv_fi_load = 0; ibuf_conv_se_load = 0;
        #10

        // State: I_DOWN_R2L
        ibuf_ld_wrn = 1; ibuf_di_revert = 1; ibuf_conv_wstrb = 3'd 0;
        ibuf_di = 32'h 061B3D55; ibuf_bank_sel = 3; 
        ibuf_conv_fi_load = 0; ibuf_conv_se_load = 0;
        #10 

        // State: I_DOWN_R2L
        ibuf_ld_wrn = 0; ibuf_di_revert = 1; 
        ibuf_conv_fi_load = 0; ibuf_conv_se_load = 1;
        #10  

        // State: I_DOWN_R2L
        ibuf_ld_wrn = 1; ibuf_di_revert = 1; ibuf_conv_wstrb = 3'd 0;
        ibuf_di = 32'h 38005B21; ibuf_bank_sel = 3; 
        ibuf_conv_fi_load = 0; ibuf_conv_se_load = 0;
        #10 

        // State: I_DOWN_R2L
        ibuf_ld_wrn = 0; ibuf_di_revert = 1; 
        ibuf_conv_fi_load = 1; ibuf_conv_se_load = 1;
        #10  

        // State: I_SHIFT_RIGHT
        ibuf_ld_wrn = 1; ibuf_di_revert = 1; ibuf_conv_wstrb = 3'd 3;
        ibuf_di = 32'h 06612524; ibuf_bank_sel = 1;
        ibuf_conv_fi_load = 0; ibuf_conv_se_load = 0;
        #10 

        // State: I_SHIFT_RIGHT
        ibuf_ld_wrn = 0; ibuf_di_revert = 1; 
        ibuf_conv_fi_load = 0; ibuf_conv_se_load = 0;
        #10 

        // State: I_SHIFT_RIGHT
        ibuf_ld_wrn = 1; ibuf_di_revert = 1; ibuf_conv_wstrb = 3'd 0;
        ibuf_di = 32'h 553B070D; ibuf_bank_sel = 1;
        ibuf_conv_fi_load = 0; ibuf_conv_se_load = 0;
        #10 
        ibuf_ld_wrn = 1; ibuf_di_revert = 1; ibuf_conv_wstrb = 3'd 0;
        ibuf_di = 32'h 1B212A26; ibuf_bank_sel = 2;
        ibuf_conv_fi_load = 0; ibuf_conv_se_load = 0;
        #10 
        ibuf_ld_wrn = 1; ibuf_di_revert = 1; ibuf_conv_wstrb = 3'd 0;
        ibuf_di = 32'h 105B415A; ibuf_bank_sel = 3;
        ibuf_conv_fi_load = 0; ibuf_conv_se_load = 0;
        #10 

        // // State: I_SHIFT_RIGHT
        // ibuf_ld_wrn = 0; ibuf_di_revert = 1; 
        // ibuf_conv_fi_load = 0; ibuf_conv_se_load = 0;
        // #10 

        // // State: I_SHIFT_RIGHT
        // ibuf_ld_wrn = 0; ibuf_di_revert = 1; 
        // ibuf_conv_fi_load = 0; ibuf_conv_se_load = 0;
        // #10 

        // // State: I_SHIFT_RIGHT
        // ibuf_ld_wrn = 0; ibuf_di_revert = 1; 
        // ibuf_conv_fi_load = 0; ibuf_conv_se_load = 0;
        // #10 

        // State: I_DOWN_L2R
        ibuf_ld_wrn = 1; ibuf_di_revert = 0; ibuf_conv_wstrb = 3'd 1;
        ibuf_di = 32'h 1C583E3D; ibuf_bank_sel = 2;
        ibuf_conv_fi_load = 0; ibuf_conv_se_load = 0;
        #10 

        // State: I_DOWN_L2R
        ibuf_ld_wrn = 0; ibuf_di_revert = 0; 
        ibuf_conv_fi_load = 0; ibuf_conv_se_load = 1;
        #10  

        // State: I_DOWN_L2R
        ibuf_ld_wrn = 1; ibuf_di_revert = 0; ibuf_conv_wstrb = 3'd 0;
        ibuf_di = 32'h 095A1F21; ibuf_bank_sel = 3;
        ibuf_conv_fi_load = 0; ibuf_conv_se_load = 0;
        #10 

        // State: I_DOWN_L2R
        ibuf_ld_wrn = 0; ibuf_di_revert = 0; 
        ibuf_conv_fi_load = 1; ibuf_conv_se_load = 1;
        #10  

        // State: I_SHIFT_LEFT
        ibuf_ld_wrn = 1; ibuf_di_revert = 0; ibuf_conv_wstrb = 3'd 3;
        ibuf_di = 32'h 105B415A; ibuf_bank_sel = 1;
        ibuf_conv_fi_load = 0; ibuf_conv_se_load = 0;
        #10 

        // State: I_SHIFT_LEFT
        ibuf_ld_wrn = 0; ibuf_di_revert = 0; 
        ibuf_conv_fi_load = 0; ibuf_conv_se_load = 0;
        #10 

        // State: I_SHIFT_LEFT
        ibuf_ld_wrn = 1; ibuf_di_revert = 0; ibuf_conv_wstrb = 3'd 0;
        ibuf_di = 32'h 38005B21; ibuf_bank_sel = 1;
        ibuf_conv_fi_load = 0; ibuf_conv_se_load = 0;
        #10 
        ibuf_ld_wrn = 1; ibuf_di_revert = 0; ibuf_conv_wstrb = 3'd 0;
        ibuf_di = 32'h 073A1514; ibuf_bank_sel = 2;
        ibuf_conv_fi_load = 0; ibuf_conv_se_load = 0;
        #10 
        ibuf_ld_wrn = 1; ibuf_di_revert = 0; ibuf_conv_wstrb = 3'd 0;
        ibuf_di = 32'h 172D3421; ibuf_bank_sel = 3;
        ibuf_conv_fi_load = 0; ibuf_conv_se_load = 0;
        #10 

        // State: I_SHIFT_LEFT
        ibuf_ld_wrn = 0; ibuf_di_revert = 0; 
        ibuf_conv_fi_load = 0; ibuf_conv_se_load = 0;
        #10 

        // State: I_SHIFT_LEFT
        ibuf_ld_wrn = 0; ibuf_di_revert = 0; 
        ibuf_conv_fi_load = 0; ibuf_conv_se_load = 0;
        #10 

        // State: I_SHIFT_LEFT
        ibuf_ld_wrn = 0; ibuf_di_revert = 0; 
        ibuf_conv_fi_load = 0; ibuf_conv_se_load = 0;
        #10 
        ;
    end

    al_accel_ibuf uut (
        .ibuf_di    (ibuf_di),
        .ibuf_init  (8'd0),

        // .ibuf_do_0  (ibuf_do_0),
        // .ibuf_do_1  (ibuf_do_1),
        // .ibuf_do_2  (ibuf_do_2),

        // .ibuf_nxt_valid (),

        .ibuf_di_revert (ibuf_di_revert),

        .ibuf_dens_wstrb (2'b00),
        .ibuf_conv_wstrb (ibuf_conv_wstrb),

        .ibuf_ld_wrn    (ibuf_ld_wrn),
        .ibuf_bank_sel  (ibuf_bank_sel),
        .ibuf_is_conv_layer (1'b1),
        .ibuf_conv_fi_load (ibuf_conv_fi_load),
        .ibuf_conv_se_load (ibuf_conv_se_load),

        .enb    (enb),
        .clk    (clk),
        .resetn (resetn)
    );

    // Debug Info
    initial begin
        $dumpfile("out_log/al_accel_ibuf_tb.vcd");
        $dumpvars(0, al_accel_ibuf_tb);

        repeat (`TIME_TO_REPEAT) begin
			repeat (1000) @(posedge clk);
		end
		$finish;
    end

endmodule