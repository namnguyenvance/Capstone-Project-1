`timescale 1 ns / 1 ps

`define TIME_TO_REPEAT 6

module al_accel_RDATA_ctrl_tb;
    localparam 
        CONV    = 4'd0,
        DENSE   = 4'd1,
        POOL    = 4'd2;

    // Ctrl Signal Setting
    reg clk;
	always #5 clk = (clk === 1'b0); 

    reg resetn;
    initial begin
        resetn = 1'b0;
        #48 
        resetn = 1'b1;
    end

// /* CONV LAYER */
//     /* 
//         Description:
//         - Input Feature Map's size : 8 x 8 x 9     => 576
//         - Kernel's size            : 3 x 3 x 9 x 6 => 486
//         - Output Feature Map's size: 6 x 6 x 6     => 216
//         - Bias's size              : 6 x 4         =>  24
//         - Partial-Sum's size       : 6 x 6 x 6 x 4 => 864
//     */


//     al_accel_RDATA_ctrl uut (
//         .i_base_addr    (32'd 1000),
//         .kw_base_addr   (32'd 2000),
//         .o_base_addr    (32'd 3000),
//         .b_base_addr    (32'd 4000),
//         .ps_base_addr   (32'd 5000),

//         .cfg_layer_typ  (CONV), 
//         .stride_width   (4'd 1),
//         .stride_height  (4'd 1),
//         .weight_kernel_patch_width  (16'd 3),
//         .weight_kernel_patch_height (16'd 3),
//         .kernel_ifm_depth   (16'd 9),
//         .nok_ofm_depth      (16'd 6),
//         .ofm_width  (16'd 6),
//         .ofm_height (16'd 6),
//         .ifm_width  (16'd 8),
//         .ifm_height (16'd 8),
//         .kernel3D_size  (16'd 81),
//         .input2D_size   (16'd 64),
//         .output2D_size  (16'd 36),

//         .mem_ready (1'b1),

//         .ibuf_0_valid (3'b 000),
//         .ibuf_1_valid (3'b 000),
//         .ibuf_2_valid (3'b 000),

//         .COMPS_rdy      (1'b 1),
//         .COMPS_start    (1'b 1),

//         .WBACK_rdy      (1'b 1),
//         .WBACK_start    (1'b 1),

//         .enb    (1'b 1),
//         .clk    (clk),
//         .resetn (resetn)
//     );
// /*************/

/* DENSE LAYER */
    /* 
        Description:
        - Input Feature Map's size : 27 x 1 =>  27
        - Kernel's size            : 27 x 9 => 243
        - Output Feature Map's size:  9 x 1 =>   9
        - Bias's size              :  9 x 4 =>  36
        - Partial-Sum's size       :  9 x 4 =>  36
    */


    al_accel_RDATA_ctrl uut (
        .i_base_addr    (32'd 1000),
        .kw_base_addr   (32'd 2000),
        .o_base_addr    (32'd 3000),
        .b_base_addr    (32'd 4000),
        .ps_base_addr   (32'd 5000),

        .cfg_layer_typ  (DENSE), 
        .stride_width   (4'd 0),
        .stride_height  (4'd 0),
        .weight_kernel_patch_width  (16'd 27),
        .weight_kernel_patch_height (16'd  9),
        .kernel_ifm_depth   (16'd 0),
        .nok_ofm_depth      (16'd 0),
        .ofm_width  (16'd  9),
        .ofm_height (16'd  1),
        .ifm_width  (16'd 27),
        .ifm_height (16'd  1),
        .kernel3D_size  (16'd 243),
        .input2D_size   (16'd  27),
        .output2D_size  (16'd   9),

        .mem_ready (1'b1),

        .ibuf_0_valid (3'b 000),
        .ibuf_1_valid (3'b 000),
        .ibuf_2_valid (3'b 000),

        .COMPS_rdy      (1'b 1),
        .COMPS_start    (1'b 1),

        .WBACK_rdy      (1'b 1),
        .WBACK_start    (1'b 1),

        .enb    (1'b 1),
        .clk    (clk),
        .resetn (resetn)
    );
/*************/


    // Debug Info
    initial begin
        $dumpfile("out_log/al_accel_RDATA_ctrl_tb.vcd");
        $dumpvars(0, al_accel_RDATA_ctrl_tb);

        repeat (`TIME_TO_REPEAT) begin
			repeat (1000) @(posedge clk);
		end
		$finish;
    end
endmodule

