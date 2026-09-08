`timescale 1 ns / 1 ps

`define TIME_TO_REPEAT 1
`define ML_TC0

module al_accel_tb;
    localparam 
        CONV    = 4'd 0,
        DENSE   = 4'd 1,
        MIXED    = 4'd 2;

    localparam 
        RELU    = 4'd0,
        RELU6   = 4'd1,
        SIGMOID = 4'd2,
        TANH    = 4'd3,
        NO_FUNC = 4'd4;

    // Mandatory Sigs Control
    reg clk;
	always #5 clk = (clk === 1'b0); 

    reg resetn;
    initial begin
        resetn = 1'b 0;
        #42
        resetn = 1'b 1;
    end

    // SoC Ctrl Sigs
    reg  [31:0] al_accel_cfgreg_di;
    reg  [ 4:0] al_accel_cfgreg_sel;
    reg         al_accel_cfgreg_wenb;
    reg         al_accel_flow_enb;
    reg         al_accel_mem_read_ready;
    reg         al_accel_mem_write_ready;

    wire [31:0] al_accel_raddr, al_accel_waddr;
    wire        al_accel_renb , al_accel_wenb;
    wire [ 3:0] al_accel_wstrb;
    wire [31:0] al_accel_rdata, al_accel_wdata;

// ===================================================================================================================================
// ======================================================== CONVOLUTION LAYER ========================================================
// ===================================================================================================================================


`ifdef CL_TC0
/* Test case 0 */
     /* 
        Description:
           - Input Feature Map's size : 7 x 7 x 3     => 147
           - Kernel's size            : 3 x 3 x 3 x 6 => 162
           - Output Feature Map's size: 5 x 5 x 6     => 150
           - Bias's size              : 6 x 4         =>  24
           - Partial-Sum's size       : 6 x 6 x 6 x 4 => 864
    */

    localparam 
        IFM_SIZE = 7 * 7 * 3     + 1,
        KER_SIZE = 3 * 3 * 3 * 6 + 2,
        OFM_SIZE = 5 * 5 * 6     + 2,
        BIS_SIZE = 6,
        PAS_SIZE = 5 * 5 * 6,
        OUTPUT_HEIGHT = 5,
        OUTPUT_WIDTH = 5,
        OUTPUT_DEPTH = 6;

    initial begin
        // al_accel_mem_read_ready = 1'b 0;
        // al_accel_mem_write_ready = 1'b 0;
        // #10
        // repeat (2000) @(posedge clk) begin
        //     #2 al_accel_mem_read_ready = $random;
        // end
        // #10 
        al_accel_mem_read_ready    = 1'b 1;
        al_accel_mem_write_ready   = 1'b 1;
    end

    initial begin
        al_accel_cfgreg_di   = 32'd 0; al_accel_cfgreg_sel = 5'd 0; 
        al_accel_cfgreg_wenb =  1'd 0;
        al_accel_flow_enb    =  1'b 0;
        #42
        al_accel_cfgreg_wenb =  1'd 1;
    // Config Data
        #10 // i_base_addr
        al_accel_cfgreg_di   = 32'd 0000;       al_accel_cfgreg_sel = 5'd 0; 

        #10 // kw_base_addr
        al_accel_cfgreg_di   = 32'd 6000;       al_accel_cfgreg_sel = 5'd 1; 

        #10 // o_base_addr
        al_accel_cfgreg_di   = 32'd 16000;       al_accel_cfgreg_sel = 5'd 2; 

        #10 // b_base_addr
        al_accel_cfgreg_di   = 32'd 5600;       al_accel_cfgreg_sel = 5'd 3; 

        #10 // ps_base_addr
        al_accel_cfgreg_di   = 32'd 20000;       al_accel_cfgreg_sel = 5'd 4; 

        #10 // {stride_height, stride_width, cfg_act_func_typ, cfg_layer_typ}
        al_accel_cfgreg_di   = {16'd 0, 4'd 1, 4'd 1, RELU, CONV}; al_accel_cfgreg_sel = 5'd 5; 

        #10 // {weight_kernel_patch_height, weight_kernel_patch_width}
        al_accel_cfgreg_di   = {16'd 3, 16'd 3}; al_accel_cfgreg_sel = 5'd 6; 

        #10 // {nok_ofm_depth, kernel_ifm_depth} 
        al_accel_cfgreg_di   = {16'd 6, 16'd 3}; al_accel_cfgreg_sel = 5'd 7;
        
        #10 // {ifm_height, ifm_width}  
        al_accel_cfgreg_di   = {16'd 7, 16'd 7}; al_accel_cfgreg_sel = 5'd 8;

        #10 // {ofm_height, ofm_width}
        al_accel_cfgreg_di   = {16'd 5, 16'd 5}; al_accel_cfgreg_sel = 5'd 9;

        #10 // {output2D_size, input2D_size}  
        al_accel_cfgreg_di   = {16'd 25, 16'd 49}; al_accel_cfgreg_sel = 5'd 10;

        #10 // kernel3D_size
        al_accel_cfgreg_di   = {16'd  0, 16'd 27}; al_accel_cfgreg_sel = 5'd 11;

    // Output Quantize Buffer
        #10 // output_quant_sel
        al_accel_cfgreg_di   = {24'd 0, 8'd 0} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 2039693188 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 8} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel
        al_accel_cfgreg_di   = {24'd 0, 8'd 1} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 2097238482 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 8} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel
        al_accel_cfgreg_di   = {24'd 0, 8'd 2} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1378465373 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 8} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel
        al_accel_cfgreg_di   = {24'd 0, 8'd 3} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1543907582 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 9} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel
        al_accel_cfgreg_di   = {24'd 0, 8'd 4} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1858862255 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd10} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel
        al_accel_cfgreg_di   = {24'd 0, 8'd 5} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1117338165 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 8} ; al_accel_cfgreg_sel = 5'd 14;

    // Data Offset
        #10 // input_offset
        al_accel_cfgreg_di   = 32'd 65; al_accel_cfgreg_sel = 5'd 15;
        #10 // output_offset
        al_accel_cfgreg_di   = 32'd 34; al_accel_cfgreg_sel = 5'd 16;

        #10 // {ofm_pool_height,  ofm_pool_width}
        al_accel_cfgreg_di   = {16'd 2, 16'd 2}; al_accel_cfgreg_sel = 5'd 17;
        #10 // output2D_pool_size
        al_accel_cfgreg_di   = 32'd 4; al_accel_cfgreg_sel = 5'd 18;

    // Flow Run
        #10
        al_accel_cfgreg_wenb =  1'd 0;
        #10 
        al_accel_flow_enb    =  1'd 1;
        // #1000
        // al_accel_flow_enb    =  1'd 0;
        // #200
        al_accel_flow_enb    =  1'd 1;
		// repeat (2000) @(posedge clk) begin
        //     #2 al_accel_flow_enb = $random;
        // end
        // #10 
        al_accel_flow_enb    =  1'd 1;
    end

    reg [(7 * 7 * 3 + 1)     * 8 - 1:0] input_data ; // Size: 7 x 7 x 3
    reg [(3 * 3 * 3 * 6 + 2) * 8 - 1:0] filter_data; // Size: 3 x 3 x 3 x 6
    reg [ 6 * 32                 - 1:0] bias_data  ; // Size: 6
    integer i;
    initial begin
        for (i = 0; i < 4096; i = i + 1)
            ram.mem[i] = 32'd 0;

        // Input Initilization
        input_data = {
            /* z = 1 */
                8'd   1, 8'd   2, 8'd   7, 8'd   8,-8'd   1,-8'd  78, 8'd  12,   
                8'd   5, 8'd  45, 8'd  64, 8'd 123,-8'd  89,-8'd  74, 8'd  12,
                8'd   7, 8'd  45, 8'd 123, 8'd  45, 8'd  90, 8'd 101, 8'd  87,
                8'd   1, 8'd   2, 8'd   7, 8'd   8,-8'd   1, 8'd   0,-8'd  19, 
                8'd   5, 8'd  45, 8'd  64, 8'd 123,-8'd  34,-8'd  20, 8'd  75, 
                8'd   7, 8'd  45, 8'd 123, 8'd  45, 8'd  90, 8'd 101, 8'd  96, 
                8'd  15, 8'd  16, 8'd  17, 8'd  18, 8'd  19, 8'd  20, 8'd  21, 
            /* z = 1 */
                  -8'd  90, 8'd   2, 8'd   7, 8'd   8,-8'd  55,-8'd  21, 8'd  10, 
                8'd  51, 8'd  45, 8'd  64, 8'd 123, 8'd  34,-8'd  20, 8'd  10, 
                8'd  57, 8'd  45, 8'd 123, 8'd  45, 8'd  90, 8'd 101, 8'd  21, 
                8'd 110, 8'd   2, 8'd   7, 8'd   8,-8'd  55,-8'd  11, 8'd  22, 
                8'd  51, 8'd  45, 8'd  64, 8'd  23,-8'd  24, 8'd  20, 8'd  88, 
                8'd  71, 8'd  45,-8'd  23, 8'd  45, 8'd  90, 8'd 101, 8'd  66, 
                8'd  15, 8'd  16, 8'd  17, 8'd  18, 8'd  19, 8'd  20, 8'd  21, 
            /* z = 2 */
                8'd   1, 8'd  23, 8'd   7, 8'd   8, 8'd  55, 8'd  21, 8'd  10,
                8'd   5, 8'd   4, 8'd  64, 8'd 123, 8'd  34, 8'd  20, 8'd  21,
                8'd   7, 8'd   5, 8'd 123, 8'd  45, 8'd  90, 8'd 101, 8'd  21,
                8'd   1, 8'd   2, 8'd   7, 8'd   8, 8'd  55,-8'd   1, 8'd  18, 
                8'd   5, 8'd   5, 8'd  64, 8'd  13, 8'd  34, 8'd  20, 8'd  21, 
                8'd  15, 8'd  16, 8'd  17, 8'd  18, 8'd  19, 8'd  20, 8'd  21,
                8'd  23, 8'd  24, 8'd  25, 8'd  26, 8'd  27, 8'd  28, 8'd  29,
            // Padding
                8'd   0
        };

        for (i = 0; i < (IFM_SIZE); i = i + 4) begin
            ram.mem[0 + (i / 4)][ 7: 0] = input_data[8*((IFM_SIZE) - 1 - i) +: 8];
            ram.mem[0 + (i / 4)][15: 8] = input_data[8*((IFM_SIZE) - 2 - i) +: 8];
            ram.mem[0 + (i / 4)][23:16] = input_data[8*((IFM_SIZE) - 3 - i) +: 8];
            ram.mem[0 + (i / 4)][31:24] = input_data[8*((IFM_SIZE) - 4 - i) +: 8];
        end

        // Kernel 
        filter_data = {
            /* Channel = 0 */
                /* z = 0 */
                8'd 10, 8'd 11, 8'd  0, 8'd 10, 8'd  0, 8'd 11, 8'd 11, 8'd 11, 8'd  0,
                /* z = 1 */
                8'd 11, 8'd 11, 8'd  0, 8'd 11, 8'd 11, 8'd  0, 8'd 11, 8'd  0, 8'd 11,
                /* z = 2 */
                8'd 11, 8'd  0, 8'd 11, 8'd 11, 8'd 11, 8'd  0, 8'd 11, 8'd 11, 8'd  0,
            /* Channel = 1 */
                /* z = 0 */
                8'd 11, 8'd 21, 8'd  0, 8'd 21, 8'd  0, 8'd 11, 8'd 21, 8'd 11, 8'd  0,
                /* z = 1 */
                8'd 21, 8'd 11, 8'd  0, 8'd 21, 8'd 11, 8'd  0, 8'd 21, 8'd  0, 8'd 11,
                /* z = 2 */
                8'd 21, 8'd  0, 8'd 11, 8'd 21, 8'd 11, 8'd  0, 8'd 21, 8'd 11, 8'd  0,
            /* Channel = 2 */
                /* z = 0 */
                8'd 11, 8'd 31, 8'd  0, 8'd 11, 8'd  0, 8'd 11, 8'd 11, 8'd 31, 8'd  0,
                /* z = 1 */
                8'd 11, 8'd 31, 8'd  0, 8'd 11, 8'd 31, 8'd  0, 8'd 11, 8'd  0, 8'd 11,
                /* z = 2 */
                8'd 11, 8'd  0, 8'd 11, 8'd 11, 8'd 31, 8'd  0, 8'd 11, 8'd 31, 8'd  0,
            /* Channel = 3 */
                /* z = 0 */
                8'd 11, 8'd 11, 8'd 40, 8'd 11, 8'd 40, 8'd 41, 8'd 21, 8'd 11, 8'd 40,
                /* z = 1 */
                8'd 21, 8'd 11, 8'd 40, 8'd 11, 8'd 41, 8'd 40, 8'd 11, 8'd 40, 8'd 11,
                /* z = 2 */
                8'd 11, 8'd 40, 8'd 41, 8'd 11, 8'd 21, 8'd 40, 8'd 11, 8'd 11, 8'd 40,
            /* Channel = 4 */
                /* z = 0 */
                8'd 11, 8'd 11, 8'd 30, 8'd 11, 8'd 30, 8'd 41, 8'd 21, 8'd 11, 8'd 30,
                /* z = 1 */
                8'd 21, 8'd 11, 8'd 30, 8'd 11, 8'd 41, 8'd 30, 8'd 11, 8'd 30, 8'd 11,
                /* z = 2 */
                8'd 11, 8'd  0, 8'd 41, 8'd 11, 8'd 21, 8'd 30, 8'd 11, 8'd 11, 8'd 30,
            /* Channel = 5 */
                /* z = 0 */
                8'd 11, 8'd 11, 8'd  0, 8'd 11,-8'd 20, 8'd 41, 8'd 21, 8'd 11, 8'd 20,
                /* z = 1 */
                8'd 21, 8'd 11, 8'd 10, 8'd 11, 8'd 41, 8'd 10, 8'd 11, 8'd 10, 8'd 11,
                /* z = 2 */
                8'd 11, 8'd 10, 8'd 21, 8'd 11, 8'd 21, 8'd 10, 8'd 11, 8'd 11, 8'd 10,
            // Padding
                8'd  0, 8'd  0
        }; 

        for (i = 0; i < KER_SIZE; i = i + 4) begin
            ram.mem[1500 + (i / 4)][ 7: 0] = filter_data[8*(KER_SIZE - 1 - i) +: 8];
            ram.mem[1500 + (i / 4)][15: 8] = filter_data[8*(KER_SIZE - 2 - i) +: 8];
            ram.mem[1500 + (i / 4)][23:16] = filter_data[8*(KER_SIZE - 3 - i) +: 8];
            ram.mem[1500 + (i / 4)][31:24] = filter_data[8*(KER_SIZE - 4 - i) +: 8];
        end

        // Bias
        bias_data = {
            32'd 20, 32'd 31, 32'd 42, 32'd 54,-32'd 15, 32'd 67
        };
        for (i = 0; i < BIS_SIZE; i = i + 1) begin
            ram.mem[1400 + i] = bias_data[32*(BIS_SIZE - 1 - i) +: 32];
        end

    end
/*******************/
`elsif CL_TC1
/* Test case 1 */
    /* 
        Description:
           - Input Feature Map's size : 7 x 7 x 6     => 294
           - Kernel's size            : 3 x 3 x 6 x 6 => 324
           - Output Feature Map's size: 5 x 5 x 6     => 150
           - Bias's size              : 6 x 4         =>  24
           - Partial-Sum's size       : 5 x 5 x 6 x 4 => 864
    */

    localparam 
        IFM_SIZE = 7 * 7 * 6     + 2,
        KER_SIZE = 3 * 3 * 6 * 6    ,
        OFM_SIZE = 5 * 5 * 6     + 2,
        BIS_SIZE = 6,
        PAS_SIZE = 5 * 5 * 6,
        OUTPUT_HEIGHT = 5,
        OUTPUT_WIDTH = 5,
        OUTPUT_DEPTH = 6;

    initial begin
        // al_accel_mem_read_ready = 1'b 0;
        // al_accel_mem_write_ready = 1'b 0;
        // #10
        // repeat (2000) @(posedge clk) begin
        //     #2 al_accel_mem_read_ready = $random;
        // end
        // #10 
        al_accel_mem_read_ready    = 1'b 1;
        al_accel_mem_write_ready   = 1'b 1;
    end

    initial begin
        al_accel_cfgreg_di   = 32'd 0;       al_accel_cfgreg_sel = 5'd 0; 
        al_accel_cfgreg_wenb =  1'd 0;
        al_accel_flow_enb    =  1'b 0;
        #42
        al_accel_cfgreg_wenb =  1'd 1;
    // Config Data
        #10 // i_base_addr
        al_accel_cfgreg_di   = 32'd 0000;       al_accel_cfgreg_sel = 5'd 0; 

        #10 // kw_base_addr
        al_accel_cfgreg_di   = 32'd 6000;       al_accel_cfgreg_sel = 5'd 1; 

        #10 // o_base_addr
        al_accel_cfgreg_di   = 32'd 16000;       al_accel_cfgreg_sel = 5'd 2; 

        #10 // b_base_addr
        al_accel_cfgreg_di   = 32'd 5600;       al_accel_cfgreg_sel = 5'd 3; 

        #10 // ps_base_addr
        al_accel_cfgreg_di   = 32'd 20000;       al_accel_cfgreg_sel = 5'd 4; 

        #10 // {stride_height, stride_width, cfg_act_func_typ, cfg_layer_typ}
        al_accel_cfgreg_di   = {16'd 0, 4'd 1, 4'd 1, RELU, CONV}; al_accel_cfgreg_sel = 5'd 5; 

        #10 // {weight_kernel_patch_height, weight_kernel_patch_width}
        al_accel_cfgreg_di   = {16'd  3, 16'd  3}; al_accel_cfgreg_sel = 5'd 6; 

        #10 // {nok_ofm_depth, kernel_ifm_depth} 
        al_accel_cfgreg_di   = {16'd  6, 16'd  6}; al_accel_cfgreg_sel = 5'd 7;

        #10 // {ifm_height, ifm_width}  
        al_accel_cfgreg_di   = {16'd  7, 16'd  7}; al_accel_cfgreg_sel = 5'd 8;

        #10 // {ofm_height, ofm_width}
        al_accel_cfgreg_di   = {16'd  5, 16'd  5}; al_accel_cfgreg_sel = 5'd 9;

        #10 // {output2D_size, input2D_size}  
        al_accel_cfgreg_di   = {16'd 25, 16'd 49}; al_accel_cfgreg_sel = 5'd 10;

        #10 // kernel3D_size
        al_accel_cfgreg_di   = {16'd  0, 16'd 54}; al_accel_cfgreg_sel = 5'd 11;

    // Output Quantize Buffer
        #10 // output_quant_sel
        al_accel_cfgreg_di   = {24'd 0, 8'd 0} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 2039693188 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 8} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel
        al_accel_cfgreg_di   = {24'd 0, 8'd 1} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 2097238482 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 8} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel
        al_accel_cfgreg_di   = {24'd 0, 8'd 2} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1378465373 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 8} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel
        al_accel_cfgreg_di   = {24'd 0, 8'd 3} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1543907582 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 9} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel
        al_accel_cfgreg_di   = {24'd 0, 8'd 4} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1858862255 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd10} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel
        al_accel_cfgreg_di   = {24'd 0, 8'd 5} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1117338165 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 8} ; al_accel_cfgreg_sel = 5'd 14;

    // Data Offset
        #10 // input_offset
        al_accel_cfgreg_di   = 32'd 128; al_accel_cfgreg_sel = 5'd 15;
        #10 // output_offset
        al_accel_cfgreg_di   = 32'd 128; al_accel_cfgreg_sel = 5'd 16;

    // Flow Run
        #10
        al_accel_cfgreg_wenb =  1'd 0;
        #10 
        al_accel_flow_enb    =  1'd 1;
        #1000
        al_accel_flow_enb    =  1'd 0;
        #200
        al_accel_flow_enb    =  1'd 1;
		repeat (2000) @(posedge clk) begin
            #2 al_accel_flow_enb = $random;
        end
        #10 
        al_accel_flow_enb    =  1'd 1;
    end

    reg [(7 * 7 * 6     + 2) * 8 - 1:0] input_data ; // Size: 7 x 7 x 6
    reg [(3 * 3 * 6 * 6    ) * 8 - 1:0] filter_data; // Size: 3 x 3 x 6 x 6
    reg [ 6 * 32                 - 1:0] bias_data  ; // Size: 6
    integer i;
    initial begin
        for (i = 0; i < 4096; i = i + 1)
            ram.mem[i] = 32'd 0;

        // Input Initilization
        input_data = {
            /* z = 0 */
                8'd   1, 8'd   2, 8'd   7, 8'd   8,-8'd   1,-8'd  78, 8'd  12, 
                8'd   5, 8'd  45, 8'd  64, 8'd 123,-8'd  89,-8'd  74, 8'd  12, 
                8'd   7, 8'd  45, 8'd 123, 8'd  45, 8'd  90, 8'd 101, 8'd  87, 
                8'd   1, 8'd   2, 8'd   7, 8'd   8,-8'd   1, 8'd   0,-8'd  19, 
                8'd   5, 8'd  45, 8'd  64, 8'd 123,-8'd  34,-8'd  20, 8'd  75, 
                8'd   7, 8'd  45, 8'd 123, 8'd  45, 8'd  90, 8'd 101, 8'd  96, 
                8'd  15, 8'd  16, 8'd  17, 8'd  18, 8'd  19, 8'd  20, 8'd  21, 
            /* z = 1 */
               -8'd  90, 8'd   2, 8'd   7, 8'd   8,-8'd  55,-8'd  21, 8'd  10,
                8'd  51, 8'd  45, 8'd  64, 8'd 123, 8'd  34,-8'd  20, 8'd  10,
                8'd  57, 8'd  45, 8'd 123, 8'd  45, 8'd  90, 8'd 101, 8'd  21, 
                8'd 110, 8'd   2, 8'd   7, 8'd   8,-8'd  55,-8'd  11, 8'd  22, 
                8'd  51, 8'd  45, 8'd  64, 8'd  23,-8'd  24, 8'd  20, 8'd  88, 
                8'd  71, 8'd  45,-8'd  23, 8'd  45, 8'd  90, 8'd 101, 8'd  66, 
                8'd  15, 8'd  16, 8'd  17, 8'd  18, 8'd  19, 8'd  20, 8'd  21, 
            /* z = 2 */
                8'd   1, 8'd  23, 8'd   7, 8'd   8, 8'd  55, 8'd  21, 8'd  10,
                8'd   5, 8'd   4, 8'd  64, 8'd 123, 8'd  34, 8'd  20, 8'd  21, 
                8'd   7, 8'd   5, 8'd 123, 8'd  45, 8'd  90, 8'd 101, 8'd  21, 
                8'd   1, 8'd   2, 8'd   7, 8'd   8, 8'd  55,-8'd   1, 8'd  18, 
                8'd   5, 8'd   5, 8'd  64, 8'd  13, 8'd  34, 8'd  20, 8'd  21, 
                8'd  15, 8'd  16, 8'd  17, 8'd  18, 8'd  19, 8'd  20, 8'd  21, 
                8'd  23, 8'd  24, 8'd  25, 8'd  26, 8'd  27, 8'd  28, 8'd  29,
            /* z = 3*/
                8'd  23, 8'd  34, 8'd  56, 8'd  12, 8'd  14,-8'd  17,-8'd  19,
                8'd  20, 8'd  21, 8'd 127,-8'd 128, 8'd 110, 8'd 103, 8'd  19,
                8'd   1, 8'd   1, 8'd   1, 8'd   2, 8'd   2, 8'd   2, 8'd   3,
                8'd  45, 8'd  54, 8'd  46, 8'd  64, 8'd  75, 8'd  74, 8'd  10,
                8'd   1, 8'd  23, 8'd   7, 8'd   8, 8'd  55, 8'd  21, 8'd  10,
                8'd   5, 8'd   4, 8'd  64, 8'd 123, 8'd  34, 8'd  20, 8'd  21, 
                8'd   7, 8'd   5, 8'd 123, 8'd  45, 8'd  90, 8'd 101, 8'd  21, 
            /* z = 4*/
                8'd   5, 8'd   5, 8'd  64, 8'd  13, 8'd  34, 8'd  20, 8'd  21,
                8'd  15, 8'd  16, 8'd  17, 8'd  18, 8'd  19, 8'd  20, 8'd  21, 
                8'd  23, 8'd  24, 8'd  25, 8'd  26, 8'd  27, 8'd  28, 8'd  29,
                8'd   1, 8'd   1, 8'd   1, 8'd   2, 8'd   2, 8'd   2, 8'd   3,
                8'd  45, 8'd  54, 8'd  46, 8'd  64, 8'd  75, 8'd  74, 8'd  10,
                8'd   1, 8'd  23, 8'd   7, 8'd   8, 8'd  55, 8'd  21, 8'd  10, 
                8'd   1, 8'd  23, 8'd   7, 8'd   8, 8'd  55, 8'd  21, 8'd  10, 
            /* z = 5*/
               -8'd  90, 8'd   2, 8'd   7, 8'd   8,-8'd  55,-8'd  21, 8'd  10, 
               -8'd  90, 8'd   2, 8'd   7, 8'd   8,-8'd  55,-8'd  21, 8'd  10, 
               -8'd  90, 8'd   2, 8'd   7, 8'd   8,-8'd  55,-8'd  21, 8'd  10, 
                8'd   1, 8'd   2, 8'd   7, 8'd   8, 8'd  55,-8'd   1, 8'd  18, 
                8'd   7, 8'd  45, 8'd 123, 8'd  45, 8'd  90, 8'd 101, 8'd  87, 
                8'd  20, 8'd  21, 8'd 127,-8'd 128, 8'd 110, 8'd 103, 8'd  19,
                8'd  23, 8'd  34, 8'd  56, 8'd  12, 8'd  14,-8'd  17,-8'd  19,
            // Padding
                8'd   0, 8'd   0
        };

        for (i = 0; i < (IFM_SIZE); i = i + 4) begin
            ram.mem[0 + (i / 4)][ 7: 0] = input_data[8*((IFM_SIZE) - 1 - i) +: 8];
            ram.mem[0 + (i / 4)][15: 8] = input_data[8*((IFM_SIZE) - 2 - i) +: 8];
            ram.mem[0 + (i / 4)][23:16] = input_data[8*((IFM_SIZE) - 3 - i) +: 8];
            ram.mem[0 + (i / 4)][31:24] = input_data[8*((IFM_SIZE) - 4 - i) +: 8];
        end

        // Kernel 
        filter_data = {
            /* Channel = 0 */
                /* z = 0 */
                8'd  10, 8'd  11, 8'd   0, 8'd  10, 8'd   0, 8'd  11, 8'd  11, 8'd  11, 8'd   0,
                /* z = 1 */
                8'd  11, 8'd  11, 8'd   0, 8'd  11, 8'd  11, 8'd   0, 8'd  11, 8'd   0, 8'd  11,
                /* z = 2 */
                8'd  11, 8'd   0, 8'd  11, 8'd  11, 8'd  11, 8'd   0, 8'd  11, 8'd  11, 8'd   0,
                /* z = 3*/
                8'd  22, 8'd  33, 8'd  44, 8'd  55, 8'd  66, 8'd  77, 8'd  88, 8'd  99, 8'd 110,
                /* z = 4*/
                8'd  22, 8'd   0, 8'd  22, 8'd  33, 8'd  22, 8'd  33, 8'd  44, 8'd  33, 8'd  22,
                /* z = 5*/
               -8'd   1,-8'd   2,-8'd   3,-8'd  11,-8'd  12,-8'd  13,-8'd  14,-8'd  15,-8'd  16,
            /* Channel = 1 */
                /* z = 0 */
                8'd  11, 8'd  21, 8'd   0, 8'd  21, 8'd   0, 8'd  11, 8'd  21, 8'd  11, 8'd   0,
                /* z = 1 */ 
                8'd  21, 8'd  11, 8'd   0, 8'd  21, 8'd  11, 8'd   0, 8'd  21, 8'd   0, 8'd  11,
                /* z = 2 */
                8'd  21, 8'd   0, 8'd  11, 8'd  21, 8'd  11, 8'd   0, 8'd  21, 8'd  11, 8'd   0,
                /* z = 3*/
                8'd   5, 8'd  10, 8'd  15, 8'd  20, 8'd  25, 8'd  30, 8'd  35, 8'd  40, 8'd  45,
                /* z = 4*/
                8'd  60, 8'd  70, 8'd  80, 8'd  80, 8'd  70, 8'd  60, 8'd  70, 8'd  80, 8'd  60,
                /* z = 5*/
                8'd  11, 8'd  22, 8'd  33, 8'd  44, 8'd  55, 8'd  66, 8'd  77, 8'd  88, 8'd  99,
            /* Channel = 2 */
                /* z = 0 */
                8'd  11, 8'd  31, 8'd   0, 8'd  11, 8'd   0, 8'd  11, 8'd  11, 8'd  31, 8'd   0,
                /* z = 1 */
                8'd  11, 8'd  31, 8'd   0, 8'd  11, 8'd  31, 8'd   0, 8'd  11, 8'd   0, 8'd  11,
                /* z = 2 */
                8'd  11, 8'd   0, 8'd  11, 8'd  11, 8'd  31, 8'd   0, 8'd  11, 8'd  31, 8'd   0,
                /* z = 3*/
               -8'd   5, 8'd  10, 8'd  15, 8'd  20,-8'd  25, 8'd  30, 8'd  35, 8'd  40,-8'd  45,
                /* z = 4*/
               -8'd  60, 8'd  70, 8'd  80, 8'd  80,-8'd  70, 8'd  60, 8'd  70, 8'd  80,-8'd  60,
                /* z = 5*/
               -8'd  11, 8'd  22, 8'd  33, 8'd  44,-8'd  55, 8'd  66, 8'd  77, 8'd  88,-8'd  99,
            /* Channel = 3 */
                /* z = 0 */
                8'd  11, 8'd  11, 8'd  40, 8'd  11, 8'd  40, 8'd  41, 8'd  21, 8'd  11, 8'd  40,
                /* z = 1 */
                8'd  21, 8'd  11, 8'd  40, 8'd  11, 8'd  41, 8'd  40, 8'd  11, 8'd  40, 8'd  11,
                /* z = 2 */
                8'd  11, 8'd  40, 8'd  41, 8'd  11, 8'd  21, 8'd  40, 8'd  11, 8'd  11, 8'd  40,
                /* z = 3*/
               -8'd   5, 8'd  10, 8'd  15,-8'd  20, 8'd  25, 8'd  30,-8'd  35, 8'd  40, 8'd  45,
                /* z = 4*/
               -8'd  60, 8'd  70, 8'd  80,-8'd  80, 8'd  70, 8'd  60,-8'd  70, 8'd  80, 8'd  60,
                /* z = 5*/
               -8'd  11, 8'd  22, 8'd  33,-8'd  44, 8'd  55, 8'd  66,-8'd  77, 8'd  88, 8'd  99,
            /* Channel = 4 */
                /* z = 0 */
                8'd  11, 8'd  11, 8'd  30, 8'd  11, 8'd  30, 8'd  41, 8'd  21, 8'd  11, 8'd  30,
                /* z = 1 */
                8'd  21, 8'd  11, 8'd  30, 8'd  11, 8'd  41, 8'd  30, 8'd  11, 8'd  30, 8'd  11,
                /* z = 2 */
                8'd  11, 8'd   0, 8'd  41, 8'd  11, 8'd  21, 8'd  30, 8'd  11, 8'd  11, 8'd  30,
                /* z = 3*/
                8'd   5,-8'd  10, 8'd  15, 8'd  20,-8'd  25, 8'd  30, 8'd  35,-8'd  40, 8'd  45,
                /* z = 4*/
                8'd  60,-8'd  70, 8'd  80, 8'd  80,-8'd  70, 8'd  60, 8'd  70,-8'd  80, 8'd  60,
                /* z = 5*/
                8'd  11,-8'd  22, 8'd  33, 8'd  44,-8'd  55, 8'd  66, 8'd  77,-8'd  88, 8'd  99,
            /* Channel = 5 */
                /* z = 0 */
                8'd  11, 8'd  11, 8'd   0, 8'd  11,-8'd  20, 8'd  41, 8'd  21, 8'd  11, 8'd  20,
                /* z = 1 */
                8'd  21, 8'd  11, 8'd  10, 8'd  11, 8'd  41, 8'd  10, 8'd  11, 8'd  10, 8'd  11,
                /* z = 2 */
                8'd  11, 8'd  10, 8'd  21, 8'd  11, 8'd  21, 8'd  10, 8'd  11, 8'd  11, 8'd  10,
                /* z = 3*/
                8'd   5, 8'd  10,-8'd  15, 8'd  20,-8'd  25, 8'd  30,-8'd  35, 8'd  40, 8'd  45,
                /* z = 4*/
                8'd  60, 8'd  70,-8'd  80, 8'd  80,-8'd  70, 8'd  60,-8'd  70, 8'd  80, 8'd  60,
                /* z = 5*/
                8'd  11, 8'd  22,-8'd  33, 8'd  44,-8'd  55, 8'd  66,-8'd  77, 8'd  88, 8'd  99
        }; 

        for (i = 0; i < KER_SIZE; i = i + 4) begin
            ram.mem[1500 + (i / 4)][ 7: 0] = filter_data[8*(KER_SIZE - 1 - i) +: 8];
            ram.mem[1500 + (i / 4)][15: 8] = filter_data[8*(KER_SIZE - 2 - i) +: 8];
            ram.mem[1500 + (i / 4)][23:16] = filter_data[8*(KER_SIZE - 3 - i) +: 8];
            ram.mem[1500 + (i / 4)][31:24] = filter_data[8*(KER_SIZE - 4 - i) +: 8];
        end

        // Bias
        bias_data = {
            32'd 20, 
            32'd 31, 
            32'd 42, 
            32'd 54,
           -32'd 15, 
            32'd 67
        };

        for (i = 0; i < BIS_SIZE; i = i + 1) begin
            ram.mem[1400 + i] = bias_data[32*(BIS_SIZE - 1 - i) +: 32];
        end

    end
/*******************/
`elsif CL_TC2
/* Test case 2 */
    /* 
        Description:
           - Input Feature Map's size : 7 x 7 x 9     => 441
           - Kernel's size            : 3 x 3 x 9 x 9 => 729
           - Output Feature Map's size: 5 x 5 x 9     => 225
           - Bias's size              : 9 x 4         =>  36
           - Partial-Sum's size       : 5 x 5 x 9 x 4 => 900
    */
    localparam 
        IFM_SIZE = 7 * 7 * 9     + 3,
        KER_SIZE = 3 * 3 * 9 * 9 + 3,
        OFM_SIZE = 5 * 5 * 9     + 3,
        BIS_SIZE = 9,
        PAS_SIZE = 5 * 5 * 9,
        OUTPUT_HEIGHT = 5,
        OUTPUT_WIDTH = 5,
        OUTPUT_DEPTH = 9;

    initial begin
        al_accel_mem_read_ready    = 1'b 1;
        al_accel_mem_write_ready   = 1'b 1;
    end

    initial begin
        al_accel_cfgreg_di   = 32'd 0;       al_accel_cfgreg_sel = 5'd 0; 
        al_accel_cfgreg_wenb =  1'd 0;
        al_accel_flow_enb    =  1'b 0;
        #42
        al_accel_cfgreg_wenb =  1'd 1;
    // Config Data
        #10 // i_base_addr
        al_accel_cfgreg_di   = 32'd 0000;       al_accel_cfgreg_sel = 5'd 0; 

        #10 // kw_base_addr
        al_accel_cfgreg_di   = 32'd 6000;       al_accel_cfgreg_sel = 5'd 1; 

        #10 // o_base_addr
        al_accel_cfgreg_di   = 32'd 16000;       al_accel_cfgreg_sel = 5'd 2; 

        #10 // b_base_addr
        al_accel_cfgreg_di   = 32'd 5600;       al_accel_cfgreg_sel = 5'd 3; 

        #10 // ps_base_addr
        al_accel_cfgreg_di   = 32'd 20000;       al_accel_cfgreg_sel = 5'd 4; 

        #10 // {stride_height, stride_width, cfg_act_func_typ, cfg_layer_typ}
        al_accel_cfgreg_di   = {16'd 0, 4'd 1, 4'd 1, RELU, CONV}; al_accel_cfgreg_sel = 5'd 5; 

        #10 // {weight_kernel_patch_height, weight_kernel_patch_width}
        al_accel_cfgreg_di   = {16'd 3, 16'd 3}; al_accel_cfgreg_sel = 5'd 6; 

        #10 // {nok_ofm_depth, kernel_ifm_depth} 
        al_accel_cfgreg_di   = {16'd 9, 16'd 9}; al_accel_cfgreg_sel = 5'd 7;

        #10 // {ifm_height, ifm_width}  
        al_accel_cfgreg_di   = {16'd 7, 16'd 7}; al_accel_cfgreg_sel = 5'd 8;

        #10 // {ofm_height, ofm_width}
        al_accel_cfgreg_di   = {16'd 5, 16'd 5}; al_accel_cfgreg_sel = 5'd 9;

        #10 // {output2D_size, input2D_size}  
        al_accel_cfgreg_di   = {16'd 25, 16'd 49} ; al_accel_cfgreg_sel = 5'd 10;

        #10 // kernel3D_size 
        al_accel_cfgreg_di   = {16'd  0, 16'd 81} ; al_accel_cfgreg_sel = 5'd 11;

    // Output Quantize Buffer
        #10 // output_quant_sel
        al_accel_cfgreg_di   = {24'd 0, 8'd 0} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 2039693188 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 8} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel
        al_accel_cfgreg_di   = {24'd 0, 8'd 1} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 2097238482 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 8} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel
        al_accel_cfgreg_di   = {24'd 0, 8'd 2} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1378465373 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 8} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel
        al_accel_cfgreg_di   = {24'd 0, 8'd 3} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1543907582 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 9} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel
        al_accel_cfgreg_di   = {24'd 0, 8'd 4} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1858862255 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd10} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel
        al_accel_cfgreg_di   = {24'd 0, 8'd 5} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1117338165 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 8} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel
        al_accel_cfgreg_di   = {24'd 0, 8'd 6} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1644917525 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 9} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel
        al_accel_cfgreg_di   = {24'd 0, 8'd 7} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1086964334 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 8} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel
        al_accel_cfgreg_di   = {24'd 0, 8'd 8} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1222442873 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 9} ; al_accel_cfgreg_sel = 5'd 14;

    // Data Offset
        #10 // input_offset
        al_accel_cfgreg_di   =-32'd  12; al_accel_cfgreg_sel = 5'd 15;
        #10 // output_offset
        al_accel_cfgreg_di   = 32'd  34; al_accel_cfgreg_sel = 5'd 16;

    // Flow Run
        #10
        al_accel_cfgreg_wenb =  1'd 0;
        #10 
        al_accel_flow_enb    =  1'd 1;
        #1000
        al_accel_flow_enb    =  1'd 0;
        #200
        al_accel_flow_enb    =  1'd 1;
		repeat (2000) @(posedge clk) begin
            #2 al_accel_flow_enb = $random;
        end
        #10 
        al_accel_flow_enb    =  1'd 1;
    end

    reg [IFM_SIZE *  8 - 1:0]  input_data ; // Size: 7 x 7 x 9
    reg [KER_SIZE *  8 - 1:0]  filter_data; // Size: 3 x 3 x 9 x 9
    reg [BIS_SIZE * 32 - 1:0]  bias_data  ; // Size: 9
    integer i;
    initial begin
        for (i = 0; i < 4096; i = i + 1)
            ram.mem[i] = 32'd 0;

        // Input Initilization
        input_data = {
        /* z = 0 */
            8'd   1, 8'd   2, 8'd   7, 8'd   8,-8'd   1,-8'd  78, 8'd  12,
            8'd   5, 8'd  45, 8'd  64, 8'd 123,-8'd  89,-8'd  74, 8'd  12,
            8'd   7, 8'd  45, 8'd 123, 8'd  45, 8'd  90, 8'd 101, 8'd  87,
            8'd   1, 8'd   2, 8'd   7, 8'd   8,-8'd   1, 8'd   0,-8'd  19,
            8'd   5, 8'd  45, 8'd  64, 8'd 123,-8'd  34,-8'd  20, 8'd  75,
            8'd   7, 8'd  45, 8'd 123, 8'd  45, 8'd  90, 8'd 101, 8'd  96,
            8'd  15, 8'd  16, 8'd  17, 8'd  18, 8'd  19, 8'd  20, 8'd  21,
        /* z = 1 */
           -8'd  90, 8'd   2, 8'd   7, 8'd   8,-8'd  55,-8'd  21, 8'd  10,
            8'd  51, 8'd  45, 8'd  64, 8'd 123, 8'd  34,-8'd  20, 8'd  10,
            8'd  57, 8'd  45, 8'd 123, 8'd  45, 8'd  90, 8'd 101, 8'd  21,
            8'd 110, 8'd   2, 8'd   7, 8'd   8,-8'd  55,-8'd  11, 8'd  22,
            8'd  51, 8'd  45, 8'd  64, 8'd  23,-8'd  24, 8'd  20, 8'd  88,
            8'd  71, 8'd  45,-8'd  23, 8'd  45, 8'd  90, 8'd 101, 8'd  66,
            8'd  15, 8'd  16, 8'd  17, 8'd  18, 8'd  19, 8'd  20, 8'd  21,
        /* z = 2 */
            8'd   1, 8'd  23, 8'd   7, 8'd   8, 8'd  55, 8'd  21, 8'd  10,
            8'd   5, 8'd   4, 8'd  64, 8'd 123, 8'd  34, 8'd  20, 8'd  21,
            8'd   7, 8'd   5, 8'd 123, 8'd  45, 8'd  90, 8'd 101, 8'd  21,
            8'd   1, 8'd   2, 8'd   7, 8'd   8, 8'd  55,-8'd   1, 8'd  18,
            8'd   5, 8'd   5, 8'd  64, 8'd  13, 8'd  34, 8'd  20, 8'd  21,
            8'd  15, 8'd  16, 8'd  17, 8'd  18, 8'd  19, 8'd  20, 8'd  21,
            8'd  23, 8'd  24, 8'd  25, 8'd  26, 8'd  27, 8'd  28, 8'd  29,
        /* z = 3*/
            8'd  23, 8'd  34, 8'd  56, 8'd  12, 8'd  14,-8'd  17,-8'd  19,
            8'd  20, 8'd  21, 8'd 127,-8'd 128, 8'd 110, 8'd 103, 8'd  19,
            8'd   1, 8'd   1, 8'd   1, 8'd   2, 8'd   2, 8'd   2, 8'd   3,
            8'd  45, 8'd  54, 8'd  46, 8'd  64, 8'd  75, 8'd  74, 8'd  10,
            8'd   1, 8'd  23, 8'd   7, 8'd   8, 8'd  55, 8'd  21, 8'd  10,
            8'd   5, 8'd   4, 8'd  64, 8'd 123, 8'd  34, 8'd  20, 8'd  21,
            8'd   7, 8'd   5, 8'd 123, 8'd  45, 8'd  90, 8'd 101, 8'd  21,
        /* z = 4*/
            8'd   5, 8'd   5, 8'd  64, 8'd  13, 8'd  34, 8'd  20, 8'd  21,
            8'd  15, 8'd  16, 8'd  17, 8'd  18, 8'd  19, 8'd  20, 8'd  21,
            8'd  23, 8'd  24, 8'd  25, 8'd  26, 8'd  27, 8'd  28, 8'd  29,
            8'd   1, 8'd   1, 8'd   1, 8'd   2, 8'd   2, 8'd   2, 8'd   3,
            8'd  45, 8'd  54, 8'd  46, 8'd  64, 8'd  75, 8'd  74, 8'd  10,
            8'd   1, 8'd  23, 8'd   7, 8'd   8, 8'd  55, 8'd  21, 8'd  10,
            8'd   1, 8'd  23, 8'd   7, 8'd   8, 8'd  55, 8'd  21, 8'd  10,
        /* z = 5*/
           -8'd  90, 8'd   2, 8'd   7, 8'd   8,-8'd  55,-8'd  21, 8'd  10,
           -8'd  90, 8'd   2, 8'd   7, 8'd   8,-8'd  55,-8'd  21, 8'd  10,
           -8'd  90, 8'd   2, 8'd   7, 8'd   8,-8'd  55,-8'd  21, 8'd  10,
            8'd   1, 8'd   2, 8'd   7, 8'd   8, 8'd  55,-8'd   1, 8'd  18,
            8'd   7, 8'd  45, 8'd 123, 8'd  45, 8'd  90, 8'd 101, 8'd  87,
            8'd  20, 8'd  21, 8'd 127,-8'd 128, 8'd 110, 8'd 103, 8'd  19,
            8'd  23, 8'd  34, 8'd  56, 8'd  12, 8'd  14,-8'd  17,-8'd  19,
        /* z = 6*/
            8'd  23, 8'd  34, 8'd  56, 8'd  12, 8'd  14,-8'd  17,-8'd  19,
            8'd  20, 8'd  21, 8'd 127,-8'd 128, 8'd 110, 8'd 103, 8'd  19,
            8'd   1, 8'd   1, 8'd   1, 8'd   2, 8'd   2, 8'd   2, 8'd   3,
            8'd  45, 8'd  54, 8'd  46, 8'd  64, 8'd  75, 8'd  74, 8'd  10,
            8'd   1, 8'd  23, 8'd   7, 8'd   8, 8'd  55, 8'd  21, 8'd  10,
            8'd   5, 8'd   4, 8'd  64, 8'd 123, 8'd  34, 8'd  20, 8'd  21,
            8'd   7, 8'd   5, 8'd 123, 8'd  45, 8'd  90, 8'd 101, 8'd  21,
        /* z = 7*/
            8'd   5, 8'd   5, 8'd  64, 8'd  13, 8'd  34, 8'd  20, 8'd  21,
            8'd  15, 8'd  16, 8'd  17, 8'd  18, 8'd  19, 8'd  20, 8'd  21,
            8'd  23, 8'd  24, 8'd  25, 8'd  26, 8'd  27, 8'd  28, 8'd  29,
            8'd   1, 8'd   1, 8'd   1, 8'd   2, 8'd   2, 8'd   2, 8'd   3,
            8'd  45, 8'd  54, 8'd  46, 8'd  64, 8'd  75, 8'd  74, 8'd  10,
            8'd   1, 8'd  23, 8'd   7, 8'd   8, 8'd  55, 8'd  21, 8'd  10,
            8'd   1, 8'd  23, 8'd   7, 8'd   8, 8'd  55, 8'd  21, 8'd  10,
        /* z = 8*/
           -8'd  90, 8'd   2, 8'd   7, 8'd   8,-8'd  55,-8'd  21, 8'd  10,
           -8'd  90, 8'd   2, 8'd   7, 8'd   8,-8'd  55,-8'd  21, 8'd  10,
           -8'd  90, 8'd   2, 8'd   7, 8'd   8,-8'd  55,-8'd  21, 8'd  10,
            8'd   1, 8'd   2, 8'd   7, 8'd   8, 8'd  55,-8'd   1, 8'd  18,
            8'd   7, 8'd  45, 8'd 123, 8'd  45, 8'd  90, 8'd 101, 8'd  87,
            8'd  20, 8'd  21, 8'd 127,-8'd 128, 8'd 110, 8'd 103, 8'd  19,
            8'd  23, 8'd  34, 8'd  56, 8'd  12, 8'd  14,-8'd  17,-8'd  19,
        // Padding
            8'd   0, 8'd   0, 8'd   0
        };

        for (i = 0; i < (IFM_SIZE); i = i + 4) begin
            ram.mem[0 + (i / 4)][ 7: 0] = input_data[8*((IFM_SIZE) - 1 - i) +: 8];
            ram.mem[0 + (i / 4)][15: 8] = input_data[8*((IFM_SIZE) - 2 - i) +: 8];
            ram.mem[0 + (i / 4)][23:16] = input_data[8*((IFM_SIZE) - 3 - i) +: 8];
            ram.mem[0 + (i / 4)][31:24] = input_data[8*((IFM_SIZE) - 4 - i) +: 8];
        end

        // Kernel 
        filter_data = {
    /* Channel = 0 */
        /* z = 0 */
            8'd  10, 8'd  11, 8'd   0,
            8'd  10, 8'd   0, 8'd  11,
            8'd  11, 8'd  11, 8'd   0,
        /* z = 1 */
            8'd  11, 8'd  11, 8'd   0,
            8'd  11, 8'd  11, 8'd   0,
            8'd  11, 8'd   0, 8'd  11,
        /* z = 2 */
            8'd  11, 8'd   0, 8'd  11,
            8'd  11, 8'd  11, 8'd   0,
            8'd  11, 8'd  11, 8'd   0,
        /* z = 3 */
            8'd  22, 8'd  33, 8'd  44,
            8'd  55, 8'd  66, 8'd  77,
            8'd  88, 8'd  99, 8'd 110,
        /* z = 4 */
            8'd  22, 8'd   0, 8'd  22,
            8'd  33, 8'd  22, 8'd  33,
            8'd  44, 8'd  33, 8'd  22,
        /* z = 5 */
           -8'd   1,-8'd   2,-8'd   3,
           -8'd  11,-8'd  12,-8'd  13,
           -8'd  14,-8'd  15,-8'd  16,
        /* z = 6 */
            8'd  11, 8'd  11, 8'd   0,
            8'd  11, 8'd  11, 8'd   0,
            8'd  11, 8'd   0, 8'd  11,
        /* z = 7 */
            8'd  11, 8'd   0, 8'd  11,
            8'd  11, 8'd  11, 8'd   0,
            8'd  11, 8'd  11, 8'd   0,
        /* z = 8 */
            8'd  22, 8'd  33, 8'd  44,
            8'd  55, 8'd  66, 8'd  77,
            8'd  88, 8'd  99, 8'd 110,
    /* Channel = 1 */
        /* z = 0 */
            8'd  11, 8'd  21, 8'd   0,
            8'd  21, 8'd   0, 8'd  11,
            8'd  21, 8'd  11, 8'd   0,
        /* z = 1 */
            8'd  21, 8'd  11, 8'd   0,
            8'd  21, 8'd  11, 8'd   0,
            8'd  21, 8'd   0, 8'd  11,
        /* z = 2 */
            8'd  21, 8'd   0, 8'd  11,
            8'd  21, 8'd  11, 8'd   0,
            8'd  21, 8'd  11, 8'd   0,
        /* z = 3 */
            8'd   5, 8'd  10, 8'd  15,
            8'd  20, 8'd  25, 8'd  30,
            8'd  35, 8'd  40, 8'd  45,
        /* z = 4 */
            8'd  60, 8'd  70, 8'd  80,
            8'd  80, 8'd  70, 8'd  60,
            8'd  70, 8'd  80, 8'd  60,
        /* z = 5 */
            8'd  11, 8'd  22, 8'd  33,
            8'd  44, 8'd  55, 8'd  66,
            8'd  77, 8'd  88, 8'd  99,
        /* z = 6 */
            8'd  11, 8'd  11, 8'd   0,
            8'd  11, 8'd  11, 8'd   0,
            8'd  11, 8'd   0, 8'd  11,
        /* z = 7 */
            8'd  11, 8'd   0, 8'd  11,
            8'd  11, 8'd  11, 8'd   0,
            8'd  11, 8'd  11, 8'd   0,
        /* z = 8 */
            8'd  22, 8'd  33, 8'd  44,
            8'd  55, 8'd  66, 8'd  77,
            8'd  88, 8'd  99, 8'd 110,
    /* Channel = 2 */
        /* z = 0 */
            8'd  11, 8'd  31, 8'd   0,
            8'd  11, 8'd   0, 8'd  11,
            8'd  11, 8'd  31, 8'd   0,
        /* z = 1 */
            8'd  11, 8'd  31, 8'd   0,
            8'd  11, 8'd  31, 8'd   0,
            8'd  11, 8'd   0, 8'd  11,
        /* z = 2 */
            8'd  11, 8'd   0, 8'd  11,
            8'd  11, 8'd  31, 8'd   0,
            8'd  11, 8'd  31, 8'd   0,
        /* z = 3 */
           -8'd   5, 8'd  10, 8'd  15,
            8'd  20,-8'd  25, 8'd  30,
            8'd  35, 8'd  40,-8'd  45,
        /* z = 4 */
           -8'd  60, 8'd  70, 8'd  80,
            8'd  80,-8'd  70, 8'd  60,
            8'd  70, 8'd  80,-8'd  60,
        /* z = 5 */
           -8'd  11, 8'd  22, 8'd  33,
            8'd  44,-8'd  55, 8'd  66,
            8'd  77, 8'd  88,-8'd  99,
        /* z = 6 */
            8'd  11, 8'd  31, 8'd   0,
            8'd  11, 8'd   0, 8'd  11,
            8'd  11, 8'd  31, 8'd   0,
        /* z = 7 */
            8'd  11, 8'd  31, 8'd   0,
            8'd  11, 8'd  31, 8'd   0,
            8'd  11, 8'd   0, 8'd  11,
        /* z = 8 */
            8'd  11, 8'd   0, 8'd  11,
            8'd  11, 8'd  31, 8'd   0,
            8'd  11, 8'd  31, 8'd   0,
    /* Channel = 3 */
        /* z = 0 */
            8'd  11, 8'd  11, 8'd  40,
            8'd  11, 8'd  40, 8'd  41,
            8'd  21, 8'd  11, 8'd  40,
        /* z = 1 */
            8'd  21, 8'd  11, 8'd  40,
            8'd  11, 8'd  41, 8'd  40,
            8'd  11, 8'd  40, 8'd  11,
        /* z = 2 */
            8'd  11, 8'd  40, 8'd  41,
            8'd  11, 8'd  21, 8'd  40,
            8'd  11, 8'd  11, 8'd  40,
        /* z = 3*/
           -8'd   5, 8'd  10, 8'd  15,
           -8'd  20, 8'd  25, 8'd  30,
           -8'd  35, 8'd  40, 8'd  45,
        /* z = 4*/
           -8'd  60, 8'd  70, 8'd  80,
           -8'd  80, 8'd  70, 8'd  60,
           -8'd  70, 8'd  80, 8'd  60,
        /* z = 5*/
           -8'd  11, 8'd  22, 8'd  33,
           -8'd  44, 8'd  55, 8'd  66,
           -8'd  77, 8'd  88, 8'd  99,
        /* z = 6 */
            8'd  11, 8'd  11, 8'd   0,
            8'd  11, 8'd  11, 8'd   0,
            8'd  11, 8'd   0, 8'd  11,
        /* z = 7 */
            8'd  11, 8'd  31, 8'd   0,
            8'd  11, 8'd  31, 8'd   0,
            8'd  11, 8'd   0, 8'd  11,
        /* z = 8 */
            8'd  11, 8'd   0, 8'd  11,
            8'd  11, 8'd  31, 8'd   0,
            8'd  11, 8'd  31, 8'd   0,
    /* Channel = 4 */
        /* z = 0 */
            8'd  11, 8'd  11, 8'd  30,
            8'd  11, 8'd  30, 8'd  41,
            8'd  21, 8'd  11, 8'd  30,
        /* z = 1 */
            8'd  21, 8'd  11, 8'd  30,
            8'd  11, 8'd  41, 8'd  30,
            8'd  11, 8'd  30, 8'd  11,
        /* z = 2 */
            8'd  11, 8'd   0, 8'd  41,
            8'd  11, 8'd  21, 8'd  30,
            8'd  11, 8'd  11, 8'd  30,
        /* z = 3*/
            8'd   5,-8'd  10, 8'd  15,
            8'd  20,-8'd  25, 8'd  30,
            8'd  35,-8'd  40, 8'd  45,
        /* z = 4*/
            8'd  60,-8'd  70, 8'd  80,
            8'd  80,-8'd  70, 8'd  60,
            8'd  70,-8'd  80, 8'd  60,
        /* z = 5*/
            8'd  11,-8'd  22, 8'd  33,
            8'd  44,-8'd  55, 8'd  66,
            8'd  77,-8'd  88, 8'd  99,
        /* z = 6 */
            8'd  11, 8'd  11, 8'd   0,
            8'd  11, 8'd  11, 8'd   0,
            8'd  11, 8'd   0, 8'd  11,
        /* z = 7 */
            8'd  11, 8'd  31, 8'd   0,
            8'd  11, 8'd  31, 8'd   0,
            8'd  11, 8'd   0, 8'd  11,
        /* z = 8 */
            8'd  11, 8'd   0, 8'd  11,
            8'd  11, 8'd  31, 8'd   0,
            8'd  11, 8'd  31, 8'd   0,
    /* Channel = 5 */
        /* z = 0 */
            8'd  11, 8'd  11, 8'd   0,
            8'd  11,-8'd  20, 8'd  41,
            8'd  21, 8'd  11, 8'd  20,
        /* z = 1 */
            8'd  21, 8'd  11, 8'd  10,
            8'd  11, 8'd  41, 8'd  10,
            8'd  11, 8'd  10, 8'd  11,
        /* z = 2 */
            8'd  11, 8'd  10, 8'd  21,
            8'd  11, 8'd  21, 8'd  10,
            8'd  11, 8'd  11, 8'd  10,
        /* z = 3 */
            8'd   5, 8'd  10,-8'd  15,
            8'd  20,-8'd  25, 8'd  30,
           -8'd  35, 8'd  40, 8'd  45,
        /* z = 4 */
            8'd  60, 8'd  70,-8'd  80,
            8'd  80,-8'd  70, 8'd  60,
           -8'd  70, 8'd  80, 8'd  60,
        /* z = 5 */
            8'd  11, 8'd  22,-8'd  33,
            8'd  44,-8'd  55, 8'd  66,
           -8'd  77, 8'd  88, 8'd  99,
        /* z = 6 */
           -8'd   5, 8'd  10, 8'd  15,
           -8'd  20, 8'd  25, 8'd  30,
           -8'd  35, 8'd  40, 8'd  45,
        /* z = 7 */
           -8'd  60, 8'd  70, 8'd  80,
           -8'd  80, 8'd  70, 8'd  60,
           -8'd  70, 8'd  80, 8'd  60,
        /* z = 8 */
           -8'd  11, 8'd  22, 8'd  33,
           -8'd  44, 8'd  55, 8'd  66,
           -8'd  77, 8'd  88, 8'd  99,
    /* Channel = 6 */
        /* z = 0 */
            8'd  1, 8'd  2, 8'd  3,
            8'd  4, 8'd  5, 8'd  6,
            8'd  7, 8'd  8, 8'd  9,
        /* z = 1 */
           -8'd  1, 8'd  2, 8'd  3,
           -8'd  4, 8'd  5, 8'd  6,
           -8'd  7, 8'd  8, 8'd  9,
        /* z = 2 */
            8'd  1,-8'd  2, 8'd  3,
            8'd  4,-8'd  5, 8'd  6,
            8'd  7,-8'd  8, 8'd  9,
        /* z = 3 */
            8'd  1, 8'd  2,-8'd  3,
            8'd  4, 8'd  5,-8'd  6,
            8'd  7, 8'd  8,-8'd  9,
        /* z = 4 */
           -8'd  1,-8'd  2,-8'd  3,
            8'd  4, 8'd  5, 8'd  6,
            8'd  7, 8'd  8, 8'd  9,
        /* z = 5 */
            8'd  1, 8'd  2, 8'd  3,
           -8'd  4,-8'd  5,-8'd  6,
            8'd  7, 8'd  8, 8'd  9,
        /* z = 6 */
            8'd  1, 8'd  2, 8'd  3,
            8'd  4, 8'd  5, 8'd  6,
           -8'd  7,-8'd  8,-8'd  9,
        /* z = 7 */
           -8'd  1, 8'd  2, 8'd  3,
            8'd  4,-8'd  5, 8'd  6,
            8'd  7, 8'd  8,-8'd  9,
        /* z = 8 */
            8'd  1, 8'd  2,-8'd  3,
            8'd  4,-8'd  5, 8'd  6,
           -8'd  7, 8'd  8, 8'd  9,
    /* Channel = 7 */
        /* z = 0 */
            8'd  1, 8'd  2, 8'd  30,
            8'd  4, 8'd  5, 8'd   6,
            8'd  7, 8'd  8, 8'd   9,
        /* z = 1 */
           -8'd  1, 8'd  2, 8'd   3,
           -8'd  4, 8'd  5, 8'd   6,
           -8'd  7, 8'd  8, 8'd  90,
        /* z = 2 */
            8'd   1,-8'd  2, 8'd  3,
            8'd  40,-8'd  5, 8'd  6,
            8'd   7,-8'd  8, 8'd  9,
        /* z = 3 */
            8'd  1, 8'd  20,-8'd  3,
            8'd  4, 8'd   5,-8'd  6,
            8'd  7, 8'd   8,-8'd  9,
        /* z = 4 */
           -8'd   1,-8'd  2,-8'd   3,
            8'd  40, 8'd  5, 8'd   6,
            8'd   7, 8'd  8, 8'd  90,
        /* z = 5 */
            8'd  1, 8'd  2, 8'd  3,
           -8'd  4,-8'd  5,-8'd  6,
            8'd  7, 8'd  8, 8'd  9,
        /* z = 6 */
            8'd  1, 8'd  20, 8'd   3,
            8'd  4, 8'd   5, 8'd  60,
           -8'd  7,-8'd   8,-8'd   9,
        /* z = 7 */
           -8'd  1, 8'd  2, 8'd   3,
            8'd  4,-8'd  5, 8'd  60,
            8'd  7, 8'd  8,-8'd   9,
        /* z = 8 */
            8'd  10, 8'd  2,-8'd  3,
            8'd   4,-8'd  5, 8'd  6,
           -8'd   7, 8'd  8, 8'd  9,
    /* Channel = 8 */
        /* z = 0 */
            8'd  1, 8'd  2, 8'd  3,
            8'd  4, 8'd  5, 8'd  6,
            8'd  7, 8'd  8, 8'd  9,
        /* z = 1 */
           -8'd  1, 8'd   2, 8'd  3,
           -8'd  4, 8'd  50, 8'd  6,
           -8'd  7, 8'd   8, 8'd  9,
        /* z = 2 */
            8'd   1,-8'd  2, 8'd  3,
            8'd  40,-8'd  5, 8'd  6,
            8'd   7,-8'd  8, 8'd  9,
        /* z = 3 */
            8'd  1, 8'd  2,-8'd  3,
            8'd  4, 8'd  5,-8'd  6,
            8'd  7, 8'd  8,-8'd  9,
        /* z = 4 */
           -8'd  1,-8'd   2,-8'd  3,
            8'd  4, 8'd  50, 8'd  6,
            8'd  7, 8'd   8, 8'd  9,
        /* z = 5 */
            8'd  1, 8'd  20, 8'd  3,
           -8'd  4,-8'd   5,-8'd  6,
            8'd  7, 8'd  80, 8'd  9,
        /* z = 6 */
            8'd  1, 8'd  20, 8'd   3,
            8'd  4, 8'd   5, 8'd   6,
           -8'd  7,-8'd   8,-8'd  90,
        /* z = 7 */
           -8'd  10, 8'd   2, 8'd  3,
            8'd   4,-8'd  50, 8'd  6,
            8'd   7, 8'd   8,-8'd  9,
        /* z = 8 */
            8'd  10, 8'd   2,-8'd   3,
            8'd  40,-8'd   5, 8'd  60,
           -8'd  70, 8'd  80, 8'd  90,
    // Padding
            8'd   0, 8'd   0, 8'd   0
        }; 
        
        for (i = 0; i < KER_SIZE; i = i + 4) begin
            ram.mem[1500 + (i / 4)][ 7: 0] = filter_data[8*(KER_SIZE - 1 - i) +: 8];
            ram.mem[1500 + (i / 4)][15: 8] = filter_data[8*(KER_SIZE - 2 - i) +: 8];
            ram.mem[1500 + (i / 4)][23:16] = filter_data[8*(KER_SIZE - 3 - i) +: 8];
            ram.mem[1500 + (i / 4)][31:24] = filter_data[8*(KER_SIZE - 4 - i) +: 8];
        end

        // Bias
        bias_data = {
            32'd 20, 
            32'd 31, 
            32'd 42, 
            32'd 54,
           -32'd 15, 
            32'd 67,
            32'd 34, 
            32'd 35, 
            32'd 78
        };
        for (i = 0; i < BIS_SIZE; i = i + 1) begin
            ram.mem[1400 + i] = bias_data[32*(BIS_SIZE - 1 - i) +: 32];
        end

    end
/*******************/
`elsif CL_TC3
/* Test case 3 */
    /* 
        Description:
           - Input Feature Map's size : 7 x 7 x 3     => 147
           - Kernel's size            : 3 x 3 x 3 x 6 => 162
           - Output Feature Map's size: 3 x 3 x 6     =>  54
           - Bias's size              : 6 x 4         =>  24
           - Partial-Sum's size       : 3 x 3 x 6 x 4 => 216
           - Stride's size            : 2 x 2
    */

    localparam 
        IFM_SIZE = 7 * 7 * 3     + 1,
        KER_SIZE = 3 * 3 * 3 * 6 + 2,
        OFM_SIZE = 3 * 3 * 6     + 2,
        BIS_SIZE = 6,
        PAS_SIZE = 3 * 3 * 6,
        OUTPUT_HEIGHT = 3,
        OUTPUT_WIDTH = 3,
        OUTPUT_DEPTH = 6;

    initial begin
        // al_accel_mem_read_ready = 1'b 0;
        // al_accel_mem_write_ready = 1'b 0;
        // #10
        // repeat (2000) @(posedge clk) begin
        //     #2 al_accel_mem_read_ready = $random;
        // end
        // #10 
        al_accel_mem_read_ready    = 1'b 1;
        al_accel_mem_write_ready   = 1'b 1;
    end

    initial begin
        al_accel_cfgreg_di   = 32'd 0;       al_accel_cfgreg_sel = 5'd 0; 
        al_accel_cfgreg_wenb =  1'd 0;
        al_accel_flow_enb    =  1'b 0;
        #42
        al_accel_cfgreg_wenb =  1'd 1;
    // Config Data
        #10 // i_base_addr
        al_accel_cfgreg_di   = 32'd 0000;       al_accel_cfgreg_sel = 5'd 0; 

        #10 // kw_base_addr
        al_accel_cfgreg_di   = 32'd 6000;       al_accel_cfgreg_sel = 5'd 1; 

        #10 // o_base_addr
        al_accel_cfgreg_di   = 32'd 16000;       al_accel_cfgreg_sel = 5'd 2; 

        #10 // b_base_addr
        al_accel_cfgreg_di   = 32'd 5600;       al_accel_cfgreg_sel = 5'd 3; 

        #10 // ps_base_addr
        al_accel_cfgreg_di   = 32'd 20000;       al_accel_cfgreg_sel = 5'd 4; 

        #10 // {stride_height, stride_width, cfg_act_func_typ, cfg_layer_typ}
        al_accel_cfgreg_di   = {16'd 0, 4'd 2, 4'd 2, RELU, CONV}; al_accel_cfgreg_sel = 5'd 5; 

        #10 // {weight_kernel_patch_height, weight_kernel_patch_width} 
        al_accel_cfgreg_di   = {16'd 3, 16'd 3}; al_accel_cfgreg_sel = 5'd 6; 

        #10 // {nok_ofm_depth, kernel_ifm_depth}
        al_accel_cfgreg_di   = {16'd 6, 16'd 3}; al_accel_cfgreg_sel = 5'd 7;

        #10 // {ifm_height, ifm_width}
        al_accel_cfgreg_di   = {16'd 7, 16'd 7}; al_accel_cfgreg_sel = 5'd 8;

        #10 // {ofm_height, ofm_width}
        al_accel_cfgreg_di   = {16'd 3, 16'd 3}; al_accel_cfgreg_sel = 5'd 9;

        #10 // {output2D_size, input2D_size}
        al_accel_cfgreg_di   = {16'd 9, 16'd 49} ; al_accel_cfgreg_sel = 5'd 10;

        #10 // kernel3D_size 
        al_accel_cfgreg_di   = {16'd 0, 16'd 27} ; al_accel_cfgreg_sel = 5'd 11;

    // Output Quantize Buffer
        #10 // output_quant_sel
        al_accel_cfgreg_di   = {24'd 0, 8'd 0} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 2039693188 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 8} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel
        al_accel_cfgreg_di   = {24'd 0, 8'd 1} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 2097238482 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 8} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel
        al_accel_cfgreg_di   = {24'd 0, 8'd 2} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1378465373 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 8} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel
        al_accel_cfgreg_di   = {24'd 0, 8'd 3} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1543907582 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 9} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel
        al_accel_cfgreg_di   = {24'd 0, 8'd 4} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1858862255 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd10} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel
        al_accel_cfgreg_di   = {24'd 0, 8'd 5} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1117338165 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 8} ; al_accel_cfgreg_sel = 5'd 14;

    // Data Offset
        #10 // input_offset
        al_accel_cfgreg_di   = 32'd  12; al_accel_cfgreg_sel = 5'd 15;
        #10 // output_offset
        al_accel_cfgreg_di   =-32'd  34; al_accel_cfgreg_sel = 5'd 16;

    // Flow Run
        #10
        al_accel_cfgreg_wenb =  1'd 0;
        #10 
        al_accel_flow_enb    =  1'd 1;
        #1000
        al_accel_flow_enb    =  1'd 0;
        #200
        al_accel_flow_enb    =  1'd 1;
		repeat (2000) @(posedge clk) begin
            #2 al_accel_flow_enb = $random;
        end
        #10 
        al_accel_flow_enb    =  1'd 1;
    end

    reg [IFM_SIZE *  8 - 1:0] input_data ;
    reg [KER_SIZE *  8 - 1:0] filter_data;
    reg [BIS_SIZE * 32 - 1:0] bias_data  ;
    integer i;
    initial begin
        for (i = 0; i < 4096; i = i + 1)
            ram.mem[i] = 32'd 0;

        // Input Initilization
        input_data = {
            /* z = 1 */
                8'd   1, 8'd   2, 8'd   7, 8'd   8,-8'd   1,-8'd  78, 8'd  12,   
                8'd   5, 8'd  45, 8'd  64, 8'd 123,-8'd  89,-8'd  74, 8'd  12,
                8'd   7, 8'd  45, 8'd 123, 8'd  45, 8'd  90, 8'd 101, 8'd  87,
                8'd   1, 8'd   2, 8'd   7, 8'd   8,-8'd   1, 8'd   0,-8'd  19, 
                8'd   5, 8'd  45, 8'd  64, 8'd 123,-8'd  34,-8'd  20, 8'd  75, 
                8'd   7, 8'd  45, 8'd 123, 8'd  45, 8'd  90, 8'd 101, 8'd  96, 
                8'd  15, 8'd  16, 8'd  17, 8'd  18, 8'd  19, 8'd  20, 8'd  21, 
            /* z = 1 */
                  -8'd  90, 8'd   2, 8'd   7, 8'd   8,-8'd  55,-8'd  21, 8'd  10, 
                8'd  51, 8'd  45, 8'd  64, 8'd 123, 8'd  34,-8'd  20, 8'd  10, 
                8'd  57, 8'd  45, 8'd 123, 8'd  45, 8'd  90, 8'd 101, 8'd  21, 
                8'd 110, 8'd   2, 8'd   7, 8'd   8,-8'd  55,-8'd  11, 8'd  22, 
                8'd  51, 8'd  45, 8'd  64, 8'd  23,-8'd  24, 8'd  20, 8'd  88, 
                8'd  71, 8'd  45,-8'd  23, 8'd  45, 8'd  90, 8'd 101, 8'd  66, 
                8'd  15, 8'd  16, 8'd  17, 8'd  18, 8'd  19, 8'd  20, 8'd  21, 
            /* z = 2 */
                8'd   1, 8'd  23, 8'd   7, 8'd   8, 8'd  55, 8'd  21, 8'd  10,
                8'd   5, 8'd   4, 8'd  64, 8'd 123, 8'd  34, 8'd  20, 8'd  21,
                8'd   7, 8'd   5, 8'd 123, 8'd  45, 8'd  90, 8'd 101, 8'd  21,
                8'd   1, 8'd   2, 8'd   7, 8'd   8, 8'd  55,-8'd   1, 8'd  18, 
                8'd   5, 8'd   5, 8'd  64, 8'd  13, 8'd  34, 8'd  20, 8'd  21, 
                8'd  15, 8'd  16, 8'd  17, 8'd  18, 8'd  19, 8'd  20, 8'd  21,
                8'd  23, 8'd  24, 8'd  25, 8'd  26, 8'd  27, 8'd  28, 8'd  29,
            // Padding
                8'd   0
        };
        for (i = 0; i < (IFM_SIZE); i = i + 4) begin
            ram.mem[0 + (i / 4)][ 7: 0] = input_data[8*((IFM_SIZE) - 1 - i) +: 8];
            ram.mem[0 + (i / 4)][15: 8] = input_data[8*((IFM_SIZE) - 2 - i) +: 8];
            ram.mem[0 + (i / 4)][23:16] = input_data[8*((IFM_SIZE) - 3 - i) +: 8];
            ram.mem[0 + (i / 4)][31:24] = input_data[8*((IFM_SIZE) - 4 - i) +: 8];
        end

        // Kernel 
        filter_data = {
            /* Channel = 0 */
                /* z = 0 */
                8'd 10, 8'd 11, 8'd  0,
                8'd 10, 8'd  0, 8'd 11,
                8'd 11, 8'd 11, 8'd  0,
                /* z = 1 */
                8'd 11, 8'd 11, 8'd  0, 
                8'd 11, 8'd 11, 8'd  0,
                8'd 11, 8'd  0, 8'd 11,
                /* z = 2 */
                8'd 11, 8'd  0, 8'd 11,
                8'd 11, 8'd 11, 8'd  0,
                8'd 11, 8'd 11, 8'd  0,
            /* Channel = 1 */
                /* z = 0 */
                8'd 11, 8'd 21, 8'd  0,
                8'd 21, 8'd  0, 8'd 11,
                8'd 21, 8'd 11, 8'd  0,
                /* z = 1 */
                8'd 21, 8'd 11, 8'd  0,
                8'd 21, 8'd 11, 8'd  0,
                8'd 21, 8'd  0, 8'd 11,
                /* z = 2 */
                8'd 21, 8'd  0, 8'd 11,
                8'd 21, 8'd 11, 8'd  0,
                8'd 21, 8'd 11, 8'd  0,
            /* Channel = 2 */
                /* z = 0 */
                8'd 11, 8'd 31, 8'd  0,
                8'd 11, 8'd  0, 8'd 11,
                8'd 11, 8'd 31, 8'd  0,
                /* z = 1 */
                8'd 11, 8'd 31, 8'd  0,
                8'd 11, 8'd 31, 8'd  0,
                8'd 11, 8'd  0, 8'd 11,
                /* z = 2 */
                8'd 11, 8'd  0, 8'd 11,
                8'd 11, 8'd 31, 8'd  0,
                8'd 11, 8'd 31, 8'd  0,
            /* Channel = 3 */
                /* z = 0 */
                8'd 11, 8'd 11, 8'd 40,
                8'd 11, 8'd 40, 8'd 41,
                8'd 21, 8'd 11, 8'd 40,
                /* z = 1 */
                8'd 21, 8'd 11, 8'd 40,
                8'd 11, 8'd 41, 8'd 40,
                8'd 11, 8'd 40, 8'd 11,
                /* z = 2 */
                8'd 11, 8'd 40, 8'd 41,
                8'd 11, 8'd 21, 8'd 40,
                8'd 11, 8'd 11, 8'd 40,
            /* Channel = 4 */
                /* z = 0 */
                8'd 11, 8'd 11, 8'd 30,
                8'd 11, 8'd 30, 8'd 41,
                8'd 21, 8'd 11, 8'd 30,
                /* z = 1 */
                8'd 21, 8'd 11, 8'd 30,
                8'd 11, 8'd 41, 8'd 30,
                8'd 11, 8'd 30, 8'd 11,
                /* z = 2 */
                8'd 11, 8'd  0, 8'd 41,
                8'd 11, 8'd 21, 8'd 30,
                8'd 11, 8'd 11, 8'd 30,
            /* Channel = 5 */
                /* z = 0 */
                8'd 11, 8'd 11, 8'd  0,
                8'd 11,-8'd 20, 8'd 41,
                8'd 21, 8'd 11, 8'd 20,
                /* z = 1 */
                8'd 21, 8'd 11, 8'd 10,
                8'd 11, 8'd 41, 8'd 10,
                8'd 11, 8'd 10, 8'd 11,
                /* z = 2 */
                8'd 11, 8'd 10, 8'd 21,
                8'd 11, 8'd 21, 8'd 10,
                8'd 11, 8'd 11, 8'd 10,
            // Padding
                8'd  0, 8'd  0
        }; 
        for (i = 0; i < KER_SIZE; i = i + 4) begin
            ram.mem[1500 + (i / 4)][ 7: 0] = filter_data[8*(KER_SIZE - 1 - i) +: 8];
            ram.mem[1500 + (i / 4)][15: 8] = filter_data[8*(KER_SIZE - 2 - i) +: 8];
            ram.mem[1500 + (i / 4)][23:16] = filter_data[8*(KER_SIZE - 3 - i) +: 8];
            ram.mem[1500 + (i / 4)][31:24] = filter_data[8*(KER_SIZE - 4 - i) +: 8];
        end

        // Bias
        bias_data = {
            32'd 20, 
            32'd 31, 
            32'd 42, 
            32'd 54,
           -32'd 15, 
            32'd 67
        };
        for (i = 0; i < BIS_SIZE; i = i + 1) begin
            ram.mem[1400 + i] = bias_data[32*(BIS_SIZE - 1 - i) +: 32];
        end

    end
/*******************/
`elsif CL_TC4
/* Test case 4 */
    /* 
        Description:
           - Input Feature Map's size : 7 x 7 x 6     => 294
           - Kernel's size            : 3 x 3 x 6 x 6 => 324
           - Output Feature Map's size: 3 x 3 x 6     => 150
           - Bias's size              : 6 x 4         =>  24
           - Partial-Sum's size       : 5 x 5 x 6 x 4 => 864
           - Stride's size            : 2 x 2
    */

    localparam 
        IFM_SIZE = 7 * 7 * 6     + 2,
        KER_SIZE = 3 * 3 * 6 * 6    ,
        OFM_SIZE = 3 * 3 * 6     + 2,
        BIS_SIZE = 6,
        PAS_SIZE = 5 * 5 * 6,
        OUTPUT_HEIGHT = 3,
        OUTPUT_WIDTH = 3,
        OUTPUT_DEPTH = 6;

    initial begin
        // al_accel_mem_read_ready = 1'b 0;
        // al_accel_mem_write_ready = 1'b 0;
        // #10
        // repeat (2000) @(posedge clk) begin
        //     #2 al_accel_mem_read_ready = $random;
        // end
        // #10 
        al_accel_mem_read_ready    = 1'b 1;
        al_accel_mem_write_ready   = 1'b 1;
    end

    initial begin
        al_accel_cfgreg_di   = 32'd 0;       al_accel_cfgreg_sel = 5'd 0; 
        al_accel_cfgreg_wenb =  1'd 0;
        al_accel_flow_enb    =  1'b 0;
        #42
        al_accel_cfgreg_wenb =  1'd 1;
    // Config Data
        #10 // i_base_addr
        al_accel_cfgreg_di   = 32'd 0000;       al_accel_cfgreg_sel = 5'd 0; 

        #10 // kw_base_addr
        al_accel_cfgreg_di   = 32'd 6000;       al_accel_cfgreg_sel = 5'd 1; 

        #10 // o_base_addr
        al_accel_cfgreg_di   = 32'd 16000;       al_accel_cfgreg_sel = 5'd 2; 

        #10 // b_base_addr
        al_accel_cfgreg_di   = 32'd 5600;       al_accel_cfgreg_sel = 5'd 3; 

        #10 // ps_base_addr
        al_accel_cfgreg_di   = 32'd 20000;       al_accel_cfgreg_sel = 5'd 4; 

        #10 // {stride_height, stride_width, cfg_act_func_typ, cfg_layer_typ}
        al_accel_cfgreg_di   = {16'd 0, 4'd 2, 4'd 2, RELU, CONV}; al_accel_cfgreg_sel = 5'd 5; 

        #10 // {weight_kernel_patch_height, weight_kernel_patch_width}
        al_accel_cfgreg_di   = {16'd 3, 16'd 3}; al_accel_cfgreg_sel = 5'd 6; 

        #10 // {nok_ofm_depth, kernel_ifm_depth} 
        al_accel_cfgreg_di   = {16'd 6, 16'd 6}; al_accel_cfgreg_sel = 5'd 7;

        #10 // {ifm_height, ifm_width}  
        al_accel_cfgreg_di   = {16'd 7, 16'd 7}; al_accel_cfgreg_sel = 5'd 8;

        #10 // {ofm_height, ofm_width}
        al_accel_cfgreg_di   = {16'd 3, 16'd 3}; al_accel_cfgreg_sel = 5'd 9;

        #10 // {output2D_size, input2D_size}  
        al_accel_cfgreg_di   = {16'd 9, 16'd 49} ; al_accel_cfgreg_sel = 5'd 10;

        #10 // kernel3D_size
        al_accel_cfgreg_di   = {16'd 0, 16'd 54} ; al_accel_cfgreg_sel = 5'd 11;

    // Output Quantize Buffer
        #10 // output_quant_sel
        al_accel_cfgreg_di   = {24'd 0, 8'd 0} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 2039693188 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 8} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel
        al_accel_cfgreg_di   = {24'd 0, 8'd 1} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 2097238482 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 8} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel
        al_accel_cfgreg_di   = {24'd 0, 8'd 2} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1378465373 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 8} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel
        al_accel_cfgreg_di   = {24'd 0, 8'd 3} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1543907582 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 9} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel
        al_accel_cfgreg_di   = {24'd 0, 8'd 4} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1858862255 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd10} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel
        al_accel_cfgreg_di   = {24'd 0, 8'd 5} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1117338165 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 8} ; al_accel_cfgreg_sel = 5'd 14;

    // Data Offset
        #10 // input_offset
        al_accel_cfgreg_di   =-32'd  12; al_accel_cfgreg_sel = 5'd 15;
        #10 // output_offset
        al_accel_cfgreg_di   =-32'd  34; al_accel_cfgreg_sel = 5'd 16;

    // Flow Run
        #10
        al_accel_cfgreg_wenb =  1'd 0;
        #10 
        al_accel_flow_enb    =  1'd 1;
        #1000
        al_accel_flow_enb    =  1'd 0;
        #200
        al_accel_flow_enb    =  1'd 1;
		repeat (2000) @(posedge clk) begin
            #2 al_accel_flow_enb = $random;
        end
        #10 
        al_accel_flow_enb    =  1'd 1;
    end

    reg [IFM_SIZE *  8 - 1:0] input_data ; 
    reg [KER_SIZE *  8 - 1:0] filter_data; 
    reg [BIS_SIZE * 32 - 1:0] bias_data  ; 
    integer i;
    initial begin
        for (i = 0; i < 4096; i = i + 1)
            ram.mem[i] = 32'd 0;

        // Input Initilization
        input_data = {
            /* z = 0 */
            8'd   1, 8'd   2, 8'd   7, 8'd   8,-8'd   1,-8'd  78, 8'd  12, 
            8'd   5, 8'd  45, 8'd  64, 8'd 123,-8'd  89,-8'd  74, 8'd  12, 
            8'd   7, 8'd  45, 8'd 123, 8'd  45, 8'd  90, 8'd 101, 8'd  87, 
            8'd   1, 8'd   2, 8'd   7, 8'd   8,-8'd   1, 8'd   0,-8'd  19, 
            8'd   5, 8'd  45, 8'd  64, 8'd 123,-8'd  34,-8'd  20, 8'd  75, 
            8'd   7, 8'd  45, 8'd 123, 8'd  45, 8'd  90, 8'd 101, 8'd  96, 
            8'd  15, 8'd  16, 8'd  17, 8'd  18, 8'd  19, 8'd  20, 8'd  21, 
            /* z = 1 */
           -8'd  90, 8'd   2, 8'd   7, 8'd   8,-8'd  55,-8'd  21, 8'd  10,
            8'd  51, 8'd  45, 8'd  64, 8'd 123, 8'd  34,-8'd  20, 8'd  10,
            8'd  57, 8'd  45, 8'd 123, 8'd  45, 8'd  90, 8'd 101, 8'd  21, 
            8'd 110, 8'd   2, 8'd   7, 8'd   8,-8'd  55,-8'd  11, 8'd  22, 
            8'd  51, 8'd  45, 8'd  64, 8'd  23,-8'd  24, 8'd  20, 8'd  88, 
            8'd  71, 8'd  45,-8'd  23, 8'd  45, 8'd  90, 8'd 101, 8'd  66, 
            8'd  15, 8'd  16, 8'd  17, 8'd  18, 8'd  19, 8'd  20, 8'd  21, 
            /* z = 2 */
            8'd   1, 8'd  23, 8'd   7, 8'd   8, 8'd  55, 8'd  21, 8'd  10,
            8'd   5, 8'd   4, 8'd  64, 8'd 123, 8'd  34, 8'd  20, 8'd  21, 
            8'd   7, 8'd   5, 8'd 123, 8'd  45, 8'd  90, 8'd 101, 8'd  21, 
            8'd   1, 8'd   2, 8'd   7, 8'd   8, 8'd  55,-8'd   1, 8'd  18, 
            8'd   5, 8'd   5, 8'd  64, 8'd  13, 8'd  34, 8'd  20, 8'd  21, 
            8'd  15, 8'd  16, 8'd  17, 8'd  18, 8'd  19, 8'd  20, 8'd  21, 
            8'd  23, 8'd  24, 8'd  25, 8'd  26, 8'd  27, 8'd  28, 8'd  29,
            /* z = 3*/
            8'd  23, 8'd  34, 8'd  56, 8'd  12, 8'd  14,-8'd  17,-8'd  19,
            8'd  20, 8'd  21, 8'd 127,-8'd 128, 8'd 110, 8'd 103, 8'd  19,
            8'd   1, 8'd   1, 8'd   1, 8'd   2, 8'd   2, 8'd   2, 8'd   3,
            8'd  45, 8'd  54, 8'd  46, 8'd  64, 8'd  75, 8'd  74, 8'd  10,
            8'd   1, 8'd  23, 8'd   7, 8'd   8, 8'd  55, 8'd  21, 8'd  10,
            8'd   5, 8'd   4, 8'd  64, 8'd 123, 8'd  34, 8'd  20, 8'd  21, 
            8'd   7, 8'd   5, 8'd 123, 8'd  45, 8'd  90, 8'd 101, 8'd  21, 
            /* z = 4*/
            8'd   5, 8'd   5, 8'd  64, 8'd  13, 8'd  34, 8'd  20, 8'd  21,
            8'd  15, 8'd  16, 8'd  17, 8'd  18, 8'd  19, 8'd  20, 8'd  21, 
            8'd  23, 8'd  24, 8'd  25, 8'd  26, 8'd  27, 8'd  28, 8'd  29,
            8'd   1, 8'd   1, 8'd   1, 8'd   2, 8'd   2, 8'd   2, 8'd   3,
            8'd  45, 8'd  54, 8'd  46, 8'd  64, 8'd  75, 8'd  74, 8'd  10,
            8'd   1, 8'd  23, 8'd   7, 8'd   8, 8'd  55, 8'd  21, 8'd  10, 
            8'd   1, 8'd  23, 8'd   7, 8'd   8, 8'd  55, 8'd  21, 8'd  10, 
            /* z = 5*/
           -8'd  90, 8'd   2, 8'd   7, 8'd   8,-8'd  55,-8'd  21, 8'd  10, 
           -8'd  90, 8'd   2, 8'd   7, 8'd   8,-8'd  55,-8'd  21, 8'd  10, 
           -8'd  90, 8'd   2, 8'd   7, 8'd   8,-8'd  55,-8'd  21, 8'd  10, 
            8'd   1, 8'd   2, 8'd   7, 8'd   8, 8'd  55,-8'd   1, 8'd  18, 
            8'd   7, 8'd  45, 8'd 123, 8'd  45, 8'd  90, 8'd 101, 8'd  87, 
            8'd  20, 8'd  21, 8'd 127,-8'd 128, 8'd 110, 8'd 103, 8'd  19,
            8'd  23, 8'd  34, 8'd  56, 8'd  12, 8'd  14,-8'd  17,-8'd  19,
            // Padding
            8'd   0, 8'd   0
        };
        for (i = 0; i < (IFM_SIZE); i = i + 4) begin
            ram.mem[0 + (i / 4)][ 7: 0] = input_data[8*((IFM_SIZE) - 1 - i) +: 8];
            ram.mem[0 + (i / 4)][15: 8] = input_data[8*((IFM_SIZE) - 2 - i) +: 8];
            ram.mem[0 + (i / 4)][23:16] = input_data[8*((IFM_SIZE) - 3 - i) +: 8];
            ram.mem[0 + (i / 4)][31:24] = input_data[8*((IFM_SIZE) - 4 - i) +: 8];
        end

        // Kernel 
        filter_data = {
        /* Channel = 0 */
            /* z = 0 */
            8'd  10, 8'd  11, 8'd   0,
            8'd  10, 8'd   0, 8'd  11,
            8'd  11, 8'd  11, 8'd   0,
            /* z = 1 */
            8'd  11, 8'd  11, 8'd   0,
            8'd  11, 8'd  11, 8'd   0,
            8'd  11, 8'd   0, 8'd  11,
            /* z = 2 */
            8'd  11, 8'd   0, 8'd  11,
            8'd  11, 8'd  11, 8'd   0,
            8'd  11, 8'd  11, 8'd   0,
            /* z = 3*/
            8'd  22, 8'd  33, 8'd  44,
            8'd  55, 8'd  66, 8'd  77,
            8'd  88, 8'd  99, 8'd 110,
            /* z = 4*/
            8'd  22, 8'd   0, 8'd  22,
            8'd  33, 8'd  22, 8'd  33,
            8'd  44, 8'd  33, 8'd  22,
            /* z = 5*/
           -8'd   1,-8'd   2,-8'd   3,
           -8'd  11,-8'd  12,-8'd  13,
           -8'd  14,-8'd  15,-8'd  16,
        /* Channel = 1 */
            /* z = 0 */
            8'd  11, 8'd  21, 8'd   0,
            8'd  21, 8'd   0, 8'd  11,
            8'd  21, 8'd  11, 8'd   0,
            /* z = 1 */ 
            8'd  21, 8'd  11, 8'd   0,
            8'd  21, 8'd  11, 8'd   0,
            8'd  21, 8'd   0, 8'd  11,
            /* z = 2 */
            8'd  21, 8'd   0, 8'd  11,
            8'd  21, 8'd  11, 8'd   0,
            8'd  21, 8'd  11, 8'd   0,
            /* z = 3*/
            8'd   5, 8'd  10, 8'd  15,
            8'd  20, 8'd  25, 8'd  30,
            8'd  35, 8'd  40, 8'd  45,
            /* z = 4*/
            8'd  60, 8'd  70, 8'd  80,
            8'd  80, 8'd  70, 8'd  60,
            8'd  70, 8'd  80, 8'd  60,
            /* z = 5*/
            8'd  11, 8'd  22, 8'd  33,
            8'd  44, 8'd  55, 8'd  66,
            8'd  77, 8'd  88, 8'd  99,
        /* Channel = 2 */
            /* z = 0 */
            8'd  11, 8'd  31, 8'd   0,
            8'd  11, 8'd   0, 8'd  11,
            8'd  11, 8'd  31, 8'd   0,
            /* z = 1 */
            8'd  11, 8'd  31, 8'd   0,
            8'd  11, 8'd  31, 8'd   0,
            8'd  11, 8'd   0, 8'd  11,
            /* z = 2 */
            8'd  11, 8'd   0, 8'd  11,
            8'd  11, 8'd  31, 8'd   0,
            8'd  11, 8'd  31, 8'd   0,
            /* z = 3*/
           -8'd   5, 8'd  10, 8'd  15,
            8'd  20,-8'd  25, 8'd  30,
            8'd  35, 8'd  40,-8'd  45,
            /* z = 4*/
           -8'd  60, 8'd  70, 8'd  80,
            8'd  80,-8'd  70, 8'd  60,
            8'd  70, 8'd  80,-8'd  60,
            /* z = 5*/
           -8'd  11, 8'd  22, 8'd  33,
            8'd  44,-8'd  55, 8'd  66,
            8'd  77, 8'd  88,-8'd  99,
        /* Channel = 3 */
            /* z = 0 */
            8'd  11, 8'd  11, 8'd  40,
            8'd  11, 8'd  40, 8'd  41,
            8'd  21, 8'd  11, 8'd  40,
            /* z = 1 */
            8'd  21, 8'd  11, 8'd  40,
            8'd  11, 8'd  41, 8'd  40,
            8'd  11, 8'd  40, 8'd  11,
            /* z = 2 */
            8'd  11, 8'd  40, 8'd  41,
            8'd  11, 8'd  21, 8'd  40,
            8'd  11, 8'd  11, 8'd  40,
            /* z = 3*/
           -8'd   5, 8'd  10, 8'd  15,
           -8'd  20, 8'd  25, 8'd  30,
           -8'd  35, 8'd  40, 8'd  45,
            /* z = 4*/
           -8'd  60, 8'd  70, 8'd  80,
           -8'd  80, 8'd  70, 8'd  60,
           -8'd  70, 8'd  80, 8'd  60,
            /* z = 5*/
           -8'd  11, 8'd  22, 8'd  33,
           -8'd  44, 8'd  55, 8'd  66,
           -8'd  77, 8'd  88, 8'd  99,
        /* Channel = 4 */
            /* z = 0 */
            8'd  11, 8'd  11, 8'd  30,
            8'd  11, 8'd  30, 8'd  41,
            8'd  21, 8'd  11, 8'd  30,
            /* z = 1 */
            8'd  21, 8'd  11, 8'd  30,
            8'd  11, 8'd  41, 8'd  30,
            8'd  11, 8'd  30, 8'd  11,
            /* z = 2 */
            8'd  11, 8'd   0, 8'd  41,
            8'd  11, 8'd  21, 8'd  30,
            8'd  11, 8'd  11, 8'd  30,
            /* z = 3*/
            8'd   5,-8'd  10, 8'd  15,
            8'd  20,-8'd  25, 8'd  30,
            8'd  35,-8'd  40, 8'd  45,
            /* z = 4*/
            8'd  60,-8'd  70, 8'd  80,
            8'd  80,-8'd  70, 8'd  60,
            8'd  70,-8'd  80, 8'd  60,
            /* z = 5*/
            8'd  11,-8'd  22, 8'd  33,
            8'd  44,-8'd  55, 8'd  66,
            8'd  77,-8'd  88, 8'd  99,
        /* Channel = 5 */
            /* z = 0 */
            8'd  11, 8'd  11, 8'd   0,
            8'd  11,-8'd  20, 8'd  41,
            8'd  21, 8'd  11, 8'd  20,
            /* z = 1 */
            8'd  21, 8'd  11, 8'd  10,
            8'd  11, 8'd  41, 8'd  10,
            8'd  11, 8'd  10, 8'd  11,
            /* z = 2 */
            8'd  11, 8'd  10, 8'd  21,
            8'd  11, 8'd  21, 8'd  10,
            8'd  11, 8'd  11, 8'd  10,
            /* z = 3*/
            8'd   5, 8'd  10,-8'd  15,
            8'd  20,-8'd  25, 8'd  30,
           -8'd  35, 8'd  40, 8'd  45,
            /* z = 4*/
            8'd  60, 8'd  70,-8'd  80,
            8'd  80,-8'd  70, 8'd  60,
           -8'd  70, 8'd  80, 8'd  60,
            /* z = 5*/
            8'd  11, 8'd  22,-8'd  33,
            8'd  44,-8'd  55, 8'd  66,
           -8'd  77, 8'd  88, 8'd  99
        }; 

        for (i = 0; i < KER_SIZE; i = i + 4) begin
            ram.mem[1500 + (i / 4)][ 7: 0] = filter_data[8*(KER_SIZE - 1 - i) +: 8];
            ram.mem[1500 + (i / 4)][15: 8] = filter_data[8*(KER_SIZE - 2 - i) +: 8];
            ram.mem[1500 + (i / 4)][23:16] = filter_data[8*(KER_SIZE - 3 - i) +: 8];
            ram.mem[1500 + (i / 4)][31:24] = filter_data[8*(KER_SIZE - 4 - i) +: 8];
        end

        // Bias
        bias_data = {
            32'd 20, 
            32'd 31, 
            32'd 42, 
            32'd 54,
           -32'd 15, 
            32'd 67
        };
        for (i = 0; i < BIS_SIZE; i = i + 1) begin
            ram.mem[1400 + i] = bias_data[32*(BIS_SIZE - 1 - i) +: 32];
        end

    end
/*******************/
`elsif CL_TC5
/* Test case 5 */
    /* 
        Description:
           - Input Feature Map's size : 7 x 7 x 9     => 441
           - Kernel's size            : 3 x 3 x 9 x 9 => 729
           - Output Feature Map's size: 3 x 3 x 9     => 225
           - Bias's size              : 9 x 4         =>  36
           - Partial-Sum's size       : 5 x 5 x 9 x 4 => 900
           - Stride's size            : 2 x 2
    */
    localparam 
        IFM_SIZE = 7 * 7 * 9     + 3,
        KER_SIZE = 3 * 3 * 9 * 9 + 3,
        OFM_SIZE = 3 * 3 * 9     + 3,
        BIS_SIZE = 9,
        PAS_SIZE = 5 * 5 * 9,
        OUTPUT_HEIGHT = 3,
        OUTPUT_WIDTH = 3,
        OUTPUT_DEPTH = 9;

    initial begin
        // al_accel_mem_read_ready = 1'b 0;
        // al_accel_mem_write_ready = 1'b 0;
        // #10
        // repeat (2000) @(posedge clk) begin
        //     #2 al_accel_mem_read_ready = $random;
        // end
        // #10 
        al_accel_mem_read_ready    = 1'b 1;
        al_accel_mem_write_ready   = 1'b 1;
    end

    initial begin
        al_accel_cfgreg_di   = 32'd 0;       al_accel_cfgreg_sel = 5'd 0; 
        al_accel_cfgreg_wenb =  1'd 0;
        al_accel_flow_enb    =  1'b 0;
        #42
        al_accel_cfgreg_wenb =  1'd 1;
    // Config Data
        #10 // i_base_addr
        al_accel_cfgreg_di   = 32'd 0000;       al_accel_cfgreg_sel = 5'd 0; 

        #10 // kw_base_addr
        al_accel_cfgreg_di   = 32'd 6000;       al_accel_cfgreg_sel = 5'd 1; 

        #10 // o_base_addr
        al_accel_cfgreg_di   = 32'd 16000;       al_accel_cfgreg_sel = 5'd 2; 

        #10 // b_base_addr
        al_accel_cfgreg_di   = 32'd 5600;       al_accel_cfgreg_sel = 5'd 3; 

        #10 // ps_base_addr
        al_accel_cfgreg_di   = 32'd 20000;       al_accel_cfgreg_sel = 5'd 4; 

        #10 // {stride_height, stride_width, cfg_act_func_typ, cfg_layer_typ}
        al_accel_cfgreg_di   = {16'd 0, 4'd 2, 4'd 2, RELU, CONV}; al_accel_cfgreg_sel = 5'd 5; 

        #10 // {weight_kernel_patch_height, weight_kernel_patch_width}
        al_accel_cfgreg_di   = {16'd 3, 16'd 3}; al_accel_cfgreg_sel = 5'd 6; 

        #10 // {nok_ofm_depth, kernel_ifm_depth} 
        al_accel_cfgreg_di   = {16'd 9, 16'd 9}; al_accel_cfgreg_sel = 5'd 7;

        #10 // {ifm_height, ifm_width}  
        al_accel_cfgreg_di   = {16'd 7, 16'd 7}; al_accel_cfgreg_sel = 5'd 8;

        #10 // {ofm_height, ofm_width}
        al_accel_cfgreg_di   = {16'd 3, 16'd 3}; al_accel_cfgreg_sel = 5'd 9;

        #10 // {output2D_size, input2D_size}  
        al_accel_cfgreg_di   = {16'd 9, 16'd 49} ; al_accel_cfgreg_sel = 5'd 10;

        #10 // kernel3D_size 
        al_accel_cfgreg_di   = {16'd 0, 16'd 81} ; al_accel_cfgreg_sel = 5'd 11;

    // Output Quantize Buffer
        #10 // output_quant_sel
        al_accel_cfgreg_di   = {24'd 0, 8'd 0} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 2039693188 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 8} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel
        al_accel_cfgreg_di   = {24'd 0, 8'd 1} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 2097238482 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 8} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel
        al_accel_cfgreg_di   = {24'd 0, 8'd 2} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1378465373 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 8} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel
        al_accel_cfgreg_di   = {24'd 0, 8'd 3} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1543907582 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 9} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel
        al_accel_cfgreg_di   = {24'd 0, 8'd 4} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1858862255 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd10} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel
        al_accel_cfgreg_di   = {24'd 0, 8'd 5} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1117338165 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 8} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel
        al_accel_cfgreg_di   = {24'd 0, 8'd 6} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1644917525 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 9} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel
        al_accel_cfgreg_di   = {24'd 0, 8'd 7} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1086964334 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 8} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel
        al_accel_cfgreg_di   = {24'd 0, 8'd 8} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1222442873 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 9} ; al_accel_cfgreg_sel = 5'd 14;

    // Data Offset
        #10 // input_offset
        al_accel_cfgreg_di   =-32'd 128; al_accel_cfgreg_sel = 5'd 15;
        #10 // output_offset
        al_accel_cfgreg_di   =-32'd 127; al_accel_cfgreg_sel = 5'd 16;

    // Flow Run
        #10
        al_accel_cfgreg_wenb =  1'd 0;
        #10 
        al_accel_flow_enb    =  1'd 1;
        #1000
        al_accel_flow_enb    =  1'd 0;
        #200
        al_accel_flow_enb    =  1'd 1;
		repeat (2000) @(posedge clk) begin
            #2 al_accel_flow_enb = $random;
        end
        #10 
        al_accel_flow_enb    =  1'd 1;
    end

    reg [IFM_SIZE *  8 - 1:0]  input_data ; // Size: 7 x 7 x 9
    reg [KER_SIZE *  8 - 1:0]  filter_data; // Size: 3 x 3 x 9 x 9
    reg [BIS_SIZE * 32 - 1:0]  bias_data  ; // Size: 9
    integer i;
    initial begin
        for (i = 0; i < 4096; i = i + 1)
            ram.mem[i] = 32'd 0;

        // Input Initilization
        input_data = {
        /* z = 0 */
            8'd   1, 8'd   2, 8'd   7, 8'd   8,-8'd   1,-8'd  78, 8'd  12,
            8'd   5, 8'd  45, 8'd  64, 8'd 123,-8'd  89,-8'd  74, 8'd  12,
            8'd   7, 8'd  45, 8'd 123, 8'd  45, 8'd  90, 8'd 101, 8'd  87,
            8'd   1, 8'd   2, 8'd   7, 8'd   8,-8'd   1, 8'd   0,-8'd  19,
            8'd   5, 8'd  45, 8'd  64, 8'd 123,-8'd  34,-8'd  20, 8'd  75,
            8'd   7, 8'd  45, 8'd 123, 8'd  45, 8'd  90, 8'd 101, 8'd  96,
            8'd  15, 8'd  16, 8'd  17, 8'd  18, 8'd  19, 8'd  20, 8'd  21,
        /* z = 1 */
           -8'd  90, 8'd   2, 8'd   7, 8'd   8,-8'd  55,-8'd  21, 8'd  10,
            8'd  51, 8'd  45, 8'd  64, 8'd 123, 8'd  34,-8'd  20, 8'd  10,
            8'd  57, 8'd  45, 8'd 123, 8'd  45, 8'd  90, 8'd 101, 8'd  21,
            8'd 110, 8'd   2, 8'd   7, 8'd   8,-8'd  55,-8'd  11, 8'd  22,
            8'd  51, 8'd  45, 8'd  64, 8'd  23,-8'd  24, 8'd  20, 8'd  88,
            8'd  71, 8'd  45,-8'd  23, 8'd  45, 8'd  90, 8'd 101, 8'd  66,
            8'd  15, 8'd  16, 8'd  17, 8'd  18, 8'd  19, 8'd  20, 8'd  21,
        /* z = 2 */
            8'd   1, 8'd  23, 8'd   7, 8'd   8, 8'd  55, 8'd  21, 8'd  10,
            8'd   5, 8'd   4, 8'd  64, 8'd 123, 8'd  34, 8'd  20, 8'd  21,
            8'd   7, 8'd   5, 8'd 123, 8'd  45, 8'd  90, 8'd 101, 8'd  21,
            8'd   1, 8'd   2, 8'd   7, 8'd   8, 8'd  55,-8'd   1, 8'd  18,
            8'd   5, 8'd   5, 8'd  64, 8'd  13, 8'd  34, 8'd  20, 8'd  21,
            8'd  15, 8'd  16, 8'd  17, 8'd  18, 8'd  19, 8'd  20, 8'd  21,
            8'd  23, 8'd  24, 8'd  25, 8'd  26, 8'd  27, 8'd  28, 8'd  29,
        /* z = 3*/
            8'd  23, 8'd  34, 8'd  56, 8'd  12, 8'd  14,-8'd  17,-8'd  19,
            8'd  20, 8'd  21, 8'd 127,-8'd 128, 8'd 110, 8'd 103, 8'd  19,
            8'd   1, 8'd   1, 8'd   1, 8'd   2, 8'd   2, 8'd   2, 8'd   3,
            8'd  45, 8'd  54, 8'd  46, 8'd  64, 8'd  75, 8'd  74, 8'd  10,
            8'd   1, 8'd  23, 8'd   7, 8'd   8, 8'd  55, 8'd  21, 8'd  10,
            8'd   5, 8'd   4, 8'd  64, 8'd 123, 8'd  34, 8'd  20, 8'd  21,
            8'd   7, 8'd   5, 8'd 123, 8'd  45, 8'd  90, 8'd 101, 8'd  21,
        /* z = 4*/
            8'd   5, 8'd   5, 8'd  64, 8'd  13, 8'd  34, 8'd  20, 8'd  21,
            8'd  15, 8'd  16, 8'd  17, 8'd  18, 8'd  19, 8'd  20, 8'd  21,
            8'd  23, 8'd  24, 8'd  25, 8'd  26, 8'd  27, 8'd  28, 8'd  29,
            8'd   1, 8'd   1, 8'd   1, 8'd   2, 8'd   2, 8'd   2, 8'd   3,
            8'd  45, 8'd  54, 8'd  46, 8'd  64, 8'd  75, 8'd  74, 8'd  10,
            8'd   1, 8'd  23, 8'd   7, 8'd   8, 8'd  55, 8'd  21, 8'd  10,
            8'd   1, 8'd  23, 8'd   7, 8'd   8, 8'd  55, 8'd  21, 8'd  10,
        /* z = 5*/
           -8'd  90, 8'd   2, 8'd   7, 8'd   8,-8'd  55,-8'd  21, 8'd  10,
           -8'd  90, 8'd   2, 8'd   7, 8'd   8,-8'd  55,-8'd  21, 8'd  10,
           -8'd  90, 8'd   2, 8'd   7, 8'd   8,-8'd  55,-8'd  21, 8'd  10,
            8'd   1, 8'd   2, 8'd   7, 8'd   8, 8'd  55,-8'd   1, 8'd  18,
            8'd   7, 8'd  45, 8'd 123, 8'd  45, 8'd  90, 8'd 101, 8'd  87,
            8'd  20, 8'd  21, 8'd 127,-8'd 128, 8'd 110, 8'd 103, 8'd  19,
            8'd  23, 8'd  34, 8'd  56, 8'd  12, 8'd  14,-8'd  17,-8'd  19,
        /* z = 6*/
            8'd  23, 8'd  34, 8'd  56, 8'd  12, 8'd  14,-8'd  17,-8'd  19,
            8'd  20, 8'd  21, 8'd 127,-8'd 128, 8'd 110, 8'd 103, 8'd  19,
            8'd   1, 8'd   1, 8'd   1, 8'd   2, 8'd   2, 8'd   2, 8'd   3,
            8'd  45, 8'd  54, 8'd  46, 8'd  64, 8'd  75, 8'd  74, 8'd  10,
            8'd   1, 8'd  23, 8'd   7, 8'd   8, 8'd  55, 8'd  21, 8'd  10,
            8'd   5, 8'd   4, 8'd  64, 8'd 123, 8'd  34, 8'd  20, 8'd  21,
            8'd   7, 8'd   5, 8'd 123, 8'd  45, 8'd  90, 8'd 101, 8'd  21,
        /* z = 7*/
            8'd   5, 8'd   5, 8'd  64, 8'd  13, 8'd  34, 8'd  20, 8'd  21,
            8'd  15, 8'd  16, 8'd  17, 8'd  18, 8'd  19, 8'd  20, 8'd  21,
            8'd  23, 8'd  24, 8'd  25, 8'd  26, 8'd  27, 8'd  28, 8'd  29,
            8'd   1, 8'd   1, 8'd   1, 8'd   2, 8'd   2, 8'd   2, 8'd   3,
            8'd  45, 8'd  54, 8'd  46, 8'd  64, 8'd  75, 8'd  74, 8'd  10,
            8'd   1, 8'd  23, 8'd   7, 8'd   8, 8'd  55, 8'd  21, 8'd  10,
            8'd   1, 8'd  23, 8'd   7, 8'd   8, 8'd  55, 8'd  21, 8'd  10,
        /* z = 8*/
           -8'd  90, 8'd   2, 8'd   7, 8'd   8,-8'd  55,-8'd  21, 8'd  10,
           -8'd  90, 8'd   2, 8'd   7, 8'd   8,-8'd  55,-8'd  21, 8'd  10,
           -8'd  90, 8'd   2, 8'd   7, 8'd   8,-8'd  55,-8'd  21, 8'd  10,
            8'd   1, 8'd   2, 8'd   7, 8'd   8, 8'd  55,-8'd   1, 8'd  18,
            8'd   7, 8'd  45, 8'd 123, 8'd  45, 8'd  90, 8'd 101, 8'd  87,
            8'd  20, 8'd  21, 8'd 127,-8'd 128, 8'd 110, 8'd 103, 8'd  19,
            8'd  23, 8'd  34, 8'd  56, 8'd  12, 8'd  14,-8'd  17,-8'd  19,
        // Padding
            8'd   0, 8'd   0, 8'd   0
        };
        for (i = 0; i < (IFM_SIZE); i = i + 4) begin
            ram.mem[0 + (i / 4)][ 7: 0] = input_data[8*((IFM_SIZE) - 1 - i) +: 8];
            ram.mem[0 + (i / 4)][15: 8] = input_data[8*((IFM_SIZE) - 2 - i) +: 8];
            ram.mem[0 + (i / 4)][23:16] = input_data[8*((IFM_SIZE) - 3 - i) +: 8];
            ram.mem[0 + (i / 4)][31:24] = input_data[8*((IFM_SIZE) - 4 - i) +: 8];
        end

        // Kernel 
        filter_data = {
    /* Channel = 0 */
        /* z = 0 */
            8'd  10, 8'd  11, 8'd   0,
            8'd  10, 8'd   0, 8'd  11,
            8'd  11, 8'd  11, 8'd   0,
        /* z = 1 */
            8'd  11, 8'd  11, 8'd   0,
            8'd  11, 8'd  11, 8'd   0,
            8'd  11, 8'd   0, 8'd  11,
        /* z = 2 */
            8'd  11, 8'd   0, 8'd  11,
            8'd  11, 8'd  11, 8'd   0,
            8'd  11, 8'd  11, 8'd   0,
        /* z = 3 */
            8'd  22, 8'd  33, 8'd  44,
            8'd  55, 8'd  66, 8'd  77,
            8'd  88, 8'd  99, 8'd 110,
        /* z = 4 */
            8'd  22, 8'd   0, 8'd  22,
            8'd  33, 8'd  22, 8'd  33,
            8'd  44, 8'd  33, 8'd  22,
        /* z = 5 */
           -8'd   1,-8'd   2,-8'd   3,
           -8'd  11,-8'd  12,-8'd  13,
           -8'd  14,-8'd  15,-8'd  16,
        /* z = 6 */
            8'd  11, 8'd  11, 8'd   0,
            8'd  11, 8'd  11, 8'd   0,
            8'd  11, 8'd   0, 8'd  11,
        /* z = 7 */
            8'd  11, 8'd   0, 8'd  11,
            8'd  11, 8'd  11, 8'd   0,
            8'd  11, 8'd  11, 8'd   0,
        /* z = 8 */
            8'd  22, 8'd  33, 8'd  44,
            8'd  55, 8'd  66, 8'd  77,
            8'd  88, 8'd  99, 8'd 110,
    /* Channel = 1 */
        /* z = 0 */
            8'd  11, 8'd  21, 8'd   0,
            8'd  21, 8'd   0, 8'd  11,
            8'd  21, 8'd  11, 8'd   0,
        /* z = 1 */
            8'd  21, 8'd  11, 8'd   0,
            8'd  21, 8'd  11, 8'd   0,
            8'd  21, 8'd   0, 8'd  11,
        /* z = 2 */
            8'd  21, 8'd   0, 8'd  11,
            8'd  21, 8'd  11, 8'd   0,
            8'd  21, 8'd  11, 8'd   0,
        /* z = 3 */
            8'd   5, 8'd  10, 8'd  15,
            8'd  20, 8'd  25, 8'd  30,
            8'd  35, 8'd  40, 8'd  45,
        /* z = 4 */
            8'd  60, 8'd  70, 8'd  80,
            8'd  80, 8'd  70, 8'd  60,
            8'd  70, 8'd  80, 8'd  60,
        /* z = 5 */
            8'd  11, 8'd  22, 8'd  33,
            8'd  44, 8'd  55, 8'd  66,
            8'd  77, 8'd  88, 8'd  99,
        /* z = 6 */
            8'd  11, 8'd  11, 8'd   0,
            8'd  11, 8'd  11, 8'd   0,
            8'd  11, 8'd   0, 8'd  11,
        /* z = 7 */
            8'd  11, 8'd   0, 8'd  11,
            8'd  11, 8'd  11, 8'd   0,
            8'd  11, 8'd  11, 8'd   0,
        /* z = 8 */
            8'd  22, 8'd  33, 8'd  44,
            8'd  55, 8'd  66, 8'd  77,
            8'd  88, 8'd  99, 8'd 110,
    /* Channel = 2 */
        /* z = 0 */
            8'd  11, 8'd  31, 8'd   0,
            8'd  11, 8'd   0, 8'd  11,
            8'd  11, 8'd  31, 8'd   0,
        /* z = 1 */
            8'd  11, 8'd  31, 8'd   0,
            8'd  11, 8'd  31, 8'd   0,
            8'd  11, 8'd   0, 8'd  11,
        /* z = 2 */
            8'd  11, 8'd   0, 8'd  11,
            8'd  11, 8'd  31, 8'd   0,
            8'd  11, 8'd  31, 8'd   0,
        /* z = 3 */
           -8'd   5, 8'd  10, 8'd  15,
            8'd  20,-8'd  25, 8'd  30,
            8'd  35, 8'd  40,-8'd  45,
        /* z = 4 */
           -8'd  60, 8'd  70, 8'd  80,
            8'd  80,-8'd  70, 8'd  60,
            8'd  70, 8'd  80,-8'd  60,
        /* z = 5 */
           -8'd  11, 8'd  22, 8'd  33,
            8'd  44,-8'd  55, 8'd  66,
            8'd  77, 8'd  88,-8'd  99,
        /* z = 6 */
            8'd  11, 8'd  31, 8'd   0,
            8'd  11, 8'd   0, 8'd  11,
            8'd  11, 8'd  31, 8'd   0,
        /* z = 7 */
            8'd  11, 8'd  31, 8'd   0,
            8'd  11, 8'd  31, 8'd   0,
            8'd  11, 8'd   0, 8'd  11,
        /* z = 8 */
            8'd  11, 8'd   0, 8'd  11,
            8'd  11, 8'd  31, 8'd   0,
            8'd  11, 8'd  31, 8'd   0,
    /* Channel = 3 */
        /* z = 0 */
            8'd  11, 8'd  11, 8'd  40,
            8'd  11, 8'd  40, 8'd  41,
            8'd  21, 8'd  11, 8'd  40,
        /* z = 1 */
            8'd  21, 8'd  11, 8'd  40,
            8'd  11, 8'd  41, 8'd  40,
            8'd  11, 8'd  40, 8'd  11,
        /* z = 2 */
            8'd  11, 8'd  40, 8'd  41,
            8'd  11, 8'd  21, 8'd  40,
            8'd  11, 8'd  11, 8'd  40,
        /* z = 3*/
           -8'd   5, 8'd  10, 8'd  15,
           -8'd  20, 8'd  25, 8'd  30,
           -8'd  35, 8'd  40, 8'd  45,
        /* z = 4*/
           -8'd  60, 8'd  70, 8'd  80,
           -8'd  80, 8'd  70, 8'd  60,
           -8'd  70, 8'd  80, 8'd  60,
        /* z = 5*/
           -8'd  11, 8'd  22, 8'd  33,
           -8'd  44, 8'd  55, 8'd  66,
           -8'd  77, 8'd  88, 8'd  99,
        /* z = 6 */
            8'd  11, 8'd  11, 8'd   0,
            8'd  11, 8'd  11, 8'd   0,
            8'd  11, 8'd   0, 8'd  11,
        /* z = 7 */
            8'd  11, 8'd  31, 8'd   0,
            8'd  11, 8'd  31, 8'd   0,
            8'd  11, 8'd   0, 8'd  11,
        /* z = 8 */
            8'd  11, 8'd   0, 8'd  11,
            8'd  11, 8'd  31, 8'd   0,
            8'd  11, 8'd  31, 8'd   0,
    /* Channel = 4 */
        /* z = 0 */
            8'd  11, 8'd  11, 8'd  30,
            8'd  11, 8'd  30, 8'd  41,
            8'd  21, 8'd  11, 8'd  30,
        /* z = 1 */
            8'd  21, 8'd  11, 8'd  30,
            8'd  11, 8'd  41, 8'd  30,
            8'd  11, 8'd  30, 8'd  11,
        /* z = 2 */
            8'd  11, 8'd   0, 8'd  41,
            8'd  11, 8'd  21, 8'd  30,
            8'd  11, 8'd  11, 8'd  30,
        /* z = 3*/
            8'd   5,-8'd  10, 8'd  15,
            8'd  20,-8'd  25, 8'd  30,
            8'd  35,-8'd  40, 8'd  45,
        /* z = 4*/
            8'd  60,-8'd  70, 8'd  80,
            8'd  80,-8'd  70, 8'd  60,
            8'd  70,-8'd  80, 8'd  60,
        /* z = 5*/
            8'd  11,-8'd  22, 8'd  33,
            8'd  44,-8'd  55, 8'd  66,
            8'd  77,-8'd  88, 8'd  99,
        /* z = 6 */
            8'd  11, 8'd  11, 8'd   0,
            8'd  11, 8'd  11, 8'd   0,
            8'd  11, 8'd   0, 8'd  11,
        /* z = 7 */
            8'd  11, 8'd  31, 8'd   0,
            8'd  11, 8'd  31, 8'd   0,
            8'd  11, 8'd   0, 8'd  11,
        /* z = 8 */
            8'd  11, 8'd   0, 8'd  11,
            8'd  11, 8'd  31, 8'd   0,
            8'd  11, 8'd  31, 8'd   0,
    /* Channel = 5 */
        /* z = 0 */
            8'd  11, 8'd  11, 8'd   0,
            8'd  11,-8'd  20, 8'd  41,
            8'd  21, 8'd  11, 8'd  20,
        /* z = 1 */
            8'd  21, 8'd  11, 8'd  10,
            8'd  11, 8'd  41, 8'd  10,
            8'd  11, 8'd  10, 8'd  11,
        /* z = 2 */
            8'd  11, 8'd  10, 8'd  21,
            8'd  11, 8'd  21, 8'd  10,
            8'd  11, 8'd  11, 8'd  10,
        /* z = 3 */
            8'd   5, 8'd  10,-8'd  15,
            8'd  20,-8'd  25, 8'd  30,
           -8'd  35, 8'd  40, 8'd  45,
        /* z = 4 */
            8'd  60, 8'd  70,-8'd  80,
            8'd  80,-8'd  70, 8'd  60,
           -8'd  70, 8'd  80, 8'd  60,
        /* z = 5 */
            8'd  11, 8'd  22,-8'd  33,
            8'd  44,-8'd  55, 8'd  66,
           -8'd  77, 8'd  88, 8'd  99,
        /* z = 6 */
           -8'd   5, 8'd  10, 8'd  15,
           -8'd  20, 8'd  25, 8'd  30,
           -8'd  35, 8'd  40, 8'd  45,
        /* z = 7 */
           -8'd  60, 8'd  70, 8'd  80,
           -8'd  80, 8'd  70, 8'd  60,
           -8'd  70, 8'd  80, 8'd  60,
        /* z = 8 */
           -8'd  11, 8'd  22, 8'd  33,
           -8'd  44, 8'd  55, 8'd  66,
           -8'd  77, 8'd  88, 8'd  99,
    /* Channel = 6 */
        /* z = 0 */
            8'd  1, 8'd  2, 8'd  3,
            8'd  4, 8'd  5, 8'd  6,
            8'd  7, 8'd  8, 8'd  9,
        /* z = 1 */
           -8'd  1, 8'd  2, 8'd  3,
           -8'd  4, 8'd  5, 8'd  6,
           -8'd  7, 8'd  8, 8'd  9,
        /* z = 2 */
            8'd  1,-8'd  2, 8'd  3,
            8'd  4,-8'd  5, 8'd  6,
            8'd  7,-8'd  8, 8'd  9,
        /* z = 3 */
            8'd  1, 8'd  2,-8'd  3,
            8'd  4, 8'd  5,-8'd  6,
            8'd  7, 8'd  8,-8'd  9,
        /* z = 4 */
           -8'd  1,-8'd  2,-8'd  3,
            8'd  4, 8'd  5, 8'd  6,
            8'd  7, 8'd  8, 8'd  9,
        /* z = 5 */
            8'd  1, 8'd  2, 8'd  3,
           -8'd  4,-8'd  5,-8'd  6,
            8'd  7, 8'd  8, 8'd  9,
        /* z = 6 */
            8'd  1, 8'd  2, 8'd  3,
            8'd  4, 8'd  5, 8'd  6,
           -8'd  7,-8'd  8,-8'd  9,
        /* z = 7 */
           -8'd  1, 8'd  2, 8'd  3,
            8'd  4,-8'd  5, 8'd  6,
            8'd  7, 8'd  8,-8'd  9,
        /* z = 8 */
            8'd  1, 8'd  2,-8'd  3,
            8'd  4,-8'd  5, 8'd  6,
           -8'd  7, 8'd  8, 8'd  9,
    /* Channel = 7 */
        /* z = 0 */
            8'd  1, 8'd  2, 8'd  30,
            8'd  4, 8'd  5, 8'd   6,
            8'd  7, 8'd  8, 8'd   9,
        /* z = 1 */
           -8'd  1, 8'd  2, 8'd   3,
           -8'd  4, 8'd  5, 8'd   6,
           -8'd  7, 8'd  8, 8'd  90,
        /* z = 2 */
            8'd   1,-8'd  2, 8'd  3,
            8'd  40,-8'd  5, 8'd  6,
            8'd   7,-8'd  8, 8'd  9,
        /* z = 3 */
            8'd  1, 8'd  20,-8'd  3,
            8'd  4, 8'd   5,-8'd  6,
            8'd  7, 8'd   8,-8'd  9,
        /* z = 4 */
           -8'd   1,-8'd  2,-8'd   3,
            8'd  40, 8'd  5, 8'd   6,
            8'd   7, 8'd  8, 8'd  90,
        /* z = 5 */
            8'd  1, 8'd  2, 8'd  3,
           -8'd  4,-8'd  5,-8'd  6,
            8'd  7, 8'd  8, 8'd  9,
        /* z = 6 */
            8'd  1, 8'd  20, 8'd   3,
            8'd  4, 8'd   5, 8'd  60,
           -8'd  7,-8'd   8,-8'd   9,
        /* z = 7 */
           -8'd  1, 8'd  2, 8'd   3,
            8'd  4,-8'd  5, 8'd  60,
            8'd  7, 8'd  8,-8'd   9,
        /* z = 8 */
            8'd  10, 8'd  2,-8'd  3,
            8'd   4,-8'd  5, 8'd  6,
           -8'd   7, 8'd  8, 8'd  9,
    /* Channel = 8 */
        /* z = 0 */
            8'd  1, 8'd  2, 8'd  3,
            8'd  4, 8'd  5, 8'd  6,
            8'd  7, 8'd  8, 8'd  9,
        /* z = 1 */
           -8'd  1, 8'd   2, 8'd  3,
           -8'd  4, 8'd  50, 8'd  6,
           -8'd  7, 8'd   8, 8'd  9,
        /* z = 2 */
            8'd   1,-8'd  2, 8'd  3,
            8'd  40,-8'd  5, 8'd  6,
            8'd   7,-8'd  8, 8'd  9,
        /* z = 3 */
            8'd  1, 8'd  2,-8'd  3,
            8'd  4, 8'd  5,-8'd  6,
            8'd  7, 8'd  8,-8'd  9,
        /* z = 4 */
           -8'd  1,-8'd   2,-8'd  3,
            8'd  4, 8'd  50, 8'd  6,
            8'd  7, 8'd   8, 8'd  9,
        /* z = 5 */
            8'd  1, 8'd  20, 8'd  3,
           -8'd  4,-8'd   5,-8'd  6,
            8'd  7, 8'd  80, 8'd  9,
        /* z = 6 */
            8'd  1, 8'd  20, 8'd   3,
            8'd  4, 8'd   5, 8'd   6,
           -8'd  7,-8'd   8,-8'd  90,
        /* z = 7 */
           -8'd  10, 8'd   2, 8'd  3,
            8'd   4,-8'd  50, 8'd  6,
            8'd   7, 8'd   8,-8'd  9,
        /* z = 8 */
            8'd  10, 8'd   2,-8'd   3,
            8'd  40,-8'd   5, 8'd  60,
           -8'd  70, 8'd  80, 8'd  90,
    // Padding
            8'd   0, 8'd   0, 8'd   0
        }; 
        for (i = 0; i < KER_SIZE; i = i + 4) begin
            ram.mem[1500 + (i / 4)][ 7: 0] = filter_data[8*(KER_SIZE - 1 - i) +: 8];
            ram.mem[1500 + (i / 4)][15: 8] = filter_data[8*(KER_SIZE - 2 - i) +: 8];
            ram.mem[1500 + (i / 4)][23:16] = filter_data[8*(KER_SIZE - 3 - i) +: 8];
            ram.mem[1500 + (i / 4)][31:24] = filter_data[8*(KER_SIZE - 4 - i) +: 8];
        end

        // Bias
        bias_data = {
            32'd 20, 
            32'd 31, 
            32'd 42, 
            32'd 54,
           -32'd 15, 
            32'd 67,
            32'd 34, 
            32'd 35, 
            32'd 78
        };
        for (i = 0; i < BIS_SIZE; i = i + 1) begin
            ram.mem[1400 + i] = bias_data[32*(BIS_SIZE - 1 - i) +: 32];
        end

    end
/*******************/

`elsif CL_TC6
/* Test case 6 */
     /* 
        Description:
           - Input Feature Map's size : 13 x 13 x 33     => 5408
           - Kernel's size            : 3 x 3 x 33 x 32 => 9216
           - Output Feature Map's size: 11 x 11 x 32     => 150
           - Bias's size              : 32 * 32         =>  1024
    */

    localparam 
        IFM_SIZE = 13 * 13 * 33,
        KER_SIZE = 3 * 3 * 33 * 32,
        OFM_SIZE = 11 * 11 * 32     ,
        BIS_SIZE = 32, 
        OUTPUT_HEIGHT = 11,
        OUTPUT_WIDTH = 11,
        OUTPUT_DEPTH = 32;

    initial begin
        al_accel_mem_read_ready    = 1'b 1;
        al_accel_mem_write_ready   = 1'b 1;
    end

    initial begin
        al_accel_cfgreg_di   = 32'd 0; al_accel_cfgreg_sel = 5'd 0; 
        al_accel_cfgreg_wenb =  1'd 0;
        al_accel_flow_enb    =  1'b 0;
        #42
        al_accel_cfgreg_wenb =  1'd 1;
    // Config Data
        #10 // i_base_addr
        al_accel_cfgreg_di   = 32'd 0000;       al_accel_cfgreg_sel = 5'd 0; 

        #10 // kw_base_addr
        al_accel_cfgreg_di   = 32'd 6000;       al_accel_cfgreg_sel = 5'd 1; 

        #10 // o_base_addr
        al_accel_cfgreg_di   = 32'd 16000;       al_accel_cfgreg_sel = 5'd 2; 

        #10 // b_base_addr
        al_accel_cfgreg_di   = 32'd 5600;       al_accel_cfgreg_sel = 5'd 3; 

        #10 // ps_base_addr
        al_accel_cfgreg_di   = 32'd 20000;       al_accel_cfgreg_sel = 5'd 4; 

        #10 // {stride_height, stride_width, cfg_act_func_typ, cfg_layer_typ}
        al_accel_cfgreg_di   = {16'd 0, 4'd 1, 4'd 1, RELU, CONV}; al_accel_cfgreg_sel = 5'd 5; 

        #10 // {weight_kernel_patch_height, weight_kernel_patch_width}
        al_accel_cfgreg_di   = {16'd 3, 16'd 3}; al_accel_cfgreg_sel = 5'd 6; 

        #10 // {nok_ofm_depth, kernel_ifm_depth} 
        al_accel_cfgreg_di   = {16'd 32, 16'd 33}; al_accel_cfgreg_sel = 5'd 7;
        
        #10 // {ifm_height, ifm_width}  
        al_accel_cfgreg_di   = {16'd 13, 16'd 13}; al_accel_cfgreg_sel = 5'd 8;

        #10 // {ofm_height, ofm_width}
        al_accel_cfgreg_di   = {16'd 11, 16'd 11}; al_accel_cfgreg_sel = 5'd 9;

        #10 // {output2D_size, input2D_size}  
        al_accel_cfgreg_di   = {16'd 121, 16'd 169}; al_accel_cfgreg_sel = 5'd 10;

        #10 // kernel3D_size
        al_accel_cfgreg_di   = {16'd  0, 16'd 297}; al_accel_cfgreg_sel = 5'd 11;

    // Output Quantize Buffer
        #10 // output_quant_sel 0
        al_accel_cfgreg_di   = {24'd 0, 8'd 0} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1689551407 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 12} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 1
        al_accel_cfgreg_di   = {24'd 0, 8'd 1} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1204010513 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 9} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 2
        al_accel_cfgreg_di   = {24'd 0, 8'd 2} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 2140008272 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 10} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 3
        al_accel_cfgreg_di   = {24'd 0, 8'd 3} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1909323516 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 10} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 4
        al_accel_cfgreg_di   = {24'd 0, 8'd 4} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1725018846 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 12} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 5
        al_accel_cfgreg_di   = {24'd 0, 8'd 5} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 2048260720 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 10} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 6
        al_accel_cfgreg_di   = {24'd 0, 8'd 6} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 2126767021 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 10} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 7
        al_accel_cfgreg_di   = {24'd 0, 8'd 7} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1808926684 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 10} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 8
        al_accel_cfgreg_di   = {24'd 0, 8'd 8} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1463903110 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 10} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 9
        al_accel_cfgreg_di   = {24'd 0, 8'd 9} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1253391477 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 9} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 10
        al_accel_cfgreg_di   = {24'd 0, 8'd 10} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1548369488 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 12} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 11
        al_accel_cfgreg_di   = {24'd 0, 8'd 11} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1854827854 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 12} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 12
        al_accel_cfgreg_di   = {24'd 0, 8'd 12} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1089899269 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 9} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 13
        al_accel_cfgreg_di   = {24'd 0, 8'd 13} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1700026496 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 12} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 14
        al_accel_cfgreg_di   = {24'd 0, 8'd 14} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 2095039993 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 10} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 15
        al_accel_cfgreg_di   = {24'd 0, 8'd 15} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1336030234 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 10} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 16
        al_accel_cfgreg_di   = {24'd 0, 8'd 16} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1663159508 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 12} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 17
        al_accel_cfgreg_di   = {24'd 0, 8'd 17} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1997878220 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 12} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 18
        al_accel_cfgreg_di   = {24'd 0, 8'd 18} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1660705979 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 12} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 19
        al_accel_cfgreg_di   = {24'd 0, 8'd 19} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1740647325 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 12} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 20
        al_accel_cfgreg_di   = {24'd 0, 8'd 20} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1385151967 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 10} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 21
        al_accel_cfgreg_di   = {24'd 0, 8'd 21} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1207776079 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 9} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 22
        al_accel_cfgreg_di   = {24'd 0, 8'd 22} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1712031603 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 10} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 23
        al_accel_cfgreg_di   = {24'd 0, 8'd 23} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1593821800 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 10} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 24
        al_accel_cfgreg_di   = {24'd 0, 8'd 24} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1368997244 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 10} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 25
        al_accel_cfgreg_di   = {24'd 0, 8'd 25} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1466326579 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 12} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 26
        al_accel_cfgreg_di   = {24'd 0, 8'd 26} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1582443027 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 10} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 27
        al_accel_cfgreg_di   = {24'd 0, 8'd 27} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1558951275 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 12} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 28
        al_accel_cfgreg_di   = {24'd 0, 8'd 28} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1682677520 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 10} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 29
        al_accel_cfgreg_di   = {24'd 0, 8'd 29} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1747796433 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 10} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 30
        al_accel_cfgreg_di   = {24'd 0, 8'd 30} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1716120888 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 12} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 31
        al_accel_cfgreg_di   = {24'd 0, 8'd 31} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1544083328 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 10} ; al_accel_cfgreg_sel = 5'd 14;
    // Data Offset
        #10 // input_offset
        al_accel_cfgreg_di   = 32'd128; al_accel_cfgreg_sel = 5'd 15;
        #10 // output_offset
        al_accel_cfgreg_di   = 32'd128; al_accel_cfgreg_sel = 5'd 16;


    // Flow Run
        #10
        al_accel_cfgreg_wenb =  1'd 0;
        #10 
        al_accel_flow_enb    =  1'd 1;
        // #1000
        // al_accel_flow_enb    =  1'd 0;
        // #200
        al_accel_flow_enb    =  1'd 1;
		// repeat (2000) @(posedge clk) begin
        //     #2 al_accel_flow_enb = $random;
        // end
        // #10 
        al_accel_flow_enb    =  1'd 1;
    end

    reg [IFM_SIZE    * 8 - 1:0] input_data ; // Size: 7 x 7 x 3
    reg [KER_SIZE * 8 - 1:0] filter_data; // Size: 3 x 3 x 3 x 6
    reg [ BIS_SIZE  * 32              - 1:0] bias_data  ; // Size: 6
    integer i;
    initial begin
        for (i = 0; i < 4096; i = i + 1)
            ram.mem[i] = 32'd 0;

        // Input Initilization
        input_data = {
        /* z = 0 */
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd90, -8'd46, -8'd63, -8'd110, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd27, 8'd58, 8'd42, 8'd63, 8'd63, 8'd69, 8'd65, 8'd61, -8'd23, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd127, -8'd128, -8'd128, -8'd111, -8'd93, -8'd81, -8'd73, -8'd13, -8'd43, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd110, -8'd3, -8'd34, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd41, -8'd11, -8'd96, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd111, -8'd26, -8'd46, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd126, -8'd20, 8'd4, -8'd103, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd66, 8'd9, -8'd36, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd108, 8'd11, -8'd24, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd44, 8'd3, -8'd52, -8'd119, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd56, -8'd35, -8'd117, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
    /* z = 1 */
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd98, -8'd102, -8'd119, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd40, -8'd2, -8'd5, -8'd21, -8'd39, -8'd39, -8'd39, -8'd40, -8'd114, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd70, -8'd36, -8'd15, 8'd1, -8'd2, -8'd1, 8'd23, 8'd27, -8'd65, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd120, -8'd115, -8'd107, -8'd10, -8'd17, -8'd82, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd52, -8'd11, -8'd28, -8'd119, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd108, -8'd20, -8'd15, -8'd89, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd126, -8'd50, -8'd14, -8'd44, -8'd123, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd73, -8'd14, -8'd16, -8'd93, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd106, -8'd13, -8'd15, -8'd59, -8'd126, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd52, 8'd28, -8'd14, -8'd115, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd28, 8'd13, -8'd32, -8'd122, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
    /* z = 2 */
        -8'd99, -8'd99, -8'd99, -8'd99, -8'd99, -8'd99, -8'd99, -8'd99, -8'd99, -8'd99, -8'd99, -8'd99, -8'd99,
        -8'd99, -8'd99, -8'd99, -8'd99, -8'd99, -8'd99, -8'd99, -8'd99, -8'd99, -8'd99, -8'd99, -8'd99, -8'd99,
        -8'd99, -8'd99, -8'd99, -8'd99, -8'd99, -8'd97, -8'd99, -8'd99, -8'd99, -8'd99, -8'd99, -8'd99, -8'd99,
        -8'd99, -8'd99, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd84, -8'd99, -8'd99,
        -8'd99, -8'd99, -8'd111, -8'd94, -8'd110, -8'd89, -8'd92, -8'd91, -8'd94, -8'd115, -8'd6, -8'd99, -8'd99,
        -8'd99, -8'd99, -8'd99, -8'd99, -8'd99, -8'd96, -8'd97, -8'd95, -8'd128, -8'd11, -8'd10, -8'd99, -8'd99,
        -8'd99, -8'd99, -8'd99, -8'd99, -8'd99, -8'd99, -8'd99, -8'd109, -8'd128, -8'd6, -8'd75, -8'd99, -8'd99,
        -8'd99, -8'd99, -8'd99, -8'd99, -8'd99, -8'd99, -8'd99, -8'd128, 8'd0, -8'd15, -8'd99, -8'd99, -8'd99,
        -8'd99, -8'd99, -8'd99, -8'd99, -8'd99, -8'd99, -8'd112, -8'd119, -8'd1, -8'd87, -8'd99, -8'd99, -8'd99,
        -8'd99, -8'd99, -8'd99, -8'd99, -8'd99, -8'd99, -8'd128, -8'd8, -8'd22, -8'd99, -8'd99, -8'd99, -8'd99,
        -8'd99, -8'd99, -8'd99, -8'd99, -8'd99, -8'd128, -8'd24, -8'd8, -8'd92, -8'd99, -8'd99, -8'd99, -8'd99,
        -8'd99, -8'd99, -8'd99, -8'd99, -8'd110, -8'd128, -8'd11, -8'd65, -8'd99, -8'd99, -8'd99, -8'd99, -8'd99,
        -8'd99, -8'd99, -8'd99, -8'd99, -8'd128, -8'd57, -8'd15, -8'd82, -8'd99, -8'd99, -8'd99, -8'd99, -8'd99,
    /* z = 3 */
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd117, -8'd109, -8'd119, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd75, -8'd2, -8'd27, -8'd50, -8'd59, -8'd58, -8'd55, -8'd57, -8'd59, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd64, -8'd25, -8'd12, 8'd4, 8'd3, 8'd8, 8'd11, 8'd36, -8'd19, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd120, -8'd114, -8'd110, -8'd55, 8'd26, -8'd56, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd121, 8'd37, 8'd23, -8'd117, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd47, 8'd25, -8'd68, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd114, 8'd29, 8'd7, -8'd125, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 8'd25, 8'd34, -8'd77, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd60, 8'd41, -8'd25, -8'd127, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd121, 8'd26, 8'd26, -8'd105, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd59, 8'd59, 8'd11, -8'd120, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
    /* z = 4 */
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
    /* z = 5 */
        -8'd78, -8'd78, -8'd78, -8'd78, -8'd78, -8'd78, -8'd78, -8'd78, -8'd78, -8'd78, -8'd78, -8'd78, -8'd78,
        -8'd78, -8'd78, -8'd78, -8'd78, -8'd78, -8'd78, -8'd78, -8'd78, -8'd78, -8'd78, -8'd78, -8'd78, -8'd78,
        -8'd78, -8'd78, -8'd71, -8'd78, -8'd78, -8'd78, -8'd78, -8'd78, -8'd78, -8'd78, -8'd78, -8'd78, -8'd78,
        -8'd78, -8'd78, -8'd70, -8'd128, -8'd128, -8'd127, -8'd113, -8'd113, -8'd113, -8'd115, -8'd89, -8'd78, -8'd78,
        -8'd78, -8'd78, -8'd94, -8'd97, -8'd118, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd89, -8'd78, -8'd78,
        -8'd78, -8'd78, -8'd78, -8'd78, -8'd78, -8'd78, -8'd78, -8'd73, -8'd74, -8'd128, -8'd75, -8'd78, -8'd78,
        -8'd78, -8'd78, -8'd78, -8'd78, -8'd78, -8'd78, -8'd78, -8'd73, -8'd128, -8'd78, -8'd76, -8'd78, -8'd78,
        -8'd78, -8'd78, -8'd78, -8'd78, -8'd78, -8'd78, -8'd73, -8'd85, -8'd128, -8'd76, -8'd78, -8'd78, -8'd78,
        -8'd78, -8'd78, -8'd78, -8'd78, -8'd78, -8'd77, -8'd70, -8'd128, -8'd77, -8'd75, -8'd78, -8'd78, -8'd78,
        -8'd78, -8'd78, -8'd78, -8'd78, -8'd78, -8'd69, -8'd95, -8'd126, -8'd75, -8'd78, -8'd78, -8'd78, -8'd78,
        -8'd78, -8'd78, -8'd78, -8'd78, -8'd73, -8'd70, -8'd128, -8'd74, -8'd76, -8'd78, -8'd78, -8'd78, -8'd78,
        -8'd78, -8'd78, -8'd78, -8'd78, -8'd74, -8'd128, -8'd128, -8'd78, -8'd78, -8'd78, -8'd78, -8'd78, -8'd78,
        -8'd78, -8'd78, -8'd78, -8'd78, -8'd89, -8'd128, -8'd71, -8'd76, -8'd78, -8'd78, -8'd78, -8'd78, -8'd78,
    /* z = 6 */
        -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90,
        -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90,
        -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90,
        -8'd90, -8'd90, -8'd97, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd93, -8'd90, -8'd90,
        -8'd90, -8'd90, -8'd107, -8'd102, -8'd126, -8'd128, -8'd127, -8'd128, -8'd128, -8'd128, -8'd60, -8'd90, -8'd90,
        -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd99, -8'd93, -8'd49, -8'd90, -8'd90,
        -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd128, -8'd44, -8'd72, -8'd90, -8'd90,
        -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd117, -8'd70, -8'd43, -8'd90, -8'd90, -8'd90,
        -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd91, -8'd128, -8'd43, -8'd78, -8'd90, -8'd90, -8'd90,
        -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd128, -8'd58, -8'd44, -8'd90, -8'd90, -8'd90, -8'd90,
        -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd102, -8'd120, -8'd45, -8'd83, -8'd90, -8'd90, -8'd90, -8'd90,
        -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd128, -8'd66, -8'd68, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90,
        -8'd90, -8'd90, -8'd90, -8'd90, -8'd114, -8'd128, -8'd46, -8'd79, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90,
    /* z = 7 */
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
    /* z = 8 */
        -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd113,
        -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd113,
        -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd113,
        -8'd113, -8'd113, -8'd67, -8'd30, -8'd60, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd119, -8'd113, -8'd113,
        -8'd113, -8'd113, -8'd33, 8'd9, 8'd24, 8'd19, 8'd7, 8'd1, 8'd6, -8'd56, -8'd59, -8'd113, -8'd113,
        -8'd113, -8'd113, -8'd113, -8'd113, -8'd111, -8'd100, -8'd93, -8'd88, -8'd128, -8'd38, -8'd61, -8'd113, -8'd113,
        -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd123, -8'd51, -8'd29, -8'd100, -8'd113, -8'd113,
        -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd128, -8'd39, -8'd68, -8'd113, -8'd113, -8'd113,
        -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd126, -8'd54, -8'd44, -8'd107, -8'd113, -8'd113, -8'd113,
        -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd89, -8'd27, -8'd70, -8'd113, -8'd113, -8'd113, -8'd113,
        -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd128, -8'd25, -8'd32, -8'd109, -8'd113, -8'd113, -8'd113, -8'd113,
        -8'd113, -8'd113, -8'd113, -8'd113, -8'd124, -8'd92, -8'd76, -8'd102, -8'd113, -8'd113, -8'd113, -8'd113, -8'd113,
        -8'd113, -8'd113, -8'd113, -8'd113, -8'd30, 8'd29, -8'd17, -8'd104, -8'd113, -8'd113, -8'd113, -8'd113, -8'd113,
    /* z = 9 */
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd95, -8'd88, -8'd104, -8'd124, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd11, 8'd16, 8'd12, -8'd6, -8'd18, -8'd17, -8'd19, -8'd21, -8'd108, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd43, -8'd18, 8'd10, 8'd24, 8'd17, 8'd18, 8'd38, 8'd74, -8'd64, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd127, -8'd114, -8'd109, -8'd102, 8'd31, 8'd36, -8'd89, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd32, 8'd34, -8'd8, -8'd123, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd108, 8'd26, 8'd31, -8'd99, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd125, -8'd24, 8'd30, -8'd29, -8'd123, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd61, 8'd30, 8'd23, -8'd102, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd104, 8'd24, 8'd40, -8'd57, -8'd125, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd33, 8'd70, 8'd16, -8'd118, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd1, 8'd58, -8'd17, -8'd125, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
    /* z = 10 */
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
    /* z = 11 */
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd93, -8'd81, -8'd99, -8'd123, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, 8'd6, 8'd46, 8'd45, 8'd24, 8'd7, 8'd6, 8'd3, 8'd2, -8'd96, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd28, 8'd1, 8'd34, 8'd51, 8'd53, 8'd53, 8'd59, 8'd108, -8'd56, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd126, -8'd111, -8'd106, -8'd101, 8'd57, 8'd71, -8'd79, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd17, 8'd74, 8'd9, -8'd120, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd113, 8'd56, 8'd71, -8'd91, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd126, 8'd0, 8'd59, -8'd13, -8'd124, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd59, 8'd72, 8'd63, -8'd94, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd108, 8'd47, 8'd72, -8'd41, -8'd125, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd20, 8'd109, 8'd53, -8'd119, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, 8'd15, 8'd99, -8'd2, -8'd123, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
    /* z = 12 */
        -8'd104, -8'd104, -8'd104, -8'd104, -8'd104, -8'd104, -8'd104, -8'd104, -8'd104, -8'd104, -8'd104, -8'd104, -8'd104,
        -8'd104, -8'd104, -8'd104, -8'd104, -8'd104, -8'd104, -8'd104, -8'd104, -8'd104, -8'd104, -8'd104, -8'd104, -8'd104,
        -8'd104, -8'd104, -8'd40, 8'd18, -8'd11, -8'd80, -8'd104, -8'd104, -8'd104, -8'd104, -8'd104, -8'd104, -8'd104,
        -8'd104, -8'd104, -8'd18, 8'd14, 8'd46, 8'd52, 8'd42, 8'd42, 8'd42, 8'd36, -8'd38, -8'd104, -8'd104,
        -8'd104, -8'd104, -8'd118, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd96, -8'd95, -8'd104, -8'd104,
        -8'd104, -8'd104, -8'd104, -8'd104, -8'd104, -8'd104, -8'd104, -8'd77, -8'd51, -8'd120, -8'd106, -8'd104, -8'd104,
        -8'd104, -8'd104, -8'd104, -8'd104, -8'd104, -8'd104, -8'd104, -8'd47, -8'd61, -8'd128, -8'd104, -8'd104, -8'd104,
        -8'd104, -8'd104, -8'd104, -8'd104, -8'd104, -8'd104, -8'd77, -8'd57, -8'd128, -8'd105, -8'd104, -8'd104, -8'd104,
        -8'd104, -8'd104, -8'd104, -8'd104, -8'd104, -8'd100, -8'd39, -8'd52, -8'd125, -8'd104, -8'd104, -8'd104, -8'd104,
        -8'd104, -8'd104, -8'd104, -8'd104, -8'd104, -8'd57, -8'd27, -8'd128, -8'd104, -8'd104, -8'd104, -8'd104, -8'd104,
        -8'd104, -8'd104, -8'd104, -8'd104, -8'd77, -8'd42, -8'd108, -8'd110, -8'd104, -8'd104, -8'd104, -8'd104, -8'd104,
        -8'd104, -8'd104, -8'd104, -8'd104, -8'd50, -8'd62, -8'd106, -8'd104, -8'd104, -8'd104, -8'd104, -8'd104, -8'd104,
        -8'd104, -8'd104, -8'd104, -8'd104, -8'd99, -8'd128, -8'd128, -8'd104, -8'd104, -8'd104, -8'd104, -8'd104, -8'd104,
    /* z = 13 */
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
    /* z = 14 */
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd112, -8'd68, -8'd78, -8'd113, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd35, 8'd19, 8'd9, 8'd16, 8'd15, 8'd18, 8'd17, 8'd10, -8'd45, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd57, -8'd39, -8'd17, 8'd2, 8'd7, 8'd17, 8'd12, 8'd56, -8'd22, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd127, -8'd119, -8'd114, -8'd113, 8'd26, 8'd63, -8'd77, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd60, 8'd71, 8'd25, -8'd124, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd124, 8'd25, 8'd59, -8'd91, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd43, 8'd59, 8'd6, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd93, 8'd73, 8'd67, -8'd98, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd121, 8'd20, 8'd68, -8'd43, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd61, 8'd91, 8'd56, -8'd113, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd35, 8'd78, 8'd5, -8'd125, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
    /* z = 15 */
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd93, -8'd84, -8'd103, -8'd125, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd31, 8'd2, 8'd10, 8'd6, -8'd4, -8'd5, -8'd8, -8'd9, -8'd94, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd72, -8'd48, -8'd25, -8'd8, 8'd1, 8'd3, 8'd17, 8'd46, -8'd75, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd127, -8'd121, -8'd118, -8'd109, 8'd18, 8'd5, -8'd93, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd26, 8'd18, -8'd47, -8'd121, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd111, 8'd9, 8'd6, -8'd97, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd126, -8'd13, 8'd13, -8'd61, -8'd126, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd59, 8'd16, 8'd2, -8'd100, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd107, 8'd17, 8'd9, -8'd76, -8'd127, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd28, 8'd50, -8'd9, -8'd119, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd8, 8'd35, -8'd56, -8'd122, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
    /* z = 16 */
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd108, -8'd91, -8'd100, -8'd122, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd28, -8'd2, -8'd9, -8'd11, -8'd19, -8'd19, -8'd20, -8'd21, -8'd87, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd63, -8'd47, -8'd25, -8'd4, -8'd1, 8'd1, -8'd5, 8'd35, -8'd67, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd126, -8'd119, -8'd116, -8'd114, 8'd21, 8'd27, -8'd102, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd51, 8'd31, -8'd31, -8'd124, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd123, 8'd16, 8'd27, -8'd108, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd34, 8'd25, -8'd49, -8'd127, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd94, 8'd32, 8'd23, -8'd111, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd121, 8'd18, 8'd28, -8'd80, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd53, 8'd47, 8'd10, -8'd122, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd24, 8'd37, -8'd46, -8'd125, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
    /* z = 17 */
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd115, -8'd104, -8'd127, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd49, -8'd58, -8'd80, -8'd69, -8'd59, -8'd55, -8'd51, -8'd59, -8'd84, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd96, -8'd128, -8'd128, -8'd128, -8'd128, -8'd122, -8'd120, -8'd105, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd8, 8'd5, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd99, 8'd12, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd9, -8'd17, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd77, 8'd11, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 8'd4, -8'd29, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd8, 8'd17, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd101, -8'd19, -8'd115, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd55, -8'd45, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
    /* z = 18 */
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
    /* z = 19 */
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
    /* z = 20 */
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd112, -8'd72, -8'd81, -8'd116, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd30, 8'd12, -8'd1, 8'd10, 8'd10, 8'd14, 8'd12, 8'd7, -8'd52, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd50, -8'd46, -8'd24, -8'd7, -8'd1, 8'd10, 8'd6, 8'd40, -8'd41, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd120, -8'd114, -8'd116, 8'd34, 8'd65, -8'd95, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd51, 8'd73, 8'd3, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd125, 8'd33, 8'd59, -8'd108, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd34, 8'd60, -8'd14, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd89, 8'd75, 8'd64, -8'd114, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd122, 8'd29, 8'd68, -8'd62, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd53, 8'd88, 8'd39, -8'd122, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd23, 8'd67, -8'd18, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
    /* z = 21 */
        -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd94,
        -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd94,
        -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd94,
        -8'd94, -8'd94, -8'd44, -8'd66, -8'd91, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd107, -8'd94, -8'd94,
        -8'd94, -8'd94, -8'd22, 8'd21, 8'd33, 8'd15, 8'd17, 8'd16, 8'd7, -8'd71, -8'd79, -8'd94, -8'd94,
        -8'd94, -8'd94, -8'd94, -8'd94, -8'd91, -8'd82, -8'd69, -8'd66, -8'd79, -8'd124, -8'd69, -8'd94, -8'd94,
        -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd86, -8'd120, -8'd51, -8'd81, -8'd94, -8'd94,
        -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd75, -8'd98, -8'd62, -8'd94, -8'd94, -8'd94,
        -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd98, -8'd128, -8'd63, -8'd83, -8'd94, -8'd94, -8'd94,
        -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd81, -8'd119, -8'd71, -8'd64, -8'd94, -8'd94, -8'd94, -8'd94,
        -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd103, -8'd119, -8'd55, -8'd87, -8'd94, -8'd94, -8'd94, -8'd94,
        -8'd94, -8'd94, -8'd94, -8'd94, -8'd83, -8'd120, -8'd128, -8'd88, -8'd94, -8'd94, -8'd94, -8'd94, -8'd94,
        -8'd94, -8'd94, -8'd94, -8'd94, -8'd6, 8'd2, -8'd40, -8'd86, -8'd94, -8'd94, -8'd94, -8'd94, -8'd94,
    /* z = 22 */
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd93, -8'd59, -8'd72, -8'd115, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd43, 8'd18, 8'd17, 8'd25, 8'd23, 8'd26, 8'd22, 8'd23, -8'd50, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd89, -8'd87, -8'd79, -8'd79, 8'd20, -8'd28, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd118, -8'd53, -8'd30, -8'd93, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd97, -8'd47, -8'd39, -8'd122, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd118, -8'd66, -8'd42, -8'd99, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd127, -8'd72, -8'd43, -8'd48, -8'd126, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd104, -8'd40, -8'd45, -8'd104, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd117, -8'd52, -8'd39, -8'd85, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd100, -8'd20, 8'd11, -8'd115, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd115, -8'd43, -8'd50, -8'd124, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
    /* z = 23 */
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd80, -8'd40, -8'd63, -8'd111, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd18, 8'd51, 8'd42, 8'd47, 8'd56, 8'd61, 8'd56, 8'd54, -8'd43, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd118, -8'd128, -8'd128, -8'd106, -8'd89, -8'd77, -8'd59, -8'd16, -8'd63, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd103, 8'd29, -8'd4, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd29, 8'd18, -8'd91, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd104, 8'd5, -8'd22, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd125, -8'd8, 8'd30, -8'd101, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd59, 8'd38, -8'd22, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd102, 8'd39, 8'd9, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd31, 8'd35, -8'd44, -8'd126, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd28, -8'd3, -8'd114, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
    /* z = 24 */
        -8'd126, -8'd126, -8'd126, -8'd126, -8'd126, -8'd126, -8'd126, -8'd126, -8'd126, -8'd126, -8'd126, -8'd126, -8'd126,
        -8'd126, -8'd126, -8'd126, -8'd126, -8'd126, -8'd126, -8'd126, -8'd126, -8'd126, -8'd126, -8'd126, -8'd126, -8'd126,
        -8'd126, -8'd126, -8'd98, -8'd91, -8'd106, -8'd122, -8'd126, -8'd126, -8'd126, -8'd126, -8'd126, -8'd126, -8'd126,
        -8'd126, -8'd126, -8'd70, -8'd21, -8'd13, -8'd20, -8'd29, -8'd29, -8'd29, -8'd32, -8'd90, -8'd126, -8'd126,
        -8'd126, -8'd126, -8'd104, -8'd64, -8'd50, -8'd34, -8'd29, -8'd27, -8'd5, -8'd3, -8'd52, -8'd126, -8'd126,
        -8'd126, -8'd126, -8'd126, -8'd126, -8'd126, -8'd122, -8'd117, -8'd106, -8'd43, -8'd39, -8'd69, -8'd126, -8'd126,
        -8'd126, -8'd126, -8'd126, -8'd126, -8'd126, -8'd126, -8'd126, -8'd66, -8'd42, -8'd37, -8'd113, -8'd126, -8'd126,
        -8'd126, -8'd126, -8'd126, -8'd126, -8'd126, -8'd126, -8'd107, -8'd53, -8'd41, -8'd75, -8'd126, -8'd126, -8'd126,
        -8'd126, -8'd126, -8'd126, -8'd126, -8'd126, -8'd123, -8'd63, -8'd42, -8'd47, -8'd120, -8'd126, -8'd126, -8'd126,
        -8'd126, -8'd126, -8'd126, -8'd126, -8'd126, -8'd75, -8'd37, -8'd38, -8'd80, -8'd126, -8'd126, -8'd126, -8'd126,
        -8'd126, -8'd126, -8'd126, -8'd126, -8'd105, -8'd42, -8'd34, -8'd56, -8'd122, -8'd126, -8'd126, -8'd126, -8'd126,
        -8'd126, -8'd126, -8'd126, -8'd126, -8'd66, 8'd3, -8'd26, -8'd105, -8'd126, -8'd126, -8'd126, -8'd126, -8'd126,
        -8'd126, -8'd126, -8'd126, -8'd126, -8'd59, -8'd16, -8'd39, -8'd116, -8'd126, -8'd126, -8'd126, -8'd126, -8'd126,
    /* z = 25 */
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
    /* z = 26 */
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd109, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd31, -8'd79, -8'd82, -8'd125, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd58, -8'd61, -8'd43, -8'd38, -8'd57, -8'd68, -8'd16, -8'd2, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd126, -8'd123, -8'd113, -8'd42, -8'd78, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd53, -8'd49, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd115, -8'd29, -8'd87, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd59, -8'd60, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd69, -8'd36, -8'd122, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd111, -8'd52, -8'd62, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd53, -8'd35, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd23, -8'd34, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
    /* z = 27 */
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
    /* z = 28 */
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
    /* z = 29 */
        -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd101,
        -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd101,
        -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd101,
        -8'd101, -8'd101, -8'd77, -8'd98, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd109, -8'd101, -8'd101,
        -8'd101, -8'd101, 8'd7, 8'd43, 8'd47, 8'd48, 8'd54, 8'd49, 8'd31, -8'd57, -8'd98, -8'd101, -8'd101,
        -8'd101, -8'd101, -8'd101, -8'd101, -8'd97, -8'd79, -8'd67, -8'd58, -8'd109, -8'd80, -8'd80, -8'd101, -8'd101,
        -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd109, -8'd98, -8'd59, -8'd93, -8'd101, -8'd101,
        -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd120, -8'd79, -8'd77, -8'd101, -8'd101, -8'd101,
        -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd112, -8'd105, -8'd79, -8'd91, -8'd101, -8'd101, -8'd101,
        -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd102, -8'd128, -8'd66, -8'd77, -8'd101, -8'd101, -8'd101, -8'd101,
        -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd128, -8'd71, -8'd58, -8'd95, -8'd101, -8'd101, -8'd101, -8'd101,
        -8'd101, -8'd101, -8'd101, -8'd101, -8'd110, -8'd128, -8'd124, -8'd97, -8'd101, -8'd101, -8'd101, -8'd101, -8'd101,
        -8'd101, -8'd101, -8'd101, -8'd101, -8'd19, 8'd13, -8'd31, -8'd94, -8'd101, -8'd101, -8'd101, -8'd101, -8'd101,
    /* z = 30 */
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd117, -8'd126, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd102, -8'd123, -8'd121, -8'd128, -8'd128, -8'd128, -8'd78, -8'd45, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd127, -8'd79, -8'd101, -8'd77, -8'd93, -8'd79, -8'd73, 8'd18, 8'd7, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd126, -8'd128, -8'd125, -8'd128, 8'd42, -8'd46, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 8'd25, 8'd39, -8'd127, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 8'd44, -8'd65, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 8'd28, 8'd39, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd58, 8'd36, -8'd77, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 8'd38, -8'd2, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd88, 8'd33, -8'd112, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd14, 8'd29, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
    /* z = 31 */
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd122, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd16, 8'd3, -8'd9, -8'd61, -8'd87, -8'd91, -8'd87, -8'd94, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd44, -8'd23, 8'd10, 8'd21, 8'd22, 8'd17, 8'd34, 8'd6, -8'd109, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd125, -8'd116, -8'd114, -8'd113, -8'd35, -8'd57, -8'd102, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd42, -8'd31, -8'd82, -8'd120, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd117, -8'd23, -8'd51, -8'd104, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd127, -8'd55, -8'd47, -8'd100, -8'd127, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd64, -8'd33, -8'd51, -8'd104, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd111, -8'd35, -8'd50, -8'd87, -8'd127, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd41, -8'd15, -8'd96, -8'd126, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd10, 8'd12, -8'd77, -8'd121, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        1352'd0
    };

        for (i = 0; i < (IFM_SIZE); i = i + 4) begin
            ram.mem[0 + (i / 4)][ 7: 0] = input_data[8*((IFM_SIZE) - 1 - i) +: 8];
            ram.mem[0 + (i / 4)][15: 8] = input_data[8*((IFM_SIZE) - 2 - i) +: 8];
            ram.mem[0 + (i / 4)][23:16] = input_data[8*((IFM_SIZE) - 3 - i) +: 8];
            ram.mem[0 + (i / 4)][31:24] = input_data[8*((IFM_SIZE) - 4 - i) +: 8];
        end
        
        // $display("INPUT RESULT");
        // for (int i = 0; i < 0 + IFM_SIZE / 4; i = i + 1) begin
        //     $display("%d %d %d %d", 
        //         $signed(ram.mem[i][ 7: 0]), 
        //         $signed(ram.mem[i][15: 8]), 
        //         $signed(ram.mem[i][23:16]), 
        //         $signed(ram.mem[i][31:24])
        //     ); 
        // end
        // $display("*************");

        // Kernel 
       filter_data = {
            -8'd79, -8'd97, -8'd56, -8'd108, -8'd102, 8'd2, -8'd70, 8'd60, -8'd66,
            -8'd123, -8'd100, -8'd71, 8'd84, -8'd83, -8'd36, 8'd3, -8'd116, 8'd34,
            8'd38, -8'd87, 8'd57, 8'd60, 8'd21, -8'd3, -8'd49, -8'd82, -8'd57,
            8'd65, 8'd89, -8'd62, -8'd126, -8'd87, -8'd25, -8'd127, -8'd62, 8'd73,
            -8'd32, 8'd64, 8'd48, -8'd10, 8'd7, 8'd32, -8'd54, -8'd80, 8'd92,
            8'd4, 8'd33, -8'd65, 8'd87, 8'd2, -8'd73, -8'd107, -8'd15, -8'd77,
            8'd40, 8'd87, -8'd29, -8'd106, -8'd70, -8'd19, -8'd4, 8'd64, -8'd118,
            8'd79, -8'd64, 8'd82, -8'd40, 8'd78, 8'd0, -8'd29, 8'd95, -8'd94,
            8'd7, 8'd23, -8'd57, -8'd118, -8'd90, 8'd36, -8'd115, 8'd15, -8'd58,
            -8'd8, -8'd74, 8'd7, -8'd104, -8'd34, -8'd36, -8'd113, 8'd90, -8'd96,
            -8'd73, -8'd17, 8'd44, 8'd107, -8'd87, -8'd38, -8'd93, 8'd93, 8'd2,
            -8'd121, 8'd37, 8'd68, -8'd62, 8'd3, -8'd113, 8'd84, -8'd57, -8'd86,
            8'd54, -8'd92, -8'd40, -8'd109, 8'd50, 8'd16, 8'd87, 8'd64, 8'd41,
            8'd71, 8'd32, 8'd2, -8'd24, -8'd55, -8'd101, 8'd85, -8'd52, 8'd88,
            -8'd6, 8'd34, -8'd83, 8'd55, -8'd58, -8'd14, -8'd5, 8'd70, -8'd118,
            -8'd18, 8'd14, 8'd8, 8'd8, 8'd30, -8'd99, 8'd83, -8'd2, -8'd42,
            8'd75, -8'd25, -8'd41, 8'd4, -8'd3, -8'd79, 8'd40, -8'd104, -8'd24,
            -8'd70, 8'd92, 8'd52, -8'd74, 8'd13, 8'd99, -8'd73, -8'd73, 8'd19,
            -8'd28, -8'd32, -8'd71, -8'd4, -8'd4, 8'd77, 8'd7, 8'd54, -8'd46,
            8'd81, -8'd65, 8'd15, -8'd68, 8'd1, 8'd44, 8'd91, 8'd84, 8'd7,
            8'd24, -8'd92, -8'd78, 8'd17, -8'd109, -8'd69, -8'd74, -8'd49, 8'd57,
            -8'd29, 8'd12, -8'd28, -8'd92, 8'd44, -8'd119, 8'd39, 8'd20, 8'd43,
            -8'd101, 8'd70, 8'd63, -8'd7, 8'd39, 8'd81, -8'd104, -8'd46, -8'd11,
            8'd62, 8'd98, 8'd54, 8'd61, -8'd56, -8'd75, 8'd84, 8'd82, 8'd41,
            -8'd68, -8'd66, 8'd48, -8'd119, -8'd120, -8'd46, -8'd52, -8'd47, -8'd118,
            8'd31, 8'd33, 8'd102, 8'd81, 8'd27, -8'd96, -8'd15, 8'd39, 8'd61,
            -8'd23, 8'd33, 8'd75, 8'd106, -8'd68, -8'd46, -8'd4, 8'd25, -8'd9,
            -8'd63, -8'd32, -8'd14, 8'd97, -8'd15, -8'd109, -8'd33, -8'd100, 8'd101,
            -8'd71, 8'd10, 8'd82, -8'd71, 8'd51, 8'd110, -8'd25, 8'd13, -8'd21,
            8'd29, 8'd8, 8'd71, -8'd3, 8'd36, -8'd38, -8'd67, -8'd58, -8'd42,
            8'd73, 8'd68, 8'd31, -8'd108, -8'd107, -8'd102, -8'd64, -8'd88, 8'd69,
            8'd12, 8'd88, -8'd30, 8'd95, -8'd115, 8'd30, 8'd14, -8'd20, 8'd53,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd45, -8'd17, -8'd48, 8'd23, -8'd8, -8'd35, -8'd33, -8'd106, -8'd15,
            8'd41, 8'd3, 8'd9, 8'd20, 8'd11, -8'd7, -8'd2, -8'd47, -8'd2,
            8'd27, 8'd4, 8'd1, 8'd20, 8'd32, 8'd13, 8'd18, 8'd20, 8'd21,
            8'd24, 8'd31, -8'd5, 8'd29, 8'd5, -8'd27, 8'd25, 8'd0, -8'd20,
            8'd21, -8'd13, 8'd13, -8'd6, -8'd14, 8'd1, 8'd19, 8'd10, -8'd16,
            -8'd13, 8'd8, 8'd20, -8'd8, 8'd14, 8'd10, 8'd14, 8'd26, 8'd17,
            8'd3, -8'd13, 8'd16, 8'd22, 8'd30, -8'd4, 8'd11, 8'd19, -8'd14,
            -8'd8, 8'd13, -8'd17, 8'd15, 8'd19, -8'd12, 8'd6, 8'd13, -8'd2,
            8'd25, 8'd0, 8'd7, 8'd20, 8'd5, -8'd1, 8'd21, -8'd3, 8'd8,
            8'd29, 8'd27, 8'd10, 8'd45, -8'd9, -8'd16, -8'd27, -8'd52, -8'd17,
            -8'd19, -8'd14, -8'd13, 8'd2, -8'd3, -8'd10, 8'd18, 8'd9, -8'd3,
            8'd39, 8'd17, -8'd3, 8'd26, 8'd7, -8'd50, 8'd11, -8'd52, 8'd18,
            -8'd47, -8'd51, -8'd60, -8'd53, -8'd22, -8'd10, -8'd47, -8'd47, -8'd26,
            8'd14, -8'd8, -8'd6, 8'd5, 8'd20, 8'd12, 8'd16, 8'd12, 8'd8,
            8'd39, 8'd35, -8'd18, 8'd26, -8'd19, -8'd45, 8'd5, -8'd57, -8'd18,
            8'd31, 8'd24, -8'd11, 8'd26, -8'd10, -8'd39, -8'd21, -8'd56, -8'd19,
            8'd24, 8'd4, -8'd22, 8'd37, -8'd20, -8'd32, -8'd18, -8'd41, -8'd12,
            8'd19, -8'd60, -8'd127, -8'd41, -8'd62, 8'd14, -8'd70, -8'd43, 8'd57,
            8'd15, 8'd13, 8'd3, 8'd11, 8'd15, -8'd8, 8'd6, 8'd1, 8'd12,
            8'd18, -8'd10, 8'd1, -8'd10, 8'd8, -8'd7, 8'd15, 8'd7, -8'd6,
            8'd52, 8'd34, -8'd13, 8'd22, -8'd16, -8'd7, 8'd19, -8'd65, -8'd24,
            -8'd18, -8'd14, 8'd5, 8'd8, -8'd9, -8'd18, 8'd10, -8'd11, 8'd18,
            8'd51, 8'd12, -8'd40, 8'd13, -8'd27, -8'd32, -8'd21, -8'd71, -8'd27,
            8'd32, 8'd7, -8'd54, -8'd5, -8'd18, -8'd22, -8'd61, -8'd64, 8'd10,
            8'd33, 8'd25, 8'd17, 8'd30, -8'd3, -8'd8, 8'd14, -8'd25, -8'd15,
            8'd2, -8'd13, 8'd7, -8'd1, -8'd16, 8'd18, -8'd1, 8'd15, -8'd17,
            8'd9, 8'd9, -8'd43, -8'd3, -8'd69, -8'd49, -8'd85, -8'd114, 8'd16,
            -8'd7, -8'd10, -8'd5, 8'd16, -8'd1, -8'd13, -8'd12, 8'd13, 8'd0,
            8'd3, 8'd16, -8'd19, -8'd13, -8'd6, 8'd0, 8'd17, -8'd11, -8'd11,
            -8'd64, 8'd3, -8'd1, -8'd15, -8'd10, -8'd24, 8'd22, -8'd9, -8'd10,
            8'd74, 8'd36, 8'd14, 8'd29, 8'd24, -8'd22, 8'd27, -8'd24, -8'd49,
            8'd10, -8'd11, -8'd37, 8'd23, -8'd27, -8'd53, -8'd32, -8'd11, 8'd11,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd6, -8'd7, -8'd3, -8'd20, -8'd36, -8'd3, -8'd25, -8'd22, -8'd17,
            -8'd37, 8'd15, 8'd6, -8'd16, 8'd12, 8'd39, -8'd23, 8'd14, 8'd41,
            -8'd7, 8'd0, -8'd30, 8'd6, -8'd5, -8'd2, 8'd12, 8'd16, 8'd2,
            -8'd11, -8'd30, 8'd1, 8'd7, -8'd35, 8'd23, 8'd8, -8'd27, 8'd19,
            8'd1, 8'd16, -8'd17, -8'd14, -8'd12, -8'd10, -8'd16, 8'd16, 8'd1,
            8'd1, 8'd20, -8'd11, 8'd7, 8'd41, -8'd49, -8'd17, 8'd8, -8'd28,
            8'd31, 8'd30, -8'd49, 8'd3, 8'd4, -8'd29, 8'd29, 8'd21, -8'd20,
            -8'd14, 8'd13, 8'd14, -8'd5, -8'd1, -8'd20, 8'd14, -8'd1, -8'd5,
            -8'd10, -8'd45, -8'd6, 8'd7, -8'd42, -8'd21, 8'd16, -8'd28, 8'd4,
            -8'd35, -8'd8, 8'd43, -8'd33, -8'd3, 8'd36, -8'd43, -8'd29, 8'd47,
            -8'd22, 8'd16, 8'd22, 8'd6, -8'd8, -8'd21, 8'd5, 8'd17, -8'd7,
            -8'd24, -8'd7, 8'd55, -8'd27, -8'd2, 8'd29, -8'd45, -8'd13, 8'd73,
            8'd14, -8'd29, -8'd48, 8'd20, -8'd49, -8'd46, 8'd0, -8'd55, -8'd49,
            -8'd22, -8'd17, -8'd16, 8'd13, 8'd10, 8'd8, 8'd18, 8'd6, -8'd11,
            -8'd28, -8'd24, 8'd29, -8'd8, -8'd15, 8'd32, -8'd32, -8'd19, 8'd42,
            -8'd50, 8'd23, 8'd41, -8'd14, 8'd3, 8'd29, -8'd52, -8'd2, 8'd28,
            -8'd54, -8'd14, 8'd43, -8'd22, 8'd8, 8'd23, -8'd17, -8'd39, 8'd22,
            8'd0, -8'd23, 8'd39, -8'd43, 8'd9, -8'd47, -8'd27, -8'd66, -8'd57,
            8'd18, -8'd17, 8'd17, 8'd4, -8'd16, -8'd4, -8'd4, -8'd10, -8'd8,
            8'd19, -8'd14, -8'd6, -8'd4, 8'd8, 8'd15, 8'd17, -8'd4, 8'd3,
            -8'd42, -8'd5, 8'd44, -8'd1, -8'd8, 8'd42, -8'd31, -8'd25, 8'd41,
            -8'd31, 8'd8, 8'd4, 8'd14, 8'd22, -8'd26, 8'd32, 8'd4, 8'd3,
            -8'd9, -8'd55, 8'd30, -8'd18, -8'd41, 8'd15, -8'd40, -8'd38, 8'd46,
            -8'd30, 8'd5, 8'd2, -8'd7, -8'd29, 8'd9, -8'd43, -8'd9, 8'd28,
            -8'd28, -8'd9, 8'd8, 8'd17, -8'd9, 8'd22, -8'd10, 8'd14, 8'd3,
            -8'd6, -8'd20, 8'd8, -8'd14, -8'd13, 8'd12, -8'd15, -8'd21, -8'd5,
            -8'd85, 8'd11, 8'd85, -8'd62, 8'd10, 8'd79, -8'd36, 8'd26, 8'd127,
            -8'd20, -8'd2, -8'd9, 8'd6, -8'd20, -8'd12, 8'd6, 8'd5, 8'd3,
            8'd17, -8'd5, 8'd9, 8'd13, 8'd10, 8'd21, -8'd13, -8'd3, 8'd2,
            -8'd11, -8'd12, -8'd102, 8'd14, -8'd44, -8'd66, 8'd51, 8'd12, -8'd31,
            8'd14, -8'd46, 8'd71, 8'd12, -8'd61, 8'd37, -8'd1, -8'd111, -8'd8,
            -8'd44, 8'd13, 8'd17, -8'd33, 8'd4, 8'd32, -8'd12, 8'd12, 8'd38,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd16, -8'd50, -8'd14, 8'd45, 8'd10, -8'd71, 8'd24, 8'd51, 8'd4,
            -8'd1, 8'd12, 8'd53, -8'd20, -8'd40, -8'd50, 8'd60, 8'd32, 8'd7,
            -8'd24, -8'd18, 8'd13, -8'd58, -8'd27, -8'd1, -8'd10, -8'd10, -8'd35,
            8'd14, -8'd13, 8'd36, -8'd33, -8'd12, -8'd48, 8'd37, 8'd47, -8'd1,
            8'd3, -8'd10, -8'd23, -8'd19, -8'd6, 8'd21, 8'd22, 8'd11, 8'd8,
            8'd25, 8'd19, 8'd27, 8'd37, 8'd18, -8'd15, -8'd24, 8'd12, -8'd9,
            8'd0, 8'd16, 8'd16, -8'd18, 8'd11, -8'd27, 8'd14, -8'd18, -8'd31,
            -8'd9, 8'd8, -8'd3, 8'd14, 8'd11, 8'd1, 8'd7, 8'd12, 8'd8,
            8'd20, 8'd48, 8'd9, -8'd12, -8'd48, -8'd3, 8'd36, -8'd14, -8'd54,
            -8'd30, -8'd1, 8'd22, -8'd34, -8'd60, -8'd46, 8'd67, 8'd15, -8'd37,
            8'd20, -8'd18, -8'd19, -8'd6, -8'd13, 8'd9, 8'd3, -8'd8, -8'd24,
            -8'd35, -8'd1, 8'd47, -8'd58, -8'd85, -8'd63, 8'd43, 8'd58, -8'd18,
            -8'd13, -8'd15, -8'd59, 8'd98, 8'd62, -8'd10, -8'd8, -8'd3, -8'd7,
            -8'd11, -8'd8, -8'd5, -8'd1, 8'd17, 8'd19, -8'd23, 8'd23, 8'd18,
            -8'd1, -8'd19, 8'd39, -8'd5, -8'd30, -8'd36, 8'd57, 8'd16, -8'd23,
            -8'd29, -8'd6, 8'd22, 8'd3, -8'd38, -8'd59, 8'd34, 8'd15, -8'd33,
            -8'd46, -8'd25, 8'd18, -8'd35, -8'd37, -8'd60, 8'd37, 8'd40, -8'd12,
            -8'd39, -8'd127, 8'd21, -8'd71, -8'd91, -8'd61, -8'd21, -8'd52, -8'd68,
            8'd17, -8'd9, -8'd15, 8'd17, -8'd11, -8'd15, -8'd24, 8'd8, -8'd12,
            -8'd12, 8'd12, -8'd1, -8'd6, -8'd12, -8'd9, -8'd5, -8'd6, -8'd1,
            -8'd17, -8'd33, 8'd17, -8'd37, -8'd27, -8'd77, 8'd19, 8'd25, -8'd25,
            8'd20, 8'd9, 8'd2, -8'd17, 8'd15, 8'd28, 8'd38, -8'd19, -8'd24,
            -8'd76, -8'd36, -8'd17, 8'd59, -8'd6, -8'd70, 8'd54, 8'd43, 8'd4,
            -8'd43, -8'd66, 8'd10, 8'd48, -8'd5, -8'd37, 8'd50, 8'd8, -8'd15,
            8'd17, -8'd8, 8'd17, 8'd11, 8'd14, -8'd21, 8'd59, 8'd22, 8'd32,
            8'd4, 8'd9, 8'd23, 8'd12, -8'd22, -8'd15, 8'd14, 8'd4, -8'd7,
            -8'd41, 8'd6, 8'd19, -8'd75, -8'd67, 8'd49, 8'd82, 8'd127, 8'd31,
            -8'd1, 8'd6, -8'd11, -8'd6, 8'd12, -8'd24, 8'd23, 8'd2, 8'd12,
            8'd15, -8'd3, 8'd7, 8'd7, 8'd15, -8'd13, -8'd9, -8'd23, -8'd16,
            8'd102, 8'd42, 8'd8, 8'd15, 8'd44, 8'd44, 8'd35, 8'd20, -8'd28,
            -8'd80, -8'd72, -8'd16, -8'd36, -8'd42, -8'd91, 8'd12, 8'd38, -8'd40,
            8'd5, 8'd10, 8'd52, -8'd65, -8'd113, -8'd40, 8'd59, 8'd16, -8'd50,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd56, -8'd56, -8'd89, 8'd32, -8'd73, 8'd64, -8'd72, 8'd99, -8'd33,
            -8'd5, -8'd56, 8'd40, 8'd29, -8'd108, 8'd101, -8'd66, 8'd96, 8'd7,
            -8'd33, -8'd111, 8'd69, 8'd54, 8'd86, -8'd63, 8'd1, -8'd95, -8'd6,
            -8'd1, 8'd70, 8'd6, 8'd55, 8'd33, 8'd90, -8'd12, -8'd22, -8'd81,
            8'd1, 8'd100, -8'd35, -8'd4, 8'd58, -8'd43, -8'd2, 8'd57, -8'd37,
            -8'd115, 8'd70, 8'd19, 8'd29, -8'd46, -8'd77, -8'd119, -8'd3, -8'd5,
            8'd34, -8'd46, -8'd4, 8'd10, -8'd99, -8'd53, 8'd81, -8'd7, -8'd18,
            -8'd105, 8'd33, -8'd81, -8'd32, 8'd62, 8'd78, 8'd16, 8'd52, -8'd100,
            -8'd58, -8'd99, -8'd93, 8'd36, -8'd59, -8'd59, 8'd78, -8'd92, -8'd64,
            -8'd47, -8'd94, 8'd53, -8'd50, 8'd4, 8'd0, 8'd65, 8'd1, 8'd1,
            8'd73, 8'd77, -8'd42, -8'd36, 8'd88, 8'd44, -8'd10, 8'd48, -8'd55,
            -8'd69, 8'd7, -8'd81, -8'd127, -8'd77, 8'd43, -8'd17, -8'd49, -8'd99,
            8'd57, 8'd63, -8'd76, 8'd39, -8'd116, 8'd56, -8'd64, -8'd59, -8'd13,
            -8'd5, 8'd28, 8'd10, 8'd37, 8'd32, 8'd92, 8'd8, 8'd58, -8'd63,
            -8'd108, -8'd39, 8'd24, -8'd67, -8'd106, -8'd93, 8'd39, 8'd40, -8'd84,
            8'd51, -8'd23, -8'd24, 8'd74, 8'd22, -8'd111, -8'd95, -8'd83, -8'd73,
            -8'd48, 8'd29, 8'd19, -8'd4, -8'd99, 8'd78, -8'd119, 8'd51, -8'd64,
            8'd69, 8'd58, -8'd46, 8'd65, -8'd8, 8'd104, 8'd46, 8'd61, -8'd11,
            -8'd77, -8'd15, -8'd45, 8'd83, 8'd38, -8'd36, -8'd79, -8'd73, 8'd79,
            8'd30, -8'd102, -8'd74, 8'd89, 8'd91, -8'd31, 8'd45, 8'd23, -8'd35,
            8'd41, -8'd38, 8'd80, 8'd2, 8'd29, 8'd47, -8'd33, -8'd44, -8'd90,
            -8'd88, -8'd38, 8'd98, 8'd58, 8'd36, 8'd51, -8'd51, -8'd63, -8'd113,
            -8'd94, -8'd55, -8'd73, 8'd53, -8'd122, -8'd80, -8'd93, 8'd68, -8'd71,
            -8'd19, 8'd63, 8'd81, -8'd6, 8'd66, 8'd13, 8'd12, 8'd5, 8'd76,
            -8'd119, -8'd98, -8'd9, 8'd24, 8'd53, 8'd11, -8'd46, 8'd13, 8'd62,
            8'd26, 8'd82, 8'd30, -8'd84, -8'd54, -8'd65, -8'd82, 8'd51, -8'd61,
            8'd74, 8'd106, 8'd102, 8'd36, 8'd107, -8'd51, 8'd108, 8'd6, -8'd37,
            8'd85, -8'd14, -8'd38, 8'd89, -8'd13, 8'd4, -8'd29, -8'd90, -8'd107,
            8'd23, -8'd15, 8'd11, -8'd43, 8'd80, -8'd88, 8'd62, -8'd19, 8'd16,
            -8'd67, -8'd16, -8'd89, -8'd35, -8'd71, -8'd17, 8'd1, 8'd13, -8'd31,
            -8'd77, -8'd96, -8'd93, -8'd55, 8'd60, -8'd79, -8'd97, -8'd44, -8'd84,
            8'd61, 8'd47, -8'd88, -8'd85, -8'd3, -8'd27, -8'd51, -8'd95, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd46, 8'd18, 8'd39, 8'd32, 8'd49, 8'd35, -8'd53, -8'd40, -8'd17,
            -8'd9, -8'd15, -8'd6, 8'd22, 8'd13, 8'd40, -8'd29, -8'd10, 8'd15,
            -8'd39, -8'd17, -8'd2, -8'd64, -8'd86, -8'd60, -8'd18, -8'd41, -8'd25,
            8'd9, -8'd18, -8'd12, 8'd18, 8'd1, 8'd34, -8'd5, 8'd2, 8'd3,
            -8'd4, 8'd22, -8'd2, 8'd5, -8'd14, -8'd23, 8'd6, -8'd17, -8'd1,
            8'd0, 8'd23, 8'd1, -8'd50, -8'd37, -8'd29, -8'd18, -8'd13, -8'd4,
            -8'd23, 8'd2, 8'd27, -8'd64, -8'd43, -8'd38, -8'd19, -8'd56, -8'd6,
            8'd22, -8'd5, -8'd7, 8'd0, 8'd22, 8'd18, 8'd13, -8'd6, 8'd6,
            8'd4, -8'd17, -8'd27, 8'd37, 8'd20, 8'd16, 8'd30, 8'd67, 8'd37,
            -8'd3, -8'd35, -8'd19, 8'd23, 8'd27, 8'd16, 8'd3, -8'd25, -8'd18,
            -8'd12, -8'd11, 8'd3, 8'd4, 8'd23, -8'd13, -8'd13, 8'd4, -8'd16,
            -8'd18, -8'd43, -8'd50, 8'd36, 8'd38, 8'd21, -8'd42, -8'd13, -8'd35,
            8'd40, 8'd41, 8'd72, -8'd42, 8'd31, 8'd31, -8'd11, 8'd24, 8'd7,
            -8'd18, 8'd0, -8'd5, -8'd1, -8'd16, 8'd3, 8'd14, 8'd1, -8'd5,
            -8'd1, 8'd9, 8'd0, 8'd1, 8'd26, 8'd48, -8'd28, -8'd44, -8'd26,
            8'd8, 8'd0, -8'd11, 8'd22, 8'd26, 8'd42, -8'd6, -8'd9, 8'd2,
            8'd7, -8'd21, -8'd41, 8'd39, 8'd21, 8'd34, -8'd33, -8'd19, -8'd14,
            8'd2, 8'd17, 8'd8, -8'd69, -8'd20, 8'd9, -8'd22, -8'd17, -8'd11,
            8'd10, 8'd18, -8'd15, 8'd19, 8'd12, -8'd3, -8'd21, 8'd4, -8'd6,
            -8'd5, -8'd2, 8'd4, -8'd16, 8'd13, -8'd9, -8'd15, -8'd6, -8'd15,
            8'd12, -8'd5, -8'd14, 8'd22, 8'd49, 8'd33, -8'd44, -8'd47, -8'd18,
            -8'd38, -8'd1, -8'd14, 8'd29, -8'd19, -8'd52, 8'd16, 8'd33, 8'd27,
            8'd23, 8'd35, 8'd5, 8'd19, 8'd28, 8'd37, -8'd19, -8'd27, -8'd46,
            8'd31, 8'd26, 8'd7, -8'd11, 8'd50, 8'd46, -8'd62, -8'd56, -8'd30,
            8'd33, -8'd1, 8'd10, 8'd1, 8'd25, 8'd8, -8'd10, -8'd27, -8'd18,
            8'd16, -8'd21, -8'd13, -8'd14, -8'd17, 8'd2, 8'd7, -8'd11, 8'd13,
            -8'd33, -8'd71, -8'd96, 8'd34, 8'd7, -8'd29, 8'd10, 8'd12, -8'd30,
            8'd15, 8'd6, 8'd19, 8'd18, -8'd2, 8'd1, 8'd9, 8'd6, 8'd10,
            -8'd11, -8'd1, 8'd8, -8'd12, 8'd2, 8'd6, -8'd12, 8'd1, 8'd2,
            -8'd21, 8'd9, 8'd13, 8'd59, -8'd6, -8'd9, 8'd78, 8'd127, 8'd107,
            8'd19, -8'd14, -8'd39, -8'd46, -8'd36, -8'd36, -8'd34, -8'd61, -8'd47,
            -8'd23, 8'd5, -8'd41, 8'd19, 8'd51, 8'd36, -8'd9, 8'd36, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd33, 8'd10, 8'd23, -8'd36, -8'd30, -8'd42, -8'd13, -8'd26, 8'd1,
            -8'd49, -8'd52, 8'd8, -8'd4, -8'd25, -8'd20, -8'd50, -8'd26, -8'd28,
            8'd1, 8'd17, 8'd10, 8'd10, 8'd18, 8'd18, 8'd13, 8'd40, 8'd0,
            -8'd38, -8'd42, 8'd37, -8'd40, 8'd18, -8'd11, -8'd8, -8'd36, -8'd57,
            -8'd13, -8'd20, -8'd19, -8'd13, -8'd12, -8'd13, 8'd2, 8'd18, 8'd10,
            8'd13, 8'd38, 8'd7, 8'd15, 8'd43, 8'd22, 8'd12, 8'd16, 8'd41,
            8'd24, 8'd9, 8'd18, 8'd24, 8'd1, 8'd40, 8'd21, 8'd31, 8'd6,
            -8'd8, 8'd16, -8'd7, -8'd11, -8'd14, -8'd12, -8'd7, -8'd5, 8'd5,
            8'd5, -8'd30, 8'd51, 8'd5, 8'd33, 8'd44, -8'd4, 8'd16, 8'd13,
            -8'd51, -8'd45, 8'd27, -8'd31, 8'd8, -8'd4, -8'd32, -8'd25, -8'd21,
            -8'd16, 8'd21, -8'd14, -8'd16, 8'd19, -8'd12, -8'd17, 8'd19, 8'd2,
            -8'd70, -8'd31, 8'd38, -8'd35, -8'd13, -8'd28, -8'd45, -8'd30, -8'd36,
            -8'd5, 8'd20, 8'd67, 8'd32, 8'd4, 8'd30, 8'd16, 8'd21, 8'd31,
            8'd10, 8'd17, 8'd7, 8'd3, 8'd17, -8'd15, 8'd19, 8'd16, 8'd17,
            -8'd33, -8'd30, 8'd40, -8'd46, -8'd25, -8'd20, -8'd26, -8'd26, -8'd42,
            -8'd48, -8'd37, 8'd12, -8'd17, -8'd1, -8'd49, -8'd20, -8'd22, 8'd5,
            -8'd43, -8'd38, 8'd47, -8'd53, -8'd30, -8'd41, -8'd38, -8'd7, -8'd6,
            -8'd57, -8'd10, 8'd127, -8'd69, 8'd4, -8'd38, 8'd5, -8'd18, -8'd47,
            -8'd5, 8'd7, 8'd20, -8'd4, -8'd10, -8'd3, 8'd1, -8'd6, 8'd0,
            8'd5, -8'd8, -8'd8, 8'd2, 8'd17, 8'd1, -8'd9, 8'd12, 8'd14,
            -8'd50, -8'd53, 8'd37, -8'd26, 8'd7, -8'd41, 8'd17, -8'd18, -8'd47,
            -8'd8, 8'd28, 8'd45, 8'd6, 8'd5, 8'd19, 8'd34, 8'd12, -8'd2,
            -8'd49, -8'd19, 8'd19, -8'd58, 8'd20, -8'd27, -8'd29, -8'd20, -8'd1,
            -8'd48, 8'd6, 8'd42, -8'd44, -8'd11, -8'd71, 8'd5, 8'd5, 8'd23,
            8'd8, -8'd20, 8'd28, 8'd10, -8'd24, 8'd7, -8'd2, -8'd12, 8'd23,
            8'd4, -8'd16, -8'd11, 8'd10, 8'd15, 8'd9, -8'd22, -8'd3, 8'd17,
            8'd5, -8'd91, 8'd25, -8'd15, -8'd19, -8'd8, -8'd28, -8'd32, -8'd33,
            8'd17, 8'd17, 8'd5, 8'd2, 8'd15, -8'd17, 8'd2, -8'd19, -8'd9,
            -8'd3, 8'd1, -8'd16, 8'd14, -8'd9, -8'd3, -8'd18, 8'd15, -8'd7,
            8'd3, -8'd6, 8'd56, 8'd31, 8'd42, 8'd26, 8'd2, 8'd35, 8'd9,
            -8'd58, -8'd7, 8'd28, -8'd46, 8'd45, 8'd11, -8'd46, -8'd18, -8'd69,
            -8'd26, -8'd42, 8'd36, -8'd6, -8'd28, -8'd16, -8'd46, -8'd58, -8'd33,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd9, 8'd17, -8'd27, 8'd7, -8'd36, -8'd17, 8'd14, 8'd10, 8'd57,
            8'd6, 8'd35, -8'd37, 8'd9, 8'd23, -8'd40, 8'd10, -8'd2, -8'd29,
            -8'd6, 8'd45, 8'd38, -8'd34, 8'd41, 8'd25, 8'd37, -8'd24, -8'd18,
            -8'd7, 8'd44, -8'd16, -8'd14, 8'd25, -8'd47, 8'd28, -8'd28, -8'd33,
            -8'd21, 8'd26, 8'd9, -8'd25, 8'd23, 8'd22, 8'd20, 8'd8, -8'd14,
            -8'd4, -8'd69, -8'd33, -8'd30, -8'd67, -8'd15, -8'd20, -8'd59, -8'd41,
            -8'd9, 8'd6, 8'd26, -8'd40, 8'd29, 8'd14, 8'd14, -8'd23, -8'd59,
            8'd0, -8'd21, 8'd3, -8'd25, -8'd11, -8'd23, -8'd9, 8'd21, -8'd21,
            -8'd53, 8'd13, 8'd33, -8'd34, -8'd17, 8'd1, 8'd18, 8'd27, 8'd25,
            8'd29, 8'd48, -8'd16, 8'd18, -8'd1, -8'd40, 8'd8, -8'd18, 8'd11,
            -8'd1, 8'd0, 8'd0, -8'd17, -8'd2, 8'd16, -8'd12, 8'd8, 8'd12,
            8'd22, 8'd40, -8'd49, 8'd46, -8'd10, -8'd60, 8'd21, 8'd9, -8'd1,
            -8'd28, -8'd52, -8'd44, -8'd101, -8'd41, 8'd10, -8'd37, 8'd54, 8'd60,
            -8'd8, -8'd11, -8'd3, -8'd7, 8'd6, -8'd20, -8'd9, -8'd12, -8'd3,
            -8'd9, 8'd55, 8'd8, 8'd29, 8'd34, -8'd54, 8'd0, -8'd37, 8'd11,
            8'd30, 8'd35, -8'd47, 8'd3, 8'd1, -8'd34, 8'd6, 8'd0, 8'd20,
            -8'd2, 8'd32, -8'd30, 8'd10, 8'd7, -8'd42, 8'd11, -8'd25, -8'd21,
            8'd50, 8'd99, 8'd101, 8'd86, 8'd31, 8'd41, 8'd11, -8'd8, 8'd29,
            8'd14, -8'd17, -8'd24, -8'd16, 8'd10, 8'd1, -8'd14, 8'd5, 8'd12,
            -8'd16, -8'd14, 8'd9, 8'd20, -8'd22, 8'd10, 8'd6, -8'd6, -8'd4,
            8'd33, 8'd53, -8'd4, 8'd45, 8'd20, -8'd53, 8'd46, 8'd7, 8'd25,
            -8'd27, -8'd36, 8'd33, -8'd39, -8'd1, -8'd28, -8'd16, 8'd40, -8'd7,
            8'd20, 8'd37, -8'd65, -8'd4, 8'd0, -8'd27, -8'd11, 8'd18, 8'd8,
            -8'd8, 8'd7, -8'd58, 8'd44, 8'd7, -8'd4, -8'd11, -8'd5, 8'd51,
            -8'd1, -8'd1, -8'd10, -8'd28, -8'd22, -8'd41, -8'd6, -8'd4, -8'd14,
            8'd21, -8'd23, 8'd10, -8'd3, -8'd24, -8'd7, 8'd4, 8'd19, 8'd25,
            8'd56, 8'd36, -8'd25, 8'd27, -8'd64, -8'd10, -8'd4, 8'd40, -8'd43,
            8'd21, -8'd23, -8'd2, -8'd18, 8'd17, -8'd22, -8'd14, -8'd13, -8'd21,
            -8'd18, -8'd12, -8'd4, -8'd14, -8'd8, 8'd18, -8'd9, 8'd4, -8'd24,
            -8'd127, -8'd80, 8'd26, -8'd127, -8'd65, -8'd11, -8'd50, 8'd28, 8'd32,
            8'd14, 8'd108, 8'd78, 8'd82, 8'd79, -8'd45, 8'd35, 8'd7, -8'd49,
            -8'd5, -8'd15, -8'd40, -8'd20, -8'd56, -8'd78, 8'd19, -8'd7, 8'd25,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd9, 8'd37, 8'd49, -8'd77, -8'd1, 8'd11, -8'd47, -8'd42, -8'd17,
            8'd23, 8'd6, 8'd58, -8'd22, 8'd37, 8'd23, -8'd74, -8'd45, -8'd18,
            -8'd8, -8'd11, -8'd56, -8'd28, -8'd37, -8'd18, -8'd38, 8'd6, 8'd35,
            -8'd1, -8'd20, 8'd37, -8'd17, 8'd25, 8'd19, -8'd50, -8'd44, -8'd28,
            8'd28, -8'd19, 8'd21, 8'd19, -8'd2, -8'd10, 8'd2, 8'd18, -8'd16,
            -8'd12, -8'd30, -8'd32, 8'd31, 8'd4, -8'd22, -8'd4, -8'd25, 8'd37,
            -8'd17, 8'd2, -8'd65, 8'd15, -8'd38, -8'd60, -8'd41, -8'd4, -8'd8,
            -8'd29, 8'd6, -8'd13, 8'd2, 8'd6, -8'd29, -8'd3, 8'd31, 8'd9,
            -8'd24, 8'd22, -8'd18, 8'd12, 8'd24, 8'd30, -8'd36, 8'd28, -8'd8,
            -8'd32, 8'd31, 8'd50, -8'd9, 8'd0, 8'd80, -8'd85, -8'd50, -8'd43,
            -8'd18, 8'd5, -8'd7, 8'd12, 8'd0, -8'd25, -8'd5, -8'd12, 8'd20,
            -8'd25, 8'd19, 8'd16, -8'd21, 8'd25, 8'd83, -8'd92, -8'd50, -8'd35,
            -8'd40, 8'd34, 8'd33, -8'd22, -8'd17, -8'd48, 8'd25, 8'd31, 8'd79,
            -8'd10, 8'd16, -8'd25, 8'd24, 8'd8, 8'd7, 8'd13, -8'd21, -8'd13,
            8'd19, 8'd4, 8'd43, -8'd38, -8'd23, 8'd16, -8'd89, -8'd28, -8'd30,
            8'd23, 8'd40, 8'd36, 8'd11, 8'd19, 8'd63, -8'd29, -8'd80, -8'd48,
            8'd15, -8'd7, 8'd28, -8'd26, 8'd28, 8'd57, -8'd25, -8'd40, -8'd42,
            -8'd35, -8'd12, 8'd38, -8'd127, 8'd70, 8'd36, 8'd109, -8'd42, -8'd70,
            -8'd1, 8'd17, -8'd20, 8'd19, -8'd26, -8'd5, 8'd16, -8'd21, 8'd5,
            8'd31, 8'd9, -8'd1, 8'd2, 8'd21, -8'd2, -8'd16, -8'd6, -8'd8,
            8'd9, 8'd10, 8'd60, -8'd21, 8'd20, 8'd25, -8'd32, -8'd47, -8'd54,
            -8'd52, -8'd35, -8'd38, 8'd22, 8'd34, 8'd10, -8'd11, -8'd8, 8'd38,
            -8'd39, 8'd3, 8'd44, -8'd70, -8'd13, -8'd31, -8'd37, -8'd46, -8'd54,
            -8'd21, 8'd14, 8'd75, -8'd85, 8'd1, 8'd15, -8'd53, -8'd75, -8'd64,
            8'd11, 8'd29, 8'd48, -8'd6, 8'd4, 8'd53, -8'd82, -8'd64, -8'd61,
            8'd0, 8'd16, -8'd6, -8'd2, 8'd13, 8'd4, 8'd21, -8'd6, -8'd1,
            -8'd21, -8'd36, 8'd7, 8'd40, 8'd1, 8'd33, 8'd0, -8'd84, -8'd60,
            8'd2, 8'd16, 8'd23, 8'd22, 8'd9, 8'd21, -8'd11, 8'd28, -8'd16,
            -8'd10, 8'd11, 8'd27, -8'd31, 8'd19, -8'd27, 8'd16, 8'd18, 8'd28,
            -8'd43, -8'd8, -8'd64, -8'd12, -8'd22, 8'd76, 8'd40, 8'd93, 8'd95,
            -8'd4, 8'd37, -8'd60, -8'd41, -8'd39, 8'd7, -8'd101, -8'd74, -8'd114,
            8'd33, 8'd39, 8'd11, 8'd1, 8'd42, 8'd91, -8'd44, -8'd42, 8'd41,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd19, 8'd39, 8'd39, 8'd2, 8'd23, 8'd3, 8'd30, -8'd45, -8'd36,
            -8'd11, -8'd25, 8'd21, 8'd6, 8'd2, -8'd2, -8'd11, 8'd4, -8'd39,
            -8'd18, -8'd36, -8'd3, -8'd22, 8'd5, 8'd7, 8'd25, 8'd44, 8'd26,
            -8'd44, -8'd22, 8'd10, -8'd6, 8'd19, -8'd4, 8'd15, 8'd20, -8'd13,
            8'd16, -8'd5, 8'd16, 8'd16, 8'd10, 8'd8, -8'd2, -8'd12, 8'd7,
            8'd3, 8'd0, -8'd14, 8'd10, -8'd18, 8'd10, -8'd19, -8'd16, -8'd1,
            -8'd5, -8'd13, -8'd24, 8'd12, 8'd0, 8'd6, 8'd3, 8'd15, 8'd17,
            -8'd13, -8'd11, 8'd18, -8'd12, 8'd17, 8'd16, -8'd9, -8'd4, -8'd13,
            -8'd5, -8'd40, 8'd14, -8'd7, 8'd8, 8'd30, 8'd27, 8'd30, -8'd5,
            -8'd39, 8'd7, 8'd3, -8'd1, 8'd3, -8'd10, 8'd13, -8'd11, -8'd32,
            8'd1, -8'd5, -8'd9, -8'd18, -8'd12, -8'd18, 8'd6, 8'd11, 8'd8,
            -8'd63, -8'd33, 8'd5, 8'd8, 8'd14, 8'd2, 8'd10, -8'd21, -8'd36,
            -8'd8, 8'd33, -8'd9, 8'd3, -8'd25, -8'd7, 8'd8, -8'd20, 8'd4,
            8'd1, 8'd7, 8'd12, -8'd21, 8'd17, 8'd4, 8'd12, 8'd12, -8'd1,
            -8'd32, -8'd10, 8'd27, -8'd14, 8'd31, 8'd4, 8'd38, -8'd19, -8'd55,
            -8'd15, -8'd17, 8'd26, 8'd5, 8'd10, 8'd9, -8'd12, -8'd20, -8'd13,
            -8'd21, 8'd3, 8'd31, -8'd8, 8'd35, -8'd5, 8'd8, -8'd34, -8'd34,
            -8'd55, 8'd43, 8'd54, 8'd45, 8'd95, 8'd44, 8'd127, 8'd55, 8'd49,
            8'd14, 8'd10, -8'd4, -8'd12, -8'd3, 8'd17, 8'd6, -8'd13, 8'd6,
            -8'd10, 8'd13, -8'd10, 8'd13, -8'd9, -8'd11, 8'd0, 8'd13, -8'd16,
            -8'd59, -8'd13, 8'd29, -8'd3, 8'd42, 8'd20, 8'd37, 8'd0, -8'd56,
            -8'd7, -8'd24, -8'd20, -8'd2, -8'd3, -8'd19, -8'd24, 8'd29, 8'd23,
            8'd6, 8'd21, 8'd1, -8'd3, 8'd26, -8'd5, 8'd19, -8'd29, -8'd33,
            -8'd15, 8'd10, 8'd15, -8'd3, 8'd24, -8'd15, 8'd23, -8'd29, -8'd50,
            -8'd34, -8'd17, 8'd16, -8'd7, 8'd3, 8'd9, -8'd18, -8'd6, -8'd19,
            8'd5, 8'd9, -8'd10, -8'd17, -8'd15, -8'd18, 8'd14, -8'd13, 8'd18,
            -8'd24, -8'd12, -8'd21, 8'd19, -8'd32, -8'd29, -8'd56, -8'd41, 8'd6,
            8'd16, -8'd4, 8'd10, 8'd9, 8'd12, -8'd1, 8'd13, 8'd3, -8'd8,
            -8'd4, 8'd17, -8'd2, 8'd7, -8'd14, 8'd16, -8'd19, -8'd3, -8'd13,
            8'd20, -8'd1, -8'd1, -8'd14, -8'd5, -8'd14, -8'd27, 8'd41, 8'd22,
            -8'd77, -8'd59, 8'd0, -8'd32, 8'd41, 8'd71, 8'd84, 8'd46, -8'd12,
            -8'd52, 8'd1, 8'd6, -8'd30, 8'd14, 8'd14, 8'd0, -8'd22, -8'd37,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd99, -8'd79, -8'd97, -8'd58, -8'd8, -8'd104, -8'd117, -8'd105, -8'd70,
            -8'd60, -8'd64, 8'd40, -8'd11, -8'd108, -8'd108, 8'd99, -8'd45, -8'd116,
            8'd9, -8'd111, -8'd111, 8'd48, -8'd10, 8'd54, -8'd117, -8'd121, -8'd25,
            -8'd49, -8'd84, 8'd102, 8'd86, -8'd105, -8'd47, -8'd9, -8'd82, -8'd78,
            8'd77, -8'd90, 8'd26, -8'd74, 8'd26, 8'd68, 8'd77, 8'd10, -8'd71,
            8'd45, 8'd23, -8'd118, -8'd38, -8'd62, 8'd63, -8'd79, 8'd84, 8'd19,
            -8'd98, 8'd90, 8'd110, -8'd56, -8'd51, 8'd2, -8'd117, 8'd86, 8'd111,
            8'd12, 8'd27, -8'd104, -8'd2, 8'd101, -8'd105, 8'd74, -8'd68, -8'd119,
            -8'd108, -8'd38, 8'd30, 8'd71, 8'd17, 8'd76, -8'd103, 8'd64, 8'd25,
            8'd93, -8'd39, -8'd90, -8'd47, 8'd88, -8'd96, 8'd67, -8'd15, -8'd24,
            -8'd84, 8'd82, -8'd100, 8'd11, -8'd25, -8'd98, 8'd5, -8'd118, -8'd119,
            -8'd25, -8'd33, 8'd15, 8'd73, -8'd26, -8'd28, 8'd39, -8'd22, -8'd53,
            -8'd109, 8'd92, -8'd118, 8'd6, 8'd60, 8'd10, 8'd86, -8'd71, -8'd72,
            8'd5, 8'd82, 8'd61, -8'd94, -8'd112, 8'd30, 8'd42, 8'd103, -8'd24,
            8'd87, -8'd66, -8'd59, 8'd91, -8'd127, 8'd76, -8'd13, 8'd70, 8'd17,
            -8'd43, 8'd41, 8'd30, -8'd16, -8'd124, -8'd21, -8'd43, -8'd114, 8'd8,
            -8'd7, -8'd53, -8'd111, -8'd125, 8'd12, 8'd40, -8'd45, -8'd89, 8'd86,
            -8'd103, -8'd6, -8'd61, 8'd54, -8'd64, 8'd42, -8'd89, -8'd90, -8'd24,
            8'd79, 8'd99, 8'd107, -8'd29, 8'd78, 8'd14, -8'd1, -8'd5, 8'd8,
            8'd39, -8'd28, -8'd121, -8'd24, 8'd70, 8'd6, -8'd92, -8'd111, 8'd105,
            8'd41, 8'd57, 8'd114, -8'd4, 8'd32, -8'd80, 8'd45, 8'd105, 8'd42,
            -8'd25, -8'd25, -8'd75, -8'd48, -8'd23, 8'd6, -8'd88, 8'd15, -8'd56,
            8'd25, -8'd53, -8'd88, 8'd104, 8'd3, 8'd70, 8'd14, -8'd3, 8'd16,
            -8'd93, 8'd86, 8'd51, 8'd10, 8'd59, 8'd27, 8'd34, 8'd75, -8'd14,
            8'd24, -8'd77, -8'd66, 8'd8, 8'd57, 8'd95, 8'd54, -8'd86, -8'd10,
            -8'd7, 8'd110, 8'd45, 8'd32, 8'd0, 8'd86, 8'd62, -8'd26, -8'd79,
            8'd0, -8'd117, 8'd46, 8'd25, -8'd116, -8'd120, -8'd117, -8'd9, -8'd105,
            -8'd52, 8'd80, 8'd94, 8'd94, 8'd52, -8'd20, 8'd60, -8'd98, -8'd109,
            -8'd1, -8'd28, 8'd28, 8'd32, -8'd19, 8'd69, -8'd72, -8'd52, -8'd13,
            -8'd57, -8'd68, -8'd30, -8'd43, -8'd98, 8'd38, -8'd23, 8'd29, -8'd50,
            -8'd103, 8'd26, 8'd92, -8'd119, -8'd23, -8'd16, 8'd0, -8'd112, 8'd81,
            -8'd70, -8'd80, -8'd91, 8'd88, 8'd8, 8'd81, -8'd73, 8'd28, -8'd113,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd110, 8'd26, 8'd53, 8'd28, -8'd23, 8'd83, 8'd72, 8'd35, 8'd3,
            8'd76, 8'd52, -8'd9, 8'd24, -8'd2, -8'd113, -8'd16, 8'd36, 8'd55,
            -8'd35, -8'd92, -8'd31, 8'd51, -8'd23, -8'd42, -8'd127, 8'd17, -8'd9,
            -8'd21, 8'd60, 8'd29, -8'd89, 8'd32, -8'd79, -8'd33, 8'd5, -8'd111,
            8'd56, 8'd68, 8'd73, -8'd1, -8'd49, 8'd73, 8'd90, 8'd12, 8'd47,
            8'd67, 8'd86, -8'd69, -8'd15, 8'd45, 8'd12, -8'd98, -8'd91, -8'd37,
            -8'd92, 8'd81, -8'd82, -8'd68, 8'd68, -8'd27, 8'd18, 8'd25, -8'd30,
            8'd74, -8'd48, -8'd90, 8'd34, -8'd95, -8'd15, 8'd16, -8'd28, 8'd36,
            -8'd76, -8'd3, -8'd90, 8'd43, 8'd35, -8'd15, 8'd20, -8'd49, -8'd105,
            -8'd6, 8'd74, 8'd15, 8'd50, 8'd25, 8'd14, 8'd8, -8'd25, 8'd33,
            8'd32, 8'd71, -8'd38, -8'd19, 8'd95, -8'd45, -8'd58, -8'd31, 8'd1,
            -8'd119, 8'd16, 8'd83, -8'd41, 8'd61, 8'd65, 8'd55, 8'd73, 8'd76,
            8'd5, -8'd41, -8'd93, -8'd36, 8'd33, 8'd17, -8'd74, -8'd30, -8'd47,
            -8'd18, 8'd3, 8'd35, -8'd77, -8'd31, -8'd52, -8'd15, -8'd46, -8'd67,
            -8'd55, -8'd72, -8'd89, -8'd54, -8'd93, 8'd75, -8'd29, 8'd15, 8'd60,
            -8'd5, -8'd12, 8'd42, -8'd27, -8'd119, 8'd28, -8'd56, -8'd11, -8'd70,
            -8'd87, -8'd13, 8'd73, -8'd18, -8'd29, -8'd40, 8'd45, 8'd43, -8'd43,
            -8'd71, 8'd54, 8'd97, -8'd41, 8'd30, -8'd37, 8'd95, -8'd92, -8'd78,
            -8'd72, 8'd15, -8'd73, 8'd47, -8'd38, -8'd90, -8'd4, -8'd53, 8'd46,
            8'd21, 8'd15, -8'd40, -8'd18, -8'd66, -8'd36, -8'd61, 8'd64, -8'd87,
            8'd20, -8'd4, -8'd65, -8'd22, -8'd97, -8'd61, -8'd5, -8'd4, 8'd24,
            -8'd39, 8'd35, -8'd78, -8'd84, -8'd121, 8'd47, -8'd77, -8'd99, -8'd9,
            8'd17, 8'd28, 8'd35, 8'd36, -8'd16, -8'd83, -8'd57, 8'd64, -8'd28,
            -8'd94, 8'd26, 8'd20, -8'd36, 8'd69, -8'd94, 8'd15, 8'd75, 8'd75,
            -8'd38, -8'd65, -8'd97, -8'd62, -8'd113, -8'd97, -8'd56, -8'd69, -8'd57,
            8'd17, -8'd91, -8'd2, -8'd6, 8'd81, -8'd52, 8'd60, -8'd43, -8'd26,
            -8'd69, 8'd87, -8'd102, -8'd39, 8'd14, 8'd67, 8'd16, -8'd12, 8'd20,
            -8'd50, -8'd45, 8'd67, -8'd23, -8'd96, 8'd71, -8'd94, -8'd9, 8'd49,
            8'd14, 8'd63, -8'd65, -8'd39, -8'd87, 8'd26, -8'd41, 8'd24, -8'd64,
            -8'd82, 8'd82, 8'd32, -8'd127, -8'd44, -8'd83, 8'd36, -8'd8, -8'd92,
            -8'd95, 8'd46, -8'd103, 8'd70, -8'd115, -8'd98, -8'd25, 8'd66, 8'd70,
            -8'd110, 8'd75, -8'd50, -8'd2, -8'd94, 8'd14, 8'd4, 8'd49, 8'd39,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd2, 8'd30, 8'd27, -8'd71, -8'd43, -8'd90, 8'd19, -8'd8, 8'd13,
            8'd33, 8'd36, 8'd17, -8'd45, 8'd0, -8'd19, -8'd17, -8'd7, 8'd2,
            -8'd16, 8'd16, 8'd18, -8'd42, 8'd24, 8'd63, -8'd19, -8'd10, -8'd25,
            8'd2, 8'd18, 8'd42, -8'd20, 8'd7, -8'd19, -8'd10, -8'd30, -8'd27,
            -8'd19, -8'd12, 8'd5, -8'd16, 8'd18, 8'd3, 8'd15, -8'd13, -8'd10,
            -8'd13, -8'd21, 8'd34, 8'd10, 8'd13, 8'd15, 8'd20, 8'd25, 8'd22,
            8'd13, 8'd1, 8'd28, 8'd5, -8'd3, 8'd30, -8'd2, 8'd16, 8'd22,
            8'd12, -8'd14, 8'd16, 8'd13, 8'd16, -8'd4, -8'd13, 8'd5, -8'd3,
            8'd19, 8'd14, 8'd42, -8'd11, 8'd29, 8'd24, -8'd18, -8'd17, -8'd7,
            8'd30, 8'd50, 8'd12, -8'd37, 8'd6, -8'd75, -8'd20, -8'd20, -8'd29,
            8'd11, 8'd14, -8'd21, -8'd5, 8'd9, -8'd7, 8'd3, 8'd6, 8'd2,
            8'd27, 8'd47, 8'd42, -8'd19, 8'd9, -8'd72, -8'd4, -8'd47, -8'd22,
            -8'd35, 8'd13, -8'd38, 8'd9, -8'd6, 8'd50, 8'd6, 8'd38, 8'd23,
            -8'd2, 8'd15, -8'd16, -8'd23, -8'd4, -8'd4, 8'd5, -8'd3, -8'd23,
            8'd5, 8'd30, 8'd22, -8'd68, -8'd30, -8'd49, -8'd9, -8'd8, -8'd21,
            8'd16, 8'd38, -8'd11, -8'd53, -8'd22, -8'd58, -8'd17, -8'd30, -8'd12,
            8'd30, 8'd39, -8'd1, -8'd22, 8'd5, -8'd44, 8'd3, -8'd23, -8'd8,
            -8'd97, 8'd14, 8'd84, -8'd58, -8'd11, -8'd33, -8'd5, 8'd37, 8'd7,
            8'd14, -8'd12, 8'd19, 8'd7, -8'd13, 8'd3, -8'd10, 8'd21, 8'd14,
            8'd8, -8'd21, 8'd6, 8'd14, 8'd13, -8'd1, 8'd10, -8'd18, 8'd3,
            -8'd5, 8'd35, 8'd41, -8'd69, -8'd4, -8'd50, 8'd2, -8'd23, 8'd13,
            8'd44, 8'd12, 8'd6, 8'd26, 8'd0, 8'd1, -8'd10, -8'd21, -8'd18,
            -8'd25, 8'd7, 8'd17, -8'd70, -8'd34, -8'd72, -8'd17, -8'd9, 8'd23,
            -8'd1, 8'd18, -8'd5, -8'd79, -8'd53, -8'd69, 8'd22, 8'd6, 8'd33,
            8'd24, 8'd19, -8'd6, -8'd35, -8'd7, -8'd53, -8'd19, -8'd10, -8'd2,
            8'd20, -8'd9, -8'd14, 8'd0, -8'd19, 8'd10, -8'd19, 8'd21, -8'd4,
            8'd19, 8'd24, -8'd83, 8'd65, 8'd13, -8'd127, -8'd72, -8'd75, -8'd20,
            -8'd20, -8'd5, 8'd2, -8'd8, 8'd3, 8'd20, -8'd19, -8'd2, -8'd14,
            -8'd13, 8'd8, 8'd20, -8'd19, -8'd12, 8'd3, 8'd3, -8'd20, 8'd4,
            8'd10, 8'd1, 8'd0, 8'd42, 8'd53, 8'd26, -8'd12, -8'd1, -8'd13,
            -8'd25, 8'd20, 8'd52, -8'd100, -8'd26, 8'd45, -8'd22, -8'd38, -8'd115,
            8'd47, 8'd24, 8'd29, -8'd28, -8'd8, -8'd68, -8'd38, -8'd27, -8'd16,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd86, -8'd102, -8'd76, -8'd73, 8'd100, -8'd103, -8'd7, -8'd58, -8'd87,
            8'd66, -8'd51, -8'd107, -8'd71, -8'd70, -8'd73, 8'd97, -8'd32, 8'd47,
            8'd28, 8'd19, -8'd51, -8'd31, -8'd92, 8'd22, 8'd60, 8'd86, -8'd66,
            -8'd63, 8'd33, -8'd98, -8'd6, -8'd41, 8'd87, -8'd71, -8'd75, -8'd6,
            -8'd9, 8'd56, 8'd18, 8'd19, 8'd23, -8'd93, -8'd91, -8'd102, -8'd49,
            8'd36, -8'd109, -8'd30, -8'd28, 8'd38, 8'd10, 8'd94, -8'd72, -8'd127,
            8'd5, 8'd24, -8'd73, -8'd2, -8'd107, -8'd95, -8'd1, -8'd110, 8'd51,
            -8'd99, 8'd14, -8'd28, 8'd83, -8'd92, 8'd62, 8'd26, -8'd46, -8'd104,
            8'd18, -8'd39, 8'd1, 8'd34, -8'd117, 8'd17, -8'd105, 8'd60, 8'd62,
            -8'd90, -8'd41, 8'd29, -8'd71, -8'd17, -8'd96, 8'd15, -8'd63, -8'd92,
            -8'd76, -8'd16, -8'd1, 8'd77, 8'd90, -8'd89, 8'd75, -8'd97, -8'd95,
            -8'd18, 8'd29, -8'd5, 8'd90, -8'd58, 8'd81, 8'd50, -8'd26, -8'd10,
            8'd43, 8'd7, -8'd60, -8'd17, 8'd0, 8'd95, -8'd46, 8'd56, -8'd85,
            -8'd58, -8'd55, -8'd66, 8'd0, 8'd68, 8'd106, -8'd54, -8'd91, -8'd89,
            8'd29, 8'd40, -8'd81, -8'd61, 8'd34, -8'd66, 8'd32, -8'd117, -8'd6,
            8'd46, -8'd22, 8'd10, 8'd79, -8'd49, 8'd52, -8'd27, 8'd0, 8'd62,
            -8'd117, -8'd42, -8'd88, -8'd94, 8'd5, 8'd46, 8'd38, -8'd92, 8'd0,
            8'd57, 8'd86, -8'd16, -8'd53, 8'd19, 8'd51, 8'd23, 8'd37, -8'd42,
            -8'd59, 8'd13, 8'd48, 8'd55, -8'd68, -8'd99, -8'd71, 8'd56, -8'd101,
            8'd71, 8'd37, -8'd87, -8'd100, -8'd21, 8'd58, -8'd22, -8'd90, 8'd89,
            8'd58, -8'd36, -8'd31, 8'd3, 8'd84, -8'd48, -8'd7, 8'd26, -8'd99,
            8'd80, -8'd110, -8'd21, 8'd80, 8'd83, -8'd11, -8'd95, 8'd24, 8'd89,
            8'd67, -8'd86, 8'd72, -8'd107, 8'd95, 8'd56, 8'd16, -8'd20, 8'd93,
            8'd73, -8'd11, -8'd10, -8'd54, 8'd14, 8'd56, 8'd19, 8'd29, -8'd75,
            8'd24, 8'd29, -8'd65, -8'd41, 8'd0, -8'd1, -8'd76, -8'd85, -8'd24,
            8'd22, -8'd108, -8'd49, 8'd85, 8'd58, 8'd54, 8'd48, 8'd84, -8'd80,
            -8'd67, 8'd95, 8'd87, -8'd29, 8'd96, -8'd48, -8'd17, -8'd62, -8'd28,
            8'd5, 8'd5, -8'd108, 8'd110, -8'd3, 8'd14, -8'd58, 8'd13, 8'd12,
            8'd6, -8'd107, 8'd54, 8'd11, 8'd71, -8'd4, 8'd32, -8'd36, -8'd48,
            8'd82, -8'd91, -8'd106, 8'd90, -8'd93, -8'd95, -8'd83, 8'd86, -8'd57,
            -8'd10, 8'd17, -8'd7, 8'd36, -8'd105, 8'd99, 8'd79, 8'd44, -8'd54,
            -8'd31, -8'd71, -8'd110, 8'd95, 8'd68, -8'd22, 8'd18, -8'd2, 8'd73,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd11, 8'd18, 8'd38, -8'd21, -8'd23, 8'd9, -8'd67, -8'd24, -8'd31,
            8'd22, -8'd5, 8'd0, -8'd26, -8'd9, 8'd0, -8'd39, -8'd36, -8'd1,
            -8'd18, -8'd60, -8'd61, -8'd5, -8'd41, -8'd94, 8'd31, -8'd12, -8'd1,
            8'd1, 8'd25, -8'd25, 8'd9, 8'd21, -8'd1, -8'd21, -8'd25, -8'd6,
            8'd10, -8'd8, -8'd4, 8'd0, 8'd14, -8'd13, 8'd6, 8'd9, 8'd3,
            8'd0, -8'd32, -8'd17, 8'd2, 8'd16, -8'd23, 8'd11, -8'd5, -8'd29,
            8'd8, -8'd52, -8'd29, -8'd12, -8'd9, -8'd35, 8'd34, -8'd12, -8'd34,
            8'd6, 8'd7, 8'd17, -8'd10, 8'd10, -8'd4, -8'd1, 8'd17, 8'd13,
            8'd8, 8'd25, -8'd27, -8'd13, 8'd14, -8'd13, 8'd5, -8'd11, 8'd18,
            -8'd11, 8'd0, 8'd12, 8'd4, 8'd14, 8'd40, -8'd34, -8'd43, 8'd7,
            8'd4, -8'd19, -8'd17, -8'd5, -8'd17, -8'd14, -8'd14, -8'd9, 8'd1,
            -8'd12, 8'd28, -8'd6, -8'd12, 8'd17, 8'd35, -8'd2, -8'd7, -8'd19,
            8'd20, -8'd4, 8'd91, -8'd2, -8'd1, 8'd17, -8'd16, 8'd13, 8'd5,
            -8'd9, 8'd19, -8'd18, 8'd8, -8'd15, -8'd8, 8'd1, 8'd20, 8'd1,
            8'd5, 8'd24, -8'd6, -8'd27, -8'd22, 8'd11, -8'd33, -8'd23, 8'd7,
            8'd5, 8'd9, 8'd14, -8'd32, 8'd3, 8'd6, -8'd8, -8'd36, 8'd21,
            8'd12, 8'd15, -8'd23, 8'd8, 8'd16, 8'd14, -8'd5, -8'd38, -8'd5,
            8'd33, -8'd34, -8'd75, 8'd22, -8'd52, -8'd127, 8'd20, 8'd94, -8'd5,
            8'd22, 8'd10, -8'd4, -8'd7, -8'd2, 8'd17, -8'd10, 8'd12, -8'd20,
            8'd0, 8'd11, 8'd3, -8'd11, -8'd15, 8'd19, 8'd10, 8'd4, 8'd12,
            8'd18, -8'd4, -8'd9, -8'd20, -8'd36, 8'd7, -8'd30, -8'd12, -8'd4,
            8'd7, 8'd26, -8'd3, -8'd31, -8'd11, 8'd10, -8'd1, -8'd12, 8'd29,
            -8'd17, 8'd42, 8'd35, -8'd41, -8'd35, 8'd17, -8'd20, -8'd22, -8'd19,
            8'd0, 8'd29, 8'd9, -8'd19, -8'd35, 8'd7, -8'd20, -8'd11, -8'd5,
            8'd3, 8'd23, 8'd16, 8'd9, -8'd5, 8'd13, -8'd30, -8'd43, -8'd20,
            -8'd7, 8'd3, -8'd8, -8'd5, -8'd17, -8'd17, -8'd4, 8'd18, -8'd15,
            8'd37, 8'd42, 8'd25, -8'd25, 8'd6, 8'd99, -8'd17, -8'd14, 8'd34,
            8'd7, -8'd8, -8'd1, 8'd14, -8'd1, -8'd21, 8'd16, -8'd1, 8'd7,
            -8'd7, 8'd9, 8'd17, -8'd5, 8'd5, -8'd12, -8'd8, -8'd16, 8'd8,
            8'd61, 8'd57, 8'd21, -8'd12, 8'd23, 8'd27, -8'd13, -8'd13, 8'd30,
            -8'd26, -8'd50, -8'd3, 8'd6, -8'd37, -8'd58, -8'd22, -8'd32, -8'd10,
            8'd32, 8'd47, -8'd7, 8'd8, 8'd11, 8'd27, -8'd21, -8'd41, 8'd54,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd15, -8'd6, 8'd1, -8'd32, 8'd10, 8'd1, 8'd15, 8'd6, 8'd0,
            -8'd8, 8'd18, 8'd17, -8'd38, 8'd0, -8'd9, -8'd28, -8'd5, 8'd0,
            8'd27, -8'd23, 8'd45, 8'd30, 8'd30, 8'd13, 8'd30, 8'd68, 8'd49,
            8'd14, 8'd7, -8'd19, -8'd30, 8'd8, 8'd40, -8'd49, 8'd18, 8'd25,
            -8'd6, -8'd31, 8'd10, -8'd5, 8'd15, 8'd4, 8'd11, -8'd25, 8'd18,
            8'd19, -8'd28, -8'd25, 8'd28, -8'd2, 8'd25, 8'd12, -8'd22, -8'd18,
            -8'd15, -8'd7, -8'd36, -8'd8, 8'd3, 8'd57, 8'd1, 8'd28, 8'd20,
            8'd30, 8'd9, -8'd8, 8'd28, 8'd8, 8'd18, 8'd15, -8'd29, 8'd20,
            8'd31, -8'd51, 8'd23, -8'd42, -8'd15, 8'd5, -8'd65, -8'd15, -8'd29,
            -8'd20, 8'd2, -8'd7, 8'd0, 8'd0, 8'd11, -8'd16, 8'd63, 8'd13,
            -8'd1, -8'd19, -8'd16, 8'd8, -8'd2, -8'd4, -8'd9, -8'd29, 8'd8,
            8'd15, 8'd60, 8'd5, -8'd87, 8'd40, 8'd11, -8'd11, 8'd22, -8'd13,
            -8'd20, -8'd32, -8'd10, 8'd15, -8'd101, -8'd71, 8'd8, -8'd69, -8'd104,
            -8'd25, 8'd28, -8'd21, 8'd26, 8'd1, 8'd1, 8'd4, -8'd32, -8'd1,
            -8'd49, 8'd5, 8'd36, -8'd60, 8'd12, 8'd28, 8'd2, 8'd56, 8'd25,
            -8'd5, 8'd24, -8'd1, -8'd52, 8'd4, 8'd1, 8'd6, 8'd39, 8'd52,
            -8'd4, 8'd15, 8'd0, -8'd44, 8'd2, 8'd34, -8'd17, 8'd39, -8'd15,
            8'd34, -8'd5, -8'd41, -8'd19, -8'd6, 8'd8, 8'd105, 8'd75, -8'd12,
            8'd5, 8'd33, -8'd17, -8'd18, 8'd32, 8'd33, -8'd35, 8'd24, -8'd4,
            -8'd3, -8'd20, 8'd13, 8'd26, 8'd33, -8'd14, 8'd0, -8'd27, 8'd17,
            -8'd62, -8'd33, 8'd0, -8'd48, 8'd42, 8'd37, -8'd9, 8'd26, 8'd11,
            8'd4, 8'd20, -8'd23, 8'd84, -8'd30, -8'd50, 8'd13, -8'd50, -8'd18,
            8'd27, 8'd11, -8'd3, -8'd99, 8'd38, 8'd21, -8'd31, -8'd5, 8'd36,
            -8'd32, 8'd42, 8'd31, -8'd62, -8'd4, -8'd37, 8'd42, 8'd56, -8'd31,
            -8'd24, 8'd14, -8'd3, 8'd4, 8'd6, 8'd24, 8'd6, 8'd30, 8'd8,
            8'd0, 8'd26, 8'd5, -8'd22, -8'd34, -8'd31, -8'd7, -8'd15, -8'd27,
            8'd78, 8'd121, 8'd61, 8'd57, 8'd85, 8'd42, -8'd2, 8'd48, 8'd71,
            8'd0, -8'd32, -8'd6, 8'd9, -8'd2, 8'd18, 8'd14, -8'd33, -8'd16,
            8'd34, 8'd2, 8'd7, -8'd3, -8'd24, 8'd15, -8'd31, 8'd26, -8'd23,
            8'd13, -8'd71, -8'd82, 8'd49, -8'd92, -8'd127, -8'd19, -8'd101, -8'd92,
            -8'd43, -8'd21, 8'd82, -8'd47, 8'd52, 8'd56, 8'd22, 8'd104, 8'd49,
            8'd24, 8'd54, -8'd10, 8'd45, 8'd26, 8'd14, 8'd39, -8'd6, 8'd5,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd28, -8'd98, 8'd86, -8'd62, 8'd81, 8'd97, 8'd69, 8'd57, -8'd74,
            -8'd39, 8'd14, -8'd53, 8'd58, -8'd103, -8'd99, 8'd27, -8'd20, 8'd86,
            8'd68, -8'd19, -8'd85, -8'd24, 8'd84, 8'd68, 8'd81, -8'd109, -8'd108,
            -8'd18, -8'd74, 8'd63, 8'd76, 8'd87, -8'd106, 8'd34, -8'd73, -8'd110,
            8'd75, 8'd7, -8'd101, -8'd95, 8'd99, 8'd77, -8'd87, 8'd51, -8'd85,
            -8'd2, 8'd21, -8'd61, 8'd41, -8'd108, 8'd44, 8'd66, -8'd94, 8'd27,
            -8'd88, -8'd104, -8'd42, 8'd55, -8'd34, -8'd43, 8'd3, -8'd48, 8'd85,
            8'd83, -8'd40, -8'd18, 8'd64, -8'd30, 8'd84, 8'd97, 8'd102, 8'd41,
            -8'd62, 8'd3, 8'd5, 8'd27, 8'd50, -8'd20, 8'd29, 8'd11, -8'd88,
            -8'd55, -8'd48, -8'd11, 8'd81, 8'd11, 8'd41, 8'd55, -8'd23, 8'd107,
            -8'd7, 8'd48, -8'd110, 8'd63, -8'd60, -8'd88, 8'd56, -8'd6, 8'd55,
            -8'd2, -8'd73, -8'd106, 8'd3, -8'd101, -8'd27, 8'd42, 8'd47, -8'd41,
            -8'd87, 8'd0, -8'd96, -8'd18, -8'd13, 8'd44, -8'd39, -8'd96, 8'd90,
            8'd34, 8'd90, 8'd3, 8'd61, -8'd3, -8'd99, -8'd84, -8'd89, 8'd62,
            8'd0, 8'd18, -8'd105, 8'd88, -8'd14, 8'd52, -8'd83, 8'd61, -8'd102,
            -8'd92, 8'd18, 8'd18, -8'd72, 8'd43, 8'd50, 8'd62, -8'd73, -8'd29,
            8'd88, -8'd41, 8'd52, -8'd115, 8'd12, 8'd37, -8'd120, -8'd16, 8'd86,
            8'd9, -8'd40, -8'd95, -8'd2, 8'd101, -8'd60, 8'd68, -8'd11, 8'd96,
            8'd24, 8'd9, -8'd69, -8'd111, -8'd8, -8'd5, 8'd91, -8'd33, -8'd76,
            8'd81, 8'd9, 8'd16, -8'd22, -8'd89, -8'd90, -8'd107, 8'd3, -8'd83,
            8'd62, 8'd53, 8'd61, 8'd4, -8'd58, -8'd29, -8'd95, 8'd88, -8'd89,
            8'd3, 8'd22, -8'd44, 8'd59, -8'd37, -8'd110, 8'd66, 8'd52, -8'd29,
            -8'd37, -8'd21, -8'd30, -8'd127, -8'd52, 8'd103, 8'd83, -8'd49, -8'd26,
            8'd35, -8'd45, 8'd56, 8'd45, -8'd86, 8'd121, -8'd17, -8'd80, 8'd87,
            -8'd104, -8'd10, -8'd12, 8'd80, 8'd62, -8'd17, -8'd41, 8'd33, -8'd86,
            -8'd53, 8'd9, 8'd0, 8'd1, -8'd86, -8'd38, 8'd29, 8'd63, -8'd88,
            -8'd76, -8'd1, -8'd22, -8'd104, 8'd88, -8'd106, 8'd102, -8'd93, -8'd83,
            8'd19, -8'd107, -8'd108, 8'd94, -8'd70, 8'd13, 8'd55, 8'd85, -8'd76,
            -8'd48, 8'd27, -8'd39, -8'd35, 8'd103, 8'd101, -8'd77, 8'd64, -8'd5,
            -8'd111, 8'd27, 8'd22, -8'd30, -8'd18, 8'd47, -8'd86, 8'd19, 8'd4,
            8'd29, -8'd44, 8'd68, -8'd78, -8'd33, -8'd94, -8'd46, 8'd109, 8'd99,
            -8'd27, -8'd11, -8'd93, -8'd14, 8'd20, -8'd118, -8'd89, -8'd51, -8'd39,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd59, -8'd30, -8'd76, 8'd79, -8'd9, -8'd60, 8'd55, -8'd49, 8'd8,
            -8'd91, 8'd41, -8'd47, 8'd37, 8'd20, -8'd50, 8'd31, 8'd52, -8'd98,
            8'd19, 8'd9, -8'd36, -8'd127, -8'd4, 8'd34, -8'd95, -8'd37, -8'd59,
            -8'd76, 8'd61, 8'd46, -8'd92, 8'd22, 8'd61, 8'd5, -8'd76, -8'd77,
            8'd23, -8'd28, 8'd12, 8'd80, -8'd61, -8'd11, 8'd17, -8'd38, -8'd41,
            -8'd42, -8'd10, 8'd53, 8'd35, -8'd59, -8'd99, 8'd20, -8'd83, -8'd27,
            -8'd84, 8'd3, -8'd21, 8'd53, -8'd36, -8'd75, -8'd89, 8'd16, 8'd51,
            8'd89, 8'd87, -8'd73, -8'd85, 8'd85, 8'd13, 8'd12, 8'd85, 8'd64,
            -8'd81, -8'd32, -8'd99, -8'd22, 8'd21, -8'd30, -8'd84, 8'd7, -8'd63,
            -8'd92, 8'd32, -8'd104, 8'd21, -8'd74, 8'd18, -8'd62, 8'd8, 8'd27,
            8'd84, 8'd9, -8'd76, -8'd2, 8'd45, 8'd34, -8'd74, -8'd34, 8'd85,
            -8'd51, 8'd82, -8'd59, -8'd93, 8'd9, -8'd3, 8'd18, 8'd34, -8'd67,
            8'd1, -8'd46, -8'd93, -8'd119, -8'd78, -8'd97, 8'd29, -8'd4, 8'd16,
            8'd17, -8'd32, 8'd18, 8'd2, 8'd39, -8'd83, -8'd22, 8'd3, -8'd68,
            8'd14, 8'd70, 8'd4, -8'd3, 8'd38, -8'd26, 8'd23, -8'd27, -8'd9,
            -8'd77, 8'd61, 8'd74, -8'd69, -8'd6, -8'd65, -8'd27, -8'd121, -8'd115,
            8'd51, 8'd63, -8'd75, -8'd65, 8'd59, -8'd88, -8'd91, -8'd51, 8'd17,
            -8'd14, 8'd69, 8'd91, 8'd37, 8'd89, 8'd59, 8'd0, -8'd66, -8'd74,
            8'd86, -8'd29, 8'd28, 8'd62, 8'd77, 8'd43, 8'd80, -8'd13, 8'd63,
            -8'd41, 8'd9, 8'd58, 8'd27, -8'd93, -8'd66, -8'd7, -8'd7, 8'd54,
            -8'd47, -8'd80, 8'd64, -8'd29, -8'd98, -8'd37, -8'd67, -8'd95, 8'd26,
            -8'd58, -8'd38, 8'd40, 8'd51, -8'd28, 8'd60, 8'd3, -8'd80, 8'd5,
            8'd81, 8'd18, 8'd2, -8'd4, 8'd57, 8'd33, -8'd8, 8'd20, -8'd37,
            8'd44, 8'd55, -8'd60, 8'd59, -8'd33, -8'd41, -8'd4, 8'd51, -8'd88,
            -8'd94, 8'd16, -8'd46, 8'd34, -8'd96, -8'd89, -8'd4, -8'd119, 8'd48,
            -8'd70, -8'd40, 8'd38, 8'd46, 8'd15, 8'd4, -8'd64, 8'd66, 8'd92,
            8'd10, -8'd9, 8'd9, 8'd39, -8'd80, -8'd46, -8'd1, -8'd12, 8'd13,
            8'd93, 8'd28, -8'd5, -8'd85, -8'd16, 8'd1, 8'd85, -8'd86, 8'd1,
            -8'd83, -8'd88, -8'd90, 8'd45, -8'd11, -8'd51, -8'd39, -8'd26, -8'd21,
            8'd27, 8'd8, -8'd64, -8'd15, -8'd106, 8'd27, 8'd41, -8'd91, 8'd48,
            -8'd11, -8'd84, -8'd71, -8'd8, 8'd14, 8'd73, 8'd49, -8'd68, 8'd66,
            8'd84, -8'd104, -8'd19, 8'd71, 8'd14, -8'd74, -8'd83, -8'd35, 8'd2,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd75, -8'd25, 8'd33, 8'd67, -8'd4, 8'd82, -8'd36, 8'd50, 8'd55,
            8'd3, -8'd60, -8'd19, -8'd82, 8'd52, -8'd97, -8'd41, -8'd40, 8'd4,
            -8'd100, 8'd69, -8'd30, -8'd102, -8'd102, 8'd71, -8'd102, -8'd11, 8'd78,
            -8'd28, -8'd124, -8'd46, -8'd75, 8'd87, -8'd90, -8'd1, -8'd47, 8'd14,
            8'd34, 8'd12, -8'd18, -8'd64, -8'd37, 8'd79, -8'd94, -8'd26, -8'd82,
            8'd15, 8'd59, 8'd63, -8'd52, -8'd112, 8'd11, 8'd61, -8'd68, 8'd87,
            -8'd67, -8'd10, -8'd72, -8'd11, 8'd10, -8'd123, 8'd64, -8'd10, 8'd31,
            -8'd71, -8'd35, 8'd64, 8'd17, -8'd34, -8'd26, 8'd8, -8'd82, -8'd100,
            -8'd103, -8'd90, 8'd5, -8'd72, -8'd24, -8'd60, -8'd17, 8'd82, -8'd39,
            8'd11, 8'd80, -8'd58, 8'd20, -8'd106, 8'd42, 8'd103, -8'd90, -8'd118,
            -8'd18, -8'd9, 8'd6, -8'd44, -8'd111, -8'd100, 8'd61, 8'd73, 8'd9,
            -8'd27, 8'd54, 8'd78, -8'd23, -8'd7, 8'd63, -8'd5, -8'd32, 8'd44,
            -8'd55, -8'd19, 8'd54, -8'd75, 8'd76, 8'd10, 8'd31, -8'd58, 8'd55,
            8'd36, 8'd111, -8'd83, -8'd74, -8'd79, 8'd38, -8'd73, -8'd16, 8'd45,
            -8'd51, -8'd28, -8'd20, -8'd61, 8'd52, 8'd21, 8'd22, 8'd77, -8'd35,
            8'd70, 8'd86, 8'd69, -8'd78, -8'd111, -8'd58, -8'd7, -8'd100, -8'd99,
            8'd64, -8'd54, 8'd37, -8'd16, -8'd15, 8'd90, -8'd113, 8'd8, 8'd12,
            8'd44, -8'd85, -8'd40, 8'd55, -8'd58, 8'd40, 8'd43, -8'd113, -8'd101,
            -8'd1, 8'd79, 8'd29, -8'd63, 8'd32, -8'd99, 8'd33, -8'd50, 8'd48,
            -8'd21, 8'd96, 8'd35, 8'd56, -8'd65, -8'd88, -8'd21, 8'd11, 8'd44,
            -8'd2, -8'd92, 8'd48, -8'd80, -8'd48, -8'd91, -8'd58, -8'd105, -8'd117,
            -8'd55, 8'd80, 8'd38, 8'd80, -8'd31, -8'd74, -8'd100, -8'd56, -8'd72,
            -8'd114, 8'd4, 8'd73, 8'd15, -8'd75, -8'd36, -8'd61, 8'd58, -8'd101,
            -8'd17, -8'd99, 8'd50, -8'd2, -8'd115, -8'd102, -8'd1, 8'd63, -8'd22,
            -8'd124, 8'd52, -8'd44, 8'd34, 8'd49, -8'd34, 8'd10, 8'd88, -8'd48,
            -8'd58, -8'd6, 8'd89, -8'd58, 8'd84, -8'd23, 8'd83, 8'd107, 8'd93,
            -8'd112, -8'd125, -8'd85, -8'd71, 8'd100, -8'd79, -8'd40, -8'd6, -8'd15,
            8'd45, 8'd88, -8'd6, 8'd32, 8'd49, 8'd22, -8'd106, -8'd26, -8'd21,
            8'd25, -8'd107, -8'd61, 8'd99, 8'd107, 8'd93, 8'd4, 8'd64, -8'd106,
            -8'd90, 8'd28, 8'd70, -8'd10, -8'd127, -8'd117, -8'd65, 8'd87, -8'd111,
            -8'd17, -8'd2, -8'd81, 8'd100, -8'd110, -8'd68, -8'd79, 8'd61, 8'd33,
            -8'd79, 8'd63, -8'd2, 8'd33, 8'd81, 8'd37, 8'd75, -8'd50, 8'd35,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd89, 8'd54, -8'd39, -8'd21, 8'd9, 8'd6, -8'd72, 8'd29, -8'd91,
            -8'd25, -8'd3, 8'd57, 8'd20, 8'd39, -8'd100, -8'd44, -8'd52, -8'd73,
            8'd12, -8'd55, 8'd59, 8'd38, 8'd51, -8'd53, -8'd37, -8'd106, 8'd36,
            -8'd78, -8'd60, 8'd45, 8'd58, 8'd10, 8'd74, -8'd89, -8'd67, 8'd48,
            8'd53, 8'd70, 8'd87, -8'd58, -8'd51, 8'd32, -8'd7, -8'd70, 8'd76,
            -8'd87, -8'd44, -8'd112, -8'd94, 8'd77, -8'd90, 8'd67, 8'd12, -8'd14,
            -8'd4, 8'd16, -8'd75, -8'd100, -8'd26, -8'd20, -8'd8, -8'd67, 8'd90,
            8'd5, 8'd49, -8'd85, 8'd54, 8'd95, 8'd19, -8'd100, -8'd90, 8'd58,
            8'd67, -8'd74, -8'd32, 8'd67, -8'd40, 8'd79, -8'd93, 8'd54, -8'd22,
            8'd36, -8'd47, 8'd40, 8'd2, 8'd63, -8'd69, -8'd105, 8'd46, 8'd80,
            -8'd23, 8'd33, 8'd27, -8'd42, -8'd30, -8'd9, 8'd36, 8'd0, -8'd97,
            8'd19, 8'd56, -8'd115, -8'd124, -8'd57, -8'd127, -8'd91, -8'd58, 8'd67,
            -8'd23, 8'd4, -8'd2, 8'd90, -8'd45, 8'd51, -8'd96, -8'd106, 8'd27,
            8'd87, -8'd35, -8'd57, 8'd98, 8'd33, 8'd91, -8'd42, 8'd93, 8'd74,
            8'd65, -8'd114, 8'd3, -8'd91, -8'd71, 8'd40, 8'd77, 8'd66, -8'd3,
            8'd82, -8'd18, -8'd27, 8'd76, 8'd80, 8'd51, -8'd93, -8'd76, -8'd80,
            8'd72, -8'd30, -8'd109, 8'd46, 8'd27, -8'd48, -8'd11, 8'd16, -8'd92,
            8'd78, 8'd76, 8'd24, 8'd65, -8'd2, -8'd22, 8'd99, 8'd85, -8'd93,
            8'd90, -8'd83, 8'd105, -8'd1, -8'd42, 8'd58, -8'd14, 8'd93, 8'd75,
            -8'd89, -8'd106, 8'd95, -8'd72, -8'd6, -8'd37, -8'd77, 8'd19, 8'd107,
            -8'd59, 8'd29, 8'd22, 8'd17, -8'd55, 8'd60, -8'd89, 8'd23, 8'd16,
            8'd58, -8'd108, -8'd9, -8'd77, 8'd92, 8'd61, 8'd53, -8'd95, 8'd44,
            -8'd116, 8'd3, -8'd10, 8'd3, -8'd8, -8'd111, -8'd4, 8'd44, -8'd19,
            -8'd10, 8'd78, -8'd29, -8'd105, 8'd94, -8'd82, 8'd7, -8'd89, 8'd72,
            -8'd35, -8'd15, -8'd14, 8'd45, -8'd64, 8'd14, -8'd88, 8'd86, 8'd86,
            8'd2, 8'd49, 8'd80, -8'd12, -8'd97, 8'd44, 8'd16, -8'd58, 8'd99,
            -8'd8, 8'd82, -8'd26, -8'd46, 8'd63, -8'd74, 8'd57, 8'd94, -8'd43,
            -8'd91, -8'd98, 8'd98, 8'd107, 8'd37, -8'd52, -8'd44, -8'd80, -8'd28,
            -8'd74, 8'd3, 8'd53, 8'd17, -8'd6, -8'd51, -8'd94, 8'd45, -8'd96,
            -8'd81, 8'd86, 8'd69, -8'd104, 8'd42, 8'd37, -8'd41, 8'd86, -8'd56,
            8'd73, -8'd32, 8'd28, 8'd0, -8'd88, -8'd52, -8'd43, -8'd60, -8'd116,
            8'd75, 8'd58, -8'd104, -8'd51, 8'd48, 8'd5, -8'd72, -8'd58, 8'd86,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd1, 8'd23, 8'd12, 8'd15, 8'd14, -8'd5, 8'd46, 8'd5, 8'd50,
            8'd1, -8'd26, -8'd14, 8'd10, 8'd42, 8'd5, 8'd10, -8'd11, 8'd53,
            -8'd29, -8'd42, -8'd25, -8'd87, -8'd63, -8'd95, -8'd51, -8'd47, -8'd82,
            -8'd14, -8'd29, 8'd27, 8'd0, 8'd8, -8'd3, 8'd29, 8'd49, 8'd31,
            8'd0, -8'd13, 8'd6, 8'd5, -8'd4, 8'd32, 8'd18, -8'd5, 8'd19,
            8'd43, 8'd5, -8'd16, 8'd19, -8'd14, -8'd20, -8'd25, -8'd53, -8'd53,
            8'd22, -8'd36, -8'd15, -8'd57, -8'd91, -8'd85, -8'd85, -8'd96, -8'd43,
            8'd9, -8'd15, 8'd8, -8'd4, -8'd3, -8'd16, -8'd32, -8'd4, -8'd33,
            -8'd29, -8'd31, -8'd59, 8'd5, -8'd8, 8'd46, 8'd31, -8'd22, 8'd42,
            -8'd11, -8'd43, -8'd32, 8'd38, -8'd16, 8'd0, 8'd19, 8'd48, 8'd1,
            8'd14, -8'd1, -8'd28, 8'd6, -8'd27, -8'd2, 8'd17, 8'd21, 8'd27,
            -8'd57, -8'd9, -8'd4, 8'd23, 8'd15, 8'd27, 8'd54, 8'd5, 8'd2,
            8'd88, 8'd75, 8'd21, -8'd12, -8'd70, -8'd89, -8'd19, 8'd16, -8'd59,
            -8'd22, 8'd5, 8'd0, -8'd4, -8'd9, 8'd31, 8'd8, 8'd14, -8'd6,
            8'd20, -8'd20, -8'd6, 8'd51, 8'd46, 8'd43, 8'd72, 8'd3, 8'd3,
            8'd18, 8'd19, 8'd10, 8'd32, 8'd33, -8'd6, 8'd58, 8'd39, 8'd18,
            -8'd39, -8'd31, 8'd1, -8'd6, 8'd21, 8'd15, 8'd25, -8'd10, 8'd55,
            8'd26, 8'd62, 8'd38, 8'd68, 8'd41, -8'd16, -8'd18, -8'd34, -8'd65,
            8'd14, -8'd34, 8'd2, 8'd26, 8'd13, -8'd29, -8'd4, 8'd29, -8'd11,
            8'd29, -8'd6, 8'd14, 8'd18, 8'd4, 8'd13, 8'd28, 8'd1, 8'd23,
            -8'd26, -8'd7, 8'd13, 8'd6, 8'd21, 8'd49, 8'd24, 8'd57, 8'd19,
            8'd10, -8'd51, -8'd26, -8'd64, -8'd98, -8'd55, -8'd94, 8'd0, -8'd20,
            8'd25, 8'd11, 8'd50, 8'd29, -8'd23, 8'd25, 8'd6, -8'd2, -8'd1,
            8'd39, 8'd61, 8'd17, 8'd15, 8'd31, 8'd14, 8'd84, -8'd16, 8'd21,
            -8'd39, 8'd31, -8'd21, -8'd10, 8'd52, 8'd36, 8'd58, 8'd16, 8'd42,
            8'd15, -8'd31, 8'd2, 8'd0, -8'd26, 8'd24, 8'd22, 8'd17, -8'd33,
            -8'd16, -8'd12, -8'd71, -8'd44, -8'd36, -8'd2, -8'd86, -8'd108, -8'd24,
            8'd34, -8'd34, -8'd23, -8'd19, 8'd12, -8'd4, -8'd27, 8'd24, 8'd22,
            8'd15, 8'd28, 8'd4, -8'd8, -8'd5, -8'd15, 8'd22, -8'd10, -8'd1,
            8'd32, 8'd22, -8'd94, -8'd127, -8'd108, -8'd72, -8'd86, -8'd37, 8'd45,
            -8'd29, -8'd34, -8'd58, -8'd14, -8'd44, -8'd45, -8'd18, -8'd31, -8'd26,
            -8'd27, -8'd28, -8'd24, -8'd51, 8'd1, 8'd54, 8'd5, 8'd10, 8'd5,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd24, 8'd12, -8'd28, -8'd25, -8'd16, 8'd10, -8'd1, -8'd11, 8'd27,
            -8'd2, 8'd26, -8'd41, 8'd0, 8'd30, 8'd11, -8'd10, 8'd17, 8'd7,
            -8'd25, -8'd35, 8'd20, -8'd24, -8'd82, -8'd40, 8'd7, -8'd19, -8'd17,
            -8'd11, -8'd11, -8'd32, -8'd12, 8'd16, -8'd36, -8'd36, 8'd6, 8'd13,
            -8'd12, -8'd11, -8'd3, 8'd15, -8'd13, -8'd17, 8'd14, 8'd0, -8'd4,
            -8'd19, -8'd63, -8'd21, 8'd8, -8'd77, -8'd33, 8'd23, -8'd6, -8'd47,
            -8'd41, -8'd50, 8'd2, -8'd12, -8'd65, -8'd27, -8'd21, -8'd37, -8'd57,
            -8'd19, 8'd16, 8'd13, 8'd14, 8'd15, 8'd10, 8'd11, -8'd5, -8'd15,
            8'd11, -8'd13, -8'd49, -8'd24, 8'd10, -8'd28, -8'd14, 8'd16, 8'd17,
            8'd3, 8'd35, -8'd56, -8'd17, 8'd32, 8'd8, -8'd6, 8'd21, 8'd15,
            8'd7, -8'd13, -8'd13, 8'd18, 8'd7, 8'd1, -8'd2, 8'd2, -8'd2,
            8'd30, 8'd32, -8'd27, -8'd6, 8'd48, -8'd5, -8'd4, 8'd7, 8'd3,
            -8'd31, -8'd9, 8'd31, -8'd63, -8'd38, 8'd33, 8'd2, -8'd21, -8'd36,
            8'd1, -8'd18, -8'd14, -8'd17, 8'd6, -8'd3, 8'd9, -8'd15, -8'd1,
            8'd8, -8'd1, -8'd10, -8'd26, -8'd4, -8'd16, 8'd0, 8'd19, -8'd7,
            8'd30, 8'd30, -8'd46, -8'd23, 8'd32, 8'd0, 8'd7, -8'd5, 8'd5,
            8'd25, 8'd13, -8'd20, -8'd4, -8'd11, -8'd4, 8'd11, 8'd18, 8'd18,
            -8'd27, -8'd13, 8'd44, -8'd29, -8'd62, -8'd51, 8'd39, -8'd7, -8'd47,
            -8'd13, 8'd18, -8'd12, -8'd1, -8'd3, 8'd15, 8'd16, 8'd4, 8'd9,
            -8'd16, -8'd17, 8'd15, -8'd17, 8'd7, 8'd4, 8'd4, 8'd4, 8'd11,
            8'd26, 8'd22, -8'd22, -8'd2, 8'd17, 8'd7, -8'd17, -8'd4, 8'd20,
            8'd15, -8'd11, -8'd22, 8'd12, -8'd9, -8'd34, -8'd11, 8'd3, -8'd2,
            8'd17, 8'd31, -8'd5, -8'd38, 8'd35, 8'd48, -8'd3, -8'd17, 8'd14,
            -8'd2, 8'd14, -8'd30, -8'd10, 8'd4, 8'd8, 8'd20, -8'd15, 8'd6,
            8'd20, -8'd4, -8'd10, -8'd9, 8'd2, 8'd13, -8'd16, -8'd13, -8'd5,
            -8'd4, -8'd18, 8'd11, 8'd18, 8'd12, -8'd1, -8'd9, 8'd13, 8'd8,
            8'd75, 8'd108, -8'd39, 8'd40, 8'd127, 8'd36, -8'd35, -8'd8, 8'd4,
            8'd13, 8'd10, -8'd1, 8'd18, 8'd10, -8'd18, 8'd13, -8'd14, 8'd14,
            8'd4, -8'd3, 8'd17, 8'd5, -8'd11, -8'd9, 8'd2, 8'd6, 8'd4,
            -8'd6, -8'd66, -8'd41, 8'd15, 8'd13, -8'd18, 8'd12, 8'd5, 8'd19,
            -8'd8, 8'd33, 8'd43, -8'd80, -8'd37, -8'd2, -8'd45, -8'd45, -8'd36,
            8'd35, 8'd28, -8'd67, 8'd17, 8'd32, -8'd1, -8'd5, 8'd4, 8'd31,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd0, 8'd25, 8'd36, 8'd33, -8'd21, -8'd35, 8'd7, 8'd4, 8'd23,
            8'd9, 8'd8, 8'd7, 8'd29, 8'd6, 8'd27, -8'd14, -8'd28, -8'd39,
            -8'd12, 8'd7, -8'd65, -8'd37, 8'd8, -8'd56, -8'd17, 8'd9, -8'd13,
            -8'd12, -8'd21, 8'd9, 8'd47, 8'd36, 8'd3, 8'd9, -8'd5, 8'd11,
            8'd27, -8'd24, 8'd6, 8'd4, -8'd22, 8'd1, -8'd17, 8'd15, 8'd2,
            -8'd46, -8'd40, -8'd27, -8'd50, -8'd37, -8'd12, -8'd8, -8'd9, 8'd17,
            -8'd18, -8'd27, -8'd49, -8'd3, -8'd19, -8'd10, -8'd1, -8'd5, 8'd17,
            8'd21, -8'd26, -8'd18, -8'd11, 8'd12, 8'd20, 8'd9, -8'd18, 8'd4,
            8'd22, 8'd26, 8'd18, 8'd37, 8'd56, 8'd50, 8'd18, -8'd6, -8'd22,
            -8'd1, -8'd7, -8'd1, 8'd20, 8'd13, -8'd6, -8'd17, -8'd54, -8'd45,
            -8'd2, -8'd6, 8'd26, -8'd27, -8'd9, 8'd6, 8'd6, -8'd11, -8'd13,
            8'd17, 8'd24, 8'd5, 8'd3, 8'd0, 8'd18, -8'd46, -8'd23, -8'd10,
            8'd70, 8'd43, 8'd99, 8'd16, -8'd18, -8'd17, 8'd44, 8'd116, 8'd38,
            -8'd2, -8'd11, 8'd19, -8'd16, -8'd17, -8'd23, 8'd22, -8'd21, -8'd6,
            -8'd19, 8'd12, 8'd8, 8'd20, 8'd16, -8'd5, -8'd19, -8'd55, -8'd6,
            -8'd6, 8'd5, 8'd21, 8'd21, 8'd36, -8'd4, -8'd43, -8'd52, -8'd32,
            -8'd2, 8'd10, 8'd26, 8'd19, 8'd24, 8'd2, -8'd1, -8'd31, -8'd16,
            8'd12, 8'd28, 8'd14, 8'd105, 8'd57, -8'd57, 8'd53, 8'd88, 8'd127,
            -8'd10, 8'd25, 8'd17, 8'd10, 8'd21, 8'd8, 8'd20, 8'd22, -8'd10,
            -8'd23, 8'd1, 8'd6, -8'd15, -8'd10, -8'd26, 8'd21, 8'd21, -8'd9,
            -8'd8, -8'd3, 8'd24, 8'd1, 8'd25, -8'd39, -8'd39, -8'd53, -8'd23,
            -8'd2, 8'd21, -8'd33, 8'd2, 8'd43, 8'd48, 8'd32, -8'd20, -8'd16,
            8'd14, 8'd54, 8'd7, -8'd10, -8'd46, 8'd6, -8'd18, 8'd18, -8'd3,
            -8'd18, 8'd28, 8'd48, 8'd22, -8'd37, -8'd47, -8'd8, -8'd36, 8'd15,
            8'd16, 8'd20, 8'd19, -8'd4, 8'd8, -8'd13, -8'd14, -8'd44, -8'd29,
            8'd25, -8'd13, -8'd14, 8'd11, 8'd8, 8'd19, -8'd15, -8'd19, -8'd18,
            8'd58, 8'd4, -8'd31, -8'd45, 8'd7, 8'd23, 8'd32, -8'd27, -8'd37,
            8'd0, 8'd17, 8'd11, 8'd28, 8'd12, 8'd8, -8'd9, 8'd20, 8'd13,
            -8'd2, 8'd20, 8'd4, -8'd6, 8'd16, -8'd5, -8'd23, -8'd26, -8'd17,
            8'd24, -8'd8, -8'd27, 8'd29, 8'd81, 8'd72, 8'd63, 8'd29, 8'd27,
            8'd4, -8'd36, -8'd27, 8'd26, -8'd5, -8'd35, -8'd2, -8'd32, -8'd24,
            8'd7, 8'd20, 8'd30, 8'd19, 8'd36, 8'd38, -8'd21, -8'd21, 8'd1,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd43, -8'd62, -8'd35, -8'd83, 8'd25, 8'd62, 8'd81, 8'd75, 8'd9,
            -8'd27, -8'd12, 8'd22, -8'd15, -8'd20, 8'd33, -8'd22, 8'd36, 8'd28,
            8'd24, -8'd12, 8'd3, -8'd7, -8'd15, -8'd90, -8'd61, -8'd45, -8'd12,
            -8'd2, -8'd1, -8'd19, -8'd61, 8'd1, 8'd23, 8'd13, 8'd18, 8'd53,
            8'd22, 8'd15, 8'd12, 8'd0, 8'd27, -8'd1, -8'd4, 8'd8, -8'd13,
            -8'd14, -8'd29, 8'd27, -8'd2, -8'd10, -8'd26, 8'd12, -8'd19, 8'd12,
            8'd20, -8'd2, 8'd39, 8'd12, -8'd40, -8'd21, -8'd36, -8'd55, -8'd33,
            8'd11, 8'd2, 8'd1, -8'd10, 8'd6, 8'd10, 8'd6, 8'd20, 8'd11,
            8'd23, 8'd20, 8'd20, -8'd26, -8'd35, 8'd16, -8'd20, 8'd63, 8'd45,
            -8'd24, -8'd17, 8'd4, -8'd8, -8'd19, 8'd45, 8'd1, 8'd19, 8'd13,
            8'd16, 8'd11, 8'd24, -8'd5, -8'd11, 8'd26, 8'd26, 8'd25, 8'd20,
            8'd1, -8'd13, -8'd5, -8'd43, -8'd29, 8'd49, -8'd21, 8'd1, 8'd18,
            -8'd7, 8'd18, 8'd31, -8'd22, 8'd25, 8'd21, 8'd79, 8'd57, 8'd4,
            8'd0, -8'd23, 8'd24, 8'd23, -8'd22, -8'd8, -8'd19, -8'd30, 8'd17,
            -8'd41, -8'd13, -8'd47, -8'd63, -8'd16, 8'd31, 8'd9, 8'd56, 8'd20,
            8'd0, -8'd6, 8'd18, -8'd33, -8'd5, 8'd9, 8'd25, 8'd28, 8'd25,
            -8'd37, -8'd36, -8'd8, -8'd62, 8'd13, 8'd24, 8'd22, 8'd15, 8'd47,
            -8'd34, 8'd17, -8'd100, -8'd103, -8'd43, 8'd45, 8'd107, 8'd120, 8'd127,
            -8'd29, 8'd6, 8'd7, 8'd22, -8'd11, 8'd4, -8'd11, 8'd12, -8'd4,
            8'd22, -8'd17, -8'd19, -8'd17, 8'd29, 8'd15, 8'd10, 8'd7, 8'd29,
            -8'd53, -8'd48, -8'd60, -8'd71, -8'd3, 8'd57, 8'd15, 8'd20, 8'd51,
            8'd22, 8'd27, 8'd2, 8'd7, -8'd45, -8'd29, 8'd16, 8'd31, 8'd26,
            -8'd6, -8'd23, -8'd35, -8'd36, 8'd9, 8'd29, 8'd55, 8'd14, -8'd22,
            -8'd32, -8'd46, -8'd29, -8'd55, 8'd40, 8'd38, 8'd66, 8'd64, 8'd9,
            -8'd16, -8'd44, 8'd0, -8'd12, 8'd15, 8'd21, -8'd17, 8'd13, -8'd21,
            8'd4, 8'd21, -8'd5, 8'd10, 8'd22, -8'd14, -8'd18, 8'd0, -8'd20,
            8'd18, 8'd4, 8'd27, 8'd5, -8'd43, -8'd81, -8'd38, -8'd47, -8'd71,
            8'd2, 8'd15, 8'd18, 8'd17, 8'd18, 8'd1, 8'd5, -8'd16, 8'd18,
            -8'd27, 8'd26, -8'd23, 8'd19, -8'd2, -8'd7, -8'd26, 8'd23, -8'd9,
            8'd28, 8'd54, 8'd32, 8'd15, -8'd5, -8'd82, -8'd27, 8'd58, 8'd24,
            -8'd65, -8'd13, -8'd65, -8'd110, -8'd126, -8'd86, -8'd64, 8'd44, -8'd33,
            -8'd8, 8'd32, -8'd23, -8'd11, -8'd16, 8'd32, -8'd24, 8'd47, 8'd21,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd33, -8'd4, -8'd74, 8'd52, 8'd11, -8'd65, 8'd8, -8'd67, -8'd69,
            8'd22, 8'd6, -8'd16, 8'd28, -8'd20, -8'd8, 8'd15, -8'd30, -8'd3,
            -8'd16, -8'd1, 8'd39, 8'd13, 8'd64, 8'd17, 8'd32, 8'd60, -8'd8,
            8'd23, -8'd23, -8'd19, 8'd0, 8'd51, -8'd38, 8'd40, 8'd24, 8'd19,
            8'd6, -8'd10, 8'd32, 8'd18, -8'd4, -8'd11, 8'd18, 8'd0, 8'd9,
            8'd12, 8'd42, 8'd2, 8'd42, 8'd20, 8'd37, 8'd7, 8'd35, 8'd36,
            8'd11, 8'd25, -8'd15, 8'd37, -8'd4, 8'd40, 8'd46, 8'd5, 8'd3,
            -8'd19, 8'd4, 8'd7, 8'd12, 8'd26, -8'd26, -8'd10, 8'd0, 8'd0,
            -8'd10, -8'd8, -8'd28, -8'd51, -8'd41, -8'd52, 8'd17, 8'd4, -8'd29,
            8'd8, -8'd29, -8'd24, 8'd78, 8'd13, -8'd9, 8'd96, -8'd24, -8'd46,
            8'd2, -8'd21, 8'd9, 8'd25, 8'd21, -8'd1, 8'd9, -8'd15, 8'd29,
            8'd16, -8'd39, -8'd71, 8'd50, -8'd30, -8'd11, 8'd63, 8'd34, -8'd28,
            -8'd31, 8'd9, -8'd45, -8'd105, -8'd25, -8'd38, -8'd76, -8'd84, -8'd32,
            -8'd12, -8'd29, -8'd10, -8'd1, 8'd9, -8'd15, -8'd27, 8'd28, 8'd26,
            8'd35, 8'd28, -8'd61, 8'd60, 8'd20, -8'd66, 8'd85, -8'd13, -8'd40,
            8'd40, 8'd5, -8'd55, 8'd101, 8'd30, -8'd63, 8'd63, -8'd27, -8'd19,
            8'd61, -8'd6, -8'd19, 8'd55, -8'd24, -8'd58, 8'd76, 8'd6, -8'd38,
            -8'd64, -8'd126, -8'd70, -8'd27, -8'd79, -8'd76, 8'd10, -8'd102, 8'd26,
            8'd9, 8'd0, -8'd11, 8'd23, 8'd13, -8'd19, -8'd27, -8'd26, 8'd1,
            8'd11, 8'd26, -8'd26, 8'd0, -8'd3, -8'd12, -8'd18, -8'd26, 8'd14,
            8'd45, -8'd29, -8'd68, 8'd39, -8'd41, -8'd25, 8'd106, -8'd23, 8'd11,
            -8'd34, 8'd16, -8'd24, -8'd53, -8'd21, 8'd3, -8'd15, -8'd56, -8'd1,
            8'd8, -8'd33, -8'd25, 8'd80, 8'd25, -8'd75, 8'd46, 8'd37, -8'd35,
            8'd25, -8'd37, -8'd42, 8'd26, -8'd50, -8'd99, 8'd26, -8'd41, 8'd1,
            8'd38, -8'd2, -8'd9, 8'd59, -8'd8, 8'd1, 8'd32, 8'd30, -8'd34,
            8'd1, -8'd30, 8'd1, -8'd17, 8'd1, -8'd26, 8'd6, 8'd26, 8'd1,
            8'd57, 8'd18, -8'd11, 8'd95, 8'd95, 8'd58, 8'd53, -8'd98, 8'd100,
            -8'd21, 8'd20, 8'd21, 8'd33, 8'd25, -8'd8, 8'd14, -8'd9, 8'd22,
            -8'd6, -8'd1, -8'd33, 8'd10, 8'd7, -8'd9, -8'd7, -8'd22, -8'd29,
            -8'd58, -8'd42, -8'd6, -8'd127, -8'd48, -8'd49, -8'd93, -8'd100, -8'd23,
            -8'd11, 8'd42, -8'd7, 8'd60, 8'd87, 8'd2, 8'd31, 8'd104, -8'd34,
            -8'd27, 8'd3, -8'd73, 8'd28, -8'd10, -8'd39, -8'd5, -8'd57, -8'd1,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd109, -8'd58, -8'd45, 8'd3, -8'd11, -8'd6, 8'd81, -8'd112, 8'd72,
            -8'd23, 8'd61, 8'd79, -8'd77, -8'd118, -8'd50, -8'd28, 8'd116, 8'd37,
            -8'd77, -8'd66, 8'd74, -8'd124, 8'd121, -8'd102, 8'd61, 8'd65, 8'd30,
            8'd71, 8'd100, -8'd57, -8'd4, 8'd106, -8'd3, -8'd8, -8'd12, 8'd20,
            -8'd112, 8'd119, 8'd104, 8'd102, -8'd67, 8'd78, 8'd21, -8'd112, -8'd95,
            8'd62, -8'd98, 8'd125, 8'd125, 8'd36, 8'd22, 8'd99, -8'd11, 8'd95,
            8'd40, 8'd3, -8'd3, -8'd80, 8'd24, -8'd56, -8'd7, -8'd109, -8'd54,
            -8'd110, -8'd6, 8'd7, -8'd47, -8'd61, -8'd18, 8'd15, 8'd105, -8'd84,
            -8'd12, 8'd29, -8'd115, -8'd56, 8'd19, 8'd63, -8'd26, 8'd81, -8'd29,
            8'd32, -8'd58, 8'd7, -8'd111, -8'd31, 8'd26, 8'd76, -8'd24, -8'd109,
            8'd102, -8'd89, -8'd96, -8'd6, -8'd108, -8'd72, 8'd85, 8'd17, -8'd100,
            8'd16, -8'd90, -8'd25, 8'd120, -8'd90, 8'd27, -8'd25, -8'd38, 8'd74,
            -8'd100, 8'd6, 8'd38, -8'd7, -8'd90, -8'd123, -8'd99, -8'd79, -8'd87,
            8'd70, 8'd53, -8'd20, -8'd78, -8'd45, -8'd15, -8'd38, -8'd1, -8'd111,
            8'd27, -8'd22, -8'd84, 8'd66, 8'd108, -8'd77, -8'd118, -8'd127, -8'd122,
            8'd41, -8'd44, -8'd125, 8'd13, 8'd125, -8'd5, -8'd49, -8'd6, -8'd6,
            8'd37, -8'd49, 8'd28, -8'd101, -8'd4, 8'd19, -8'd73, 8'd86, -8'd109,
            -8'd120, 8'd107, 8'd115, -8'd50, 8'd15, -8'd39, -8'd103, -8'd123, -8'd47,
            8'd126, 8'd12, -8'd14, -8'd46, 8'd73, 8'd22, -8'd36, 8'd84, -8'd3,
            -8'd84, 8'd122, 8'd27, 8'd2, 8'd118, 8'd32, 8'd4, 8'd18, -8'd99,
            -8'd125, 8'd127, 8'd122, -8'd41, 8'd118, 8'd31, 8'd41, -8'd62, -8'd105,
            -8'd72, 8'd12, 8'd15, 8'd91, 8'd100, -8'd55, 8'd83, -8'd78, 8'd11,
            -8'd104, 8'd57, 8'd2, -8'd81, -8'd21, -8'd14, -8'd33, -8'd56, 8'd31,
            8'd99, -8'd53, -8'd7, -8'd121, 8'd59, 8'd36, -8'd46, -8'd29, -8'd85,
            -8'd105, -8'd35, -8'd112, 8'd50, 8'd40, -8'd3, 8'd35, 8'd68, -8'd6,
            8'd44, -8'd97, -8'd37, 8'd10, 8'd111, 8'd111, -8'd12, 8'd96, -8'd9,
            -8'd16, 8'd9, -8'd19, 8'd22, 8'd102, 8'd33, 8'd118, -8'd75, 8'd50,
            -8'd107, -8'd48, -8'd13, 8'd11, -8'd88, -8'd58, 8'd42, -8'd7, -8'd99,
            8'd105, 8'd121, -8'd90, 8'd51, -8'd39, 8'd55, -8'd53, -8'd43, 8'd50,
            -8'd111, -8'd6, 8'd49, 8'd106, -8'd92, 8'd66, 8'd6, -8'd12, 8'd110,
            8'd67, -8'd15, -8'd122, 8'd105, 8'd37, -8'd116, -8'd49, 8'd109, 8'd37,
            -8'd91, 8'd67, -8'd18, -8'd61, -8'd4, 8'd110, 8'd100, -8'd122, -8'd66,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd2, 8'd40, -8'd12, -8'd28, -8'd58, -8'd34, -8'd59, 8'd55, 8'd86,
            8'd22, 8'd52, 8'd18, 8'd30, 8'd5, -8'd58, -8'd57, -8'd29, -8'd7,
            -8'd14, -8'd25, -8'd35, 8'd4, 8'd43, 8'd14, -8'd21, -8'd11, -8'd28,
            -8'd23, 8'd54, 8'd40, 8'd39, 8'd33, -8'd45, -8'd43, -8'd61, 8'd2,
            8'd24, 8'd20, -8'd20, 8'd9, 8'd10, -8'd24, 8'd20, 8'd17, 8'd5,
            -8'd40, -8'd48, -8'd29, -8'd2, -8'd6, 8'd30, 8'd39, 8'd8, 8'd15,
            -8'd8, -8'd44, -8'd10, -8'd32, 8'd29, 8'd36, -8'd15, 8'd38, -8'd19,
            -8'd20, 8'd27, 8'd12, 8'd27, 8'd26, -8'd4, -8'd1, -8'd13, 8'd7,
            8'd6, 8'd42, 8'd71, 8'd59, 8'd66, 8'd1, -8'd31, -8'd35, 8'd1,
            8'd31, 8'd27, 8'd11, 8'd3, 8'd6, -8'd54, -8'd62, -8'd11, 8'd3,
            -8'd25, -8'd15, 8'd28, -8'd23, -8'd28, -8'd21, -8'd24, -8'd22, -8'd17,
            8'd23, 8'd11, 8'd59, -8'd23, -8'd38, -8'd45, -8'd67, -8'd1, 8'd0,
            -8'd40, -8'd18, -8'd54, 8'd21, 8'd7, 8'd25, 8'd62, 8'd50, 8'd59,
            -8'd3, -8'd12, -8'd42, 8'd3, -8'd9, -8'd13, -8'd11, 8'd0, -8'd8,
            8'd31, 8'd17, 8'd53, -8'd12, -8'd39, -8'd64, -8'd29, -8'd22, 8'd35,
            8'd1, 8'd3, 8'd42, -8'd15, -8'd34, -8'd24, -8'd64, -8'd13, 8'd43,
            -8'd4, 8'd55, 8'd65, 8'd6, -8'd23, -8'd66, -8'd72, -8'd19, 8'd23,
            -8'd10, 8'd69, 8'd50, 8'd34, 8'd16, 8'd60, 8'd9, 8'd87, 8'd113,
            8'd27, 8'd11, 8'd19, 8'd19, -8'd23, 8'd25, -8'd8, -8'd29, -8'd11,
            -8'd7, 8'd21, -8'd29, -8'd20, -8'd6, 8'd18, 8'd21, -8'd11, 8'd11,
            8'd2, 8'd25, 8'd58, 8'd11, -8'd25, -8'd27, -8'd73, 8'd3, 8'd14,
            -8'd23, -8'd40, 8'd8, 8'd19, 8'd42, -8'd19, 8'd15, -8'd14, -8'd24,
            8'd9, 8'd23, -8'd4, -8'd5, -8'd58, -8'd63, -8'd58, -8'd12, 8'd56,
            8'd16, 8'd21, 8'd30, -8'd36, -8'd69, -8'd49, -8'd24, 8'd47, 8'd39,
            8'd17, 8'd7, 8'd17, 8'd22, -8'd39, -8'd46, -8'd56, -8'd25, 8'd29,
            8'd20, 8'd16, 8'd19, 8'd27, 8'd19, -8'd23, 8'd4, -8'd16, 8'd28,
            -8'd16, 8'd15, -8'd30, -8'd2, -8'd67, -8'd120, -8'd75, -8'd75, -8'd92,
            8'd8, -8'd13, -8'd27, 8'd18, 8'd8, 8'd20, -8'd2, -8'd15, 8'd3,
            -8'd28, 8'd12, -8'd21, 8'd29, 8'd26, -8'd1, 8'd1, 8'd8, 8'd1,
            -8'd90, -8'd14, 8'd30, 8'd70, 8'd91, 8'd69, 8'd15, -8'd14, -8'd2,
            8'd6, 8'd24, 8'd72, 8'd7, 8'd20, -8'd70, -8'd72, -8'd127, -8'd124,
            -8'd5, 8'd2, 8'd59, 8'd15, -8'd5, -8'd52, -8'd114, -8'd82, 8'd20,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd77, -8'd95, 8'd102, -8'd38, -8'd37, -8'd120, -8'd104, -8'd7, -8'd125,
            8'd80, 8'd41, 8'd3, -8'd57, 8'd94, 8'd81, -8'd36, 8'd61, 8'd106,
            -8'd83, 8'd78, -8'd55, 8'd4, -8'd76, -8'd79, -8'd22, -8'd107, 8'd68,
            8'd109, -8'd83, 8'd36, -8'd73, 8'd7, 8'd95, 8'd68, 8'd65, 8'd10,
            8'd15, -8'd53, -8'd16, 8'd112, -8'd52, -8'd96, 8'd74, -8'd37, 8'd42,
            8'd13, -8'd8, -8'd26, -8'd114, -8'd55, 8'd79, -8'd105, 8'd85, -8'd101,
            -8'd121, 8'd53, 8'd72, 8'd27, -8'd1, -8'd97, -8'd7, 8'd54, 8'd48,
            -8'd57, 8'd105, -8'd43, -8'd12, -8'd27, -8'd119, -8'd76, -8'd100, 8'd103,
            -8'd118, -8'd91, -8'd117, 8'd54, 8'd78, -8'd79, -8'd114, -8'd65, -8'd81,
            8'd4, 8'd18, -8'd20, 8'd85, -8'd58, 8'd61, 8'd45, -8'd44, -8'd43,
            -8'd54, 8'd79, 8'd4, -8'd31, 8'd58, 8'd14, 8'd104, 8'd25, 8'd46,
            8'd95, -8'd50, -8'd89, 8'd40, 8'd75, 8'd35, -8'd6, -8'd127, -8'd68,
            8'd72, -8'd109, -8'd111, -8'd42, 8'd18, -8'd84, -8'd102, -8'd5, -8'd92,
            -8'd9, 8'd70, 8'd88, -8'd111, 8'd116, 8'd93, -8'd79, -8'd85, 8'd27,
            -8'd40, -8'd100, -8'd95, -8'd67, 8'd54, -8'd23, -8'd43, -8'd41, -8'd77,
            8'd21, -8'd87, -8'd52, -8'd75, 8'd11, -8'd11, -8'd17, -8'd37, -8'd127,
            -8'd121, 8'd111, -8'd88, -8'd20, 8'd57, -8'd9, -8'd25, 8'd94, 8'd47,
            -8'd14, 8'd78, 8'd72, -8'd8, 8'd76, 8'd39, -8'd81, 8'd7, -8'd21,
            -8'd57, 8'd90, 8'd82, -8'd94, 8'd58, -8'd119, -8'd66, 8'd25, -8'd61,
            -8'd97, 8'd96, -8'd61, -8'd103, -8'd4, 8'd10, 8'd54, 8'd13, -8'd28,
            8'd69, 8'd8, 8'd96, -8'd33, 8'd100, 8'd60, 8'd24, 8'd77, 8'd59,
            8'd57, -8'd11, -8'd83, 8'd59, 8'd47, -8'd117, -8'd6, -8'd123, 8'd103,
            -8'd6, -8'd9, -8'd22, 8'd6, -8'd115, -8'd24, 8'd108, -8'd7, 8'd105,
            -8'd78, -8'd90, -8'd16, -8'd11, -8'd61, -8'd8, 8'd65, 8'd82, 8'd17,
            8'd45, -8'd46, -8'd81, 8'd9, 8'd14, 8'd107, 8'd43, -8'd78, -8'd109,
            -8'd109, 8'd80, 8'd110, 8'd3, 8'd18, -8'd94, 8'd35, -8'd67, 8'd107,
            8'd35, -8'd49, -8'd74, 8'd47, 8'd33, 8'd68, 8'd20, 8'd79, -8'd117,
            -8'd107, -8'd87, 8'd42, -8'd77, -8'd109, -8'd73, -8'd33, -8'd111, -8'd115,
            8'd116, -8'd10, -8'd41, 8'd44, -8'd40, 8'd27, 8'd7, 8'd91, -8'd99,
            8'd90, -8'd9, -8'd15, -8'd32, 8'd78, 8'd112, -8'd99, -8'd57, -8'd39,
            8'd61, -8'd36, -8'd73, 8'd39, -8'd42, -8'd32, -8'd48, 8'd38, -8'd120,
            -8'd109, 8'd25, 8'd38, -8'd113, -8'd65, 8'd42, 8'd96, 8'd6, -8'd18,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd11, 8'd38, 8'd48, 8'd26, 8'd18, -8'd33, 8'd21, 8'd15, -8'd37,
            -8'd38, 8'd1, 8'd36, 8'd11, 8'd11, -8'd7, 8'd28, -8'd7, -8'd12,
            -8'd92, -8'd91, -8'd9, -8'd47, 8'd24, 8'd46, -8'd16, -8'd42, -8'd4,
            -8'd12, 8'd5, 8'd38, 8'd34, 8'd34, 8'd12, 8'd15, 8'd16, -8'd18,
            -8'd26, -8'd10, -8'd18, -8'd8, -8'd18, -8'd24, 8'd0, 8'd2, -8'd7,
            -8'd40, -8'd29, -8'd88, -8'd28, -8'd52, -8'd6, -8'd90, -8'd122, -8'd85,
            -8'd72, -8'd64, -8'd69, -8'd16, 8'd16, 8'd22, -8'd38, -8'd28, -8'd37,
            8'd11, 8'd21, -8'd24, 8'd6, -8'd4, 8'd22, -8'd25, 8'd3, -8'd23,
            -8'd36, -8'd15, 8'd60, -8'd20, 8'd30, 8'd0, -8'd11, -8'd29, 8'd4,
            -8'd3, 8'd25, 8'd5, 8'd23, 8'd11, -8'd11, 8'd24, -8'd13, -8'd27,
            8'd22, -8'd18, 8'd17, -8'd2, -8'd20, -8'd13, 8'd3, -8'd20, 8'd17,
            -8'd62, 8'd4, 8'd17, 8'd24, 8'd7, -8'd28, -8'd6, 8'd2, -8'd19,
            8'd74, 8'd69, -8'd59, -8'd43, -8'd103, 8'd37, -8'd105, 8'd5, -8'd27,
            8'd10, 8'd3, 8'd6, -8'd3, -8'd20, -8'd16, -8'd30, 8'd14, 8'd23,
            -8'd6, 8'd32, 8'd24, 8'd23, 8'd24, -8'd45, 8'd38, -8'd3, -8'd29,
            -8'd22, 8'd8, 8'd26, 8'd35, -8'd7, -8'd40, -8'd6, -8'd35, -8'd31,
            -8'd40, 8'd17, 8'd40, 8'd18, 8'd25, -8'd29, 8'd21, -8'd36, -8'd4,
            8'd8, 8'd72, 8'd71, 8'd106, 8'd127, 8'd73, 8'd40, -8'd6, 8'd42,
            -8'd16, -8'd24, 8'd28, -8'd7, 8'd22, 8'd3, 8'd11, 8'd5, -8'd17,
            8'd15, 8'd8, -8'd26, 8'd5, -8'd16, 8'd5, -8'd17, -8'd4, -8'd27,
            -8'd23, 8'd42, 8'd31, 8'd35, 8'd25, -8'd2, 8'd23, -8'd5, -8'd1,
            -8'd39, -8'd4, -8'd8, -8'd65, -8'd18, 8'd13, -8'd21, -8'd5, -8'd22,
            -8'd9, 8'd32, 8'd8, 8'd8, 8'd9, -8'd41, -8'd2, -8'd3, -8'd13,
            8'd5, 8'd62, 8'd47, 8'd19, 8'd17, -8'd38, 8'd42, -8'd23, -8'd11,
            -8'd35, -8'd3, -8'd19, 8'd9, -8'd15, -8'd32, -8'd7, 8'd23, -8'd59,
            8'd7, 8'd4, -8'd17, -8'd18, -8'd12, 8'd20, -8'd6, -8'd21, -8'd24,
            -8'd58, -8'd6, 8'd24, -8'd32, -8'd78, -8'd70, -8'd23, -8'd5, -8'd33,
            -8'd19, 8'd12, -8'd14, -8'd7, 8'd15, -8'd27, -8'd12, 8'd22, 8'd3,
            -8'd15, 8'd20, 8'd20, -8'd11, -8'd12, 8'd14, -8'd22, -8'd23, -8'd27,
            -8'd10, -8'd53, -8'd17, -8'd79, -8'd42, 8'd17, -8'd96, -8'd44, 8'd1,
            -8'd76, 8'd14, 8'd81, 8'd61, 8'd125, 8'd39, 8'd66, 8'd33, 8'd61,
            -8'd29, -8'd7, 8'd72, -8'd15, 8'd30, -8'd49, 8'd38, -8'd24, -8'd19,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd44, -8'd1, -8'd24, 8'd22, 8'd42, 8'd22, 8'd2, 8'd22, 8'd48,
            8'd15, -8'd52, -8'd40, -8'd9, 8'd17, -8'd10, 8'd5, 8'd1, 8'd7,
            -8'd4, -8'd21, -8'd18, -8'd15, -8'd52, -8'd11, -8'd47, -8'd69, -8'd41,
            -8'd25, -8'd14, -8'd45, -8'd13, -8'd12, 8'd10, 8'd17, 8'd32, -8'd15,
            -8'd10, -8'd12, 8'd24, 8'd10, -8'd21, 8'd9, 8'd11, 8'd24, -8'd19,
            -8'd31, 8'd5, -8'd9, -8'd37, -8'd38, 8'd4, -8'd62, -8'd75, -8'd34,
            8'd7, -8'd3, -8'd9, -8'd28, -8'd54, -8'd14, -8'd32, -8'd61, -8'd38,
            -8'd25, -8'd1, -8'd11, -8'd13, 8'd5, 8'd25, -8'd15, -8'd26, -8'd3,
            8'd5, -8'd34, 8'd19, 8'd29, -8'd11, -8'd1, 8'd33, 8'd48, 8'd1,
            -8'd2, -8'd68, -8'd63, -8'd6, 8'd19, -8'd40, 8'd34, 8'd19, 8'd19,
            -8'd9, 8'd19, -8'd27, 8'd12, -8'd10, -8'd26, -8'd11, 8'd15, -8'd10,
            -8'd9, -8'd35, -8'd60, 8'd37, -8'd12, -8'd27, 8'd12, 8'd24, -8'd11,
            8'd16, 8'd24, 8'd19, 8'd30, 8'd31, 8'd52, -8'd13, 8'd1, 8'd18,
            8'd2, 8'd26, 8'd11, 8'd6, 8'd28, -8'd15, -8'd2, -8'd7, 8'd18,
            -8'd2, -8'd17, -8'd65, 8'd35, -8'd22, 8'd14, -8'd10, 8'd27, 8'd33,
            -8'd13, -8'd16, -8'd69, 8'd16, 8'd30, 8'd0, 8'd29, 8'd40, 8'd17,
            -8'd11, -8'd10, -8'd63, 8'd13, 8'd0, -8'd17, 8'd10, -8'd9, 8'd16,
            8'd7, 8'd53, 8'd57, -8'd36, -8'd70, -8'd21, 8'd39, -8'd55, 8'd2,
            8'd13, 8'd9, 8'd2, -8'd22, 8'd20, -8'd11, 8'd26, -8'd25, 8'd13,
            -8'd15, 8'd13, 8'd23, 8'd26, -8'd23, -8'd24, 8'd6, -8'd16, 8'd24,
            -8'd24, -8'd24, -8'd64, -8'd8, 8'd11, -8'd36, 8'd25, -8'd18, 8'd16,
            8'd4, -8'd33, 8'd40, 8'd27, 8'd7, -8'd33, 8'd48, 8'd21, 8'd8,
            8'd30, 8'd10, -8'd57, 8'd17, 8'd16, 8'd27, -8'd5, 8'd24, 8'd60,
            8'd22, -8'd14, -8'd51, 8'd11, 8'd21, 8'd20, -8'd12, 8'd12, 8'd44,
            8'd13, 8'd4, -8'd55, 8'd38, 8'd29, -8'd15, 8'd9, 8'd13, 8'd13,
            8'd26, 8'd9, -8'd22, 8'd14, -8'd27, 8'd16, 8'd19, -8'd8, -8'd6,
            8'd20, -8'd41, -8'd38, 8'd53, 8'd65, -8'd73, 8'd40, 8'd127, 8'd16,
            8'd10, -8'd3, -8'd14, 8'd7, 8'd12, -8'd19, -8'd29, -8'd10, 8'd9,
            8'd12, 8'd18, 8'd18, 8'd3, 8'd11, -8'd25, -8'd16, 8'd19, -8'd15,
            -8'd16, -8'd2, 8'd26, 8'd22, -8'd29, 8'd14, 8'd30, 8'd58, 8'd8,
            8'd46, 8'd25, -8'd16, -8'd18, -8'd62, 8'd26, -8'd2, -8'd30, 8'd29,
            8'd30, -8'd54, -8'd36, 8'd58, 8'd2, -8'd61, 8'd46, 8'd55, 8'd36,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd88, 8'd77, -8'd20, -8'd29, 8'd1, -8'd21, -8'd14, -8'd37, 8'd45,
            8'd75, -8'd15, 8'd84, 8'd31, -8'd69, -8'd45, -8'd111, 8'd54, -8'd100,
            -8'd65, 8'd20, -8'd65, 8'd14, -8'd8, 8'd40, -8'd23, 8'd5, 8'd77,
            8'd76, 8'd90, 8'd83, -8'd81, 8'd93, -8'd88, 8'd60, 8'd47, -8'd98,
            8'd18, 8'd91, 8'd27, -8'd62, -8'd3, 8'd95, 8'd35, 8'd81, 8'd108,
            -8'd108, 8'd0, 8'd52, -8'd59, -8'd36, -8'd87, -8'd64, 8'd56, 8'd48,
            8'd46, -8'd60, -8'd19, 8'd2, 8'd24, -8'd71, 8'd26, 8'd43, 8'd47,
            -8'd65, 8'd58, 8'd24, -8'd39, 8'd53, 8'd49, 8'd34, -8'd5, 8'd65,
            -8'd96, -8'd41, 8'd6, -8'd85, -8'd12, 8'd84, -8'd58, 8'd36, 8'd19,
            -8'd34, 8'd86, -8'd39, -8'd1, -8'd38, 8'd73, -8'd101, -8'd87, 8'd21,
            8'd42, 8'd38, -8'd13, -8'd100, -8'd88, 8'd74, 8'd53, -8'd52, -8'd93,
            8'd25, -8'd70, -8'd22, -8'd94, 8'd56, -8'd15, 8'd28, -8'd122, -8'd92,
            -8'd34, -8'd76, -8'd103, -8'd29, -8'd40, -8'd18, 8'd43, 8'd18, -8'd32,
            -8'd37, -8'd85, 8'd69, 8'd15, 8'd100, 8'd38, -8'd94, -8'd50, -8'd85,
            8'd73, 8'd1, -8'd60, 8'd19, 8'd80, 8'd12, -8'd68, -8'd5, 8'd60,
            -8'd89, -8'd127, 8'd65, -8'd97, -8'd33, -8'd41, -8'd6, -8'd27, -8'd126,
            -8'd59, 8'd0, -8'd26, -8'd4, -8'd23, -8'd97, 8'd59, -8'd37, -8'd44,
            -8'd81, -8'd46, 8'd69, -8'd47, 8'd5, 8'd54, -8'd29, -8'd30, 8'd106,
            8'd56, 8'd59, -8'd73, 8'd104, 8'd47, 8'd94, 8'd16, -8'd83, 8'd32,
            8'd93, 8'd42, 8'd79, 8'd85, -8'd15, -8'd25, 8'd5, 8'd57, -8'd95,
            8'd8, -8'd52, -8'd37, 8'd73, 8'd64, -8'd45, 8'd25, -8'd70, 8'd54,
            -8'd23, 8'd38, -8'd95, -8'd121, 8'd44, 8'd61, -8'd29, -8'd81, 8'd84,
            -8'd14, -8'd56, -8'd66, -8'd109, 8'd28, -8'd46, -8'd89, -8'd37, 8'd49,
            -8'd62, 8'd57, -8'd34, 8'd33, -8'd18, -8'd124, -8'd17, 8'd1, -8'd81,
            -8'd11, -8'd18, -8'd101, -8'd52, 8'd50, -8'd54, -8'd36, 8'd6, 8'd33,
            -8'd37, 8'd8, -8'd71, 8'd83, -8'd82, 8'd9, 8'd105, 8'd66, -8'd108,
            8'd52, -8'd118, -8'd89, -8'd70, -8'd37, -8'd10, -8'd105, 8'd73, -8'd103,
            -8'd77, -8'd33, 8'd54, 8'd41, -8'd31, -8'd57, 8'd94, 8'd25, -8'd89,
            8'd18, 8'd32, 8'd64, 8'd45, 8'd108, -8'd34, 8'd10, 8'd98, 8'd101,
            8'd54, 8'd0, 8'd50, 8'd65, -8'd22, 8'd32, 8'd27, -8'd90, -8'd56,
            -8'd51, 8'd39, -8'd77, -8'd7, 8'd34, 8'd20, 8'd59, -8'd84, -8'd2,
            -8'd111, 8'd23, -8'd87, -8'd122, 8'd56, 8'd41, -8'd85, -8'd37, 8'd76,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd31, 8'd11, -8'd28, -8'd36, -8'd12, -8'd1, 8'd5, -8'd40, 8'd7,
            -8'd19, 8'd24, 8'd28, -8'd6, 8'd0, -8'd3, -8'd60, -8'd3, 8'd37,
            8'd14, -8'd13, 8'd69, 8'd28, -8'd26, -8'd5, -8'd2, 8'd0, -8'd81,
            8'd28, 8'd31, 8'd1, -8'd26, -8'd5, 8'd15, -8'd9, 8'd17, 8'd2,
            -8'd8, 8'd13, 8'd18, -8'd12, 8'd20, 8'd0, 8'd10, -8'd4, 8'd14,
            -8'd5, -8'd35, -8'd60, -8'd18, -8'd24, -8'd108, -8'd22, -8'd6, -8'd92,
            -8'd38, -8'd47, -8'd34, 8'd35, -8'd16, -8'd24, -8'd18, 8'd6, -8'd64,
            -8'd16, 8'd17, 8'd14, 8'd28, 8'd16, -8'd1, -8'd27, -8'd25, -8'd23,
            8'd12, -8'd24, 8'd43, 8'd4, -8'd10, 8'd0, 8'd29, 8'd14, -8'd11,
            8'd11, 8'd33, -8'd10, -8'd8, 8'd1, 8'd13, -8'd28, 8'd20, 8'd13,
            -8'd26, -8'd23, -8'd26, 8'd0, -8'd8, 8'd21, -8'd26, -8'd18, 8'd13,
            -8'd7, -8'd4, -8'd21, -8'd21, 8'd42, 8'd21, -8'd42, -8'd33, 8'd33,
            -8'd8, -8'd32, 8'd6, 8'd41, -8'd64, 8'd23, 8'd54, -8'd26, -8'd38,
            8'd16, 8'd2, -8'd30, -8'd16, -8'd5, -8'd13, 8'd15, 8'd10, 8'd2,
            -8'd18, -8'd11, -8'd23, 8'd3, 8'd5, -8'd33, -8'd54, -8'd8, 8'd36,
            8'd17, 8'd15, 8'd22, -8'd22, -8'd2, 8'd4, -8'd60, -8'd30, 8'd28,
            8'd14, 8'd35, 8'd28, -8'd35, -8'd23, 8'd9, -8'd50, 8'd20, 8'd42,
            8'd77, -8'd44, 8'd69, 8'd54, 8'd52, -8'd73, 8'd64, -8'd48, -8'd127,
            -8'd30, 8'd13, 8'd9, -8'd30, 8'd4, -8'd11, 8'd25, 8'd12, 8'd29,
            -8'd10, 8'd21, -8'd29, 8'd7, -8'd11, -8'd2, 8'd18, 8'd26, 8'd16,
            -8'd6, 8'd14, 8'd17, -8'd42, 8'd9, -8'd43, -8'd25, -8'd53, 8'd6,
            8'd14, 8'd50, 8'd25, 8'd11, 8'd19, -8'd47, 8'd7, 8'd51, 8'd35,
            -8'd11, 8'd31, 8'd30, -8'd37, 8'd19, 8'd61, -8'd24, -8'd58, 8'd40,
            -8'd25, -8'd10, -8'd14, -8'd32, 8'd10, -8'd14, -8'd23, -8'd18, -8'd5,
            -8'd26, 8'd32, 8'd6, -8'd18, 8'd32, 8'd1, -8'd52, -8'd37, 8'd29,
            8'd3, -8'd29, 8'd4, -8'd27, -8'd8, 8'd20, 8'd17, 8'd12, 8'd4,
            8'd26, 8'd91, 8'd50, -8'd37, 8'd86, 8'd101, -8'd37, 8'd13, 8'd127,
            -8'd16, 8'd1, 8'd32, 8'd24, -8'd14, 8'd9, -8'd24, -8'd25, -8'd1,
            8'd9, -8'd8, -8'd18, 8'd4, -8'd19, -8'd3, 8'd27, -8'd24, -8'd18,
            8'd63, -8'd21, -8'd20, -8'd10, -8'd11, -8'd46, 8'd6, 8'd55, 8'd37,
            8'd37, 8'd32, 8'd107, 8'd9, -8'd19, 8'd38, -8'd39, -8'd57, -8'd9,
            8'd52, 8'd33, -8'd12, -8'd10, 8'd17, -8'd21, 8'd11, 8'd62, 8'd59, 
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0
        };

 
        for (i = 0; i < KER_SIZE; i = i + 4) begin
            ram.mem[1500 + (i / 4)][ 7: 0] = filter_data[8*(KER_SIZE - 1 - i) +: 8];
            ram.mem[1500 + (i / 4)][15: 8] = filter_data[8*(KER_SIZE - 2 - i) +: 8];
            ram.mem[1500 + (i / 4)][23:16] = filter_data[8*(KER_SIZE - 3 - i) +: 8];
            ram.mem[1500 + (i / 4)][31:24] = filter_data[8*(KER_SIZE - 4 - i) +: 8];
        end

        // $display("KERNEL RESULT");
        // for (int i = 1500; i < 1500 + KER_SIZE/4; i = i + 1) begin
        //     $display("%d %d %d %d", 
        //         $signed(ram.mem[i][ 7: 0]), 
        //         $signed(ram.mem[i][15: 8]), 
        //         $signed(ram.mem[i][23:16]), 
        //         $signed(ram.mem[i][31:24])
        //     ); 
        // end
        // $display("*************");
        // Bias
        bias_data = {
            -32'd28517, 32'd2966, 32'd5775, 32'd5654, -32'd11145, 32'd7002, 32'd8439, -32'd9378, 32'd8529, -32'd489, -32'd38044, -32'd34300, 32'd4925, -32'd28784, -32'd1970, 32'd60, -32'd8178, -32'd26840, -32'd28935, -32'd31502, -32'd10251, 32'd6148, -32'd3370, -32'd8798, 32'd7343, -32'd44597, -32'd6740, -32'd31376, -32'd15323, 32'd3003, -32'd31031, -32'd2781
        };

        for (i = 0; i < BIS_SIZE; i = i + 1) begin
            ram.mem[1400 + i] = bias_data[32*(BIS_SIZE - 1 - i) +: 32];
        end

    end
/*******************/

`elsif CL_TC7
/* Test case 7 */
     /* 
        Description:
           - Input Feature Map's size : 28 x 28 x 3     => 2352
           - Kernel's size            : 3 x 3 x 3 x 32 => 864
           - Output Feature Map's size: 26 x 26 x 32     => 21632
           - Bias's size              : 32         =>  3872
    */
    localparam 
        IFM_SIZE = 28 * 28 * 3,
        KER_SIZE = 3 * 3 * 3 * 32,
        OFM_SIZE = 13 * 13 * 32,
        BIS_SIZE = 32,
        PAS_SIZE = 5 * 5 * 6,
        OUTPUT_HEIGHT = 26,
        OUTPUT_WIDTH = 26,
        OUTPUT_DEPTH = 32;

    initial begin
        al_accel_mem_read_ready    = 1'b 1;
        al_accel_mem_write_ready   = 1'b 1;
    end

    initial begin
        al_accel_cfgreg_di   = 32'd 0; al_accel_cfgreg_sel = 5'd 0; 
        al_accel_cfgreg_wenb =  1'd 0;
        al_accel_flow_enb    =  1'b 0;
        #42
        al_accel_cfgreg_wenb =  1'd 1;
    // Config Data
        #10 // i_base_addr
        al_accel_cfgreg_di   = 32'd 0000;       al_accel_cfgreg_sel = 5'd 0; 

        #10 // kw_base_addr
        al_accel_cfgreg_di   = 32'd 6000;       al_accel_cfgreg_sel = 5'd 1; 

        #10 // o_base_addr
        al_accel_cfgreg_di   = 32'd 16000;       al_accel_cfgreg_sel = 5'd 2; 

        #10 // b_base_addr
        al_accel_cfgreg_di   = 32'd 5600;       al_accel_cfgreg_sel = 5'd 3; 

        #10 // ps_base_addr
        al_accel_cfgreg_di   = 32'd 20000;       al_accel_cfgreg_sel = 5'd 4; 

        #10 // {stride_height, stride_width, cfg_act_func_typ, cfg_layer_typ}
        al_accel_cfgreg_di   = {16'd 0, 4'd 1, 4'd 1, RELU, CONV}; al_accel_cfgreg_sel = 5'd 5; 

        #10 // {weight_kernel_patch_height, weight_kernel_patch_width}
        al_accel_cfgreg_di   = {16'd 3, 16'd 3}; al_accel_cfgreg_sel = 5'd 6; 

        #10 // {nok_ofm_depth, kernel_ifm_depth} 
        al_accel_cfgreg_di   = {16'd 32, 16'd 3}; al_accel_cfgreg_sel = 5'd 7;
        
        #10 // {ifm_height, ifm_width}  
        al_accel_cfgreg_di   = {16'd 28, 16'd 28}; al_accel_cfgreg_sel = 5'd 8;

        #10 // {ofm_height, ofm_width}
        al_accel_cfgreg_di   = {16'd 26, 16'd 26}; al_accel_cfgreg_sel = 5'd 9;

        #10 // {output2D_size, input2D_size}  
        al_accel_cfgreg_di   = {16'd 676, 16'd 784}; al_accel_cfgreg_sel = 5'd 10;

        #10 // kernel3D_size
        al_accel_cfgreg_di   = {16'd  0, 16'd 27}; al_accel_cfgreg_sel = 5'd 11;

        // Output Quantize Buffer
        #10 // output_quant_sel 0
        al_accel_cfgreg_di   = {24'd 0, 8'd 0} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 2006707479 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 9} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 1
        al_accel_cfgreg_di   = {24'd 0, 8'd 1} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1433835724 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 9} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 2
        al_accel_cfgreg_di   = {24'd 0, 8'd 2} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1192390444 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 8} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 3
        al_accel_cfgreg_di   = {24'd 0, 8'd 3} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1361289408 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 9} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 4
        al_accel_cfgreg_di   = {24'd 0, 8'd 4} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1285031363 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 10} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 5
        al_accel_cfgreg_di   = {24'd 0, 8'd 5} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 2063009507 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 9} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 6
        al_accel_cfgreg_di   = {24'd 0, 8'd 6} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 2143833947 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 9} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 7
        al_accel_cfgreg_di   = {24'd 0, 8'd 7} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 2040046477 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 11} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 8
        al_accel_cfgreg_di   = {24'd 0, 8'd 8} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1117137979 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 8} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 9
        al_accel_cfgreg_di   = {24'd 0, 8'd 9} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1529727281 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 9} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 10
        al_accel_cfgreg_di   = {24'd 0, 8'd 10} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1118076866 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 10} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 11
        al_accel_cfgreg_di   = {24'd 0, 8'd 11} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1909265169 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 9} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 12
        al_accel_cfgreg_di   = {24'd 0, 8'd 12} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1213134709 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 8} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 13
        al_accel_cfgreg_di   = {24'd 0, 8'd 13} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1219315125 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 10} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 14
        al_accel_cfgreg_di   = {24'd 0, 8'd 14} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1693522756 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 9} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 15
        al_accel_cfgreg_di   = {24'd 0, 8'd 15} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1244537046 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 9} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 16
        al_accel_cfgreg_di   = {24'd 0, 8'd 16} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1439731708 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 9} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 17
        al_accel_cfgreg_di   = {24'd 0, 8'd 17} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1469553438 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 8} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 18
        al_accel_cfgreg_di   = {24'd 0, 8'd 18} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1858048416 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 11} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 19
        al_accel_cfgreg_di   = {24'd 0, 8'd 19} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1955939902 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 11} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 20
        al_accel_cfgreg_di   = {24'd 0, 8'd 20} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1424595433 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 9} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 21
        al_accel_cfgreg_di   = {24'd 0, 8'd 21} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1295986055 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 8} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 22
        al_accel_cfgreg_di   = {24'd 0, 8'd 22} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1959811992 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 9} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 23
        al_accel_cfgreg_di   = {24'd 0, 8'd 23} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1607690141 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 9} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 24
        al_accel_cfgreg_di   = {24'd 0, 8'd 24} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1265787593 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 9} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 25
        al_accel_cfgreg_di   = {24'd 0, 8'd 25} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1154422605 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 10} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 26
        al_accel_cfgreg_di   = {24'd 0, 8'd 26} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1891572973 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 9} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 27
        al_accel_cfgreg_di   = {24'd 0, 8'd 27} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1267784783 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 10} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 28
        al_accel_cfgreg_di   = {24'd 0, 8'd 28} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1192481101 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 10} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 29
        al_accel_cfgreg_di   = {24'd 0, 8'd 29} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1139166983 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 8} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 30
        al_accel_cfgreg_di   = {24'd 0, 8'd 30} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1242432765 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 8} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 31
        al_accel_cfgreg_di   = {24'd 0, 8'd 31} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 2027832722 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 9} ; al_accel_cfgreg_sel = 5'd 14;

    // Data Offset
        #10 // input_offset
        al_accel_cfgreg_di   = 32'd 128; al_accel_cfgreg_sel = 5'd 15;
        #10 // output_offset
        al_accel_cfgreg_di   = 32'd 128; al_accel_cfgreg_sel = 5'd 16;
        
        #10 // {ofm_pool_height,  ofm_pool_width}
        al_accel_cfgreg_di   = {16'd 0, 16'd 0}; al_accel_cfgreg_sel = 5'd 17;
        #10 // output2D_pool_size
        al_accel_cfgreg_di   = 32'd 0; al_accel_cfgreg_sel = 5'd 18;
        

    // Flow Run
        #10
        al_accel_cfgreg_wenb =  1'd 0;
        #10 
        al_accel_flow_enb    =  1'd 1;
        // #1000
        // al_accel_flow_enb    =  1'd 0;
        // #200
        al_accel_flow_enb    =  1'd 1;
		// repeat (2000) @(posedge clk) begin
        //     #2 al_accel_flow_enb = $random;
        // end
        // #10 
        al_accel_flow_enb    =  1'd 1;
    end

    reg [IFM_SIZE    * 8 - 1:0] input_data ; // Size: 28 x 28 x 3
    reg [KER_SIZE * 8 - 1:0] filter_data; // Size: 3 x 3 x 3 x 6
    reg [ BIS_SIZE  * 32              - 1:0] bias_data  ; // Size: 6
    integer i;
    initial begin
        for (i = 0; i < 32768; i = i + 1)
            ram.mem[i] = 32'd 0;

        // Input Initilization
        input_data = {
            /* z = 0 */
            -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 
            -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 
            -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 
            -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 
            -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 
            -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 
            -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 
            -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd44, 8'd56, 8'd30, 8'd22, -8'd68, -8'd92, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 
            -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 8'd93, 8'd125, 8'd125, 8'd125, 8'd125, 8'd112, 8'd69, 8'd69, 8'd69, 8'd69, 8'd69, 8'd69, 8'd69, 8'd69, 8'd41, -8'd76, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 
            -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd61, -8'd14, -8'd56, -8'd14, 8'd34, 8'd98, 8'd125, 8'd96, 8'd125, 8'd125, 8'd125, 8'd121, 8'd100, 8'd125, 8'd125, 8'd11, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 
            -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd111, -8'd62, -8'd114, -8'd61, -8'd61, -8'd61, -8'd69, -8'd107, 8'd107, 8'd125, -8'd22, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 
            -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd45, 8'd124, 8'd80, -8'd110, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 
            -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd106, 8'd104, 8'd126, -8'd45, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 
            -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 8'd0, 8'd125, 8'd109, -8'd84, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 
            -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd69, 8'd120, 8'd125, -8'd66, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 
            -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 8'd4, 8'd125, 8'd58, -8'd123, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 
            -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd119, 8'd76, 8'd119, -8'd70, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 
            -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd2, 8'd125, 8'd53, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 
            -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd53, 8'd122, 8'd111, -8'd71, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 
            -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd109, 8'd92, 8'd125, 8'd37, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 
            -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd125, 8'd74, 8'd125, 8'd90, -8'd93, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 
            -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd90, 8'd125, 8'd125, -8'd51, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 
            -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd97, 8'd95, 8'd125, -8'd13, -8'd127, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 
            -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 8'd4, 8'd125, 8'd125, -8'd76, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 
            -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd67, 8'd113, 8'd125, 8'd125, -8'd76, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 
            -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd7, 8'd125, 8'd125, 8'd90, -8'd88, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 
            -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd7, 8'd125, 8'd78, -8'd110, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 
            -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
            12544'd0
        };


        for (i = 0; i < IFM_SIZE; i = i + 4) begin
            ram.mem[0 + (i / 4)][ 7: 0] = input_data[8*(IFM_SIZE - 1 - i) +: 8];
            ram.mem[0 + (i / 4)][15: 8] = input_data[8*(IFM_SIZE - 2 - i) +: 8];
            ram.mem[0 + (i / 4)][23:16] = input_data[8*(IFM_SIZE - 3 - i) +: 8];
            ram.mem[0 + (i / 4)][31:24] = input_data[8*(IFM_SIZE - 4 - i) +: 8];
        end

        // $display("INPUT RESULT");
        // for (int i = 0; i < 0 + (28 * 28 * 3) / 4; i = i + 1) begin
        //     $display("%d %d %d %d", 
        //         $signed(ram.mem[i][ 7: 0]), 
        //         $signed(ram.mem[i][15: 8]), 
        //         $signed(ram.mem[i][23:16]), 
        //         $signed(ram.mem[i][31:24])
        //     ); 
        // end
        // $display("*************");
        

        // Kernel 
        filter_data = {
           -8'd72, -8'd127, -8'd17, 8'd90, 8'd41, 8'd67, 8'd102, 8'd103, 8'd67,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd78, 8'd73, 8'd66, 8'd31, 8'd108, 8'd46, 8'd0, 8'd4, 8'd127,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd93, 8'd15, -8'd83, 8'd68, -8'd26, -8'd102, 8'd24, -8'd127, -8'd85,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd65, 8'd78, 8'd95, 8'd110, 8'd70, 8'd61, 8'd127, 8'd20, -8'd107,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd26, 8'd9, -8'd41, 8'd17, 8'd0, -8'd125, 8'd44, -8'd127, -8'd62,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd27, -8'd24, -8'd127, -8'd73, -8'd111, -8'd9, -8'd114, -8'd5, 8'd24,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd106, -8'd47, -8'd127, 8'd11, -8'd96, -8'd37, -8'd22, -8'd126, -8'd1,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd99, 8'd37, 8'd65, 8'd76, -8'd127, 8'd0, 8'd49, 8'd0, -8'd87,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd52, 8'd69, 8'd63, 8'd42, 8'd70, 8'd32, -8'd57, -8'd127, -8'd88,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd62, 8'd127, 8'd65, -8'd26, 8'd114, 8'd83, 8'd32, 8'd38, 8'd113,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd109, -8'd66, 8'd18, -8'd52, 8'd95, 8'd65, -8'd113, 8'd15, -8'd127,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd40, 8'd127, 8'd51, 8'd19, 8'd89, 8'd93, -8'd12, 8'd98, 8'd62,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd34, -8'd54, -8'd92, -8'd60, -8'd96, -8'd35, 8'd109, 8'd127, 8'd101,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd87, 8'd82, 8'd38, -8'd68, -8'd29, 8'd42, 8'd10, -8'd127, 8'd31,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd15, 8'd85, 8'd58, 8'd42, 8'd83, 8'd66, 8'd127, 8'd79, 8'd23,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd38, 8'd47, 8'd84, 8'd83, 8'd59, 8'd127, -8'd15, 8'd122, 8'd115,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd23, 8'd40, 8'd104, 8'd34, 8'd125, 8'd59, 8'd7, 8'd127, 8'd28,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd127, -8'd42, 8'd61, -8'd32, 8'd81, 8'd50, 8'd53, 8'd70, -8'd71,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd102, 8'd43, -8'd127, -8'd8, 8'd55, 8'd59, -8'd73, -8'd114, -8'd125,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd117, -8'd20, 8'd35, -8'd105, 8'd84, -8'd124, 8'd1, 8'd8, 8'd127,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd25, 8'd99, 8'd98, 8'd53, 8'd83, 8'd89, 8'd127, 8'd108, 8'd31,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd81, 8'd27, 8'd69, -8'd28, -8'd25, 8'd78, -8'd106, -8'd127, -8'd26,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd28, -8'd10, -8'd126, 8'd36, 8'd105, -8'd9, 8'd61, 8'd127, 8'd53,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd97, -8'd107, 8'd18, 8'd34, 8'd102, 8'd49, 8'd125, 8'd115, 8'd127,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd94, 8'd28, 8'd14, 8'd83, 8'd43, 8'd58, 8'd52, 8'd11, 8'd127,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd124, -8'd26, -8'd88, 8'd81, -8'd127, 8'd70, 8'd45, -8'd125, -8'd14,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd7, 8'd113, 8'd37, -8'd127, 8'd90, 8'd66, -8'd118, -8'd31, 8'd111,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd100, 8'd89, -8'd100, 8'd119, 8'd7, 8'd21, -8'd117, -8'd57, -8'd127,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd127, -8'd77, 8'd21, 8'd74, -8'd124, -8'd106, -8'd42, 8'd56, -8'd81,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd88, 8'd118, 8'd106, -8'd89, -8'd2, -8'd4, -8'd71, -8'd127, -8'd68,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd25, 8'd90, -8'd16, 8'd82, 8'd49, -8'd119, 8'd95, 8'd10, -8'd127,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd9, 8'd15, 8'd97, 8'd76, 8'd44, 8'd127, -8'd79, -8'd73, 8'd39,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0
        };
        
 
        for (i = 0; i < KER_SIZE; i = i + 4) begin
            ram.mem[1500 + (i / 4)][ 7: 0] = filter_data[8*(KER_SIZE - 1 - i) +: 8];
            ram.mem[1500 + (i / 4)][15: 8] = filter_data[8*(KER_SIZE - 2 - i) +: 8];
            ram.mem[1500 + (i / 4)][23:16] = filter_data[8*(KER_SIZE- 3 - i) +: 8];
            ram.mem[1500 + (i / 4)][31:24] = filter_data[8*(KER_SIZE - 4 - i) +: 8];
        end

        // Bias
        bias_data = {
            32'd32, -32'd959, 32'd13568, -32'd1270, -32'd17005, 32'd26575, 32'd19294, -32'd54577, 32'd7416, -32'd304, -32'd59788, 32'd241, 32'd10772, -32'd49339, -32'd639, -32'd430, -32'd459, -32'd5451, -32'd55838, -32'd64084, -32'd2100, 32'd14497, -32'd714, -32'd189, 32'd1789, -32'd68024, -32'd6961, -32'd46619, -32'd69764, 32'd12967, -32'd5197, 32'd49
        };

        for (i = 0; i < BIS_SIZE; i = i + 1) begin
            ram.mem[1400 + i] = bias_data[32*(BIS_SIZE - 1 - i) +: 32];
        end
    end
/*******************/
`endif 


// ===============================================================================================================================
// ==================================================== FULLY CONNECTED LAYER ====================================================
// ===============================================================================================================================

`ifdef FCL_TC0
/* Test case 0 */
    /* 
        Description:
            - Input Feature Map's size : 27 x 1 =>  27
            - Kernel's size            : 27 x 9 => 243
            - Output Feature Map's size:  9 x 1 =>   9
            - Bias's size              :  9 x 4 =>  36
            - Partial-Sum's size       :  9 x 4 =>  36
    */

    localparam 
        IFM_SIZE = 27 * 1 + 1,
        KER_SIZE = 27 * 9 + 1,
        OFM_SIZE =  9 * 1 + 3,
        BIS_SIZE =  9,
        PAS_SIZE =  9,
        OUTPUT_HEIGHT = 1,
        OUTPUT_WIDTH = 9,
        OUTPUT_DEPTH = 1;

    initial begin
        // al_accel_mem_read_ready = 1'b 0;
        // al_accel_mem_write_ready = 1'b 0;
        // #10
        // repeat (2000) @(posedge clk) begin
        //     #2 al_accel_mem_read_ready = $random;
        // end
        // #10 
        al_accel_mem_read_ready    = 1'b 1;
        al_accel_mem_write_ready   = 1'b 1;
    end

    initial begin
        al_accel_cfgreg_di   = 32'd 0;       al_accel_cfgreg_sel = 5'd 0; 
        al_accel_cfgreg_wenb =  1'd 0;
        al_accel_flow_enb    =  1'b 0;
        #42
        al_accel_cfgreg_wenb =  1'd 1;
    // Config Data
        #10 // i_base_addr
        al_accel_cfgreg_di   = 32'd 0000;       al_accel_cfgreg_sel = 5'd 0; 

        #10 // kw_base_addr
        al_accel_cfgreg_di   = 32'd 6000;       al_accel_cfgreg_sel = 5'd 1; 

        #10 // o_base_addr
        al_accel_cfgreg_di   = 32'd 16000;       al_accel_cfgreg_sel = 5'd 2; 

        #10 // b_base_addr
        al_accel_cfgreg_di   = 32'd 5600;       al_accel_cfgreg_sel = 5'd 3; 

        #10 // ps_base_addr
        al_accel_cfgreg_di   = 32'd 20000;       al_accel_cfgreg_sel = 5'd 4;

        #10 // {stride_height, stride_width, cfg_act_func_typ, cfg_layer_typ}
        al_accel_cfgreg_di   = {16'd 0, 4'd 0, 4'd 0, NO_FUNC, DENSE}; al_accel_cfgreg_sel = 5'd 5; 

        #10 // {weight_kernel_patch_height, weight_kernel_patch_width}
        al_accel_cfgreg_di   = {16'd 9, 16'd 27}; al_accel_cfgreg_sel = 5'd 6; 

        #10 // {nok_ofm_depth, kernel_ifm_depth} 
        al_accel_cfgreg_di   = 32'd 0; al_accel_cfgreg_sel = 5'd 7;

        #10 // {ifm_height, ifm_width}  
        al_accel_cfgreg_di   = {16'd 1, 16'd 27}; al_accel_cfgreg_sel = 5'd 8;

        #10 // {ofm_height, ofm_width}
        al_accel_cfgreg_di   = {16'd 1, 16'd  9}; al_accel_cfgreg_sel = 5'd 9;

        #10 // {output2D_size, input2D_size}  
        al_accel_cfgreg_di   = {16'd  9, 16'd 27} ; al_accel_cfgreg_sel = 5'd 10;

        #10 // kernel3D_size 
        al_accel_cfgreg_di   = {16'd  0, 16'd 243}; al_accel_cfgreg_sel = 5'd 11;

    // Output Quantize Buffer
        #10 // output_quant_sel
        al_accel_cfgreg_di   = {24'd 0, 8'd 0} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 2039693188 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 8} ; al_accel_cfgreg_sel = 5'd 14;

    // Data Offset
        #10 // input_offset
        al_accel_cfgreg_di   = 32'd 11238; al_accel_cfgreg_sel = 5'd 15;
        #10 // output_offset
        al_accel_cfgreg_di   = 32'd  1236; al_accel_cfgreg_sel = 5'd 16;

    // Flow Run
        #10 
        al_accel_cfgreg_wenb =  1'd 0;
        #10 
        al_accel_flow_enb    =  1'd 1;
        #1000
        al_accel_flow_enb    =  1'd 0;
        #200
        al_accel_flow_enb    =  1'd 1;
		repeat (2000) @(posedge clk) begin
            #2 al_accel_flow_enb = $random;
        end
        #10 
        al_accel_flow_enb    =  1'd 1;
    end

    reg [IFM_SIZE *  8 - 1:0]  input_data ; // Size: 7 x 7 x 9
    reg [KER_SIZE *  8 - 1:0]  filter_data; // Size: 3 x 3 x 9 x 9
    reg [BIS_SIZE * 32 - 1:0]  bias_data  ; // Size: 9
    integer i;
    initial begin
        for (i = 0; i < 4096; i = i + 1)
            ram.mem[i] = 32'd 0;

        // Input Initilization
        input_data = {
            8'd   1, 8'd   2,-8'd   3,-8'd   4,-8'd   5,-8'd   6,-8'd   7,-8'd   8, 8'd  90,
            8'd  20, 8'd  25, 8'd  42, 8'd  32, 8'd  12, 8'd  66,-8'd 128, 8'd 127, 8'd  34,
            8'd  11, 8'd  22,-8'd  33, 8'd  44,-8'd  55, 8'd  66,-8'd  77, 8'd  88,-8'd  99,
        // Padding
            8'd   0
        };
        for (i = 0; i < (IFM_SIZE); i = i + 4) begin
            ram.mem[0 + (i / 4)][ 7: 0] = input_data[8*((IFM_SIZE) - 1 - i) +: 8];
            ram.mem[0 + (i / 4)][15: 8] = input_data[8*((IFM_SIZE) - 2 - i) +: 8];
            ram.mem[0 + (i / 4)][23:16] = input_data[8*((IFM_SIZE) - 3 - i) +: 8];
            ram.mem[0 + (i / 4)][31:24] = input_data[8*((IFM_SIZE) - 4 - i) +: 8];
        end

        // Kernel 
        filter_data = {
            8'd   2, 8'd   3, 8'd  43, 8'd  56, 8'd  11, 8'd  22,-8'd 128, 8'd  79, 8'd  27,
            8'd   2, 8'd   3, 8'd  43, 8'd  56, 8'd  11, 8'd  22,-8'd 128, 8'd  79, 8'd  27,
            8'd   2, 8'd   3, 8'd  43, 8'd  56, 8'd  11, 8'd  22,-8'd 128, 8'd  79, 8'd  27,
            8'd   4, 8'd  28, 8'd  74, 8'd  66, 8'd  43, 8'd 111,-8'd 110, 8'd  19, 8'd  81,
            8'd   4, 8'd  28, 8'd  74, 8'd  66, 8'd  43, 8'd 111,-8'd 110, 8'd  19, 8'd  81,
            8'd   4, 8'd  28, 8'd  74, 8'd  66, 8'd  43, 8'd 111,-8'd 110, 8'd  19, 8'd  81,
            8'd  90, 8'd  42, 8'd  64, 8'd  19, 8'd   1, 8'd   2, 8'd   3, 8'd   4, 8'd   5,
            8'd  90, 8'd  42, 8'd  64, 8'd  19, 8'd   1, 8'd   2, 8'd   3, 8'd   4, 8'd   5,
            8'd  90, 8'd  42, 8'd  64, 8'd  19, 8'd   1, 8'd   2, 8'd   3, 8'd   4, 8'd   5,
            8'd  98, 8'd  32, 8'd  17, 8'd  89, 8'd   1,-8'd   2, 8'd   3, 8'd   4, 8'd   5,
            8'd  98, 8'd  32, 8'd  17, 8'd  89, 8'd   1,-8'd   2, 8'd   3, 8'd   4, 8'd   5,
            8'd  98, 8'd  32, 8'd  17, 8'd  89, 8'd   1,-8'd   2, 8'd   3, 8'd   4, 8'd   5,
            8'd   6, 8'd  23, 8'd  65, 8'd  76, 8'd   1, 8'd   2,-8'd   3, 8'd   4, 8'd   5,
            8'd   6, 8'd  23, 8'd  65, 8'd  76, 8'd   1, 8'd   2,-8'd   3, 8'd   4, 8'd   5,
            8'd   6, 8'd  23, 8'd  65, 8'd  76, 8'd   1, 8'd   2,-8'd   3, 8'd   4, 8'd   5,
            8'd  43, 8'd   4,-8'd   1,-8'd  89, 8'd   1, 8'd   2, 8'd   3,-8'd   4, 8'd   5,
            8'd  43, 8'd   4,-8'd   1,-8'd  89, 8'd   1, 8'd   2, 8'd   3,-8'd   4, 8'd   5,
            8'd  43, 8'd   4,-8'd   1,-8'd  89, 8'd   1, 8'd   2, 8'd   3,-8'd   4, 8'd   5,
           -8'd  30, 8'd   6,-8'd  45, 8'd  89, 8'd   1, 8'd   2, 8'd   3, 8'd   4,-8'd   5,
           -8'd  30, 8'd   6,-8'd  45, 8'd  89, 8'd   1, 8'd   2, 8'd   3, 8'd   4,-8'd   5,
           -8'd  30, 8'd   6,-8'd  45, 8'd  89, 8'd   1, 8'd   2, 8'd   3, 8'd   4,-8'd   5,
            8'd  43, 8'd   4,-8'd   1,-8'd  89, 8'd   1, 8'd   2, 8'd   3,-8'd   4, 8'd   5,
            8'd  43, 8'd   4,-8'd   1,-8'd  89, 8'd   1, 8'd   2, 8'd   3,-8'd   4, 8'd   5,
            8'd  43, 8'd   4,-8'd   1,-8'd  89, 8'd   1, 8'd   2, 8'd   3,-8'd   4, 8'd   5,
           -8'd  30, 8'd   6,-8'd  45, 8'd  89, 8'd   1, 8'd   2, 8'd   3, 8'd   4,-8'd   5,
           -8'd  30, 8'd   6,-8'd  45, 8'd  89, 8'd   1, 8'd   2, 8'd   3, 8'd   4,-8'd   5,
           -8'd  30, 8'd   6,-8'd  45, 8'd  89, 8'd   1, 8'd   2, 8'd   3, 8'd   4,-8'd   5,
        // Padding
            8'd   0
        }; 

        for (i = 0; i < KER_SIZE; i = i + 4) begin
            ram.mem[1500 + (i / 4)][ 7: 0] = filter_data[8*(KER_SIZE - 1 - i) +: 8];
            ram.mem[1500 + (i / 4)][15: 8] = filter_data[8*(KER_SIZE - 2 - i) +: 8];
            ram.mem[1500 + (i / 4)][23:16] = filter_data[8*(KER_SIZE - 3 - i) +: 8];
            ram.mem[1500 + (i / 4)][31:24] = filter_data[8*(KER_SIZE - 4 - i) +: 8];
        end

        // Bias
        bias_data = {
            32'd   1, 
            32'd  43, 
            32'd  87, 
            32'd 119,
            32'd  46, 
            32'd  67,
            32'd 100, 
            32'd  23, 
           -32'd  24
        };
        for (i = 0; i < BIS_SIZE; i = i + 1) begin
            ram.mem[1400 + i] = bias_data[32*(BIS_SIZE - 1 - i) +: 32];
        end

    end
/*******************/
`elsif FCL_TC1
/* Test case 1 */
    /* 
        Description:
            - Input Feature Map's size : 27 x  1 =>  27
            - Kernel's size            : 27 x 12 => 324
            - Output Feature Map's size: 12 x  1 =>  12
            - Bias's size              : 12 x  4 =>  48
            - Partial-Sum's size       : 12 x  4 =>  48
    */

    localparam 
        IFM_SIZE = 27 *  1 + 1,
        KER_SIZE = 27 * 12    ,
        OFM_SIZE = 12 *  1    ,
        BIS_SIZE = 12,
        PAS_SIZE = 12, 
        OUTPUT_HEIGHT = 1,
        OUTPUT_WIDTH = 12,
        OUTPUT_DEPTH = 1;

    initial begin
        // al_accel_mem_read_ready = 1'b 0;
        // al_accel_mem_write_ready = 1'b 0;
        // #10
        // repeat (2000) @(posedge clk) begin
        //     #2 al_accel_mem_read_ready = $random;
        // end
        // #10 
        al_accel_mem_read_ready    = 1'b 1;
        al_accel_mem_write_ready   = 1'b 1;
    end

    initial begin
        al_accel_cfgreg_di   = 32'd 0; al_accel_cfgreg_sel = 5'd 0; 
        al_accel_cfgreg_wenb =  1'd 0;
        al_accel_flow_enb    =  1'b 0;
        #42
        al_accel_cfgreg_wenb =  1'd 1;
    // Config Data
        #10 // i_base_addr
        al_accel_cfgreg_di   = 32'd 0000;       al_accel_cfgreg_sel = 5'd 0; 

        #10 // kw_base_addr
        al_accel_cfgreg_di   = 32'd 6000;       al_accel_cfgreg_sel = 5'd 1; 

        #10 // o_base_addr
        al_accel_cfgreg_di   = 32'd 16000;       al_accel_cfgreg_sel = 5'd 2; 

        #10 // b_base_addr
        al_accel_cfgreg_di   = 32'd 5600;       al_accel_cfgreg_sel = 5'd 3; 

        #10 // ps_base_addr
        al_accel_cfgreg_di   = 32'd 20000;       al_accel_cfgreg_sel = 5'd 4; 

        #10 // {stride_height, stride_width, cfg_act_func_typ, cfg_layer_typ}
        al_accel_cfgreg_di   = {16'd 0, 4'd 0, 4'd 0, NO_FUNC, DENSE}; al_accel_cfgreg_sel = 5'd 5; 

        #10 // {weight_kernel_patch_height, weight_kernel_patch_width}
        al_accel_cfgreg_di   = {16'd 12, 16'd 27}; al_accel_cfgreg_sel = 5'd 6; 

        #10 // {nok_ofm_depth, kernel_ifm_depth} 
        al_accel_cfgreg_di   = 32'd 0; al_accel_cfgreg_sel = 5'd 7;

        #10 // {ifm_height, ifm_width}  
        al_accel_cfgreg_di   = {16'd 1, 16'd 27}; al_accel_cfgreg_sel = 5'd 8;

        #10 // {ofm_height, ofm_width}
        al_accel_cfgreg_di   = {16'd 1, 16'd 12}; al_accel_cfgreg_sel = 5'd 9;

        #10 // {output2D_size, input2D_size}  
        al_accel_cfgreg_di   = {16'd 12, 16'd  27}; al_accel_cfgreg_sel = 5'd 10;

        #10 // kernel3D_size 
        al_accel_cfgreg_di   = {16'd  0, 16'd 324}; al_accel_cfgreg_sel = 5'd 11;

    // Output Quantize Buffer
        #10 // output_quant_sel
        al_accel_cfgreg_di   = {24'd 0, 8'd 0} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1073742347 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 7} ; al_accel_cfgreg_sel = 5'd 14;

    // Data Offset
        #10 // input_offset
        al_accel_cfgreg_di   =-32'd 11238; al_accel_cfgreg_sel = 5'd 15;
        #10 // output_offset
        al_accel_cfgreg_di   = 32'd  1236; al_accel_cfgreg_sel = 5'd 16;

    // Flow Run
        #10 
        al_accel_cfgreg_wenb =  1'd 0;
        #10 
        al_accel_flow_enb    =  1'd 1;
        #1000
        al_accel_flow_enb    =  1'd 0;
        #200
        al_accel_flow_enb    =  1'd 1;
		repeat (2000) @(posedge clk) begin
            #2 al_accel_flow_enb = $random;
        end
        #10 
        al_accel_flow_enb    =  1'd 1;
    end

    reg [IFM_SIZE *  8 - 1:0]  input_data ; // Size: 7 x 7 x 9
    reg [KER_SIZE *  8 - 1:0]  filter_data; // Size: 3 x 3 x 9 x 9
    reg [BIS_SIZE * 32 - 1:0]  bias_data  ; // Size: 9
    integer i;
    initial begin
        for (i = 0; i < 4096; i = i + 1)
            ram.mem[i] = 32'd 0;

        // Input Initilization
        input_data = {
            8'd   1, 8'd   2,-8'd   3,-8'd   4,-8'd   5,-8'd   6,-8'd   7,-8'd   8, 8'd  90,
            8'd  20, 8'd  25, 8'd  42, 8'd  32, 8'd  12, 8'd  66,-8'd 128, 8'd 127, 8'd  34,
            8'd  11, 8'd  22,-8'd  33, 8'd  44,-8'd  55, 8'd  66,-8'd  77, 8'd  88,-8'd  99,
        // Padding
            8'd   0
        };
        for (i = 0; i < (IFM_SIZE); i = i + 4) begin
            ram.mem[0 + (i / 4)][ 7: 0] = input_data[8*((IFM_SIZE) - 1 - i) +: 8];
            ram.mem[0 + (i / 4)][15: 8] = input_data[8*((IFM_SIZE) - 2 - i) +: 8];
            ram.mem[0 + (i / 4)][23:16] = input_data[8*((IFM_SIZE) - 3 - i) +: 8];
            ram.mem[0 + (i / 4)][31:24] = input_data[8*((IFM_SIZE) - 4 - i) +: 8];
        end

        // Kernel 
        filter_data = {
            8'd   2, 8'd   3, 8'd  43, 8'd  56, 8'd  11, 8'd  22,-8'd 128, 8'd  79, 8'd  27,
            8'd   2, 8'd   3, 8'd  43, 8'd  56, 8'd  11, 8'd  22,-8'd 128, 8'd  79, 8'd  27,
            8'd   2, 8'd   3, 8'd  43, 8'd  56, 8'd  11, 8'd  22,-8'd 128, 8'd  79, 8'd  27,
            8'd   4, 8'd  28, 8'd  74, 8'd  66, 8'd  43, 8'd 111,-8'd 110, 8'd  19, 8'd  81,
            8'd   4, 8'd  28, 8'd  74, 8'd  66, 8'd  43, 8'd 111,-8'd 110, 8'd  19, 8'd  81,
            8'd   4, 8'd  28, 8'd  74, 8'd  66, 8'd  43, 8'd 111,-8'd 110, 8'd  19, 8'd  81,
            8'd  90, 8'd  42, 8'd  64, 8'd  19, 8'd   1, 8'd   2, 8'd   3, 8'd   4, 8'd   5,
            8'd  90, 8'd  42, 8'd  64, 8'd  19, 8'd   1, 8'd   2, 8'd   3, 8'd   4, 8'd   5,
            8'd  90, 8'd  42, 8'd  64, 8'd  19, 8'd   1, 8'd   2, 8'd   3, 8'd   4, 8'd   5,
            8'd  98, 8'd  32, 8'd  17, 8'd  89, 8'd   1,-8'd   2, 8'd   3, 8'd   4, 8'd   5,
            8'd  98, 8'd  32, 8'd  17, 8'd  89, 8'd   1,-8'd   2, 8'd   3, 8'd   4, 8'd   5,
            8'd  98, 8'd  32, 8'd  17, 8'd  89, 8'd   1,-8'd   2, 8'd   3, 8'd   4, 8'd   5,
            8'd   6, 8'd  23, 8'd  65, 8'd  76, 8'd   1, 8'd   2,-8'd   3, 8'd   4, 8'd   5,
            8'd   6, 8'd  23, 8'd  65, 8'd  76, 8'd   1, 8'd   2,-8'd   3, 8'd   4, 8'd   5,
            8'd   6, 8'd  23, 8'd  65, 8'd  76, 8'd   1, 8'd   2,-8'd   3, 8'd   4, 8'd   5,
            8'd  43, 8'd   4,-8'd   1,-8'd  89, 8'd   1, 8'd   2, 8'd   3,-8'd   4, 8'd   5,
            8'd  43, 8'd   4,-8'd   1,-8'd  89, 8'd   1, 8'd   2, 8'd   3,-8'd   4, 8'd   5,
            8'd  43, 8'd   4,-8'd   1,-8'd  89, 8'd   1, 8'd   2, 8'd   3,-8'd   4, 8'd   5,
           -8'd  30, 8'd   6,-8'd  45, 8'd  89, 8'd   1, 8'd   2, 8'd   3, 8'd   4,-8'd   5,
           -8'd  30, 8'd   6,-8'd  45, 8'd  89, 8'd   1, 8'd   2, 8'd   3, 8'd   4,-8'd   5,
           -8'd  30, 8'd   6,-8'd  45, 8'd  89, 8'd   1, 8'd   2, 8'd   3, 8'd   4,-8'd   5,
            8'd  43, 8'd   4,-8'd   1,-8'd  89, 8'd   1, 8'd   2, 8'd   3,-8'd   4, 8'd   5,
            8'd  43, 8'd   4,-8'd   1,-8'd  89, 8'd   1, 8'd   2, 8'd   3,-8'd   4, 8'd   5,
            8'd  43, 8'd   4,-8'd   1,-8'd  89, 8'd   1, 8'd   2, 8'd   3,-8'd   4, 8'd   5,
           -8'd  30, 8'd   6,-8'd  45, 8'd  89, 8'd   1, 8'd   2, 8'd   3, 8'd   4,-8'd   5,
           -8'd  30, 8'd   6,-8'd  45, 8'd  89, 8'd   1, 8'd   2, 8'd   3, 8'd   4,-8'd   5,
           -8'd  30, 8'd   6,-8'd  45, 8'd  89, 8'd   1, 8'd   2, 8'd   3, 8'd   4,-8'd   5,
            8'd   6, 8'd  23, 8'd  65, 8'd  76, 8'd   1, 8'd   2,-8'd   3, 8'd   4, 8'd   5,
           -8'd  30, 8'd   6,-8'd  45, 8'd  89, 8'd   1, 8'd   2, 8'd   3, 8'd   4,-8'd   5,
            8'd   4, 8'd  28, 8'd  74, 8'd  66, 8'd  43, 8'd 111,-8'd 110, 8'd  19, 8'd  81,
            8'd   2, 8'd   3, 8'd  43, 8'd  56, 8'd  11, 8'd  22,-8'd 128, 8'd  79, 8'd  27,
            8'd  90, 8'd  42, 8'd  64, 8'd  19, 8'd   1, 8'd   2, 8'd   3, 8'd   4, 8'd   5,
            8'd   6, 8'd  23, 8'd  65, 8'd  76, 8'd   1, 8'd   2,-8'd   3, 8'd   4, 8'd   5,
            8'd  98, 8'd  32, 8'd  17, 8'd  89, 8'd   1,-8'd   2, 8'd   3, 8'd   4, 8'd   5,
            8'd  98, 8'd  32, 8'd  17, 8'd  89, 8'd   1,-8'd   2, 8'd   3, 8'd   4, 8'd   5,
            8'd   6, 8'd  23, 8'd  65, 8'd  76, 8'd   1, 8'd   2,-8'd   3, 8'd   4, 8'd   5
        // Padding
        }; 

        for (i = 0; i < KER_SIZE; i = i + 4) begin
            ram.mem[1500 + (i / 4)][ 7: 0] = filter_data[8*(KER_SIZE - 1 - i) +: 8];
            ram.mem[1500 + (i / 4)][15: 8] = filter_data[8*(KER_SIZE - 2 - i) +: 8];
            ram.mem[1500 + (i / 4)][23:16] = filter_data[8*(KER_SIZE - 3 - i) +: 8];
            ram.mem[1500 + (i / 4)][31:24] = filter_data[8*(KER_SIZE - 4 - i) +: 8];
        end

        // Bias
        bias_data = {
            32'd     1,
            32'd    43, 
            32'd    87, 
            32'd   119,
            32'd    46, 
            32'd    67,
            32'd   100, 
            32'd    23, 
           -32'd    24,
            32'd 81324,
            32'd 98123,
           -32'd 10002
        };
        for (i = 0; i < BIS_SIZE; i = i + 1) begin
            ram.mem[1400 + i] = bias_data[32*(BIS_SIZE - 1 - i) +: 32];
        end

    end
/*******************/
`elsif FCL_TC2
/* Test case 2 */
    /* 
        Description:
            - Input Feature Map's size : 801
            - Kernel's size            : 801 x 12 => 324
            - Output Feature Map's size: 12  x  1 =>  12
            - Bias's size              : 12  x  4 =>  48
            - Partial-Sum's size       : 12  x  4 =>  48
    */

    localparam 
        IFM_SIZE = 801 * 1 + 3,
        KER_SIZE = 801 * 12   ,
        OFM_SIZE = 12 *  1    ,
        BIS_SIZE = 12,
        PAS_SIZE = 12,
        OUTPUT_HEIGHT = 1,
        OUTPUT_WIDTH = 12,
        OUTPUT_DEPTH = 1;

    initial begin
        // al_accel_mem_read_ready = 1'b 0;
        // al_accel_mem_write_ready = 1'b 0;
        // #10
        // repeat (2000) @(posedge clk) begin
        //     #2 al_accel_mem_read_ready = $random;
        // end
        // #10 
        al_accel_mem_read_ready    = 1'b 1;
        al_accel_mem_write_ready   = 1'b 1;
    end

    initial begin
        al_accel_cfgreg_di   = 32'd 0; al_accel_cfgreg_sel = 5'd 0; 
        al_accel_cfgreg_wenb =  1'd 0;
        al_accel_flow_enb    =  1'b 0;
        #42
        al_accel_cfgreg_wenb =  1'd 1;
    // Config Data
        #10 // i_base_addr
        al_accel_cfgreg_di   = 32'd 0000;       al_accel_cfgreg_sel = 5'd 0; 

        #10 // kw_base_addr
        al_accel_cfgreg_di   = 32'd 6000;       al_accel_cfgreg_sel = 5'd 1; 

        #10 // o_base_addr
        al_accel_cfgreg_di   = 32'd 16000;       al_accel_cfgreg_sel = 5'd 2; 

        #10 // b_base_addr
        al_accel_cfgreg_di   = 32'd 5600;       al_accel_cfgreg_sel = 5'd 3; 

        #10 // ps_base_addr
        al_accel_cfgreg_di   = 32'd 20000;       al_accel_cfgreg_sel = 5'd 4; 

        #10 // {stride_height, stride_width, cfg_act_func_typ, cfg_layer_typ}
        al_accel_cfgreg_di   = {16'd 0, 4'd 0, 4'd 0, RELU, DENSE}; al_accel_cfgreg_sel = 5'd 5; 

        #10 // {weight_kernel_patch_height, weight_kernel_patch_width}
        al_accel_cfgreg_di   = {16'd 12, 16'd 801}; al_accel_cfgreg_sel = 5'd 6; 

        #10 // {nok_ofm_depth, kernel_ifm_depth} 
        al_accel_cfgreg_di   = 32'd 0; al_accel_cfgreg_sel = 5'd 7;

        #10 // {ifm_height, ifm_width}  
        al_accel_cfgreg_di   = {16'd 1, 16'd 801}; al_accel_cfgreg_sel = 5'd 8;

        #10 // {ofm_height, ofm_width}
        al_accel_cfgreg_di   = {16'd 1, 16'd 12}; al_accel_cfgreg_sel = 5'd 9;

        #10 // {output2D_size, input2D_size}  
        al_accel_cfgreg_di   = {16'd 12, 16'd  27}; al_accel_cfgreg_sel = 5'd 10;

        #10 // kernel3D_size 
        al_accel_cfgreg_di   = {16'd  0, 16'd 9612}; al_accel_cfgreg_sel = 5'd 11;

    // Output Quantize Buffer
        #10 // output_quant_sel
        al_accel_cfgreg_di   = {24'd 0, 8'd 0} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1073742347 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 7} ; al_accel_cfgreg_sel = 5'd 14;

    // Data Offset
        #10 // input_offset
        al_accel_cfgreg_di   =-32'd 11238; al_accel_cfgreg_sel = 5'd 15;
        #10 // output_offset
        al_accel_cfgreg_di   = 32'd  1236; al_accel_cfgreg_sel = 5'd 16;

    // Flow Run
        #10 
        al_accel_cfgreg_wenb =  1'd 0;
        #10 
        al_accel_flow_enb    =  1'd 1;
        #1000
        al_accel_flow_enb    =  1'd 0;
        #200
        al_accel_flow_enb    =  1'd 1;
		repeat (2000) @(posedge clk) begin
            #2 al_accel_flow_enb = $random;
        end
        #10 
        al_accel_flow_enb    =  1'd 1;
    end

    reg [IFM_SIZE *  8 - 1:0]  input_data ; // Size: 7 x 7 x 9
    reg [KER_SIZE *  8 - 1:0]  filter_data; // Size: 3 x 3 x 9 x 9
    reg [BIS_SIZE * 32 - 1:0]  bias_data  ; // Size: 9
    integer i;
    initial begin
        for (i = 0; i < 4096; i = i + 1)
            ram.mem[i] = 32'd 0;

        // Input Initilization
        input_data = {
            8'd   1, 8'd   2,-8'd   3,-8'd   4,-8'd   5,-8'd   6,-8'd   7,-8'd   8, 8'd  90,
            8'd  20, 8'd  25, 8'd  42, 8'd  32, 8'd  12, 8'd  66,-8'd 128, 8'd 127, 8'd  34,
            8'd  11, 8'd  22,-8'd  33, 8'd  44,-8'd  55, 8'd  66,-8'd  77, 8'd  88,-8'd  99,
        // Padding
            8'd   0
        };
        for (i = 0; i < (IFM_SIZE); i = i + 4) begin
            ram.mem[0 + (i / 4)][ 7: 0] = input_data[8*((IFM_SIZE) - 1 - i) +: 8];
            ram.mem[0 + (i / 4)][15: 8] = input_data[8*((IFM_SIZE) - 2 - i) +: 8];
            ram.mem[0 + (i / 4)][23:16] = input_data[8*((IFM_SIZE) - 3 - i) +: 8];
            ram.mem[0 + (i / 4)][31:24] = input_data[8*((IFM_SIZE) - 4 - i) +: 8];
        end

        // Kernel 
        filter_data = {
            8'd   2, 8'd   3, 8'd  43, 8'd  56, 8'd  11, 8'd  22,-8'd 128, 8'd  79, 8'd  27,
            8'd   2, 8'd   3, 8'd  43, 8'd  56, 8'd  11, 8'd  22,-8'd 128, 8'd  79, 8'd  27,
            8'd   2, 8'd   3, 8'd  43, 8'd  56, 8'd  11, 8'd  22,-8'd 128, 8'd  79, 8'd  27,
            8'd   4, 8'd  28, 8'd  74, 8'd  66, 8'd  43, 8'd 111,-8'd 110, 8'd  19, 8'd  81,
            8'd   4, 8'd  28, 8'd  74, 8'd  66, 8'd  43, 8'd 111,-8'd 110, 8'd  19, 8'd  81,
            8'd   4, 8'd  28, 8'd  74, 8'd  66, 8'd  43, 8'd 111,-8'd 110, 8'd  19, 8'd  81,
            8'd  90, 8'd  42, 8'd  64, 8'd  19, 8'd   1, 8'd   2, 8'd   3, 8'd   4, 8'd   5,
            8'd  90, 8'd  42, 8'd  64, 8'd  19, 8'd   1, 8'd   2, 8'd   3, 8'd   4, 8'd   5,
            8'd  90, 8'd  42, 8'd  64, 8'd  19, 8'd   1, 8'd   2, 8'd   3, 8'd   4, 8'd   5,
            8'd  98, 8'd  32, 8'd  17, 8'd  89, 8'd   1,-8'd   2, 8'd   3, 8'd   4, 8'd   5,
            8'd  98, 8'd  32, 8'd  17, 8'd  89, 8'd   1,-8'd   2, 8'd   3, 8'd   4, 8'd   5,
            8'd  98, 8'd  32, 8'd  17, 8'd  89, 8'd   1,-8'd   2, 8'd   3, 8'd   4, 8'd   5,
            8'd   6, 8'd  23, 8'd  65, 8'd  76, 8'd   1, 8'd   2,-8'd   3, 8'd   4, 8'd   5,
            8'd   6, 8'd  23, 8'd  65, 8'd  76, 8'd   1, 8'd   2,-8'd   3, 8'd   4, 8'd   5,
            8'd   6, 8'd  23, 8'd  65, 8'd  76, 8'd   1, 8'd   2,-8'd   3, 8'd   4, 8'd   5,
            8'd  43, 8'd   4,-8'd   1,-8'd  89, 8'd   1, 8'd   2, 8'd   3,-8'd   4, 8'd   5,
            8'd  43, 8'd   4,-8'd   1,-8'd  89, 8'd   1, 8'd   2, 8'd   3,-8'd   4, 8'd   5,
            8'd  43, 8'd   4,-8'd   1,-8'd  89, 8'd   1, 8'd   2, 8'd   3,-8'd   4, 8'd   5,
           -8'd  30, 8'd   6,-8'd  45, 8'd  89, 8'd   1, 8'd   2, 8'd   3, 8'd   4,-8'd   5,
           -8'd  30, 8'd   6,-8'd  45, 8'd  89, 8'd   1, 8'd   2, 8'd   3, 8'd   4,-8'd   5,
           -8'd  30, 8'd   6,-8'd  45, 8'd  89, 8'd   1, 8'd   2, 8'd   3, 8'd   4,-8'd   5,
            8'd  43, 8'd   4,-8'd   1,-8'd  89, 8'd   1, 8'd   2, 8'd   3,-8'd   4, 8'd   5,
            8'd  43, 8'd   4,-8'd   1,-8'd  89, 8'd   1, 8'd   2, 8'd   3,-8'd   4, 8'd   5,
            8'd  43, 8'd   4,-8'd   1,-8'd  89, 8'd   1, 8'd   2, 8'd   3,-8'd   4, 8'd   5,
           -8'd  30, 8'd   6,-8'd  45, 8'd  89, 8'd   1, 8'd   2, 8'd   3, 8'd   4,-8'd   5,
           -8'd  30, 8'd   6,-8'd  45, 8'd  89, 8'd   1, 8'd   2, 8'd   3, 8'd   4,-8'd   5,
           -8'd  30, 8'd   6,-8'd  45, 8'd  89, 8'd   1, 8'd   2, 8'd   3, 8'd   4,-8'd   5,
            8'd   6, 8'd  23, 8'd  65, 8'd  76, 8'd   1, 8'd   2,-8'd   3, 8'd   4, 8'd   5,
           -8'd  30, 8'd   6,-8'd  45, 8'd  89, 8'd   1, 8'd   2, 8'd   3, 8'd   4,-8'd   5,
            8'd   4, 8'd  28, 8'd  74, 8'd  66, 8'd  43, 8'd 111,-8'd 110, 8'd  19, 8'd  81,
            8'd   2, 8'd   3, 8'd  43, 8'd  56, 8'd  11, 8'd  22,-8'd 128, 8'd  79, 8'd  27,
            8'd  90, 8'd  42, 8'd  64, 8'd  19, 8'd   1, 8'd   2, 8'd   3, 8'd   4, 8'd   5,
            8'd   6, 8'd  23, 8'd  65, 8'd  76, 8'd   1, 8'd   2,-8'd   3, 8'd   4, 8'd   5,
            8'd  98, 8'd  32, 8'd  17, 8'd  89, 8'd   1,-8'd   2, 8'd   3, 8'd   4, 8'd   5,
            8'd  98, 8'd  32, 8'd  17, 8'd  89, 8'd   1,-8'd   2, 8'd   3, 8'd   4, 8'd   5,
            8'd   6, 8'd  23, 8'd  65, 8'd  76, 8'd   1, 8'd   2,-8'd   3, 8'd   4, 8'd   5
        // Padding
        }; 

        for (i = 0; i < KER_SIZE; i = i + 4) begin
            ram.mem[1500 + (i / 4)][ 7: 0] = filter_data[8*(KER_SIZE - 1 - i) +: 8];
            ram.mem[1500 + (i / 4)][15: 8] = filter_data[8*(KER_SIZE - 2 - i) +: 8];
            ram.mem[1500 + (i / 4)][23:16] = filter_data[8*(KER_SIZE - 3 - i) +: 8];
            ram.mem[1500 + (i / 4)][31:24] = filter_data[8*(KER_SIZE - 4 - i) +: 8];
        end

        // Bias
        bias_data = {
            32'd     1,
            32'd    43, 
            32'd    87, 
            32'd   119,
            32'd    46, 
            32'd    67,
            32'd   100, 
            32'd    23, 
           -32'd    24,
            32'd 81324,
            32'd 98123,
           -32'd 10002
        };
        for (i = 0; i < BIS_SIZE; i = i + 1) begin
            ram.mem[1400 + i] = bias_data[32*(BIS_SIZE - 1 - i) +: 32];
        end

    end
/*******************/
`endif  


// =================================================================================================================================
// ========================================================== MIXED LAYER ==========================================================
// =================================================================================================================================
`ifdef ML_TC0
/* Test case 0 */
    /* 
        Description:
        - Input Feature Map's size : 8 x 8 x 3       => 192
        - Kernel's size            : 3 x 3 x 3 x 6   => 162
        - Output Feature Map's size: 6 x 6 x 6       => 216
        - Bias's size              : 6               =>  6
    */

    localparam 
        IFM_SIZE = 8 * 8 * 3     + 1,
        KER_SIZE = 3 * 3 * 3 * 6 + 2,
        OFM_SIZE = 3 * 3 * 6     + 2,
        BIS_SIZE = 6,
        PAS_SIZE = 5 * 5 * 6,
        OUTPUT_HEIGHT = 3,
        OUTPUT_WIDTH = 3,
        OUTPUT_DEPTH = 6;

    initial begin
        // al_accel_mem_read_ready = 1'b 0;
        // al_accel_mem_write_ready = 1'b 0;
        // #10
        // repeat (2000) @(posedge clk) begin
        //     #2 al_accel_mem_read_ready = $random;
        // end
        // #10 
        al_accel_mem_read_ready    = 1'b 1;
        al_accel_mem_write_ready   = 1'b 1;
    end

    initial begin
        al_accel_cfgreg_di   = 32'd 0; al_accel_cfgreg_sel = 5'd 0; 
        al_accel_cfgreg_wenb =  1'd 0;
        al_accel_flow_enb    =  1'b 0;
        #42
        al_accel_cfgreg_wenb =  1'd 1;
    // Config Data
        #10 // i_base_addr
        al_accel_cfgreg_di   = 32'd 0000;       al_accel_cfgreg_sel = 5'd 0; 

        #10 // kw_base_addr
        al_accel_cfgreg_di   = 32'd 6000;       al_accel_cfgreg_sel = 5'd 1; 

        #10 // o_base_addr
        al_accel_cfgreg_di   = 32'd 16000;       al_accel_cfgreg_sel = 5'd 2; 

        #10 // b_base_addr
        al_accel_cfgreg_di   = 32'd 5600;       al_accel_cfgreg_sel = 5'd 3; 

        #10 // ps_base_addr
        al_accel_cfgreg_di   = 32'd 20000;       al_accel_cfgreg_sel = 5'd 4; 

        #10 // {stride_height, stride_width, cfg_act_func_typ, cfg_layer_typ}
        al_accel_cfgreg_di   = {16'd 0, 4'd 1, 4'd 1, RELU, MIXED}; al_accel_cfgreg_sel = 5'd 5; 

        #10 // {weight_kernel_patch_height, weight_kernel_patch_width}
        al_accel_cfgreg_di   = {16'd 3, 16'd 3}; al_accel_cfgreg_sel = 5'd 6; 

        #10 // {nok_ofm_depth, kernel_ifm_depth} 
        al_accel_cfgreg_di   = {16'd 6, 16'd 3}; al_accel_cfgreg_sel = 5'd 7;
        
        #10 // {ifm_height, ifm_width}  
        al_accel_cfgreg_di   = {16'd 8, 16'd 8}; al_accel_cfgreg_sel = 5'd 8;

        #10 // {ofm_height, ofm_width}
        al_accel_cfgreg_di   = {16'd 6, 16'd 6}; al_accel_cfgreg_sel = 5'd 9;

        #10 // {output2D_size, input2D_size}  
        al_accel_cfgreg_di   = {16'd 36, 16'd 64}; al_accel_cfgreg_sel = 5'd 10;

        #10 // kernel3D_size
        al_accel_cfgreg_di   = {16'd  0, 16'd 27}; al_accel_cfgreg_sel = 5'd 11;

    // Output Quantize Buffer
        #10 // output_quant_sel
        al_accel_cfgreg_di   = {24'd 0, 8'd 0} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 2039693188 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 8} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel
        al_accel_cfgreg_di   = {24'd 0, 8'd 1} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 2097238482 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 8} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel
        al_accel_cfgreg_di   = {24'd 0, 8'd 2} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1378465373 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 8} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel
        al_accel_cfgreg_di   = {24'd 0, 8'd 3} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1543907582 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 9} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel
        al_accel_cfgreg_di   = {24'd 0, 8'd 4} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1858862255 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd10} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel
        al_accel_cfgreg_di   = {24'd 0, 8'd 5} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1117338165 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 8} ; al_accel_cfgreg_sel = 5'd 14;

    // Data Offset
        #10 // input_offset
        al_accel_cfgreg_di   = 32'd 128; al_accel_cfgreg_sel = 5'd 15;
        #10 // output_offset
        al_accel_cfgreg_di   = 32'd 128; al_accel_cfgreg_sel = 5'd 16;

        #10 // {ofm_pool_height,  ofm_pool_width}
        al_accel_cfgreg_di   = {16'd 3, 16'd 3}; al_accel_cfgreg_sel = 5'd 17;
        #10 // output2D_pool_size
        al_accel_cfgreg_di   = 32'd 9; al_accel_cfgreg_sel = 5'd 18;

    // Flow Run

        al_accel_flow_enb    =  1'd 1;
    end

    reg [(8 * 8 * 3 + 1)     * 8 - 1:0] input_data ; // Size: 7 x 7 x 3
    reg [(3 * 3 * 3 * 6 + 2) * 8 - 1:0] filter_data; // Size: 3 x 3 x 3 x 6
    reg [ 6 * 32                 - 1:0] bias_data  ; // Size: 6
    integer i;
    initial begin
        for (i = 0; i < 4096; i = i + 1)
            ram.mem[i] = 32'd 0;

        // Input Initilization
        input_data = {
            /* z = 1 */
                8'd   1, 8'd   2, 8'd   7, 8'd   8,-8'd   1,-8'd  78, 8'd  12, 8'd  12,  
                8'd   5, 8'd  45, 8'd  64, 8'd 123,-8'd  89,-8'd  74, 8'd  12, 8'd  14,
                8'd   7, 8'd  45, 8'd 123, 8'd  45, 8'd  90, 8'd 101, 8'd  87, 8'd  12,
                8'd   1, 8'd   2, 8'd   7, 8'd   8,-8'd   1, 8'd   0,-8'd  19, 8'd  11,
                8'd   5, 8'd  45, 8'd  64, 8'd 123,-8'd  34,-8'd  20, 8'd  75, 8'd  14,
                8'd   7, 8'd  45, 8'd 123, 8'd  45, 8'd  90, 8'd 101, 8'd  96, 8'd  15,
                8'd  15, 8'd  16, 8'd  17, 8'd  18, 8'd  19, 8'd  20, 8'd  21, 8'd  11,
                8'd  19, 8'd  20, 8'd  21, 8'd  32, 8'd  121, 8'd  123, 8'd  121, 8'd  11, 
            /* z = 1 */
                -8'd  90, 8'd   2, 8'd   7, 8'd   8,-8'd  55,-8'd  21, 8'd  10, 8'd  12,
                8'd  51, 8'd  45, 8'd  64, 8'd 123, 8'd  34,-8'd  20, 8'd  10, 8'd  12,
                8'd  57, 8'd  45, 8'd 123, 8'd  45, 8'd  90, 8'd 101, 8'd  21, 8'd  12,
                8'd 110, 8'd   2, 8'd   7, 8'd   8,-8'd  55,-8'd  11, 8'd  22, 8'd  12,
                8'd  51, 8'd  45, 8'd  64, 8'd  23,-8'd  24, 8'd  20, 8'd  88, 8'd  12,
                8'd  71, 8'd  45,-8'd  23, 8'd  45, 8'd  90, 8'd 101, 8'd  66, 8'd  12,
                8'd  15, 8'd  16, 8'd  17, 8'd  18, 8'd  19, 8'd  20, 8'd  21, 8'd  12,
                8'd  12, 8'd  12, 8'd  12, 8'd  12, 8'd  12, 8'd  12, 8'd  12, 8'd  12, 
            /* z = 2 */
                8'd   1, 8'd  23, 8'd   7, 8'd   8, 8'd  55, 8'd  21, 8'd  10, 8'd  12,
                8'd   5, 8'd   4, 8'd  64, 8'd 123, 8'd  34, 8'd  20, 8'd  21, 8'd  12,
                8'd   7, 8'd   5, 8'd 123, 8'd  45, 8'd  90, 8'd 101, 8'd  21, 8'd  12,
                8'd   1, 8'd   2, 8'd   7, 8'd   8, 8'd  55,-8'd   1, 8'd  18,  8'd  12,
                8'd   5, 8'd   5, 8'd  64, 8'd  13, 8'd  34, 8'd  20, 8'd  21,  8'd  12,
                8'd  15, 8'd  16, 8'd  17, 8'd  18, 8'd  19, 8'd  20, 8'd  21, 8'd  12,
                8'd  23, 8'd  24, 8'd  25, 8'd  26, 8'd  27, 8'd  28, 8'd  29, 8'd  12,
                8'd  12, 8'd  12, 8'd  12, 8'd  12, 8'd  12, 8'd  12, 8'd  12, 8'd  12,
                8'd0
        };
        for (i = 0; i < (IFM_SIZE); i = i + 4) begin
            ram.mem[0 + (i / 4)][ 7: 0] = input_data[8*((IFM_SIZE) - 1 - i) +: 8];
            ram.mem[0 + (i / 4)][15: 8] = input_data[8*((IFM_SIZE) - 2 - i) +: 8];
            ram.mem[0 + (i / 4)][23:16] = input_data[8*((IFM_SIZE) - 3 - i) +: 8];
            ram.mem[0 + (i / 4)][31:24] = input_data[8*((IFM_SIZE) - 4 - i) +: 8];
        end
        

        // Kernel 
        filter_data = {
            /* Channel = 0 */
                /* z = 0 */
                8'd 10, 8'd 11, 8'd  0, 8'd 10, 8'd  0, 8'd 11, 8'd 11, 8'd 11, 8'd  0,
                /* z = 1 */
                8'd 11, 8'd 11, 8'd  0, 8'd 11, 8'd 11, 8'd  0, 8'd 11, 8'd  0, 8'd 11,
                /* z = 2 */
                8'd 11, 8'd  0, 8'd 11, 8'd 11, 8'd 11, 8'd  0, 8'd 11, 8'd 11, 8'd  0,
            /* Channel = 1 */
                /* z = 0 */
                8'd 11, 8'd 21, 8'd  0, 8'd 21, 8'd  0, 8'd 11, 8'd 21, 8'd 11, 8'd  0,
                /* z = 1 */
                8'd 21, 8'd 11, 8'd  0, 8'd 21, 8'd 11, 8'd  0, 8'd 21, 8'd  0, 8'd 11,
                /* z = 2 */
                8'd 21, 8'd  0, 8'd 11, 8'd 21, 8'd 11, 8'd  0, 8'd 21, 8'd 11, 8'd  0,
            /* Channel = 2 */
                /* z = 0 */
                8'd 11, 8'd 31, 8'd  0, 8'd 11, 8'd  0, 8'd 11, 8'd 11, 8'd 31, 8'd  0,
                /* z = 1 */
                8'd 11, 8'd 31, 8'd  0, 8'd 11, 8'd 31, 8'd  0, 8'd 11, 8'd  0, 8'd 11,
                /* z = 2 */
                8'd 11, 8'd  0, 8'd 11, 8'd 11, 8'd 31, 8'd  0, 8'd 11, 8'd 31, 8'd  0,
            /* Channel = 3 */
                /* z = 0 */
                8'd 11, 8'd 11, 8'd 40, 8'd 11, 8'd 40, 8'd 41, 8'd 21, 8'd 11, 8'd 40,
                /* z = 1 */
                8'd 21, 8'd 11, 8'd 40, 8'd 11, 8'd 41, 8'd 40, 8'd 11, 8'd 40, 8'd 11,
                /* z = 2 */
                8'd 11, 8'd 40, 8'd 41, 8'd 11, 8'd 21, 8'd 40, 8'd 11, 8'd 11, 8'd 40,
            /* Channel = 4 */
                /* z = 0 */
                8'd 11, 8'd 11, 8'd 30, 8'd 11, 8'd 30, 8'd 41, 8'd 21, 8'd 11, 8'd 30,
                /* z = 1 */
                8'd 21, 8'd 11, 8'd 30, 8'd 11, 8'd 41, 8'd 30, 8'd 11, 8'd 30, 8'd 11,
                /* z = 2 */
                8'd 11, 8'd  0, 8'd 41, 8'd 11, 8'd 21, 8'd 30, 8'd 11, 8'd 11, 8'd 30,
            /* Channel = 5 */
                /* z = 0 */
                8'd 11, 8'd 11, 8'd  0, 8'd 11,-8'd 20, 8'd 41, 8'd 21, 8'd 11, 8'd 20,
                /* z = 1 */
                8'd 21, 8'd 11, 8'd 10, 8'd 11, 8'd 41, 8'd 10, 8'd 11, 8'd 10, 8'd 11,
                /* z = 2 */
                8'd 11, 8'd 10, 8'd 21, 8'd 11, 8'd 21, 8'd 10, 8'd 11, 8'd 11, 8'd 10,
            // Padding
                8'd  0, 8'd  0
        }; 
        for (i = 0; i < KER_SIZE; i = i + 4) begin
            ram.mem[1500 + (i / 4)][ 7: 0] = filter_data[8*(KER_SIZE - 1 - i) +: 8];
            ram.mem[1500 + (i / 4)][15: 8] = filter_data[8*(KER_SIZE - 2 - i) +: 8];
            ram.mem[1500 + (i / 4)][23:16] = filter_data[8*(KER_SIZE - 3 - i) +: 8];
            ram.mem[1500 + (i / 4)][31:24] = filter_data[8*(KER_SIZE - 4 - i) +: 8];
        end


        // Bias
        bias_data = {
            32'd 20, 32'd 31, 32'd 42, 32'd 54,-32'd 15, 32'd 67
        };
        for (i = 0; i < BIS_SIZE; i = i + 1) begin
            ram.mem[1400 + i] = bias_data[32*(BIS_SIZE - 1 - i) +: 32];
        end

    end
/*******************/

`elsif ML_TC1
/* Test case 7 */
     /* 
        Description:
           - Input Feature Map's size : 28 x 28 x 3     => 2352
           - Kernel's size            : 3 x 3 x 3 x 32 => 864
           - Output Feature Map's size: 26 x 26 x 32     => 21632
           - Bias's size              : 32         =>  3872
    */
    localparam 
        IFM_SIZE = 28 * 28 * 3,
        KER_SIZE = 3 * 3 * 3 * 32,
        OFM_SIZE = 13 * 13 * 32,
        BIS_SIZE = 32,
        PAS_SIZE = 5 * 5 * 6,
        OUTPUT_HEIGHT = 13,
        OUTPUT_WIDTH = 13,
        OUTPUT_DEPTH = 32;

    initial begin
        al_accel_mem_read_ready    = 1'b 1;
        al_accel_mem_write_ready   = 1'b 1;
    end

    initial begin
        al_accel_cfgreg_di   = 32'd 0; al_accel_cfgreg_sel = 5'd 0; 
        al_accel_cfgreg_wenb =  1'd 0;
        al_accel_flow_enb    =  1'b 0;
        #42
        al_accel_cfgreg_wenb =  1'd 1;
    // Config Data
        #10 // i_base_addr
        al_accel_cfgreg_di   = 32'd 0000;       al_accel_cfgreg_sel = 5'd 0; 

        #10 // kw_base_addr
        al_accel_cfgreg_di   = 32'd 6000;       al_accel_cfgreg_sel = 5'd 1; 

        #10 // o_base_addr
        al_accel_cfgreg_di   = 32'd 16000;       al_accel_cfgreg_sel = 5'd 2; 

        #10 // b_base_addr
        al_accel_cfgreg_di   = 32'd 5600;       al_accel_cfgreg_sel = 5'd 3; 

        #10 // ps_base_addr
        al_accel_cfgreg_di   = 32'd 20000;       al_accel_cfgreg_sel = 5'd 4; 

        #10 // {stride_height, stride_width, cfg_act_func_typ, cfg_layer_typ}
        al_accel_cfgreg_di   = {16'd 0, 4'd 1, 4'd 1, RELU, MIXED}; al_accel_cfgreg_sel = 5'd 5; 

        #10 // {weight_kernel_patch_height, weight_kernel_patch_width}
        al_accel_cfgreg_di   = {16'd 3, 16'd 3}; al_accel_cfgreg_sel = 5'd 6; 

        #10 // {nok_ofm_depth, kernel_ifm_depth} 
        al_accel_cfgreg_di   = {16'd 32, 16'd 3}; al_accel_cfgreg_sel = 5'd 7;
        
        #10 // {ifm_height, ifm_width}  
        al_accel_cfgreg_di   = {16'd 28, 16'd 28}; al_accel_cfgreg_sel = 5'd 8;

        #10 // {ofm_height, ofm_width}
        al_accel_cfgreg_di   = {16'd 26, 16'd 26}; al_accel_cfgreg_sel = 5'd 9;

        #10 // {output2D_size, input2D_size}  
        al_accel_cfgreg_di   = {16'd 676, 16'd 784}; al_accel_cfgreg_sel = 5'd 10;

        #10 // kernel3D_size
        al_accel_cfgreg_di   = {16'd  0, 16'd 27}; al_accel_cfgreg_sel = 5'd 11;

        // Output Quantize Buffer
        #10 // output_quant_sel 0
        al_accel_cfgreg_di   = {24'd 0, 8'd 0} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 2006707479 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 9} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 1
        al_accel_cfgreg_di   = {24'd 0, 8'd 1} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1433835724 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 9} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 2
        al_accel_cfgreg_di   = {24'd 0, 8'd 2} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1192390444 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 8} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 3
        al_accel_cfgreg_di   = {24'd 0, 8'd 3} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1361289408 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 9} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 4
        al_accel_cfgreg_di   = {24'd 0, 8'd 4} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1285031363 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 10} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 5
        al_accel_cfgreg_di   = {24'd 0, 8'd 5} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 2063009507 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 9} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 6
        al_accel_cfgreg_di   = {24'd 0, 8'd 6} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 2143833947 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 9} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 7
        al_accel_cfgreg_di   = {24'd 0, 8'd 7} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 2040046477 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 11} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 8
        al_accel_cfgreg_di   = {24'd 0, 8'd 8} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1117137979 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 8} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 9
        al_accel_cfgreg_di   = {24'd 0, 8'd 9} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1529727281 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 9} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 10
        al_accel_cfgreg_di   = {24'd 0, 8'd 10} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1118076866 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 10} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 11
        al_accel_cfgreg_di   = {24'd 0, 8'd 11} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1909265169 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 9} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 12
        al_accel_cfgreg_di   = {24'd 0, 8'd 12} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1213134709 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 8} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 13
        al_accel_cfgreg_di   = {24'd 0, 8'd 13} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1219315125 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 10} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 14
        al_accel_cfgreg_di   = {24'd 0, 8'd 14} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1693522756 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 9} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 15
        al_accel_cfgreg_di   = {24'd 0, 8'd 15} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1244537046 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 9} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 16
        al_accel_cfgreg_di   = {24'd 0, 8'd 16} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1439731708 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 9} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 17
        al_accel_cfgreg_di   = {24'd 0, 8'd 17} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1469553438 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 8} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 18
        al_accel_cfgreg_di   = {24'd 0, 8'd 18} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1858048416 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 11} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 19
        al_accel_cfgreg_di   = {24'd 0, 8'd 19} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1955939902 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 11} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 20
        al_accel_cfgreg_di   = {24'd 0, 8'd 20} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1424595433 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 9} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 21
        al_accel_cfgreg_di   = {24'd 0, 8'd 21} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1295986055 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 8} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 22
        al_accel_cfgreg_di   = {24'd 0, 8'd 22} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1959811992 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 9} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 23
        al_accel_cfgreg_di   = {24'd 0, 8'd 23} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1607690141 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 9} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 24
        al_accel_cfgreg_di   = {24'd 0, 8'd 24} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1265787593 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 9} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 25
        al_accel_cfgreg_di   = {24'd 0, 8'd 25} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1154422605 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 10} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 26
        al_accel_cfgreg_di   = {24'd 0, 8'd 26} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1891572973 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 9} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 27
        al_accel_cfgreg_di   = {24'd 0, 8'd 27} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1267784783 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 10} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 28
        al_accel_cfgreg_di   = {24'd 0, 8'd 28} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1192481101 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 10} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 29
        al_accel_cfgreg_di   = {24'd 0, 8'd 29} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1139166983 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 8} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 30
        al_accel_cfgreg_di   = {24'd 0, 8'd 30} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1242432765 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 8} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 31
        al_accel_cfgreg_di   = {24'd 0, 8'd 31} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 2027832722 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 9} ; al_accel_cfgreg_sel = 5'd 14;

    // Data Offset
        #10 // input_offset
        al_accel_cfgreg_di   = 32'd 128; al_accel_cfgreg_sel = 5'd 15;
        #10 // output_offset
        al_accel_cfgreg_di   = 32'd 128; al_accel_cfgreg_sel = 5'd 16;
        
        #10 // {ofm_pool_height,  ofm_pool_width}
        al_accel_cfgreg_di   = {16'd 13, 16'd 13}; al_accel_cfgreg_sel = 5'd 17;
        #10 // output2D_pool_size
        al_accel_cfgreg_di   = 32'd 169; al_accel_cfgreg_sel = 5'd 18;
        

    // Flow Run
        #10
        al_accel_cfgreg_wenb =  1'd 0;
        #10 
        al_accel_flow_enb    =  1'd 1;
        // #1000
        // al_accel_flow_enb    =  1'd 0;
        // #200
        al_accel_flow_enb    =  1'd 1;
		// repeat (2000) @(posedge clk) begin
        //     #2 al_accel_flow_enb = $random;
        // end
        // #10 
        al_accel_flow_enb    =  1'd 1;
    end

    reg [IFM_SIZE    * 8 - 1:0] input_data ; // Size: 28 x 28 x 3
    reg [KER_SIZE * 8 - 1:0] filter_data; // Size: 3 x 3 x 3 x 6
    reg [ BIS_SIZE  * 32              - 1:0] bias_data  ; // Size: 6
    integer i;
    initial begin
        for (i = 0; i < 32768; i = i + 1)
            ram.mem[i] = 32'd 0;

        // Input Initilization
        input_data = {
            /* z = 0 */
            -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 
            -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 
            -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 
            -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 
            -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 
            -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 
            -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 
            -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd44, 8'd56, 8'd30, 8'd22, -8'd68, -8'd92, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 
            -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 8'd93, 8'd125, 8'd125, 8'd125, 8'd125, 8'd112, 8'd69, 8'd69, 8'd69, 8'd69, 8'd69, 8'd69, 8'd69, 8'd69, 8'd41, -8'd76, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 
            -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd61, -8'd14, -8'd56, -8'd14, 8'd34, 8'd98, 8'd125, 8'd96, 8'd125, 8'd125, 8'd125, 8'd121, 8'd100, 8'd125, 8'd125, 8'd11, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 
            -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd111, -8'd62, -8'd114, -8'd61, -8'd61, -8'd61, -8'd69, -8'd107, 8'd107, 8'd125, -8'd22, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 
            -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd45, 8'd124, 8'd80, -8'd110, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 
            -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd106, 8'd104, 8'd126, -8'd45, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 
            -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 8'd0, 8'd125, 8'd109, -8'd84, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 
            -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd69, 8'd120, 8'd125, -8'd66, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 
            -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 8'd4, 8'd125, 8'd58, -8'd123, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 
            -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd119, 8'd76, 8'd119, -8'd70, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 
            -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd2, 8'd125, 8'd53, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 
            -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd53, 8'd122, 8'd111, -8'd71, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 
            -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd109, 8'd92, 8'd125, 8'd37, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 
            -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd125, 8'd74, 8'd125, 8'd90, -8'd93, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 
            -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd90, 8'd125, 8'd125, -8'd51, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 
            -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd97, 8'd95, 8'd125, -8'd13, -8'd127, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 
            -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 8'd4, 8'd125, 8'd125, -8'd76, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 
            -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd67, 8'd113, 8'd125, 8'd125, -8'd76, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 
            -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd7, 8'd125, 8'd125, 8'd90, -8'd88, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 
            -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd7, 8'd125, 8'd78, -8'd110, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 
            -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
            12544'd0
        };


        for (i = 0; i < IFM_SIZE; i = i + 4) begin
            ram.mem[0 + (i / 4)][ 7: 0] = input_data[8*(IFM_SIZE - 1 - i) +: 8];
            ram.mem[0 + (i / 4)][15: 8] = input_data[8*(IFM_SIZE - 2 - i) +: 8];
            ram.mem[0 + (i / 4)][23:16] = input_data[8*(IFM_SIZE - 3 - i) +: 8];
            ram.mem[0 + (i / 4)][31:24] = input_data[8*(IFM_SIZE - 4 - i) +: 8];
        end

        // $display("INPUT RESULT");
        // for (int i = 0; i < 0 + (28 * 28 * 3) / 4; i = i + 1) begin
        //     $display("%d %d %d %d", 
        //         $signed(ram.mem[i][ 7: 0]), 
        //         $signed(ram.mem[i][15: 8]), 
        //         $signed(ram.mem[i][23:16]), 
        //         $signed(ram.mem[i][31:24])
        //     ); 
        // end
        // $display("*************");
        

        // Kernel 
        filter_data = {
           -8'd72, -8'd127, -8'd17, 8'd90, 8'd41, 8'd67, 8'd102, 8'd103, 8'd67,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd78, 8'd73, 8'd66, 8'd31, 8'd108, 8'd46, 8'd0, 8'd4, 8'd127,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd93, 8'd15, -8'd83, 8'd68, -8'd26, -8'd102, 8'd24, -8'd127, -8'd85,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd65, 8'd78, 8'd95, 8'd110, 8'd70, 8'd61, 8'd127, 8'd20, -8'd107,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd26, 8'd9, -8'd41, 8'd17, 8'd0, -8'd125, 8'd44, -8'd127, -8'd62,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd27, -8'd24, -8'd127, -8'd73, -8'd111, -8'd9, -8'd114, -8'd5, 8'd24,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd106, -8'd47, -8'd127, 8'd11, -8'd96, -8'd37, -8'd22, -8'd126, -8'd1,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd99, 8'd37, 8'd65, 8'd76, -8'd127, 8'd0, 8'd49, 8'd0, -8'd87,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd52, 8'd69, 8'd63, 8'd42, 8'd70, 8'd32, -8'd57, -8'd127, -8'd88,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd62, 8'd127, 8'd65, -8'd26, 8'd114, 8'd83, 8'd32, 8'd38, 8'd113,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd109, -8'd66, 8'd18, -8'd52, 8'd95, 8'd65, -8'd113, 8'd15, -8'd127,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd40, 8'd127, 8'd51, 8'd19, 8'd89, 8'd93, -8'd12, 8'd98, 8'd62,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd34, -8'd54, -8'd92, -8'd60, -8'd96, -8'd35, 8'd109, 8'd127, 8'd101,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd87, 8'd82, 8'd38, -8'd68, -8'd29, 8'd42, 8'd10, -8'd127, 8'd31,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd15, 8'd85, 8'd58, 8'd42, 8'd83, 8'd66, 8'd127, 8'd79, 8'd23,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd38, 8'd47, 8'd84, 8'd83, 8'd59, 8'd127, -8'd15, 8'd122, 8'd115,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd23, 8'd40, 8'd104, 8'd34, 8'd125, 8'd59, 8'd7, 8'd127, 8'd28,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd127, -8'd42, 8'd61, -8'd32, 8'd81, 8'd50, 8'd53, 8'd70, -8'd71,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd102, 8'd43, -8'd127, -8'd8, 8'd55, 8'd59, -8'd73, -8'd114, -8'd125,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd117, -8'd20, 8'd35, -8'd105, 8'd84, -8'd124, 8'd1, 8'd8, 8'd127,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd25, 8'd99, 8'd98, 8'd53, 8'd83, 8'd89, 8'd127, 8'd108, 8'd31,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd81, 8'd27, 8'd69, -8'd28, -8'd25, 8'd78, -8'd106, -8'd127, -8'd26,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd28, -8'd10, -8'd126, 8'd36, 8'd105, -8'd9, 8'd61, 8'd127, 8'd53,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd97, -8'd107, 8'd18, 8'd34, 8'd102, 8'd49, 8'd125, 8'd115, 8'd127,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd94, 8'd28, 8'd14, 8'd83, 8'd43, 8'd58, 8'd52, 8'd11, 8'd127,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd124, -8'd26, -8'd88, 8'd81, -8'd127, 8'd70, 8'd45, -8'd125, -8'd14,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd7, 8'd113, 8'd37, -8'd127, 8'd90, 8'd66, -8'd118, -8'd31, 8'd111,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd100, 8'd89, -8'd100, 8'd119, 8'd7, 8'd21, -8'd117, -8'd57, -8'd127,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd127, -8'd77, 8'd21, 8'd74, -8'd124, -8'd106, -8'd42, 8'd56, -8'd81,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd88, 8'd118, 8'd106, -8'd89, -8'd2, -8'd4, -8'd71, -8'd127, -8'd68,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd25, 8'd90, -8'd16, 8'd82, 8'd49, -8'd119, 8'd95, 8'd10, -8'd127,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd9, 8'd15, 8'd97, 8'd76, 8'd44, 8'd127, -8'd79, -8'd73, 8'd39,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0
        };
        
 
        for (i = 0; i < KER_SIZE; i = i + 4) begin
            ram.mem[1500 + (i / 4)][ 7: 0] = filter_data[8*(KER_SIZE - 1 - i) +: 8];
            ram.mem[1500 + (i / 4)][15: 8] = filter_data[8*(KER_SIZE - 2 - i) +: 8];
            ram.mem[1500 + (i / 4)][23:16] = filter_data[8*(KER_SIZE- 3 - i) +: 8];
            ram.mem[1500 + (i / 4)][31:24] = filter_data[8*(KER_SIZE - 4 - i) +: 8];
        end

        // $display("KERNEL RESULT");
        // for (int i = 1500; i < 1500 + KER_SIZE / 4; i = i + 1) begin
        //     $display("%d %d %d %d", 
        //         $signed(ram.mem[i][ 7: 0]), 
        //         $signed(ram.mem[i][15: 8]), 
        //         $signed(ram.mem[i][23:16]), 
        //         $signed(ram.mem[i][31:24])
        //     ); 
        // end
        // $display("*************");

        // Bias
        bias_data = {
            32'd32, -32'd959, 32'd13568, -32'd1270, -32'd17005, 32'd26575, 32'd19294, -32'd54577, 32'd7416, -32'd304, -32'd59788, 32'd241, 32'd10772, -32'd49339, -32'd639, -32'd430, -32'd459, -32'd5451, -32'd55838, -32'd64084, -32'd2100, 32'd14497, -32'd714, -32'd189, 32'd1789, -32'd68024, -32'd6961, -32'd46619, -32'd69764, 32'd12967, -32'd5197, 32'd49
        };

        for (i = 0; i < BIS_SIZE; i = i + 1) begin
            ram.mem[1400 + i] = bias_data[32*(BIS_SIZE - 1 - i) +: 32];
        end

        // $display("BIAS RESULT");
        // for (int i = 1400; i < 1400 + 3; i = i + 1) begin
        //     $display("%d ", 
        //         $signed(ram.mem[i])
        //     ); 
        // end
        // $display("*************");
    end
/*******************/

`elsif ML_TC2
/* Test case 6 */
     /* 
        Description:
           - Input Feature Map's size : 13 x 13 x 33     => 5408
           - Kernel's size            : 3 x 3 x 33 x 32 => 9216
           - Output Feature Map's size: 11 x 11 x 32     => 150
           - Bias's size              : 32 * 32         =>  1024
    */



    localparam 
        IFM_SIZE = 13 * 13 * 33,
        KER_SIZE = 3 * 3 * 33 * 32,
        OFM_SIZE = 11 * 11 * 32     ,
        BIS_SIZE = 32,
        OUTPUT_HEIGHT = 5,
        OUTPUT_WIDTH = 5,
        OUTPUT_DEPTH = 32;


    initial begin
        // al_accel_mem_read_ready = 1'b 0;
        // al_accel_mem_write_ready = 1'b 0;
        // #10
        // repeat (2000) @(posedge clk) begin
        //     #2 al_accel_mem_read_ready = $random;
        // end
        // #10 
        al_accel_mem_read_ready    = 1'b 1;
        al_accel_mem_write_ready   = 1'b 1;
    end

    initial begin
        al_accel_cfgreg_di   = 32'd 0; al_accel_cfgreg_sel = 5'd 0; 
        al_accel_cfgreg_wenb =  1'd 0;
        al_accel_flow_enb    =  1'b 0;
        #42
        al_accel_cfgreg_wenb =  1'd 1;
    // Config Data
        #10 // i_base_addr
        al_accel_cfgreg_di   = 32'd 0000;       al_accel_cfgreg_sel = 5'd 0; 

        #10 // kw_base_addr
        al_accel_cfgreg_di   = 32'd 6000;       al_accel_cfgreg_sel = 5'd 1; 

        #10 // o_base_addr
        al_accel_cfgreg_di   = 32'd 16000;       al_accel_cfgreg_sel = 5'd 2; 

        #10 // b_base_addr
        al_accel_cfgreg_di   = 32'd 5600;       al_accel_cfgreg_sel = 5'd 3; 

        #10 // ps_base_addr
        al_accel_cfgreg_di   = 32'd 20000;       al_accel_cfgreg_sel = 5'd 4; 

        #10 // {stride_height, stride_width, cfg_act_func_typ, cfg_layer_typ}
        al_accel_cfgreg_di   = {16'd 0, 4'd 1, 4'd 1, RELU, MIXED}; al_accel_cfgreg_sel = 5'd 5; 

        #10 // {weight_kernel_patch_height, weight_kernel_patch_width}
        al_accel_cfgreg_di   = {16'd 3, 16'd 3}; al_accel_cfgreg_sel = 5'd 6; 

        #10 // {nok_ofm_depth, kernel_ifm_depth} 
        al_accel_cfgreg_di   = {16'd 32, 16'd 33}; al_accel_cfgreg_sel = 5'd 7;
        
        #10 // {ifm_height, ifm_width}  
        al_accel_cfgreg_di   = {16'd 13, 16'd 13}; al_accel_cfgreg_sel = 5'd 8;

        #10 // {ofm_height, ofm_width}
        al_accel_cfgreg_di   = {16'd 11, 16'd 11}; al_accel_cfgreg_sel = 5'd 9;

        #10 // {output2D_size, input2D_size}  
        al_accel_cfgreg_di   = {16'd 121, 16'd 169}; al_accel_cfgreg_sel = 5'd 10;

        #10 // kernel3D_size
        al_accel_cfgreg_di   = {16'd  0, 16'd 297}; al_accel_cfgreg_sel = 5'd 11;

    // Output Quantize Buffer
        #10 // output_quant_sel 0
        al_accel_cfgreg_di   = {24'd 0, 8'd 0} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1689551407 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 12} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 1
        al_accel_cfgreg_di   = {24'd 0, 8'd 1} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1204010513 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 9} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 2
        al_accel_cfgreg_di   = {24'd 0, 8'd 2} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 2140008272 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 10} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 3
        al_accel_cfgreg_di   = {24'd 0, 8'd 3} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1909323516 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 10} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 4
        al_accel_cfgreg_di   = {24'd 0, 8'd 4} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1725018846 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 12} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 5
        al_accel_cfgreg_di   = {24'd 0, 8'd 5} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 2048260720 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 10} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 6
        al_accel_cfgreg_di   = {24'd 0, 8'd 6} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 2126767021 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 10} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 7
        al_accel_cfgreg_di   = {24'd 0, 8'd 7} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1808926684 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 10} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 8
        al_accel_cfgreg_di   = {24'd 0, 8'd 8} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1463903110 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 10} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 9
        al_accel_cfgreg_di   = {24'd 0, 8'd 9} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1253391477 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 9} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 10
        al_accel_cfgreg_di   = {24'd 0, 8'd 10} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1548369488 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 12} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 11
        al_accel_cfgreg_di   = {24'd 0, 8'd 11} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1854827854 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 12} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 12
        al_accel_cfgreg_di   = {24'd 0, 8'd 12} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1089899269 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 9} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 13
        al_accel_cfgreg_di   = {24'd 0, 8'd 13} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1700026496 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 12} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 14
        al_accel_cfgreg_di   = {24'd 0, 8'd 14} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 2095039993 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 10} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 15
        al_accel_cfgreg_di   = {24'd 0, 8'd 15} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1336030234 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 10} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 16
        al_accel_cfgreg_di   = {24'd 0, 8'd 16} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1663159508 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 12} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 17
        al_accel_cfgreg_di   = {24'd 0, 8'd 17} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1997878220 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 12} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 18
        al_accel_cfgreg_di   = {24'd 0, 8'd 18} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1660705979 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 12} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 19
        al_accel_cfgreg_di   = {24'd 0, 8'd 19} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1740647325 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 12} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 20
        al_accel_cfgreg_di   = {24'd 0, 8'd 20} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1385151967 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 10} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 21
        al_accel_cfgreg_di   = {24'd 0, 8'd 21} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1207776079 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 9} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 22
        al_accel_cfgreg_di   = {24'd 0, 8'd 22} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1712031603 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 10} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 23
        al_accel_cfgreg_di   = {24'd 0, 8'd 23} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1593821800 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 10} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 24
        al_accel_cfgreg_di   = {24'd 0, 8'd 24} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1368997244 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 10} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 25
        al_accel_cfgreg_di   = {24'd 0, 8'd 25} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1466326579 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 12} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 26
        al_accel_cfgreg_di   = {24'd 0, 8'd 26} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1582443027 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 10} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 27
        al_accel_cfgreg_di   = {24'd 0, 8'd 27} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1558951275 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 12} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 28
        al_accel_cfgreg_di   = {24'd 0, 8'd 28} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1682677520 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 10} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 29
        al_accel_cfgreg_di   = {24'd 0, 8'd 29} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1747796433 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 10} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 30
        al_accel_cfgreg_di   = {24'd 0, 8'd 30} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1716120888 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 12} ; al_accel_cfgreg_sel = 5'd 14;

        #10 // output_quant_sel 31
        al_accel_cfgreg_di   = {24'd 0, 8'd 31} ; al_accel_cfgreg_sel = 5'd 12;
        #10 // output_multiplier
        al_accel_cfgreg_di   = 32'd 1544083328 ; al_accel_cfgreg_sel = 5'd 13;
        #10 // output_shift
        al_accel_cfgreg_di   = {24'd 0, 8'd 10} ; al_accel_cfgreg_sel = 5'd 14;
    // Data Offset
        #10 // input_offset
        al_accel_cfgreg_di   = 32'd 128; al_accel_cfgreg_sel = 5'd 15;
        #10 // output_offset
        al_accel_cfgreg_di   = 32'd 128; al_accel_cfgreg_sel = 5'd 16;
        
        #10 // {ofm_pool_height,  ofm_pool_width}
        al_accel_cfgreg_di   = {16'd 5, 16'd 5}; al_accel_cfgreg_sel = 5'd 17;
        #10 // output2D_pool_size
        al_accel_cfgreg_di   = 32'd 25; al_accel_cfgreg_sel = 5'd 18;


    // Flow Run
        #10
        al_accel_cfgreg_wenb =  1'd 0;
        #10 
        al_accel_flow_enb    =  1'd 1;
        // #1000
        // al_accel_flow_enb    =  1'd 0;
        // #200
        al_accel_flow_enb    =  1'd 1;
		// repeat (2000) @(posedge clk) begin
        //     #2 al_accel_flow_enb = $random;
        // end
        // #10 
        al_accel_flow_enb    =  1'd 1;
    end

    reg [IFM_SIZE    * 8 - 1:0] input_data ; // Size: 7 x 7 x 3
    reg [KER_SIZE * 8 - 1:0] filter_data; // Size: 3 x 3 x 3 x 6
    reg [ BIS_SIZE  * 32              - 1:0] bias_data  ; // Size: 6
    integer i;
    initial begin
        for (i = 0; i < 4096; i = i + 1)
            ram.mem[i] = 32'd 0;

        // Input Initilization
        input_data = {
        /* z = 0 */
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd90, -8'd46, -8'd63, -8'd110, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd27, 8'd58, 8'd42, 8'd63, 8'd63, 8'd69, 8'd65, 8'd61, -8'd23, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd127, -8'd128, -8'd128, -8'd111, -8'd93, -8'd81, -8'd73, -8'd13, -8'd43, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd110, -8'd3, -8'd34, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd41, -8'd11, -8'd96, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd111, -8'd26, -8'd46, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd126, -8'd20, 8'd4, -8'd103, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd66, 8'd9, -8'd36, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd108, 8'd11, -8'd24, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd44, 8'd3, -8'd52, -8'd119, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd56, -8'd35, -8'd117, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
    /* z = 1 */
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd98, -8'd102, -8'd119, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd40, -8'd2, -8'd5, -8'd21, -8'd39, -8'd39, -8'd39, -8'd40, -8'd114, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd70, -8'd36, -8'd15, 8'd1, -8'd2, -8'd1, 8'd23, 8'd27, -8'd65, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd120, -8'd115, -8'd107, -8'd10, -8'd17, -8'd82, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd52, -8'd11, -8'd28, -8'd119, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd108, -8'd20, -8'd15, -8'd89, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd126, -8'd50, -8'd14, -8'd44, -8'd123, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd73, -8'd14, -8'd16, -8'd93, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd106, -8'd13, -8'd15, -8'd59, -8'd126, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd52, 8'd28, -8'd14, -8'd115, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd28, 8'd13, -8'd32, -8'd122, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
    /* z = 2 */
        -8'd99, -8'd99, -8'd99, -8'd99, -8'd99, -8'd99, -8'd99, -8'd99, -8'd99, -8'd99, -8'd99, -8'd99, -8'd99,
        -8'd99, -8'd99, -8'd99, -8'd99, -8'd99, -8'd99, -8'd99, -8'd99, -8'd99, -8'd99, -8'd99, -8'd99, -8'd99,
        -8'd99, -8'd99, -8'd99, -8'd99, -8'd99, -8'd97, -8'd99, -8'd99, -8'd99, -8'd99, -8'd99, -8'd99, -8'd99,
        -8'd99, -8'd99, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd84, -8'd99, -8'd99,
        -8'd99, -8'd99, -8'd111, -8'd94, -8'd110, -8'd89, -8'd92, -8'd91, -8'd94, -8'd115, -8'd6, -8'd99, -8'd99,
        -8'd99, -8'd99, -8'd99, -8'd99, -8'd99, -8'd96, -8'd97, -8'd95, -8'd128, -8'd11, -8'd10, -8'd99, -8'd99,
        -8'd99, -8'd99, -8'd99, -8'd99, -8'd99, -8'd99, -8'd99, -8'd109, -8'd128, -8'd6, -8'd75, -8'd99, -8'd99,
        -8'd99, -8'd99, -8'd99, -8'd99, -8'd99, -8'd99, -8'd99, -8'd128, 8'd0, -8'd15, -8'd99, -8'd99, -8'd99,
        -8'd99, -8'd99, -8'd99, -8'd99, -8'd99, -8'd99, -8'd112, -8'd119, -8'd1, -8'd87, -8'd99, -8'd99, -8'd99,
        -8'd99, -8'd99, -8'd99, -8'd99, -8'd99, -8'd99, -8'd128, -8'd8, -8'd22, -8'd99, -8'd99, -8'd99, -8'd99,
        -8'd99, -8'd99, -8'd99, -8'd99, -8'd99, -8'd128, -8'd24, -8'd8, -8'd92, -8'd99, -8'd99, -8'd99, -8'd99,
        -8'd99, -8'd99, -8'd99, -8'd99, -8'd110, -8'd128, -8'd11, -8'd65, -8'd99, -8'd99, -8'd99, -8'd99, -8'd99,
        -8'd99, -8'd99, -8'd99, -8'd99, -8'd128, -8'd57, -8'd15, -8'd82, -8'd99, -8'd99, -8'd99, -8'd99, -8'd99,
    /* z = 3 */
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd117, -8'd109, -8'd119, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd75, -8'd2, -8'd27, -8'd50, -8'd59, -8'd58, -8'd55, -8'd57, -8'd59, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd64, -8'd25, -8'd12, 8'd4, 8'd3, 8'd8, 8'd11, 8'd36, -8'd19, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd120, -8'd114, -8'd110, -8'd55, 8'd26, -8'd56, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd121, 8'd37, 8'd23, -8'd117, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd47, 8'd25, -8'd68, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd114, 8'd29, 8'd7, -8'd125, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 8'd25, 8'd34, -8'd77, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd60, 8'd41, -8'd25, -8'd127, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd121, 8'd26, 8'd26, -8'd105, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd59, 8'd59, 8'd11, -8'd120, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
    /* z = 4 */
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
    /* z = 5 */
        -8'd78, -8'd78, -8'd78, -8'd78, -8'd78, -8'd78, -8'd78, -8'd78, -8'd78, -8'd78, -8'd78, -8'd78, -8'd78,
        -8'd78, -8'd78, -8'd78, -8'd78, -8'd78, -8'd78, -8'd78, -8'd78, -8'd78, -8'd78, -8'd78, -8'd78, -8'd78,
        -8'd78, -8'd78, -8'd71, -8'd78, -8'd78, -8'd78, -8'd78, -8'd78, -8'd78, -8'd78, -8'd78, -8'd78, -8'd78,
        -8'd78, -8'd78, -8'd70, -8'd128, -8'd128, -8'd127, -8'd113, -8'd113, -8'd113, -8'd115, -8'd89, -8'd78, -8'd78,
        -8'd78, -8'd78, -8'd94, -8'd97, -8'd118, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd89, -8'd78, -8'd78,
        -8'd78, -8'd78, -8'd78, -8'd78, -8'd78, -8'd78, -8'd78, -8'd73, -8'd74, -8'd128, -8'd75, -8'd78, -8'd78,
        -8'd78, -8'd78, -8'd78, -8'd78, -8'd78, -8'd78, -8'd78, -8'd73, -8'd128, -8'd78, -8'd76, -8'd78, -8'd78,
        -8'd78, -8'd78, -8'd78, -8'd78, -8'd78, -8'd78, -8'd73, -8'd85, -8'd128, -8'd76, -8'd78, -8'd78, -8'd78,
        -8'd78, -8'd78, -8'd78, -8'd78, -8'd78, -8'd77, -8'd70, -8'd128, -8'd77, -8'd75, -8'd78, -8'd78, -8'd78,
        -8'd78, -8'd78, -8'd78, -8'd78, -8'd78, -8'd69, -8'd95, -8'd126, -8'd75, -8'd78, -8'd78, -8'd78, -8'd78,
        -8'd78, -8'd78, -8'd78, -8'd78, -8'd73, -8'd70, -8'd128, -8'd74, -8'd76, -8'd78, -8'd78, -8'd78, -8'd78,
        -8'd78, -8'd78, -8'd78, -8'd78, -8'd74, -8'd128, -8'd128, -8'd78, -8'd78, -8'd78, -8'd78, -8'd78, -8'd78,
        -8'd78, -8'd78, -8'd78, -8'd78, -8'd89, -8'd128, -8'd71, -8'd76, -8'd78, -8'd78, -8'd78, -8'd78, -8'd78,
    /* z = 6 */
        -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90,
        -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90,
        -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90,
        -8'd90, -8'd90, -8'd97, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd93, -8'd90, -8'd90,
        -8'd90, -8'd90, -8'd107, -8'd102, -8'd126, -8'd128, -8'd127, -8'd128, -8'd128, -8'd128, -8'd60, -8'd90, -8'd90,
        -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd99, -8'd93, -8'd49, -8'd90, -8'd90,
        -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd128, -8'd44, -8'd72, -8'd90, -8'd90,
        -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd117, -8'd70, -8'd43, -8'd90, -8'd90, -8'd90,
        -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd91, -8'd128, -8'd43, -8'd78, -8'd90, -8'd90, -8'd90,
        -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd128, -8'd58, -8'd44, -8'd90, -8'd90, -8'd90, -8'd90,
        -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd102, -8'd120, -8'd45, -8'd83, -8'd90, -8'd90, -8'd90, -8'd90,
        -8'd90, -8'd90, -8'd90, -8'd90, -8'd90, -8'd128, -8'd66, -8'd68, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90,
        -8'd90, -8'd90, -8'd90, -8'd90, -8'd114, -8'd128, -8'd46, -8'd79, -8'd90, -8'd90, -8'd90, -8'd90, -8'd90,
    /* z = 7 */
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
    /* z = 8 */
        -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd113,
        -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd113,
        -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd113,
        -8'd113, -8'd113, -8'd67, -8'd30, -8'd60, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd119, -8'd113, -8'd113,
        -8'd113, -8'd113, -8'd33, 8'd9, 8'd24, 8'd19, 8'd7, 8'd1, 8'd6, -8'd56, -8'd59, -8'd113, -8'd113,
        -8'd113, -8'd113, -8'd113, -8'd113, -8'd111, -8'd100, -8'd93, -8'd88, -8'd128, -8'd38, -8'd61, -8'd113, -8'd113,
        -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd123, -8'd51, -8'd29, -8'd100, -8'd113, -8'd113,
        -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd128, -8'd39, -8'd68, -8'd113, -8'd113, -8'd113,
        -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd126, -8'd54, -8'd44, -8'd107, -8'd113, -8'd113, -8'd113,
        -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd89, -8'd27, -8'd70, -8'd113, -8'd113, -8'd113, -8'd113,
        -8'd113, -8'd113, -8'd113, -8'd113, -8'd113, -8'd128, -8'd25, -8'd32, -8'd109, -8'd113, -8'd113, -8'd113, -8'd113,
        -8'd113, -8'd113, -8'd113, -8'd113, -8'd124, -8'd92, -8'd76, -8'd102, -8'd113, -8'd113, -8'd113, -8'd113, -8'd113,
        -8'd113, -8'd113, -8'd113, -8'd113, -8'd30, 8'd29, -8'd17, -8'd104, -8'd113, -8'd113, -8'd113, -8'd113, -8'd113,
    /* z = 9 */
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd95, -8'd88, -8'd104, -8'd124, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd11, 8'd16, 8'd12, -8'd6, -8'd18, -8'd17, -8'd19, -8'd21, -8'd108, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd43, -8'd18, 8'd10, 8'd24, 8'd17, 8'd18, 8'd38, 8'd74, -8'd64, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd127, -8'd114, -8'd109, -8'd102, 8'd31, 8'd36, -8'd89, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd32, 8'd34, -8'd8, -8'd123, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd108, 8'd26, 8'd31, -8'd99, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd125, -8'd24, 8'd30, -8'd29, -8'd123, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd61, 8'd30, 8'd23, -8'd102, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd104, 8'd24, 8'd40, -8'd57, -8'd125, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd33, 8'd70, 8'd16, -8'd118, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd1, 8'd58, -8'd17, -8'd125, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
    /* z = 10 */
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
    /* z = 11 */
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd93, -8'd81, -8'd99, -8'd123, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, 8'd6, 8'd46, 8'd45, 8'd24, 8'd7, 8'd6, 8'd3, 8'd2, -8'd96, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd28, 8'd1, 8'd34, 8'd51, 8'd53, 8'd53, 8'd59, 8'd108, -8'd56, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd126, -8'd111, -8'd106, -8'd101, 8'd57, 8'd71, -8'd79, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd17, 8'd74, 8'd9, -8'd120, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd113, 8'd56, 8'd71, -8'd91, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd126, 8'd0, 8'd59, -8'd13, -8'd124, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd59, 8'd72, 8'd63, -8'd94, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd108, 8'd47, 8'd72, -8'd41, -8'd125, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd20, 8'd109, 8'd53, -8'd119, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, 8'd15, 8'd99, -8'd2, -8'd123, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
    /* z = 12 */
        -8'd104, -8'd104, -8'd104, -8'd104, -8'd104, -8'd104, -8'd104, -8'd104, -8'd104, -8'd104, -8'd104, -8'd104, -8'd104,
        -8'd104, -8'd104, -8'd104, -8'd104, -8'd104, -8'd104, -8'd104, -8'd104, -8'd104, -8'd104, -8'd104, -8'd104, -8'd104,
        -8'd104, -8'd104, -8'd40, 8'd18, -8'd11, -8'd80, -8'd104, -8'd104, -8'd104, -8'd104, -8'd104, -8'd104, -8'd104,
        -8'd104, -8'd104, -8'd18, 8'd14, 8'd46, 8'd52, 8'd42, 8'd42, 8'd42, 8'd36, -8'd38, -8'd104, -8'd104,
        -8'd104, -8'd104, -8'd118, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd96, -8'd95, -8'd104, -8'd104,
        -8'd104, -8'd104, -8'd104, -8'd104, -8'd104, -8'd104, -8'd104, -8'd77, -8'd51, -8'd120, -8'd106, -8'd104, -8'd104,
        -8'd104, -8'd104, -8'd104, -8'd104, -8'd104, -8'd104, -8'd104, -8'd47, -8'd61, -8'd128, -8'd104, -8'd104, -8'd104,
        -8'd104, -8'd104, -8'd104, -8'd104, -8'd104, -8'd104, -8'd77, -8'd57, -8'd128, -8'd105, -8'd104, -8'd104, -8'd104,
        -8'd104, -8'd104, -8'd104, -8'd104, -8'd104, -8'd100, -8'd39, -8'd52, -8'd125, -8'd104, -8'd104, -8'd104, -8'd104,
        -8'd104, -8'd104, -8'd104, -8'd104, -8'd104, -8'd57, -8'd27, -8'd128, -8'd104, -8'd104, -8'd104, -8'd104, -8'd104,
        -8'd104, -8'd104, -8'd104, -8'd104, -8'd77, -8'd42, -8'd108, -8'd110, -8'd104, -8'd104, -8'd104, -8'd104, -8'd104,
        -8'd104, -8'd104, -8'd104, -8'd104, -8'd50, -8'd62, -8'd106, -8'd104, -8'd104, -8'd104, -8'd104, -8'd104, -8'd104,
        -8'd104, -8'd104, -8'd104, -8'd104, -8'd99, -8'd128, -8'd128, -8'd104, -8'd104, -8'd104, -8'd104, -8'd104, -8'd104,
    /* z = 13 */
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
    /* z = 14 */
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd112, -8'd68, -8'd78, -8'd113, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd35, 8'd19, 8'd9, 8'd16, 8'd15, 8'd18, 8'd17, 8'd10, -8'd45, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd57, -8'd39, -8'd17, 8'd2, 8'd7, 8'd17, 8'd12, 8'd56, -8'd22, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd127, -8'd119, -8'd114, -8'd113, 8'd26, 8'd63, -8'd77, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd60, 8'd71, 8'd25, -8'd124, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd124, 8'd25, 8'd59, -8'd91, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd43, 8'd59, 8'd6, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd93, 8'd73, 8'd67, -8'd98, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd121, 8'd20, 8'd68, -8'd43, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd61, 8'd91, 8'd56, -8'd113, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd35, 8'd78, 8'd5, -8'd125, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
    /* z = 15 */
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd93, -8'd84, -8'd103, -8'd125, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd31, 8'd2, 8'd10, 8'd6, -8'd4, -8'd5, -8'd8, -8'd9, -8'd94, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd72, -8'd48, -8'd25, -8'd8, 8'd1, 8'd3, 8'd17, 8'd46, -8'd75, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd127, -8'd121, -8'd118, -8'd109, 8'd18, 8'd5, -8'd93, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd26, 8'd18, -8'd47, -8'd121, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd111, 8'd9, 8'd6, -8'd97, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd126, -8'd13, 8'd13, -8'd61, -8'd126, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd59, 8'd16, 8'd2, -8'd100, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd107, 8'd17, 8'd9, -8'd76, -8'd127, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd28, 8'd50, -8'd9, -8'd119, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd8, 8'd35, -8'd56, -8'd122, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
    /* z = 16 */
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd108, -8'd91, -8'd100, -8'd122, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd28, -8'd2, -8'd9, -8'd11, -8'd19, -8'd19, -8'd20, -8'd21, -8'd87, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd63, -8'd47, -8'd25, -8'd4, -8'd1, 8'd1, -8'd5, 8'd35, -8'd67, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd126, -8'd119, -8'd116, -8'd114, 8'd21, 8'd27, -8'd102, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd51, 8'd31, -8'd31, -8'd124, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd123, 8'd16, 8'd27, -8'd108, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd34, 8'd25, -8'd49, -8'd127, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd94, 8'd32, 8'd23, -8'd111, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd121, 8'd18, 8'd28, -8'd80, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd53, 8'd47, 8'd10, -8'd122, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd24, 8'd37, -8'd46, -8'd125, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
    /* z = 17 */
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd115, -8'd104, -8'd127, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd49, -8'd58, -8'd80, -8'd69, -8'd59, -8'd55, -8'd51, -8'd59, -8'd84, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd96, -8'd128, -8'd128, -8'd128, -8'd128, -8'd122, -8'd120, -8'd105, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd8, 8'd5, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd99, 8'd12, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd9, -8'd17, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd77, 8'd11, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 8'd4, -8'd29, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd8, 8'd17, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd101, -8'd19, -8'd115, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd55, -8'd45, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
    /* z = 18 */
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
    /* z = 19 */
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
    /* z = 20 */
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd112, -8'd72, -8'd81, -8'd116, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd30, 8'd12, -8'd1, 8'd10, 8'd10, 8'd14, 8'd12, 8'd7, -8'd52, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd50, -8'd46, -8'd24, -8'd7, -8'd1, 8'd10, 8'd6, 8'd40, -8'd41, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd120, -8'd114, -8'd116, 8'd34, 8'd65, -8'd95, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd51, 8'd73, 8'd3, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd125, 8'd33, 8'd59, -8'd108, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd34, 8'd60, -8'd14, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd89, 8'd75, 8'd64, -8'd114, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd122, 8'd29, 8'd68, -8'd62, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd53, 8'd88, 8'd39, -8'd122, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd23, 8'd67, -8'd18, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
    /* z = 21 */
        -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd94,
        -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd94,
        -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd94,
        -8'd94, -8'd94, -8'd44, -8'd66, -8'd91, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd107, -8'd94, -8'd94,
        -8'd94, -8'd94, -8'd22, 8'd21, 8'd33, 8'd15, 8'd17, 8'd16, 8'd7, -8'd71, -8'd79, -8'd94, -8'd94,
        -8'd94, -8'd94, -8'd94, -8'd94, -8'd91, -8'd82, -8'd69, -8'd66, -8'd79, -8'd124, -8'd69, -8'd94, -8'd94,
        -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd86, -8'd120, -8'd51, -8'd81, -8'd94, -8'd94,
        -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd75, -8'd98, -8'd62, -8'd94, -8'd94, -8'd94,
        -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd98, -8'd128, -8'd63, -8'd83, -8'd94, -8'd94, -8'd94,
        -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd81, -8'd119, -8'd71, -8'd64, -8'd94, -8'd94, -8'd94, -8'd94,
        -8'd94, -8'd94, -8'd94, -8'd94, -8'd94, -8'd103, -8'd119, -8'd55, -8'd87, -8'd94, -8'd94, -8'd94, -8'd94,
        -8'd94, -8'd94, -8'd94, -8'd94, -8'd83, -8'd120, -8'd128, -8'd88, -8'd94, -8'd94, -8'd94, -8'd94, -8'd94,
        -8'd94, -8'd94, -8'd94, -8'd94, -8'd6, 8'd2, -8'd40, -8'd86, -8'd94, -8'd94, -8'd94, -8'd94, -8'd94,
    /* z = 22 */
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd93, -8'd59, -8'd72, -8'd115, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd43, 8'd18, 8'd17, 8'd25, 8'd23, 8'd26, 8'd22, 8'd23, -8'd50, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd89, -8'd87, -8'd79, -8'd79, 8'd20, -8'd28, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd118, -8'd53, -8'd30, -8'd93, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd97, -8'd47, -8'd39, -8'd122, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd118, -8'd66, -8'd42, -8'd99, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd127, -8'd72, -8'd43, -8'd48, -8'd126, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd104, -8'd40, -8'd45, -8'd104, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd117, -8'd52, -8'd39, -8'd85, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd100, -8'd20, 8'd11, -8'd115, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd115, -8'd43, -8'd50, -8'd124, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
    /* z = 23 */
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd80, -8'd40, -8'd63, -8'd111, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd18, 8'd51, 8'd42, 8'd47, 8'd56, 8'd61, 8'd56, 8'd54, -8'd43, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd118, -8'd128, -8'd128, -8'd106, -8'd89, -8'd77, -8'd59, -8'd16, -8'd63, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd103, 8'd29, -8'd4, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd29, 8'd18, -8'd91, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd104, 8'd5, -8'd22, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd125, -8'd8, 8'd30, -8'd101, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd59, 8'd38, -8'd22, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd102, 8'd39, 8'd9, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd31, 8'd35, -8'd44, -8'd126, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd28, -8'd3, -8'd114, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
    /* z = 24 */
        -8'd126, -8'd126, -8'd126, -8'd126, -8'd126, -8'd126, -8'd126, -8'd126, -8'd126, -8'd126, -8'd126, -8'd126, -8'd126,
        -8'd126, -8'd126, -8'd126, -8'd126, -8'd126, -8'd126, -8'd126, -8'd126, -8'd126, -8'd126, -8'd126, -8'd126, -8'd126,
        -8'd126, -8'd126, -8'd98, -8'd91, -8'd106, -8'd122, -8'd126, -8'd126, -8'd126, -8'd126, -8'd126, -8'd126, -8'd126,
        -8'd126, -8'd126, -8'd70, -8'd21, -8'd13, -8'd20, -8'd29, -8'd29, -8'd29, -8'd32, -8'd90, -8'd126, -8'd126,
        -8'd126, -8'd126, -8'd104, -8'd64, -8'd50, -8'd34, -8'd29, -8'd27, -8'd5, -8'd3, -8'd52, -8'd126, -8'd126,
        -8'd126, -8'd126, -8'd126, -8'd126, -8'd126, -8'd122, -8'd117, -8'd106, -8'd43, -8'd39, -8'd69, -8'd126, -8'd126,
        -8'd126, -8'd126, -8'd126, -8'd126, -8'd126, -8'd126, -8'd126, -8'd66, -8'd42, -8'd37, -8'd113, -8'd126, -8'd126,
        -8'd126, -8'd126, -8'd126, -8'd126, -8'd126, -8'd126, -8'd107, -8'd53, -8'd41, -8'd75, -8'd126, -8'd126, -8'd126,
        -8'd126, -8'd126, -8'd126, -8'd126, -8'd126, -8'd123, -8'd63, -8'd42, -8'd47, -8'd120, -8'd126, -8'd126, -8'd126,
        -8'd126, -8'd126, -8'd126, -8'd126, -8'd126, -8'd75, -8'd37, -8'd38, -8'd80, -8'd126, -8'd126, -8'd126, -8'd126,
        -8'd126, -8'd126, -8'd126, -8'd126, -8'd105, -8'd42, -8'd34, -8'd56, -8'd122, -8'd126, -8'd126, -8'd126, -8'd126,
        -8'd126, -8'd126, -8'd126, -8'd126, -8'd66, 8'd3, -8'd26, -8'd105, -8'd126, -8'd126, -8'd126, -8'd126, -8'd126,
        -8'd126, -8'd126, -8'd126, -8'd126, -8'd59, -8'd16, -8'd39, -8'd116, -8'd126, -8'd126, -8'd126, -8'd126, -8'd126,
    /* z = 25 */
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
    /* z = 26 */
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd109, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd31, -8'd79, -8'd82, -8'd125, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd58, -8'd61, -8'd43, -8'd38, -8'd57, -8'd68, -8'd16, -8'd2, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd126, -8'd123, -8'd113, -8'd42, -8'd78, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd53, -8'd49, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd115, -8'd29, -8'd87, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd59, -8'd60, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd69, -8'd36, -8'd122, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd111, -8'd52, -8'd62, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd53, -8'd35, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd23, -8'd34, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
    /* z = 27 */
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
    /* z = 28 */
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
    /* z = 29 */
        -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd101,
        -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd101,
        -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd101,
        -8'd101, -8'd101, -8'd77, -8'd98, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd109, -8'd101, -8'd101,
        -8'd101, -8'd101, 8'd7, 8'd43, 8'd47, 8'd48, 8'd54, 8'd49, 8'd31, -8'd57, -8'd98, -8'd101, -8'd101,
        -8'd101, -8'd101, -8'd101, -8'd101, -8'd97, -8'd79, -8'd67, -8'd58, -8'd109, -8'd80, -8'd80, -8'd101, -8'd101,
        -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd109, -8'd98, -8'd59, -8'd93, -8'd101, -8'd101,
        -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd120, -8'd79, -8'd77, -8'd101, -8'd101, -8'd101,
        -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd112, -8'd105, -8'd79, -8'd91, -8'd101, -8'd101, -8'd101,
        -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd102, -8'd128, -8'd66, -8'd77, -8'd101, -8'd101, -8'd101, -8'd101,
        -8'd101, -8'd101, -8'd101, -8'd101, -8'd101, -8'd128, -8'd71, -8'd58, -8'd95, -8'd101, -8'd101, -8'd101, -8'd101,
        -8'd101, -8'd101, -8'd101, -8'd101, -8'd110, -8'd128, -8'd124, -8'd97, -8'd101, -8'd101, -8'd101, -8'd101, -8'd101,
        -8'd101, -8'd101, -8'd101, -8'd101, -8'd19, 8'd13, -8'd31, -8'd94, -8'd101, -8'd101, -8'd101, -8'd101, -8'd101,
    /* z = 30 */
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd117, -8'd126, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd102, -8'd123, -8'd121, -8'd128, -8'd128, -8'd128, -8'd78, -8'd45, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd127, -8'd79, -8'd101, -8'd77, -8'd93, -8'd79, -8'd73, 8'd18, 8'd7, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd126, -8'd128, -8'd125, -8'd128, 8'd42, -8'd46, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 8'd25, 8'd39, -8'd127, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 8'd44, -8'd65, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 8'd28, 8'd39, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd58, 8'd36, -8'd77, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, 8'd38, -8'd2, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd88, 8'd33, -8'd112, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd14, 8'd29, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
    /* z = 31 */
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd122, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd16, 8'd3, -8'd9, -8'd61, -8'd87, -8'd91, -8'd87, -8'd94, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd44, -8'd23, 8'd10, 8'd21, 8'd22, 8'd17, 8'd34, 8'd6, -8'd109, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd125, -8'd116, -8'd114, -8'd113, -8'd35, -8'd57, -8'd102, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd42, -8'd31, -8'd82, -8'd120, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd117, -8'd23, -8'd51, -8'd104, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd127, -8'd55, -8'd47, -8'd100, -8'd127, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd128, -8'd64, -8'd33, -8'd51, -8'd104, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd111, -8'd35, -8'd50, -8'd87, -8'd127, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd41, -8'd15, -8'd96, -8'd126, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        -8'd128, -8'd128, -8'd128, -8'd128, -8'd10, 8'd12, -8'd77, -8'd121, -8'd128, -8'd128, -8'd128, -8'd128, -8'd128,
        1352'd0
    };

        for (i = 0; i < (IFM_SIZE); i = i + 4) begin
            ram.mem[0 + (i / 4)][ 7: 0] = input_data[8*((IFM_SIZE) - 1 - i) +: 8];
            ram.mem[0 + (i / 4)][15: 8] = input_data[8*((IFM_SIZE) - 2 - i) +: 8];
            ram.mem[0 + (i / 4)][23:16] = input_data[8*((IFM_SIZE) - 3 - i) +: 8];
            ram.mem[0 + (i / 4)][31:24] = input_data[8*((IFM_SIZE) - 4 - i) +: 8];
        end
        
        // $display("INPUT RESULT");
        // for (int i = 0; i < 0 + IFM_SIZE / 4; i = i + 1) begin
        //     $display("%d %d %d %d", 
        //         $signed(ram.mem[i][ 7: 0]), 
        //         $signed(ram.mem[i][15: 8]), 
        //         $signed(ram.mem[i][23:16]), 
        //         $signed(ram.mem[i][31:24])
        //     ); 
        // end
        // $display("*************");

        // Kernel 
       filter_data = {
            -8'd79, -8'd97, -8'd56, -8'd108, -8'd102, 8'd2, -8'd70, 8'd60, -8'd66,
            -8'd123, -8'd100, -8'd71, 8'd84, -8'd83, -8'd36, 8'd3, -8'd116, 8'd34,
            8'd38, -8'd87, 8'd57, 8'd60, 8'd21, -8'd3, -8'd49, -8'd82, -8'd57,
            8'd65, 8'd89, -8'd62, -8'd126, -8'd87, -8'd25, -8'd127, -8'd62, 8'd73,
            -8'd32, 8'd64, 8'd48, -8'd10, 8'd7, 8'd32, -8'd54, -8'd80, 8'd92,
            8'd4, 8'd33, -8'd65, 8'd87, 8'd2, -8'd73, -8'd107, -8'd15, -8'd77,
            8'd40, 8'd87, -8'd29, -8'd106, -8'd70, -8'd19, -8'd4, 8'd64, -8'd118,
            8'd79, -8'd64, 8'd82, -8'd40, 8'd78, 8'd0, -8'd29, 8'd95, -8'd94,
            8'd7, 8'd23, -8'd57, -8'd118, -8'd90, 8'd36, -8'd115, 8'd15, -8'd58,
            -8'd8, -8'd74, 8'd7, -8'd104, -8'd34, -8'd36, -8'd113, 8'd90, -8'd96,
            -8'd73, -8'd17, 8'd44, 8'd107, -8'd87, -8'd38, -8'd93, 8'd93, 8'd2,
            -8'd121, 8'd37, 8'd68, -8'd62, 8'd3, -8'd113, 8'd84, -8'd57, -8'd86,
            8'd54, -8'd92, -8'd40, -8'd109, 8'd50, 8'd16, 8'd87, 8'd64, 8'd41,
            8'd71, 8'd32, 8'd2, -8'd24, -8'd55, -8'd101, 8'd85, -8'd52, 8'd88,
            -8'd6, 8'd34, -8'd83, 8'd55, -8'd58, -8'd14, -8'd5, 8'd70, -8'd118,
            -8'd18, 8'd14, 8'd8, 8'd8, 8'd30, -8'd99, 8'd83, -8'd2, -8'd42,
            8'd75, -8'd25, -8'd41, 8'd4, -8'd3, -8'd79, 8'd40, -8'd104, -8'd24,
            -8'd70, 8'd92, 8'd52, -8'd74, 8'd13, 8'd99, -8'd73, -8'd73, 8'd19,
            -8'd28, -8'd32, -8'd71, -8'd4, -8'd4, 8'd77, 8'd7, 8'd54, -8'd46,
            8'd81, -8'd65, 8'd15, -8'd68, 8'd1, 8'd44, 8'd91, 8'd84, 8'd7,
            8'd24, -8'd92, -8'd78, 8'd17, -8'd109, -8'd69, -8'd74, -8'd49, 8'd57,
            -8'd29, 8'd12, -8'd28, -8'd92, 8'd44, -8'd119, 8'd39, 8'd20, 8'd43,
            -8'd101, 8'd70, 8'd63, -8'd7, 8'd39, 8'd81, -8'd104, -8'd46, -8'd11,
            8'd62, 8'd98, 8'd54, 8'd61, -8'd56, -8'd75, 8'd84, 8'd82, 8'd41,
            -8'd68, -8'd66, 8'd48, -8'd119, -8'd120, -8'd46, -8'd52, -8'd47, -8'd118,
            8'd31, 8'd33, 8'd102, 8'd81, 8'd27, -8'd96, -8'd15, 8'd39, 8'd61,
            -8'd23, 8'd33, 8'd75, 8'd106, -8'd68, -8'd46, -8'd4, 8'd25, -8'd9,
            -8'd63, -8'd32, -8'd14, 8'd97, -8'd15, -8'd109, -8'd33, -8'd100, 8'd101,
            -8'd71, 8'd10, 8'd82, -8'd71, 8'd51, 8'd110, -8'd25, 8'd13, -8'd21,
            8'd29, 8'd8, 8'd71, -8'd3, 8'd36, -8'd38, -8'd67, -8'd58, -8'd42,
            8'd73, 8'd68, 8'd31, -8'd108, -8'd107, -8'd102, -8'd64, -8'd88, 8'd69,
            8'd12, 8'd88, -8'd30, 8'd95, -8'd115, 8'd30, 8'd14, -8'd20, 8'd53,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd45, -8'd17, -8'd48, 8'd23, -8'd8, -8'd35, -8'd33, -8'd106, -8'd15,
            8'd41, 8'd3, 8'd9, 8'd20, 8'd11, -8'd7, -8'd2, -8'd47, -8'd2,
            8'd27, 8'd4, 8'd1, 8'd20, 8'd32, 8'd13, 8'd18, 8'd20, 8'd21,
            8'd24, 8'd31, -8'd5, 8'd29, 8'd5, -8'd27, 8'd25, 8'd0, -8'd20,
            8'd21, -8'd13, 8'd13, -8'd6, -8'd14, 8'd1, 8'd19, 8'd10, -8'd16,
            -8'd13, 8'd8, 8'd20, -8'd8, 8'd14, 8'd10, 8'd14, 8'd26, 8'd17,
            8'd3, -8'd13, 8'd16, 8'd22, 8'd30, -8'd4, 8'd11, 8'd19, -8'd14,
            -8'd8, 8'd13, -8'd17, 8'd15, 8'd19, -8'd12, 8'd6, 8'd13, -8'd2,
            8'd25, 8'd0, 8'd7, 8'd20, 8'd5, -8'd1, 8'd21, -8'd3, 8'd8,
            8'd29, 8'd27, 8'd10, 8'd45, -8'd9, -8'd16, -8'd27, -8'd52, -8'd17,
            -8'd19, -8'd14, -8'd13, 8'd2, -8'd3, -8'd10, 8'd18, 8'd9, -8'd3,
            8'd39, 8'd17, -8'd3, 8'd26, 8'd7, -8'd50, 8'd11, -8'd52, 8'd18,
            -8'd47, -8'd51, -8'd60, -8'd53, -8'd22, -8'd10, -8'd47, -8'd47, -8'd26,
            8'd14, -8'd8, -8'd6, 8'd5, 8'd20, 8'd12, 8'd16, 8'd12, 8'd8,
            8'd39, 8'd35, -8'd18, 8'd26, -8'd19, -8'd45, 8'd5, -8'd57, -8'd18,
            8'd31, 8'd24, -8'd11, 8'd26, -8'd10, -8'd39, -8'd21, -8'd56, -8'd19,
            8'd24, 8'd4, -8'd22, 8'd37, -8'd20, -8'd32, -8'd18, -8'd41, -8'd12,
            8'd19, -8'd60, -8'd127, -8'd41, -8'd62, 8'd14, -8'd70, -8'd43, 8'd57,
            8'd15, 8'd13, 8'd3, 8'd11, 8'd15, -8'd8, 8'd6, 8'd1, 8'd12,
            8'd18, -8'd10, 8'd1, -8'd10, 8'd8, -8'd7, 8'd15, 8'd7, -8'd6,
            8'd52, 8'd34, -8'd13, 8'd22, -8'd16, -8'd7, 8'd19, -8'd65, -8'd24,
            -8'd18, -8'd14, 8'd5, 8'd8, -8'd9, -8'd18, 8'd10, -8'd11, 8'd18,
            8'd51, 8'd12, -8'd40, 8'd13, -8'd27, -8'd32, -8'd21, -8'd71, -8'd27,
            8'd32, 8'd7, -8'd54, -8'd5, -8'd18, -8'd22, -8'd61, -8'd64, 8'd10,
            8'd33, 8'd25, 8'd17, 8'd30, -8'd3, -8'd8, 8'd14, -8'd25, -8'd15,
            8'd2, -8'd13, 8'd7, -8'd1, -8'd16, 8'd18, -8'd1, 8'd15, -8'd17,
            8'd9, 8'd9, -8'd43, -8'd3, -8'd69, -8'd49, -8'd85, -8'd114, 8'd16,
            -8'd7, -8'd10, -8'd5, 8'd16, -8'd1, -8'd13, -8'd12, 8'd13, 8'd0,
            8'd3, 8'd16, -8'd19, -8'd13, -8'd6, 8'd0, 8'd17, -8'd11, -8'd11,
            -8'd64, 8'd3, -8'd1, -8'd15, -8'd10, -8'd24, 8'd22, -8'd9, -8'd10,
            8'd74, 8'd36, 8'd14, 8'd29, 8'd24, -8'd22, 8'd27, -8'd24, -8'd49,
            8'd10, -8'd11, -8'd37, 8'd23, -8'd27, -8'd53, -8'd32, -8'd11, 8'd11,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd6, -8'd7, -8'd3, -8'd20, -8'd36, -8'd3, -8'd25, -8'd22, -8'd17,
            -8'd37, 8'd15, 8'd6, -8'd16, 8'd12, 8'd39, -8'd23, 8'd14, 8'd41,
            -8'd7, 8'd0, -8'd30, 8'd6, -8'd5, -8'd2, 8'd12, 8'd16, 8'd2,
            -8'd11, -8'd30, 8'd1, 8'd7, -8'd35, 8'd23, 8'd8, -8'd27, 8'd19,
            8'd1, 8'd16, -8'd17, -8'd14, -8'd12, -8'd10, -8'd16, 8'd16, 8'd1,
            8'd1, 8'd20, -8'd11, 8'd7, 8'd41, -8'd49, -8'd17, 8'd8, -8'd28,
            8'd31, 8'd30, -8'd49, 8'd3, 8'd4, -8'd29, 8'd29, 8'd21, -8'd20,
            -8'd14, 8'd13, 8'd14, -8'd5, -8'd1, -8'd20, 8'd14, -8'd1, -8'd5,
            -8'd10, -8'd45, -8'd6, 8'd7, -8'd42, -8'd21, 8'd16, -8'd28, 8'd4,
            -8'd35, -8'd8, 8'd43, -8'd33, -8'd3, 8'd36, -8'd43, -8'd29, 8'd47,
            -8'd22, 8'd16, 8'd22, 8'd6, -8'd8, -8'd21, 8'd5, 8'd17, -8'd7,
            -8'd24, -8'd7, 8'd55, -8'd27, -8'd2, 8'd29, -8'd45, -8'd13, 8'd73,
            8'd14, -8'd29, -8'd48, 8'd20, -8'd49, -8'd46, 8'd0, -8'd55, -8'd49,
            -8'd22, -8'd17, -8'd16, 8'd13, 8'd10, 8'd8, 8'd18, 8'd6, -8'd11,
            -8'd28, -8'd24, 8'd29, -8'd8, -8'd15, 8'd32, -8'd32, -8'd19, 8'd42,
            -8'd50, 8'd23, 8'd41, -8'd14, 8'd3, 8'd29, -8'd52, -8'd2, 8'd28,
            -8'd54, -8'd14, 8'd43, -8'd22, 8'd8, 8'd23, -8'd17, -8'd39, 8'd22,
            8'd0, -8'd23, 8'd39, -8'd43, 8'd9, -8'd47, -8'd27, -8'd66, -8'd57,
            8'd18, -8'd17, 8'd17, 8'd4, -8'd16, -8'd4, -8'd4, -8'd10, -8'd8,
            8'd19, -8'd14, -8'd6, -8'd4, 8'd8, 8'd15, 8'd17, -8'd4, 8'd3,
            -8'd42, -8'd5, 8'd44, -8'd1, -8'd8, 8'd42, -8'd31, -8'd25, 8'd41,
            -8'd31, 8'd8, 8'd4, 8'd14, 8'd22, -8'd26, 8'd32, 8'd4, 8'd3,
            -8'd9, -8'd55, 8'd30, -8'd18, -8'd41, 8'd15, -8'd40, -8'd38, 8'd46,
            -8'd30, 8'd5, 8'd2, -8'd7, -8'd29, 8'd9, -8'd43, -8'd9, 8'd28,
            -8'd28, -8'd9, 8'd8, 8'd17, -8'd9, 8'd22, -8'd10, 8'd14, 8'd3,
            -8'd6, -8'd20, 8'd8, -8'd14, -8'd13, 8'd12, -8'd15, -8'd21, -8'd5,
            -8'd85, 8'd11, 8'd85, -8'd62, 8'd10, 8'd79, -8'd36, 8'd26, 8'd127,
            -8'd20, -8'd2, -8'd9, 8'd6, -8'd20, -8'd12, 8'd6, 8'd5, 8'd3,
            8'd17, -8'd5, 8'd9, 8'd13, 8'd10, 8'd21, -8'd13, -8'd3, 8'd2,
            -8'd11, -8'd12, -8'd102, 8'd14, -8'd44, -8'd66, 8'd51, 8'd12, -8'd31,
            8'd14, -8'd46, 8'd71, 8'd12, -8'd61, 8'd37, -8'd1, -8'd111, -8'd8,
            -8'd44, 8'd13, 8'd17, -8'd33, 8'd4, 8'd32, -8'd12, 8'd12, 8'd38,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd16, -8'd50, -8'd14, 8'd45, 8'd10, -8'd71, 8'd24, 8'd51, 8'd4,
            -8'd1, 8'd12, 8'd53, -8'd20, -8'd40, -8'd50, 8'd60, 8'd32, 8'd7,
            -8'd24, -8'd18, 8'd13, -8'd58, -8'd27, -8'd1, -8'd10, -8'd10, -8'd35,
            8'd14, -8'd13, 8'd36, -8'd33, -8'd12, -8'd48, 8'd37, 8'd47, -8'd1,
            8'd3, -8'd10, -8'd23, -8'd19, -8'd6, 8'd21, 8'd22, 8'd11, 8'd8,
            8'd25, 8'd19, 8'd27, 8'd37, 8'd18, -8'd15, -8'd24, 8'd12, -8'd9,
            8'd0, 8'd16, 8'd16, -8'd18, 8'd11, -8'd27, 8'd14, -8'd18, -8'd31,
            -8'd9, 8'd8, -8'd3, 8'd14, 8'd11, 8'd1, 8'd7, 8'd12, 8'd8,
            8'd20, 8'd48, 8'd9, -8'd12, -8'd48, -8'd3, 8'd36, -8'd14, -8'd54,
            -8'd30, -8'd1, 8'd22, -8'd34, -8'd60, -8'd46, 8'd67, 8'd15, -8'd37,
            8'd20, -8'd18, -8'd19, -8'd6, -8'd13, 8'd9, 8'd3, -8'd8, -8'd24,
            -8'd35, -8'd1, 8'd47, -8'd58, -8'd85, -8'd63, 8'd43, 8'd58, -8'd18,
            -8'd13, -8'd15, -8'd59, 8'd98, 8'd62, -8'd10, -8'd8, -8'd3, -8'd7,
            -8'd11, -8'd8, -8'd5, -8'd1, 8'd17, 8'd19, -8'd23, 8'd23, 8'd18,
            -8'd1, -8'd19, 8'd39, -8'd5, -8'd30, -8'd36, 8'd57, 8'd16, -8'd23,
            -8'd29, -8'd6, 8'd22, 8'd3, -8'd38, -8'd59, 8'd34, 8'd15, -8'd33,
            -8'd46, -8'd25, 8'd18, -8'd35, -8'd37, -8'd60, 8'd37, 8'd40, -8'd12,
            -8'd39, -8'd127, 8'd21, -8'd71, -8'd91, -8'd61, -8'd21, -8'd52, -8'd68,
            8'd17, -8'd9, -8'd15, 8'd17, -8'd11, -8'd15, -8'd24, 8'd8, -8'd12,
            -8'd12, 8'd12, -8'd1, -8'd6, -8'd12, -8'd9, -8'd5, -8'd6, -8'd1,
            -8'd17, -8'd33, 8'd17, -8'd37, -8'd27, -8'd77, 8'd19, 8'd25, -8'd25,
            8'd20, 8'd9, 8'd2, -8'd17, 8'd15, 8'd28, 8'd38, -8'd19, -8'd24,
            -8'd76, -8'd36, -8'd17, 8'd59, -8'd6, -8'd70, 8'd54, 8'd43, 8'd4,
            -8'd43, -8'd66, 8'd10, 8'd48, -8'd5, -8'd37, 8'd50, 8'd8, -8'd15,
            8'd17, -8'd8, 8'd17, 8'd11, 8'd14, -8'd21, 8'd59, 8'd22, 8'd32,
            8'd4, 8'd9, 8'd23, 8'd12, -8'd22, -8'd15, 8'd14, 8'd4, -8'd7,
            -8'd41, 8'd6, 8'd19, -8'd75, -8'd67, 8'd49, 8'd82, 8'd127, 8'd31,
            -8'd1, 8'd6, -8'd11, -8'd6, 8'd12, -8'd24, 8'd23, 8'd2, 8'd12,
            8'd15, -8'd3, 8'd7, 8'd7, 8'd15, -8'd13, -8'd9, -8'd23, -8'd16,
            8'd102, 8'd42, 8'd8, 8'd15, 8'd44, 8'd44, 8'd35, 8'd20, -8'd28,
            -8'd80, -8'd72, -8'd16, -8'd36, -8'd42, -8'd91, 8'd12, 8'd38, -8'd40,
            8'd5, 8'd10, 8'd52, -8'd65, -8'd113, -8'd40, 8'd59, 8'd16, -8'd50,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd56, -8'd56, -8'd89, 8'd32, -8'd73, 8'd64, -8'd72, 8'd99, -8'd33,
            -8'd5, -8'd56, 8'd40, 8'd29, -8'd108, 8'd101, -8'd66, 8'd96, 8'd7,
            -8'd33, -8'd111, 8'd69, 8'd54, 8'd86, -8'd63, 8'd1, -8'd95, -8'd6,
            -8'd1, 8'd70, 8'd6, 8'd55, 8'd33, 8'd90, -8'd12, -8'd22, -8'd81,
            8'd1, 8'd100, -8'd35, -8'd4, 8'd58, -8'd43, -8'd2, 8'd57, -8'd37,
            -8'd115, 8'd70, 8'd19, 8'd29, -8'd46, -8'd77, -8'd119, -8'd3, -8'd5,
            8'd34, -8'd46, -8'd4, 8'd10, -8'd99, -8'd53, 8'd81, -8'd7, -8'd18,
            -8'd105, 8'd33, -8'd81, -8'd32, 8'd62, 8'd78, 8'd16, 8'd52, -8'd100,
            -8'd58, -8'd99, -8'd93, 8'd36, -8'd59, -8'd59, 8'd78, -8'd92, -8'd64,
            -8'd47, -8'd94, 8'd53, -8'd50, 8'd4, 8'd0, 8'd65, 8'd1, 8'd1,
            8'd73, 8'd77, -8'd42, -8'd36, 8'd88, 8'd44, -8'd10, 8'd48, -8'd55,
            -8'd69, 8'd7, -8'd81, -8'd127, -8'd77, 8'd43, -8'd17, -8'd49, -8'd99,
            8'd57, 8'd63, -8'd76, 8'd39, -8'd116, 8'd56, -8'd64, -8'd59, -8'd13,
            -8'd5, 8'd28, 8'd10, 8'd37, 8'd32, 8'd92, 8'd8, 8'd58, -8'd63,
            -8'd108, -8'd39, 8'd24, -8'd67, -8'd106, -8'd93, 8'd39, 8'd40, -8'd84,
            8'd51, -8'd23, -8'd24, 8'd74, 8'd22, -8'd111, -8'd95, -8'd83, -8'd73,
            -8'd48, 8'd29, 8'd19, -8'd4, -8'd99, 8'd78, -8'd119, 8'd51, -8'd64,
            8'd69, 8'd58, -8'd46, 8'd65, -8'd8, 8'd104, 8'd46, 8'd61, -8'd11,
            -8'd77, -8'd15, -8'd45, 8'd83, 8'd38, -8'd36, -8'd79, -8'd73, 8'd79,
            8'd30, -8'd102, -8'd74, 8'd89, 8'd91, -8'd31, 8'd45, 8'd23, -8'd35,
            8'd41, -8'd38, 8'd80, 8'd2, 8'd29, 8'd47, -8'd33, -8'd44, -8'd90,
            -8'd88, -8'd38, 8'd98, 8'd58, 8'd36, 8'd51, -8'd51, -8'd63, -8'd113,
            -8'd94, -8'd55, -8'd73, 8'd53, -8'd122, -8'd80, -8'd93, 8'd68, -8'd71,
            -8'd19, 8'd63, 8'd81, -8'd6, 8'd66, 8'd13, 8'd12, 8'd5, 8'd76,
            -8'd119, -8'd98, -8'd9, 8'd24, 8'd53, 8'd11, -8'd46, 8'd13, 8'd62,
            8'd26, 8'd82, 8'd30, -8'd84, -8'd54, -8'd65, -8'd82, 8'd51, -8'd61,
            8'd74, 8'd106, 8'd102, 8'd36, 8'd107, -8'd51, 8'd108, 8'd6, -8'd37,
            8'd85, -8'd14, -8'd38, 8'd89, -8'd13, 8'd4, -8'd29, -8'd90, -8'd107,
            8'd23, -8'd15, 8'd11, -8'd43, 8'd80, -8'd88, 8'd62, -8'd19, 8'd16,
            -8'd67, -8'd16, -8'd89, -8'd35, -8'd71, -8'd17, 8'd1, 8'd13, -8'd31,
            -8'd77, -8'd96, -8'd93, -8'd55, 8'd60, -8'd79, -8'd97, -8'd44, -8'd84,
            8'd61, 8'd47, -8'd88, -8'd85, -8'd3, -8'd27, -8'd51, -8'd95, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd46, 8'd18, 8'd39, 8'd32, 8'd49, 8'd35, -8'd53, -8'd40, -8'd17,
            -8'd9, -8'd15, -8'd6, 8'd22, 8'd13, 8'd40, -8'd29, -8'd10, 8'd15,
            -8'd39, -8'd17, -8'd2, -8'd64, -8'd86, -8'd60, -8'd18, -8'd41, -8'd25,
            8'd9, -8'd18, -8'd12, 8'd18, 8'd1, 8'd34, -8'd5, 8'd2, 8'd3,
            -8'd4, 8'd22, -8'd2, 8'd5, -8'd14, -8'd23, 8'd6, -8'd17, -8'd1,
            8'd0, 8'd23, 8'd1, -8'd50, -8'd37, -8'd29, -8'd18, -8'd13, -8'd4,
            -8'd23, 8'd2, 8'd27, -8'd64, -8'd43, -8'd38, -8'd19, -8'd56, -8'd6,
            8'd22, -8'd5, -8'd7, 8'd0, 8'd22, 8'd18, 8'd13, -8'd6, 8'd6,
            8'd4, -8'd17, -8'd27, 8'd37, 8'd20, 8'd16, 8'd30, 8'd67, 8'd37,
            -8'd3, -8'd35, -8'd19, 8'd23, 8'd27, 8'd16, 8'd3, -8'd25, -8'd18,
            -8'd12, -8'd11, 8'd3, 8'd4, 8'd23, -8'd13, -8'd13, 8'd4, -8'd16,
            -8'd18, -8'd43, -8'd50, 8'd36, 8'd38, 8'd21, -8'd42, -8'd13, -8'd35,
            8'd40, 8'd41, 8'd72, -8'd42, 8'd31, 8'd31, -8'd11, 8'd24, 8'd7,
            -8'd18, 8'd0, -8'd5, -8'd1, -8'd16, 8'd3, 8'd14, 8'd1, -8'd5,
            -8'd1, 8'd9, 8'd0, 8'd1, 8'd26, 8'd48, -8'd28, -8'd44, -8'd26,
            8'd8, 8'd0, -8'd11, 8'd22, 8'd26, 8'd42, -8'd6, -8'd9, 8'd2,
            8'd7, -8'd21, -8'd41, 8'd39, 8'd21, 8'd34, -8'd33, -8'd19, -8'd14,
            8'd2, 8'd17, 8'd8, -8'd69, -8'd20, 8'd9, -8'd22, -8'd17, -8'd11,
            8'd10, 8'd18, -8'd15, 8'd19, 8'd12, -8'd3, -8'd21, 8'd4, -8'd6,
            -8'd5, -8'd2, 8'd4, -8'd16, 8'd13, -8'd9, -8'd15, -8'd6, -8'd15,
            8'd12, -8'd5, -8'd14, 8'd22, 8'd49, 8'd33, -8'd44, -8'd47, -8'd18,
            -8'd38, -8'd1, -8'd14, 8'd29, -8'd19, -8'd52, 8'd16, 8'd33, 8'd27,
            8'd23, 8'd35, 8'd5, 8'd19, 8'd28, 8'd37, -8'd19, -8'd27, -8'd46,
            8'd31, 8'd26, 8'd7, -8'd11, 8'd50, 8'd46, -8'd62, -8'd56, -8'd30,
            8'd33, -8'd1, 8'd10, 8'd1, 8'd25, 8'd8, -8'd10, -8'd27, -8'd18,
            8'd16, -8'd21, -8'd13, -8'd14, -8'd17, 8'd2, 8'd7, -8'd11, 8'd13,
            -8'd33, -8'd71, -8'd96, 8'd34, 8'd7, -8'd29, 8'd10, 8'd12, -8'd30,
            8'd15, 8'd6, 8'd19, 8'd18, -8'd2, 8'd1, 8'd9, 8'd6, 8'd10,
            -8'd11, -8'd1, 8'd8, -8'd12, 8'd2, 8'd6, -8'd12, 8'd1, 8'd2,
            -8'd21, 8'd9, 8'd13, 8'd59, -8'd6, -8'd9, 8'd78, 8'd127, 8'd107,
            8'd19, -8'd14, -8'd39, -8'd46, -8'd36, -8'd36, -8'd34, -8'd61, -8'd47,
            -8'd23, 8'd5, -8'd41, 8'd19, 8'd51, 8'd36, -8'd9, 8'd36, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd33, 8'd10, 8'd23, -8'd36, -8'd30, -8'd42, -8'd13, -8'd26, 8'd1,
            -8'd49, -8'd52, 8'd8, -8'd4, -8'd25, -8'd20, -8'd50, -8'd26, -8'd28,
            8'd1, 8'd17, 8'd10, 8'd10, 8'd18, 8'd18, 8'd13, 8'd40, 8'd0,
            -8'd38, -8'd42, 8'd37, -8'd40, 8'd18, -8'd11, -8'd8, -8'd36, -8'd57,
            -8'd13, -8'd20, -8'd19, -8'd13, -8'd12, -8'd13, 8'd2, 8'd18, 8'd10,
            8'd13, 8'd38, 8'd7, 8'd15, 8'd43, 8'd22, 8'd12, 8'd16, 8'd41,
            8'd24, 8'd9, 8'd18, 8'd24, 8'd1, 8'd40, 8'd21, 8'd31, 8'd6,
            -8'd8, 8'd16, -8'd7, -8'd11, -8'd14, -8'd12, -8'd7, -8'd5, 8'd5,
            8'd5, -8'd30, 8'd51, 8'd5, 8'd33, 8'd44, -8'd4, 8'd16, 8'd13,
            -8'd51, -8'd45, 8'd27, -8'd31, 8'd8, -8'd4, -8'd32, -8'd25, -8'd21,
            -8'd16, 8'd21, -8'd14, -8'd16, 8'd19, -8'd12, -8'd17, 8'd19, 8'd2,
            -8'd70, -8'd31, 8'd38, -8'd35, -8'd13, -8'd28, -8'd45, -8'd30, -8'd36,
            -8'd5, 8'd20, 8'd67, 8'd32, 8'd4, 8'd30, 8'd16, 8'd21, 8'd31,
            8'd10, 8'd17, 8'd7, 8'd3, 8'd17, -8'd15, 8'd19, 8'd16, 8'd17,
            -8'd33, -8'd30, 8'd40, -8'd46, -8'd25, -8'd20, -8'd26, -8'd26, -8'd42,
            -8'd48, -8'd37, 8'd12, -8'd17, -8'd1, -8'd49, -8'd20, -8'd22, 8'd5,
            -8'd43, -8'd38, 8'd47, -8'd53, -8'd30, -8'd41, -8'd38, -8'd7, -8'd6,
            -8'd57, -8'd10, 8'd127, -8'd69, 8'd4, -8'd38, 8'd5, -8'd18, -8'd47,
            -8'd5, 8'd7, 8'd20, -8'd4, -8'd10, -8'd3, 8'd1, -8'd6, 8'd0,
            8'd5, -8'd8, -8'd8, 8'd2, 8'd17, 8'd1, -8'd9, 8'd12, 8'd14,
            -8'd50, -8'd53, 8'd37, -8'd26, 8'd7, -8'd41, 8'd17, -8'd18, -8'd47,
            -8'd8, 8'd28, 8'd45, 8'd6, 8'd5, 8'd19, 8'd34, 8'd12, -8'd2,
            -8'd49, -8'd19, 8'd19, -8'd58, 8'd20, -8'd27, -8'd29, -8'd20, -8'd1,
            -8'd48, 8'd6, 8'd42, -8'd44, -8'd11, -8'd71, 8'd5, 8'd5, 8'd23,
            8'd8, -8'd20, 8'd28, 8'd10, -8'd24, 8'd7, -8'd2, -8'd12, 8'd23,
            8'd4, -8'd16, -8'd11, 8'd10, 8'd15, 8'd9, -8'd22, -8'd3, 8'd17,
            8'd5, -8'd91, 8'd25, -8'd15, -8'd19, -8'd8, -8'd28, -8'd32, -8'd33,
            8'd17, 8'd17, 8'd5, 8'd2, 8'd15, -8'd17, 8'd2, -8'd19, -8'd9,
            -8'd3, 8'd1, -8'd16, 8'd14, -8'd9, -8'd3, -8'd18, 8'd15, -8'd7,
            8'd3, -8'd6, 8'd56, 8'd31, 8'd42, 8'd26, 8'd2, 8'd35, 8'd9,
            -8'd58, -8'd7, 8'd28, -8'd46, 8'd45, 8'd11, -8'd46, -8'd18, -8'd69,
            -8'd26, -8'd42, 8'd36, -8'd6, -8'd28, -8'd16, -8'd46, -8'd58, -8'd33,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd9, 8'd17, -8'd27, 8'd7, -8'd36, -8'd17, 8'd14, 8'd10, 8'd57,
            8'd6, 8'd35, -8'd37, 8'd9, 8'd23, -8'd40, 8'd10, -8'd2, -8'd29,
            -8'd6, 8'd45, 8'd38, -8'd34, 8'd41, 8'd25, 8'd37, -8'd24, -8'd18,
            -8'd7, 8'd44, -8'd16, -8'd14, 8'd25, -8'd47, 8'd28, -8'd28, -8'd33,
            -8'd21, 8'd26, 8'd9, -8'd25, 8'd23, 8'd22, 8'd20, 8'd8, -8'd14,
            -8'd4, -8'd69, -8'd33, -8'd30, -8'd67, -8'd15, -8'd20, -8'd59, -8'd41,
            -8'd9, 8'd6, 8'd26, -8'd40, 8'd29, 8'd14, 8'd14, -8'd23, -8'd59,
            8'd0, -8'd21, 8'd3, -8'd25, -8'd11, -8'd23, -8'd9, 8'd21, -8'd21,
            -8'd53, 8'd13, 8'd33, -8'd34, -8'd17, 8'd1, 8'd18, 8'd27, 8'd25,
            8'd29, 8'd48, -8'd16, 8'd18, -8'd1, -8'd40, 8'd8, -8'd18, 8'd11,
            -8'd1, 8'd0, 8'd0, -8'd17, -8'd2, 8'd16, -8'd12, 8'd8, 8'd12,
            8'd22, 8'd40, -8'd49, 8'd46, -8'd10, -8'd60, 8'd21, 8'd9, -8'd1,
            -8'd28, -8'd52, -8'd44, -8'd101, -8'd41, 8'd10, -8'd37, 8'd54, 8'd60,
            -8'd8, -8'd11, -8'd3, -8'd7, 8'd6, -8'd20, -8'd9, -8'd12, -8'd3,
            -8'd9, 8'd55, 8'd8, 8'd29, 8'd34, -8'd54, 8'd0, -8'd37, 8'd11,
            8'd30, 8'd35, -8'd47, 8'd3, 8'd1, -8'd34, 8'd6, 8'd0, 8'd20,
            -8'd2, 8'd32, -8'd30, 8'd10, 8'd7, -8'd42, 8'd11, -8'd25, -8'd21,
            8'd50, 8'd99, 8'd101, 8'd86, 8'd31, 8'd41, 8'd11, -8'd8, 8'd29,
            8'd14, -8'd17, -8'd24, -8'd16, 8'd10, 8'd1, -8'd14, 8'd5, 8'd12,
            -8'd16, -8'd14, 8'd9, 8'd20, -8'd22, 8'd10, 8'd6, -8'd6, -8'd4,
            8'd33, 8'd53, -8'd4, 8'd45, 8'd20, -8'd53, 8'd46, 8'd7, 8'd25,
            -8'd27, -8'd36, 8'd33, -8'd39, -8'd1, -8'd28, -8'd16, 8'd40, -8'd7,
            8'd20, 8'd37, -8'd65, -8'd4, 8'd0, -8'd27, -8'd11, 8'd18, 8'd8,
            -8'd8, 8'd7, -8'd58, 8'd44, 8'd7, -8'd4, -8'd11, -8'd5, 8'd51,
            -8'd1, -8'd1, -8'd10, -8'd28, -8'd22, -8'd41, -8'd6, -8'd4, -8'd14,
            8'd21, -8'd23, 8'd10, -8'd3, -8'd24, -8'd7, 8'd4, 8'd19, 8'd25,
            8'd56, 8'd36, -8'd25, 8'd27, -8'd64, -8'd10, -8'd4, 8'd40, -8'd43,
            8'd21, -8'd23, -8'd2, -8'd18, 8'd17, -8'd22, -8'd14, -8'd13, -8'd21,
            -8'd18, -8'd12, -8'd4, -8'd14, -8'd8, 8'd18, -8'd9, 8'd4, -8'd24,
            -8'd127, -8'd80, 8'd26, -8'd127, -8'd65, -8'd11, -8'd50, 8'd28, 8'd32,
            8'd14, 8'd108, 8'd78, 8'd82, 8'd79, -8'd45, 8'd35, 8'd7, -8'd49,
            -8'd5, -8'd15, -8'd40, -8'd20, -8'd56, -8'd78, 8'd19, -8'd7, 8'd25,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd9, 8'd37, 8'd49, -8'd77, -8'd1, 8'd11, -8'd47, -8'd42, -8'd17,
            8'd23, 8'd6, 8'd58, -8'd22, 8'd37, 8'd23, -8'd74, -8'd45, -8'd18,
            -8'd8, -8'd11, -8'd56, -8'd28, -8'd37, -8'd18, -8'd38, 8'd6, 8'd35,
            -8'd1, -8'd20, 8'd37, -8'd17, 8'd25, 8'd19, -8'd50, -8'd44, -8'd28,
            8'd28, -8'd19, 8'd21, 8'd19, -8'd2, -8'd10, 8'd2, 8'd18, -8'd16,
            -8'd12, -8'd30, -8'd32, 8'd31, 8'd4, -8'd22, -8'd4, -8'd25, 8'd37,
            -8'd17, 8'd2, -8'd65, 8'd15, -8'd38, -8'd60, -8'd41, -8'd4, -8'd8,
            -8'd29, 8'd6, -8'd13, 8'd2, 8'd6, -8'd29, -8'd3, 8'd31, 8'd9,
            -8'd24, 8'd22, -8'd18, 8'd12, 8'd24, 8'd30, -8'd36, 8'd28, -8'd8,
            -8'd32, 8'd31, 8'd50, -8'd9, 8'd0, 8'd80, -8'd85, -8'd50, -8'd43,
            -8'd18, 8'd5, -8'd7, 8'd12, 8'd0, -8'd25, -8'd5, -8'd12, 8'd20,
            -8'd25, 8'd19, 8'd16, -8'd21, 8'd25, 8'd83, -8'd92, -8'd50, -8'd35,
            -8'd40, 8'd34, 8'd33, -8'd22, -8'd17, -8'd48, 8'd25, 8'd31, 8'd79,
            -8'd10, 8'd16, -8'd25, 8'd24, 8'd8, 8'd7, 8'd13, -8'd21, -8'd13,
            8'd19, 8'd4, 8'd43, -8'd38, -8'd23, 8'd16, -8'd89, -8'd28, -8'd30,
            8'd23, 8'd40, 8'd36, 8'd11, 8'd19, 8'd63, -8'd29, -8'd80, -8'd48,
            8'd15, -8'd7, 8'd28, -8'd26, 8'd28, 8'd57, -8'd25, -8'd40, -8'd42,
            -8'd35, -8'd12, 8'd38, -8'd127, 8'd70, 8'd36, 8'd109, -8'd42, -8'd70,
            -8'd1, 8'd17, -8'd20, 8'd19, -8'd26, -8'd5, 8'd16, -8'd21, 8'd5,
            8'd31, 8'd9, -8'd1, 8'd2, 8'd21, -8'd2, -8'd16, -8'd6, -8'd8,
            8'd9, 8'd10, 8'd60, -8'd21, 8'd20, 8'd25, -8'd32, -8'd47, -8'd54,
            -8'd52, -8'd35, -8'd38, 8'd22, 8'd34, 8'd10, -8'd11, -8'd8, 8'd38,
            -8'd39, 8'd3, 8'd44, -8'd70, -8'd13, -8'd31, -8'd37, -8'd46, -8'd54,
            -8'd21, 8'd14, 8'd75, -8'd85, 8'd1, 8'd15, -8'd53, -8'd75, -8'd64,
            8'd11, 8'd29, 8'd48, -8'd6, 8'd4, 8'd53, -8'd82, -8'd64, -8'd61,
            8'd0, 8'd16, -8'd6, -8'd2, 8'd13, 8'd4, 8'd21, -8'd6, -8'd1,
            -8'd21, -8'd36, 8'd7, 8'd40, 8'd1, 8'd33, 8'd0, -8'd84, -8'd60,
            8'd2, 8'd16, 8'd23, 8'd22, 8'd9, 8'd21, -8'd11, 8'd28, -8'd16,
            -8'd10, 8'd11, 8'd27, -8'd31, 8'd19, -8'd27, 8'd16, 8'd18, 8'd28,
            -8'd43, -8'd8, -8'd64, -8'd12, -8'd22, 8'd76, 8'd40, 8'd93, 8'd95,
            -8'd4, 8'd37, -8'd60, -8'd41, -8'd39, 8'd7, -8'd101, -8'd74, -8'd114,
            8'd33, 8'd39, 8'd11, 8'd1, 8'd42, 8'd91, -8'd44, -8'd42, 8'd41,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd19, 8'd39, 8'd39, 8'd2, 8'd23, 8'd3, 8'd30, -8'd45, -8'd36,
            -8'd11, -8'd25, 8'd21, 8'd6, 8'd2, -8'd2, -8'd11, 8'd4, -8'd39,
            -8'd18, -8'd36, -8'd3, -8'd22, 8'd5, 8'd7, 8'd25, 8'd44, 8'd26,
            -8'd44, -8'd22, 8'd10, -8'd6, 8'd19, -8'd4, 8'd15, 8'd20, -8'd13,
            8'd16, -8'd5, 8'd16, 8'd16, 8'd10, 8'd8, -8'd2, -8'd12, 8'd7,
            8'd3, 8'd0, -8'd14, 8'd10, -8'd18, 8'd10, -8'd19, -8'd16, -8'd1,
            -8'd5, -8'd13, -8'd24, 8'd12, 8'd0, 8'd6, 8'd3, 8'd15, 8'd17,
            -8'd13, -8'd11, 8'd18, -8'd12, 8'd17, 8'd16, -8'd9, -8'd4, -8'd13,
            -8'd5, -8'd40, 8'd14, -8'd7, 8'd8, 8'd30, 8'd27, 8'd30, -8'd5,
            -8'd39, 8'd7, 8'd3, -8'd1, 8'd3, -8'd10, 8'd13, -8'd11, -8'd32,
            8'd1, -8'd5, -8'd9, -8'd18, -8'd12, -8'd18, 8'd6, 8'd11, 8'd8,
            -8'd63, -8'd33, 8'd5, 8'd8, 8'd14, 8'd2, 8'd10, -8'd21, -8'd36,
            -8'd8, 8'd33, -8'd9, 8'd3, -8'd25, -8'd7, 8'd8, -8'd20, 8'd4,
            8'd1, 8'd7, 8'd12, -8'd21, 8'd17, 8'd4, 8'd12, 8'd12, -8'd1,
            -8'd32, -8'd10, 8'd27, -8'd14, 8'd31, 8'd4, 8'd38, -8'd19, -8'd55,
            -8'd15, -8'd17, 8'd26, 8'd5, 8'd10, 8'd9, -8'd12, -8'd20, -8'd13,
            -8'd21, 8'd3, 8'd31, -8'd8, 8'd35, -8'd5, 8'd8, -8'd34, -8'd34,
            -8'd55, 8'd43, 8'd54, 8'd45, 8'd95, 8'd44, 8'd127, 8'd55, 8'd49,
            8'd14, 8'd10, -8'd4, -8'd12, -8'd3, 8'd17, 8'd6, -8'd13, 8'd6,
            -8'd10, 8'd13, -8'd10, 8'd13, -8'd9, -8'd11, 8'd0, 8'd13, -8'd16,
            -8'd59, -8'd13, 8'd29, -8'd3, 8'd42, 8'd20, 8'd37, 8'd0, -8'd56,
            -8'd7, -8'd24, -8'd20, -8'd2, -8'd3, -8'd19, -8'd24, 8'd29, 8'd23,
            8'd6, 8'd21, 8'd1, -8'd3, 8'd26, -8'd5, 8'd19, -8'd29, -8'd33,
            -8'd15, 8'd10, 8'd15, -8'd3, 8'd24, -8'd15, 8'd23, -8'd29, -8'd50,
            -8'd34, -8'd17, 8'd16, -8'd7, 8'd3, 8'd9, -8'd18, -8'd6, -8'd19,
            8'd5, 8'd9, -8'd10, -8'd17, -8'd15, -8'd18, 8'd14, -8'd13, 8'd18,
            -8'd24, -8'd12, -8'd21, 8'd19, -8'd32, -8'd29, -8'd56, -8'd41, 8'd6,
            8'd16, -8'd4, 8'd10, 8'd9, 8'd12, -8'd1, 8'd13, 8'd3, -8'd8,
            -8'd4, 8'd17, -8'd2, 8'd7, -8'd14, 8'd16, -8'd19, -8'd3, -8'd13,
            8'd20, -8'd1, -8'd1, -8'd14, -8'd5, -8'd14, -8'd27, 8'd41, 8'd22,
            -8'd77, -8'd59, 8'd0, -8'd32, 8'd41, 8'd71, 8'd84, 8'd46, -8'd12,
            -8'd52, 8'd1, 8'd6, -8'd30, 8'd14, 8'd14, 8'd0, -8'd22, -8'd37,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd99, -8'd79, -8'd97, -8'd58, -8'd8, -8'd104, -8'd117, -8'd105, -8'd70,
            -8'd60, -8'd64, 8'd40, -8'd11, -8'd108, -8'd108, 8'd99, -8'd45, -8'd116,
            8'd9, -8'd111, -8'd111, 8'd48, -8'd10, 8'd54, -8'd117, -8'd121, -8'd25,
            -8'd49, -8'd84, 8'd102, 8'd86, -8'd105, -8'd47, -8'd9, -8'd82, -8'd78,
            8'd77, -8'd90, 8'd26, -8'd74, 8'd26, 8'd68, 8'd77, 8'd10, -8'd71,
            8'd45, 8'd23, -8'd118, -8'd38, -8'd62, 8'd63, -8'd79, 8'd84, 8'd19,
            -8'd98, 8'd90, 8'd110, -8'd56, -8'd51, 8'd2, -8'd117, 8'd86, 8'd111,
            8'd12, 8'd27, -8'd104, -8'd2, 8'd101, -8'd105, 8'd74, -8'd68, -8'd119,
            -8'd108, -8'd38, 8'd30, 8'd71, 8'd17, 8'd76, -8'd103, 8'd64, 8'd25,
            8'd93, -8'd39, -8'd90, -8'd47, 8'd88, -8'd96, 8'd67, -8'd15, -8'd24,
            -8'd84, 8'd82, -8'd100, 8'd11, -8'd25, -8'd98, 8'd5, -8'd118, -8'd119,
            -8'd25, -8'd33, 8'd15, 8'd73, -8'd26, -8'd28, 8'd39, -8'd22, -8'd53,
            -8'd109, 8'd92, -8'd118, 8'd6, 8'd60, 8'd10, 8'd86, -8'd71, -8'd72,
            8'd5, 8'd82, 8'd61, -8'd94, -8'd112, 8'd30, 8'd42, 8'd103, -8'd24,
            8'd87, -8'd66, -8'd59, 8'd91, -8'd127, 8'd76, -8'd13, 8'd70, 8'd17,
            -8'd43, 8'd41, 8'd30, -8'd16, -8'd124, -8'd21, -8'd43, -8'd114, 8'd8,
            -8'd7, -8'd53, -8'd111, -8'd125, 8'd12, 8'd40, -8'd45, -8'd89, 8'd86,
            -8'd103, -8'd6, -8'd61, 8'd54, -8'd64, 8'd42, -8'd89, -8'd90, -8'd24,
            8'd79, 8'd99, 8'd107, -8'd29, 8'd78, 8'd14, -8'd1, -8'd5, 8'd8,
            8'd39, -8'd28, -8'd121, -8'd24, 8'd70, 8'd6, -8'd92, -8'd111, 8'd105,
            8'd41, 8'd57, 8'd114, -8'd4, 8'd32, -8'd80, 8'd45, 8'd105, 8'd42,
            -8'd25, -8'd25, -8'd75, -8'd48, -8'd23, 8'd6, -8'd88, 8'd15, -8'd56,
            8'd25, -8'd53, -8'd88, 8'd104, 8'd3, 8'd70, 8'd14, -8'd3, 8'd16,
            -8'd93, 8'd86, 8'd51, 8'd10, 8'd59, 8'd27, 8'd34, 8'd75, -8'd14,
            8'd24, -8'd77, -8'd66, 8'd8, 8'd57, 8'd95, 8'd54, -8'd86, -8'd10,
            -8'd7, 8'd110, 8'd45, 8'd32, 8'd0, 8'd86, 8'd62, -8'd26, -8'd79,
            8'd0, -8'd117, 8'd46, 8'd25, -8'd116, -8'd120, -8'd117, -8'd9, -8'd105,
            -8'd52, 8'd80, 8'd94, 8'd94, 8'd52, -8'd20, 8'd60, -8'd98, -8'd109,
            -8'd1, -8'd28, 8'd28, 8'd32, -8'd19, 8'd69, -8'd72, -8'd52, -8'd13,
            -8'd57, -8'd68, -8'd30, -8'd43, -8'd98, 8'd38, -8'd23, 8'd29, -8'd50,
            -8'd103, 8'd26, 8'd92, -8'd119, -8'd23, -8'd16, 8'd0, -8'd112, 8'd81,
            -8'd70, -8'd80, -8'd91, 8'd88, 8'd8, 8'd81, -8'd73, 8'd28, -8'd113,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd110, 8'd26, 8'd53, 8'd28, -8'd23, 8'd83, 8'd72, 8'd35, 8'd3,
            8'd76, 8'd52, -8'd9, 8'd24, -8'd2, -8'd113, -8'd16, 8'd36, 8'd55,
            -8'd35, -8'd92, -8'd31, 8'd51, -8'd23, -8'd42, -8'd127, 8'd17, -8'd9,
            -8'd21, 8'd60, 8'd29, -8'd89, 8'd32, -8'd79, -8'd33, 8'd5, -8'd111,
            8'd56, 8'd68, 8'd73, -8'd1, -8'd49, 8'd73, 8'd90, 8'd12, 8'd47,
            8'd67, 8'd86, -8'd69, -8'd15, 8'd45, 8'd12, -8'd98, -8'd91, -8'd37,
            -8'd92, 8'd81, -8'd82, -8'd68, 8'd68, -8'd27, 8'd18, 8'd25, -8'd30,
            8'd74, -8'd48, -8'd90, 8'd34, -8'd95, -8'd15, 8'd16, -8'd28, 8'd36,
            -8'd76, -8'd3, -8'd90, 8'd43, 8'd35, -8'd15, 8'd20, -8'd49, -8'd105,
            -8'd6, 8'd74, 8'd15, 8'd50, 8'd25, 8'd14, 8'd8, -8'd25, 8'd33,
            8'd32, 8'd71, -8'd38, -8'd19, 8'd95, -8'd45, -8'd58, -8'd31, 8'd1,
            -8'd119, 8'd16, 8'd83, -8'd41, 8'd61, 8'd65, 8'd55, 8'd73, 8'd76,
            8'd5, -8'd41, -8'd93, -8'd36, 8'd33, 8'd17, -8'd74, -8'd30, -8'd47,
            -8'd18, 8'd3, 8'd35, -8'd77, -8'd31, -8'd52, -8'd15, -8'd46, -8'd67,
            -8'd55, -8'd72, -8'd89, -8'd54, -8'd93, 8'd75, -8'd29, 8'd15, 8'd60,
            -8'd5, -8'd12, 8'd42, -8'd27, -8'd119, 8'd28, -8'd56, -8'd11, -8'd70,
            -8'd87, -8'd13, 8'd73, -8'd18, -8'd29, -8'd40, 8'd45, 8'd43, -8'd43,
            -8'd71, 8'd54, 8'd97, -8'd41, 8'd30, -8'd37, 8'd95, -8'd92, -8'd78,
            -8'd72, 8'd15, -8'd73, 8'd47, -8'd38, -8'd90, -8'd4, -8'd53, 8'd46,
            8'd21, 8'd15, -8'd40, -8'd18, -8'd66, -8'd36, -8'd61, 8'd64, -8'd87,
            8'd20, -8'd4, -8'd65, -8'd22, -8'd97, -8'd61, -8'd5, -8'd4, 8'd24,
            -8'd39, 8'd35, -8'd78, -8'd84, -8'd121, 8'd47, -8'd77, -8'd99, -8'd9,
            8'd17, 8'd28, 8'd35, 8'd36, -8'd16, -8'd83, -8'd57, 8'd64, -8'd28,
            -8'd94, 8'd26, 8'd20, -8'd36, 8'd69, -8'd94, 8'd15, 8'd75, 8'd75,
            -8'd38, -8'd65, -8'd97, -8'd62, -8'd113, -8'd97, -8'd56, -8'd69, -8'd57,
            8'd17, -8'd91, -8'd2, -8'd6, 8'd81, -8'd52, 8'd60, -8'd43, -8'd26,
            -8'd69, 8'd87, -8'd102, -8'd39, 8'd14, 8'd67, 8'd16, -8'd12, 8'd20,
            -8'd50, -8'd45, 8'd67, -8'd23, -8'd96, 8'd71, -8'd94, -8'd9, 8'd49,
            8'd14, 8'd63, -8'd65, -8'd39, -8'd87, 8'd26, -8'd41, 8'd24, -8'd64,
            -8'd82, 8'd82, 8'd32, -8'd127, -8'd44, -8'd83, 8'd36, -8'd8, -8'd92,
            -8'd95, 8'd46, -8'd103, 8'd70, -8'd115, -8'd98, -8'd25, 8'd66, 8'd70,
            -8'd110, 8'd75, -8'd50, -8'd2, -8'd94, 8'd14, 8'd4, 8'd49, 8'd39,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd2, 8'd30, 8'd27, -8'd71, -8'd43, -8'd90, 8'd19, -8'd8, 8'd13,
            8'd33, 8'd36, 8'd17, -8'd45, 8'd0, -8'd19, -8'd17, -8'd7, 8'd2,
            -8'd16, 8'd16, 8'd18, -8'd42, 8'd24, 8'd63, -8'd19, -8'd10, -8'd25,
            8'd2, 8'd18, 8'd42, -8'd20, 8'd7, -8'd19, -8'd10, -8'd30, -8'd27,
            -8'd19, -8'd12, 8'd5, -8'd16, 8'd18, 8'd3, 8'd15, -8'd13, -8'd10,
            -8'd13, -8'd21, 8'd34, 8'd10, 8'd13, 8'd15, 8'd20, 8'd25, 8'd22,
            8'd13, 8'd1, 8'd28, 8'd5, -8'd3, 8'd30, -8'd2, 8'd16, 8'd22,
            8'd12, -8'd14, 8'd16, 8'd13, 8'd16, -8'd4, -8'd13, 8'd5, -8'd3,
            8'd19, 8'd14, 8'd42, -8'd11, 8'd29, 8'd24, -8'd18, -8'd17, -8'd7,
            8'd30, 8'd50, 8'd12, -8'd37, 8'd6, -8'd75, -8'd20, -8'd20, -8'd29,
            8'd11, 8'd14, -8'd21, -8'd5, 8'd9, -8'd7, 8'd3, 8'd6, 8'd2,
            8'd27, 8'd47, 8'd42, -8'd19, 8'd9, -8'd72, -8'd4, -8'd47, -8'd22,
            -8'd35, 8'd13, -8'd38, 8'd9, -8'd6, 8'd50, 8'd6, 8'd38, 8'd23,
            -8'd2, 8'd15, -8'd16, -8'd23, -8'd4, -8'd4, 8'd5, -8'd3, -8'd23,
            8'd5, 8'd30, 8'd22, -8'd68, -8'd30, -8'd49, -8'd9, -8'd8, -8'd21,
            8'd16, 8'd38, -8'd11, -8'd53, -8'd22, -8'd58, -8'd17, -8'd30, -8'd12,
            8'd30, 8'd39, -8'd1, -8'd22, 8'd5, -8'd44, 8'd3, -8'd23, -8'd8,
            -8'd97, 8'd14, 8'd84, -8'd58, -8'd11, -8'd33, -8'd5, 8'd37, 8'd7,
            8'd14, -8'd12, 8'd19, 8'd7, -8'd13, 8'd3, -8'd10, 8'd21, 8'd14,
            8'd8, -8'd21, 8'd6, 8'd14, 8'd13, -8'd1, 8'd10, -8'd18, 8'd3,
            -8'd5, 8'd35, 8'd41, -8'd69, -8'd4, -8'd50, 8'd2, -8'd23, 8'd13,
            8'd44, 8'd12, 8'd6, 8'd26, 8'd0, 8'd1, -8'd10, -8'd21, -8'd18,
            -8'd25, 8'd7, 8'd17, -8'd70, -8'd34, -8'd72, -8'd17, -8'd9, 8'd23,
            -8'd1, 8'd18, -8'd5, -8'd79, -8'd53, -8'd69, 8'd22, 8'd6, 8'd33,
            8'd24, 8'd19, -8'd6, -8'd35, -8'd7, -8'd53, -8'd19, -8'd10, -8'd2,
            8'd20, -8'd9, -8'd14, 8'd0, -8'd19, 8'd10, -8'd19, 8'd21, -8'd4,
            8'd19, 8'd24, -8'd83, 8'd65, 8'd13, -8'd127, -8'd72, -8'd75, -8'd20,
            -8'd20, -8'd5, 8'd2, -8'd8, 8'd3, 8'd20, -8'd19, -8'd2, -8'd14,
            -8'd13, 8'd8, 8'd20, -8'd19, -8'd12, 8'd3, 8'd3, -8'd20, 8'd4,
            8'd10, 8'd1, 8'd0, 8'd42, 8'd53, 8'd26, -8'd12, -8'd1, -8'd13,
            -8'd25, 8'd20, 8'd52, -8'd100, -8'd26, 8'd45, -8'd22, -8'd38, -8'd115,
            8'd47, 8'd24, 8'd29, -8'd28, -8'd8, -8'd68, -8'd38, -8'd27, -8'd16,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd86, -8'd102, -8'd76, -8'd73, 8'd100, -8'd103, -8'd7, -8'd58, -8'd87,
            8'd66, -8'd51, -8'd107, -8'd71, -8'd70, -8'd73, 8'd97, -8'd32, 8'd47,
            8'd28, 8'd19, -8'd51, -8'd31, -8'd92, 8'd22, 8'd60, 8'd86, -8'd66,
            -8'd63, 8'd33, -8'd98, -8'd6, -8'd41, 8'd87, -8'd71, -8'd75, -8'd6,
            -8'd9, 8'd56, 8'd18, 8'd19, 8'd23, -8'd93, -8'd91, -8'd102, -8'd49,
            8'd36, -8'd109, -8'd30, -8'd28, 8'd38, 8'd10, 8'd94, -8'd72, -8'd127,
            8'd5, 8'd24, -8'd73, -8'd2, -8'd107, -8'd95, -8'd1, -8'd110, 8'd51,
            -8'd99, 8'd14, -8'd28, 8'd83, -8'd92, 8'd62, 8'd26, -8'd46, -8'd104,
            8'd18, -8'd39, 8'd1, 8'd34, -8'd117, 8'd17, -8'd105, 8'd60, 8'd62,
            -8'd90, -8'd41, 8'd29, -8'd71, -8'd17, -8'd96, 8'd15, -8'd63, -8'd92,
            -8'd76, -8'd16, -8'd1, 8'd77, 8'd90, -8'd89, 8'd75, -8'd97, -8'd95,
            -8'd18, 8'd29, -8'd5, 8'd90, -8'd58, 8'd81, 8'd50, -8'd26, -8'd10,
            8'd43, 8'd7, -8'd60, -8'd17, 8'd0, 8'd95, -8'd46, 8'd56, -8'd85,
            -8'd58, -8'd55, -8'd66, 8'd0, 8'd68, 8'd106, -8'd54, -8'd91, -8'd89,
            8'd29, 8'd40, -8'd81, -8'd61, 8'd34, -8'd66, 8'd32, -8'd117, -8'd6,
            8'd46, -8'd22, 8'd10, 8'd79, -8'd49, 8'd52, -8'd27, 8'd0, 8'd62,
            -8'd117, -8'd42, -8'd88, -8'd94, 8'd5, 8'd46, 8'd38, -8'd92, 8'd0,
            8'd57, 8'd86, -8'd16, -8'd53, 8'd19, 8'd51, 8'd23, 8'd37, -8'd42,
            -8'd59, 8'd13, 8'd48, 8'd55, -8'd68, -8'd99, -8'd71, 8'd56, -8'd101,
            8'd71, 8'd37, -8'd87, -8'd100, -8'd21, 8'd58, -8'd22, -8'd90, 8'd89,
            8'd58, -8'd36, -8'd31, 8'd3, 8'd84, -8'd48, -8'd7, 8'd26, -8'd99,
            8'd80, -8'd110, -8'd21, 8'd80, 8'd83, -8'd11, -8'd95, 8'd24, 8'd89,
            8'd67, -8'd86, 8'd72, -8'd107, 8'd95, 8'd56, 8'd16, -8'd20, 8'd93,
            8'd73, -8'd11, -8'd10, -8'd54, 8'd14, 8'd56, 8'd19, 8'd29, -8'd75,
            8'd24, 8'd29, -8'd65, -8'd41, 8'd0, -8'd1, -8'd76, -8'd85, -8'd24,
            8'd22, -8'd108, -8'd49, 8'd85, 8'd58, 8'd54, 8'd48, 8'd84, -8'd80,
            -8'd67, 8'd95, 8'd87, -8'd29, 8'd96, -8'd48, -8'd17, -8'd62, -8'd28,
            8'd5, 8'd5, -8'd108, 8'd110, -8'd3, 8'd14, -8'd58, 8'd13, 8'd12,
            8'd6, -8'd107, 8'd54, 8'd11, 8'd71, -8'd4, 8'd32, -8'd36, -8'd48,
            8'd82, -8'd91, -8'd106, 8'd90, -8'd93, -8'd95, -8'd83, 8'd86, -8'd57,
            -8'd10, 8'd17, -8'd7, 8'd36, -8'd105, 8'd99, 8'd79, 8'd44, -8'd54,
            -8'd31, -8'd71, -8'd110, 8'd95, 8'd68, -8'd22, 8'd18, -8'd2, 8'd73,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd11, 8'd18, 8'd38, -8'd21, -8'd23, 8'd9, -8'd67, -8'd24, -8'd31,
            8'd22, -8'd5, 8'd0, -8'd26, -8'd9, 8'd0, -8'd39, -8'd36, -8'd1,
            -8'd18, -8'd60, -8'd61, -8'd5, -8'd41, -8'd94, 8'd31, -8'd12, -8'd1,
            8'd1, 8'd25, -8'd25, 8'd9, 8'd21, -8'd1, -8'd21, -8'd25, -8'd6,
            8'd10, -8'd8, -8'd4, 8'd0, 8'd14, -8'd13, 8'd6, 8'd9, 8'd3,
            8'd0, -8'd32, -8'd17, 8'd2, 8'd16, -8'd23, 8'd11, -8'd5, -8'd29,
            8'd8, -8'd52, -8'd29, -8'd12, -8'd9, -8'd35, 8'd34, -8'd12, -8'd34,
            8'd6, 8'd7, 8'd17, -8'd10, 8'd10, -8'd4, -8'd1, 8'd17, 8'd13,
            8'd8, 8'd25, -8'd27, -8'd13, 8'd14, -8'd13, 8'd5, -8'd11, 8'd18,
            -8'd11, 8'd0, 8'd12, 8'd4, 8'd14, 8'd40, -8'd34, -8'd43, 8'd7,
            8'd4, -8'd19, -8'd17, -8'd5, -8'd17, -8'd14, -8'd14, -8'd9, 8'd1,
            -8'd12, 8'd28, -8'd6, -8'd12, 8'd17, 8'd35, -8'd2, -8'd7, -8'd19,
            8'd20, -8'd4, 8'd91, -8'd2, -8'd1, 8'd17, -8'd16, 8'd13, 8'd5,
            -8'd9, 8'd19, -8'd18, 8'd8, -8'd15, -8'd8, 8'd1, 8'd20, 8'd1,
            8'd5, 8'd24, -8'd6, -8'd27, -8'd22, 8'd11, -8'd33, -8'd23, 8'd7,
            8'd5, 8'd9, 8'd14, -8'd32, 8'd3, 8'd6, -8'd8, -8'd36, 8'd21,
            8'd12, 8'd15, -8'd23, 8'd8, 8'd16, 8'd14, -8'd5, -8'd38, -8'd5,
            8'd33, -8'd34, -8'd75, 8'd22, -8'd52, -8'd127, 8'd20, 8'd94, -8'd5,
            8'd22, 8'd10, -8'd4, -8'd7, -8'd2, 8'd17, -8'd10, 8'd12, -8'd20,
            8'd0, 8'd11, 8'd3, -8'd11, -8'd15, 8'd19, 8'd10, 8'd4, 8'd12,
            8'd18, -8'd4, -8'd9, -8'd20, -8'd36, 8'd7, -8'd30, -8'd12, -8'd4,
            8'd7, 8'd26, -8'd3, -8'd31, -8'd11, 8'd10, -8'd1, -8'd12, 8'd29,
            -8'd17, 8'd42, 8'd35, -8'd41, -8'd35, 8'd17, -8'd20, -8'd22, -8'd19,
            8'd0, 8'd29, 8'd9, -8'd19, -8'd35, 8'd7, -8'd20, -8'd11, -8'd5,
            8'd3, 8'd23, 8'd16, 8'd9, -8'd5, 8'd13, -8'd30, -8'd43, -8'd20,
            -8'd7, 8'd3, -8'd8, -8'd5, -8'd17, -8'd17, -8'd4, 8'd18, -8'd15,
            8'd37, 8'd42, 8'd25, -8'd25, 8'd6, 8'd99, -8'd17, -8'd14, 8'd34,
            8'd7, -8'd8, -8'd1, 8'd14, -8'd1, -8'd21, 8'd16, -8'd1, 8'd7,
            -8'd7, 8'd9, 8'd17, -8'd5, 8'd5, -8'd12, -8'd8, -8'd16, 8'd8,
            8'd61, 8'd57, 8'd21, -8'd12, 8'd23, 8'd27, -8'd13, -8'd13, 8'd30,
            -8'd26, -8'd50, -8'd3, 8'd6, -8'd37, -8'd58, -8'd22, -8'd32, -8'd10,
            8'd32, 8'd47, -8'd7, 8'd8, 8'd11, 8'd27, -8'd21, -8'd41, 8'd54,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd15, -8'd6, 8'd1, -8'd32, 8'd10, 8'd1, 8'd15, 8'd6, 8'd0,
            -8'd8, 8'd18, 8'd17, -8'd38, 8'd0, -8'd9, -8'd28, -8'd5, 8'd0,
            8'd27, -8'd23, 8'd45, 8'd30, 8'd30, 8'd13, 8'd30, 8'd68, 8'd49,
            8'd14, 8'd7, -8'd19, -8'd30, 8'd8, 8'd40, -8'd49, 8'd18, 8'd25,
            -8'd6, -8'd31, 8'd10, -8'd5, 8'd15, 8'd4, 8'd11, -8'd25, 8'd18,
            8'd19, -8'd28, -8'd25, 8'd28, -8'd2, 8'd25, 8'd12, -8'd22, -8'd18,
            -8'd15, -8'd7, -8'd36, -8'd8, 8'd3, 8'd57, 8'd1, 8'd28, 8'd20,
            8'd30, 8'd9, -8'd8, 8'd28, 8'd8, 8'd18, 8'd15, -8'd29, 8'd20,
            8'd31, -8'd51, 8'd23, -8'd42, -8'd15, 8'd5, -8'd65, -8'd15, -8'd29,
            -8'd20, 8'd2, -8'd7, 8'd0, 8'd0, 8'd11, -8'd16, 8'd63, 8'd13,
            -8'd1, -8'd19, -8'd16, 8'd8, -8'd2, -8'd4, -8'd9, -8'd29, 8'd8,
            8'd15, 8'd60, 8'd5, -8'd87, 8'd40, 8'd11, -8'd11, 8'd22, -8'd13,
            -8'd20, -8'd32, -8'd10, 8'd15, -8'd101, -8'd71, 8'd8, -8'd69, -8'd104,
            -8'd25, 8'd28, -8'd21, 8'd26, 8'd1, 8'd1, 8'd4, -8'd32, -8'd1,
            -8'd49, 8'd5, 8'd36, -8'd60, 8'd12, 8'd28, 8'd2, 8'd56, 8'd25,
            -8'd5, 8'd24, -8'd1, -8'd52, 8'd4, 8'd1, 8'd6, 8'd39, 8'd52,
            -8'd4, 8'd15, 8'd0, -8'd44, 8'd2, 8'd34, -8'd17, 8'd39, -8'd15,
            8'd34, -8'd5, -8'd41, -8'd19, -8'd6, 8'd8, 8'd105, 8'd75, -8'd12,
            8'd5, 8'd33, -8'd17, -8'd18, 8'd32, 8'd33, -8'd35, 8'd24, -8'd4,
            -8'd3, -8'd20, 8'd13, 8'd26, 8'd33, -8'd14, 8'd0, -8'd27, 8'd17,
            -8'd62, -8'd33, 8'd0, -8'd48, 8'd42, 8'd37, -8'd9, 8'd26, 8'd11,
            8'd4, 8'd20, -8'd23, 8'd84, -8'd30, -8'd50, 8'd13, -8'd50, -8'd18,
            8'd27, 8'd11, -8'd3, -8'd99, 8'd38, 8'd21, -8'd31, -8'd5, 8'd36,
            -8'd32, 8'd42, 8'd31, -8'd62, -8'd4, -8'd37, 8'd42, 8'd56, -8'd31,
            -8'd24, 8'd14, -8'd3, 8'd4, 8'd6, 8'd24, 8'd6, 8'd30, 8'd8,
            8'd0, 8'd26, 8'd5, -8'd22, -8'd34, -8'd31, -8'd7, -8'd15, -8'd27,
            8'd78, 8'd121, 8'd61, 8'd57, 8'd85, 8'd42, -8'd2, 8'd48, 8'd71,
            8'd0, -8'd32, -8'd6, 8'd9, -8'd2, 8'd18, 8'd14, -8'd33, -8'd16,
            8'd34, 8'd2, 8'd7, -8'd3, -8'd24, 8'd15, -8'd31, 8'd26, -8'd23,
            8'd13, -8'd71, -8'd82, 8'd49, -8'd92, -8'd127, -8'd19, -8'd101, -8'd92,
            -8'd43, -8'd21, 8'd82, -8'd47, 8'd52, 8'd56, 8'd22, 8'd104, 8'd49,
            8'd24, 8'd54, -8'd10, 8'd45, 8'd26, 8'd14, 8'd39, -8'd6, 8'd5,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd28, -8'd98, 8'd86, -8'd62, 8'd81, 8'd97, 8'd69, 8'd57, -8'd74,
            -8'd39, 8'd14, -8'd53, 8'd58, -8'd103, -8'd99, 8'd27, -8'd20, 8'd86,
            8'd68, -8'd19, -8'd85, -8'd24, 8'd84, 8'd68, 8'd81, -8'd109, -8'd108,
            -8'd18, -8'd74, 8'd63, 8'd76, 8'd87, -8'd106, 8'd34, -8'd73, -8'd110,
            8'd75, 8'd7, -8'd101, -8'd95, 8'd99, 8'd77, -8'd87, 8'd51, -8'd85,
            -8'd2, 8'd21, -8'd61, 8'd41, -8'd108, 8'd44, 8'd66, -8'd94, 8'd27,
            -8'd88, -8'd104, -8'd42, 8'd55, -8'd34, -8'd43, 8'd3, -8'd48, 8'd85,
            8'd83, -8'd40, -8'd18, 8'd64, -8'd30, 8'd84, 8'd97, 8'd102, 8'd41,
            -8'd62, 8'd3, 8'd5, 8'd27, 8'd50, -8'd20, 8'd29, 8'd11, -8'd88,
            -8'd55, -8'd48, -8'd11, 8'd81, 8'd11, 8'd41, 8'd55, -8'd23, 8'd107,
            -8'd7, 8'd48, -8'd110, 8'd63, -8'd60, -8'd88, 8'd56, -8'd6, 8'd55,
            -8'd2, -8'd73, -8'd106, 8'd3, -8'd101, -8'd27, 8'd42, 8'd47, -8'd41,
            -8'd87, 8'd0, -8'd96, -8'd18, -8'd13, 8'd44, -8'd39, -8'd96, 8'd90,
            8'd34, 8'd90, 8'd3, 8'd61, -8'd3, -8'd99, -8'd84, -8'd89, 8'd62,
            8'd0, 8'd18, -8'd105, 8'd88, -8'd14, 8'd52, -8'd83, 8'd61, -8'd102,
            -8'd92, 8'd18, 8'd18, -8'd72, 8'd43, 8'd50, 8'd62, -8'd73, -8'd29,
            8'd88, -8'd41, 8'd52, -8'd115, 8'd12, 8'd37, -8'd120, -8'd16, 8'd86,
            8'd9, -8'd40, -8'd95, -8'd2, 8'd101, -8'd60, 8'd68, -8'd11, 8'd96,
            8'd24, 8'd9, -8'd69, -8'd111, -8'd8, -8'd5, 8'd91, -8'd33, -8'd76,
            8'd81, 8'd9, 8'd16, -8'd22, -8'd89, -8'd90, -8'd107, 8'd3, -8'd83,
            8'd62, 8'd53, 8'd61, 8'd4, -8'd58, -8'd29, -8'd95, 8'd88, -8'd89,
            8'd3, 8'd22, -8'd44, 8'd59, -8'd37, -8'd110, 8'd66, 8'd52, -8'd29,
            -8'd37, -8'd21, -8'd30, -8'd127, -8'd52, 8'd103, 8'd83, -8'd49, -8'd26,
            8'd35, -8'd45, 8'd56, 8'd45, -8'd86, 8'd121, -8'd17, -8'd80, 8'd87,
            -8'd104, -8'd10, -8'd12, 8'd80, 8'd62, -8'd17, -8'd41, 8'd33, -8'd86,
            -8'd53, 8'd9, 8'd0, 8'd1, -8'd86, -8'd38, 8'd29, 8'd63, -8'd88,
            -8'd76, -8'd1, -8'd22, -8'd104, 8'd88, -8'd106, 8'd102, -8'd93, -8'd83,
            8'd19, -8'd107, -8'd108, 8'd94, -8'd70, 8'd13, 8'd55, 8'd85, -8'd76,
            -8'd48, 8'd27, -8'd39, -8'd35, 8'd103, 8'd101, -8'd77, 8'd64, -8'd5,
            -8'd111, 8'd27, 8'd22, -8'd30, -8'd18, 8'd47, -8'd86, 8'd19, 8'd4,
            8'd29, -8'd44, 8'd68, -8'd78, -8'd33, -8'd94, -8'd46, 8'd109, 8'd99,
            -8'd27, -8'd11, -8'd93, -8'd14, 8'd20, -8'd118, -8'd89, -8'd51, -8'd39,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd59, -8'd30, -8'd76, 8'd79, -8'd9, -8'd60, 8'd55, -8'd49, 8'd8,
            -8'd91, 8'd41, -8'd47, 8'd37, 8'd20, -8'd50, 8'd31, 8'd52, -8'd98,
            8'd19, 8'd9, -8'd36, -8'd127, -8'd4, 8'd34, -8'd95, -8'd37, -8'd59,
            -8'd76, 8'd61, 8'd46, -8'd92, 8'd22, 8'd61, 8'd5, -8'd76, -8'd77,
            8'd23, -8'd28, 8'd12, 8'd80, -8'd61, -8'd11, 8'd17, -8'd38, -8'd41,
            -8'd42, -8'd10, 8'd53, 8'd35, -8'd59, -8'd99, 8'd20, -8'd83, -8'd27,
            -8'd84, 8'd3, -8'd21, 8'd53, -8'd36, -8'd75, -8'd89, 8'd16, 8'd51,
            8'd89, 8'd87, -8'd73, -8'd85, 8'd85, 8'd13, 8'd12, 8'd85, 8'd64,
            -8'd81, -8'd32, -8'd99, -8'd22, 8'd21, -8'd30, -8'd84, 8'd7, -8'd63,
            -8'd92, 8'd32, -8'd104, 8'd21, -8'd74, 8'd18, -8'd62, 8'd8, 8'd27,
            8'd84, 8'd9, -8'd76, -8'd2, 8'd45, 8'd34, -8'd74, -8'd34, 8'd85,
            -8'd51, 8'd82, -8'd59, -8'd93, 8'd9, -8'd3, 8'd18, 8'd34, -8'd67,
            8'd1, -8'd46, -8'd93, -8'd119, -8'd78, -8'd97, 8'd29, -8'd4, 8'd16,
            8'd17, -8'd32, 8'd18, 8'd2, 8'd39, -8'd83, -8'd22, 8'd3, -8'd68,
            8'd14, 8'd70, 8'd4, -8'd3, 8'd38, -8'd26, 8'd23, -8'd27, -8'd9,
            -8'd77, 8'd61, 8'd74, -8'd69, -8'd6, -8'd65, -8'd27, -8'd121, -8'd115,
            8'd51, 8'd63, -8'd75, -8'd65, 8'd59, -8'd88, -8'd91, -8'd51, 8'd17,
            -8'd14, 8'd69, 8'd91, 8'd37, 8'd89, 8'd59, 8'd0, -8'd66, -8'd74,
            8'd86, -8'd29, 8'd28, 8'd62, 8'd77, 8'd43, 8'd80, -8'd13, 8'd63,
            -8'd41, 8'd9, 8'd58, 8'd27, -8'd93, -8'd66, -8'd7, -8'd7, 8'd54,
            -8'd47, -8'd80, 8'd64, -8'd29, -8'd98, -8'd37, -8'd67, -8'd95, 8'd26,
            -8'd58, -8'd38, 8'd40, 8'd51, -8'd28, 8'd60, 8'd3, -8'd80, 8'd5,
            8'd81, 8'd18, 8'd2, -8'd4, 8'd57, 8'd33, -8'd8, 8'd20, -8'd37,
            8'd44, 8'd55, -8'd60, 8'd59, -8'd33, -8'd41, -8'd4, 8'd51, -8'd88,
            -8'd94, 8'd16, -8'd46, 8'd34, -8'd96, -8'd89, -8'd4, -8'd119, 8'd48,
            -8'd70, -8'd40, 8'd38, 8'd46, 8'd15, 8'd4, -8'd64, 8'd66, 8'd92,
            8'd10, -8'd9, 8'd9, 8'd39, -8'd80, -8'd46, -8'd1, -8'd12, 8'd13,
            8'd93, 8'd28, -8'd5, -8'd85, -8'd16, 8'd1, 8'd85, -8'd86, 8'd1,
            -8'd83, -8'd88, -8'd90, 8'd45, -8'd11, -8'd51, -8'd39, -8'd26, -8'd21,
            8'd27, 8'd8, -8'd64, -8'd15, -8'd106, 8'd27, 8'd41, -8'd91, 8'd48,
            -8'd11, -8'd84, -8'd71, -8'd8, 8'd14, 8'd73, 8'd49, -8'd68, 8'd66,
            8'd84, -8'd104, -8'd19, 8'd71, 8'd14, -8'd74, -8'd83, -8'd35, 8'd2,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd75, -8'd25, 8'd33, 8'd67, -8'd4, 8'd82, -8'd36, 8'd50, 8'd55,
            8'd3, -8'd60, -8'd19, -8'd82, 8'd52, -8'd97, -8'd41, -8'd40, 8'd4,
            -8'd100, 8'd69, -8'd30, -8'd102, -8'd102, 8'd71, -8'd102, -8'd11, 8'd78,
            -8'd28, -8'd124, -8'd46, -8'd75, 8'd87, -8'd90, -8'd1, -8'd47, 8'd14,
            8'd34, 8'd12, -8'd18, -8'd64, -8'd37, 8'd79, -8'd94, -8'd26, -8'd82,
            8'd15, 8'd59, 8'd63, -8'd52, -8'd112, 8'd11, 8'd61, -8'd68, 8'd87,
            -8'd67, -8'd10, -8'd72, -8'd11, 8'd10, -8'd123, 8'd64, -8'd10, 8'd31,
            -8'd71, -8'd35, 8'd64, 8'd17, -8'd34, -8'd26, 8'd8, -8'd82, -8'd100,
            -8'd103, -8'd90, 8'd5, -8'd72, -8'd24, -8'd60, -8'd17, 8'd82, -8'd39,
            8'd11, 8'd80, -8'd58, 8'd20, -8'd106, 8'd42, 8'd103, -8'd90, -8'd118,
            -8'd18, -8'd9, 8'd6, -8'd44, -8'd111, -8'd100, 8'd61, 8'd73, 8'd9,
            -8'd27, 8'd54, 8'd78, -8'd23, -8'd7, 8'd63, -8'd5, -8'd32, 8'd44,
            -8'd55, -8'd19, 8'd54, -8'd75, 8'd76, 8'd10, 8'd31, -8'd58, 8'd55,
            8'd36, 8'd111, -8'd83, -8'd74, -8'd79, 8'd38, -8'd73, -8'd16, 8'd45,
            -8'd51, -8'd28, -8'd20, -8'd61, 8'd52, 8'd21, 8'd22, 8'd77, -8'd35,
            8'd70, 8'd86, 8'd69, -8'd78, -8'd111, -8'd58, -8'd7, -8'd100, -8'd99,
            8'd64, -8'd54, 8'd37, -8'd16, -8'd15, 8'd90, -8'd113, 8'd8, 8'd12,
            8'd44, -8'd85, -8'd40, 8'd55, -8'd58, 8'd40, 8'd43, -8'd113, -8'd101,
            -8'd1, 8'd79, 8'd29, -8'd63, 8'd32, -8'd99, 8'd33, -8'd50, 8'd48,
            -8'd21, 8'd96, 8'd35, 8'd56, -8'd65, -8'd88, -8'd21, 8'd11, 8'd44,
            -8'd2, -8'd92, 8'd48, -8'd80, -8'd48, -8'd91, -8'd58, -8'd105, -8'd117,
            -8'd55, 8'd80, 8'd38, 8'd80, -8'd31, -8'd74, -8'd100, -8'd56, -8'd72,
            -8'd114, 8'd4, 8'd73, 8'd15, -8'd75, -8'd36, -8'd61, 8'd58, -8'd101,
            -8'd17, -8'd99, 8'd50, -8'd2, -8'd115, -8'd102, -8'd1, 8'd63, -8'd22,
            -8'd124, 8'd52, -8'd44, 8'd34, 8'd49, -8'd34, 8'd10, 8'd88, -8'd48,
            -8'd58, -8'd6, 8'd89, -8'd58, 8'd84, -8'd23, 8'd83, 8'd107, 8'd93,
            -8'd112, -8'd125, -8'd85, -8'd71, 8'd100, -8'd79, -8'd40, -8'd6, -8'd15,
            8'd45, 8'd88, -8'd6, 8'd32, 8'd49, 8'd22, -8'd106, -8'd26, -8'd21,
            8'd25, -8'd107, -8'd61, 8'd99, 8'd107, 8'd93, 8'd4, 8'd64, -8'd106,
            -8'd90, 8'd28, 8'd70, -8'd10, -8'd127, -8'd117, -8'd65, 8'd87, -8'd111,
            -8'd17, -8'd2, -8'd81, 8'd100, -8'd110, -8'd68, -8'd79, 8'd61, 8'd33,
            -8'd79, 8'd63, -8'd2, 8'd33, 8'd81, 8'd37, 8'd75, -8'd50, 8'd35,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd89, 8'd54, -8'd39, -8'd21, 8'd9, 8'd6, -8'd72, 8'd29, -8'd91,
            -8'd25, -8'd3, 8'd57, 8'd20, 8'd39, -8'd100, -8'd44, -8'd52, -8'd73,
            8'd12, -8'd55, 8'd59, 8'd38, 8'd51, -8'd53, -8'd37, -8'd106, 8'd36,
            -8'd78, -8'd60, 8'd45, 8'd58, 8'd10, 8'd74, -8'd89, -8'd67, 8'd48,
            8'd53, 8'd70, 8'd87, -8'd58, -8'd51, 8'd32, -8'd7, -8'd70, 8'd76,
            -8'd87, -8'd44, -8'd112, -8'd94, 8'd77, -8'd90, 8'd67, 8'd12, -8'd14,
            -8'd4, 8'd16, -8'd75, -8'd100, -8'd26, -8'd20, -8'd8, -8'd67, 8'd90,
            8'd5, 8'd49, -8'd85, 8'd54, 8'd95, 8'd19, -8'd100, -8'd90, 8'd58,
            8'd67, -8'd74, -8'd32, 8'd67, -8'd40, 8'd79, -8'd93, 8'd54, -8'd22,
            8'd36, -8'd47, 8'd40, 8'd2, 8'd63, -8'd69, -8'd105, 8'd46, 8'd80,
            -8'd23, 8'd33, 8'd27, -8'd42, -8'd30, -8'd9, 8'd36, 8'd0, -8'd97,
            8'd19, 8'd56, -8'd115, -8'd124, -8'd57, -8'd127, -8'd91, -8'd58, 8'd67,
            -8'd23, 8'd4, -8'd2, 8'd90, -8'd45, 8'd51, -8'd96, -8'd106, 8'd27,
            8'd87, -8'd35, -8'd57, 8'd98, 8'd33, 8'd91, -8'd42, 8'd93, 8'd74,
            8'd65, -8'd114, 8'd3, -8'd91, -8'd71, 8'd40, 8'd77, 8'd66, -8'd3,
            8'd82, -8'd18, -8'd27, 8'd76, 8'd80, 8'd51, -8'd93, -8'd76, -8'd80,
            8'd72, -8'd30, -8'd109, 8'd46, 8'd27, -8'd48, -8'd11, 8'd16, -8'd92,
            8'd78, 8'd76, 8'd24, 8'd65, -8'd2, -8'd22, 8'd99, 8'd85, -8'd93,
            8'd90, -8'd83, 8'd105, -8'd1, -8'd42, 8'd58, -8'd14, 8'd93, 8'd75,
            -8'd89, -8'd106, 8'd95, -8'd72, -8'd6, -8'd37, -8'd77, 8'd19, 8'd107,
            -8'd59, 8'd29, 8'd22, 8'd17, -8'd55, 8'd60, -8'd89, 8'd23, 8'd16,
            8'd58, -8'd108, -8'd9, -8'd77, 8'd92, 8'd61, 8'd53, -8'd95, 8'd44,
            -8'd116, 8'd3, -8'd10, 8'd3, -8'd8, -8'd111, -8'd4, 8'd44, -8'd19,
            -8'd10, 8'd78, -8'd29, -8'd105, 8'd94, -8'd82, 8'd7, -8'd89, 8'd72,
            -8'd35, -8'd15, -8'd14, 8'd45, -8'd64, 8'd14, -8'd88, 8'd86, 8'd86,
            8'd2, 8'd49, 8'd80, -8'd12, -8'd97, 8'd44, 8'd16, -8'd58, 8'd99,
            -8'd8, 8'd82, -8'd26, -8'd46, 8'd63, -8'd74, 8'd57, 8'd94, -8'd43,
            -8'd91, -8'd98, 8'd98, 8'd107, 8'd37, -8'd52, -8'd44, -8'd80, -8'd28,
            -8'd74, 8'd3, 8'd53, 8'd17, -8'd6, -8'd51, -8'd94, 8'd45, -8'd96,
            -8'd81, 8'd86, 8'd69, -8'd104, 8'd42, 8'd37, -8'd41, 8'd86, -8'd56,
            8'd73, -8'd32, 8'd28, 8'd0, -8'd88, -8'd52, -8'd43, -8'd60, -8'd116,
            8'd75, 8'd58, -8'd104, -8'd51, 8'd48, 8'd5, -8'd72, -8'd58, 8'd86,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd1, 8'd23, 8'd12, 8'd15, 8'd14, -8'd5, 8'd46, 8'd5, 8'd50,
            8'd1, -8'd26, -8'd14, 8'd10, 8'd42, 8'd5, 8'd10, -8'd11, 8'd53,
            -8'd29, -8'd42, -8'd25, -8'd87, -8'd63, -8'd95, -8'd51, -8'd47, -8'd82,
            -8'd14, -8'd29, 8'd27, 8'd0, 8'd8, -8'd3, 8'd29, 8'd49, 8'd31,
            8'd0, -8'd13, 8'd6, 8'd5, -8'd4, 8'd32, 8'd18, -8'd5, 8'd19,
            8'd43, 8'd5, -8'd16, 8'd19, -8'd14, -8'd20, -8'd25, -8'd53, -8'd53,
            8'd22, -8'd36, -8'd15, -8'd57, -8'd91, -8'd85, -8'd85, -8'd96, -8'd43,
            8'd9, -8'd15, 8'd8, -8'd4, -8'd3, -8'd16, -8'd32, -8'd4, -8'd33,
            -8'd29, -8'd31, -8'd59, 8'd5, -8'd8, 8'd46, 8'd31, -8'd22, 8'd42,
            -8'd11, -8'd43, -8'd32, 8'd38, -8'd16, 8'd0, 8'd19, 8'd48, 8'd1,
            8'd14, -8'd1, -8'd28, 8'd6, -8'd27, -8'd2, 8'd17, 8'd21, 8'd27,
            -8'd57, -8'd9, -8'd4, 8'd23, 8'd15, 8'd27, 8'd54, 8'd5, 8'd2,
            8'd88, 8'd75, 8'd21, -8'd12, -8'd70, -8'd89, -8'd19, 8'd16, -8'd59,
            -8'd22, 8'd5, 8'd0, -8'd4, -8'd9, 8'd31, 8'd8, 8'd14, -8'd6,
            8'd20, -8'd20, -8'd6, 8'd51, 8'd46, 8'd43, 8'd72, 8'd3, 8'd3,
            8'd18, 8'd19, 8'd10, 8'd32, 8'd33, -8'd6, 8'd58, 8'd39, 8'd18,
            -8'd39, -8'd31, 8'd1, -8'd6, 8'd21, 8'd15, 8'd25, -8'd10, 8'd55,
            8'd26, 8'd62, 8'd38, 8'd68, 8'd41, -8'd16, -8'd18, -8'd34, -8'd65,
            8'd14, -8'd34, 8'd2, 8'd26, 8'd13, -8'd29, -8'd4, 8'd29, -8'd11,
            8'd29, -8'd6, 8'd14, 8'd18, 8'd4, 8'd13, 8'd28, 8'd1, 8'd23,
            -8'd26, -8'd7, 8'd13, 8'd6, 8'd21, 8'd49, 8'd24, 8'd57, 8'd19,
            8'd10, -8'd51, -8'd26, -8'd64, -8'd98, -8'd55, -8'd94, 8'd0, -8'd20,
            8'd25, 8'd11, 8'd50, 8'd29, -8'd23, 8'd25, 8'd6, -8'd2, -8'd1,
            8'd39, 8'd61, 8'd17, 8'd15, 8'd31, 8'd14, 8'd84, -8'd16, 8'd21,
            -8'd39, 8'd31, -8'd21, -8'd10, 8'd52, 8'd36, 8'd58, 8'd16, 8'd42,
            8'd15, -8'd31, 8'd2, 8'd0, -8'd26, 8'd24, 8'd22, 8'd17, -8'd33,
            -8'd16, -8'd12, -8'd71, -8'd44, -8'd36, -8'd2, -8'd86, -8'd108, -8'd24,
            8'd34, -8'd34, -8'd23, -8'd19, 8'd12, -8'd4, -8'd27, 8'd24, 8'd22,
            8'd15, 8'd28, 8'd4, -8'd8, -8'd5, -8'd15, 8'd22, -8'd10, -8'd1,
            8'd32, 8'd22, -8'd94, -8'd127, -8'd108, -8'd72, -8'd86, -8'd37, 8'd45,
            -8'd29, -8'd34, -8'd58, -8'd14, -8'd44, -8'd45, -8'd18, -8'd31, -8'd26,
            -8'd27, -8'd28, -8'd24, -8'd51, 8'd1, 8'd54, 8'd5, 8'd10, 8'd5,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd24, 8'd12, -8'd28, -8'd25, -8'd16, 8'd10, -8'd1, -8'd11, 8'd27,
            -8'd2, 8'd26, -8'd41, 8'd0, 8'd30, 8'd11, -8'd10, 8'd17, 8'd7,
            -8'd25, -8'd35, 8'd20, -8'd24, -8'd82, -8'd40, 8'd7, -8'd19, -8'd17,
            -8'd11, -8'd11, -8'd32, -8'd12, 8'd16, -8'd36, -8'd36, 8'd6, 8'd13,
            -8'd12, -8'd11, -8'd3, 8'd15, -8'd13, -8'd17, 8'd14, 8'd0, -8'd4,
            -8'd19, -8'd63, -8'd21, 8'd8, -8'd77, -8'd33, 8'd23, -8'd6, -8'd47,
            -8'd41, -8'd50, 8'd2, -8'd12, -8'd65, -8'd27, -8'd21, -8'd37, -8'd57,
            -8'd19, 8'd16, 8'd13, 8'd14, 8'd15, 8'd10, 8'd11, -8'd5, -8'd15,
            8'd11, -8'd13, -8'd49, -8'd24, 8'd10, -8'd28, -8'd14, 8'd16, 8'd17,
            8'd3, 8'd35, -8'd56, -8'd17, 8'd32, 8'd8, -8'd6, 8'd21, 8'd15,
            8'd7, -8'd13, -8'd13, 8'd18, 8'd7, 8'd1, -8'd2, 8'd2, -8'd2,
            8'd30, 8'd32, -8'd27, -8'd6, 8'd48, -8'd5, -8'd4, 8'd7, 8'd3,
            -8'd31, -8'd9, 8'd31, -8'd63, -8'd38, 8'd33, 8'd2, -8'd21, -8'd36,
            8'd1, -8'd18, -8'd14, -8'd17, 8'd6, -8'd3, 8'd9, -8'd15, -8'd1,
            8'd8, -8'd1, -8'd10, -8'd26, -8'd4, -8'd16, 8'd0, 8'd19, -8'd7,
            8'd30, 8'd30, -8'd46, -8'd23, 8'd32, 8'd0, 8'd7, -8'd5, 8'd5,
            8'd25, 8'd13, -8'd20, -8'd4, -8'd11, -8'd4, 8'd11, 8'd18, 8'd18,
            -8'd27, -8'd13, 8'd44, -8'd29, -8'd62, -8'd51, 8'd39, -8'd7, -8'd47,
            -8'd13, 8'd18, -8'd12, -8'd1, -8'd3, 8'd15, 8'd16, 8'd4, 8'd9,
            -8'd16, -8'd17, 8'd15, -8'd17, 8'd7, 8'd4, 8'd4, 8'd4, 8'd11,
            8'd26, 8'd22, -8'd22, -8'd2, 8'd17, 8'd7, -8'd17, -8'd4, 8'd20,
            8'd15, -8'd11, -8'd22, 8'd12, -8'd9, -8'd34, -8'd11, 8'd3, -8'd2,
            8'd17, 8'd31, -8'd5, -8'd38, 8'd35, 8'd48, -8'd3, -8'd17, 8'd14,
            -8'd2, 8'd14, -8'd30, -8'd10, 8'd4, 8'd8, 8'd20, -8'd15, 8'd6,
            8'd20, -8'd4, -8'd10, -8'd9, 8'd2, 8'd13, -8'd16, -8'd13, -8'd5,
            -8'd4, -8'd18, 8'd11, 8'd18, 8'd12, -8'd1, -8'd9, 8'd13, 8'd8,
            8'd75, 8'd108, -8'd39, 8'd40, 8'd127, 8'd36, -8'd35, -8'd8, 8'd4,
            8'd13, 8'd10, -8'd1, 8'd18, 8'd10, -8'd18, 8'd13, -8'd14, 8'd14,
            8'd4, -8'd3, 8'd17, 8'd5, -8'd11, -8'd9, 8'd2, 8'd6, 8'd4,
            -8'd6, -8'd66, -8'd41, 8'd15, 8'd13, -8'd18, 8'd12, 8'd5, 8'd19,
            -8'd8, 8'd33, 8'd43, -8'd80, -8'd37, -8'd2, -8'd45, -8'd45, -8'd36,
            8'd35, 8'd28, -8'd67, 8'd17, 8'd32, -8'd1, -8'd5, 8'd4, 8'd31,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd0, 8'd25, 8'd36, 8'd33, -8'd21, -8'd35, 8'd7, 8'd4, 8'd23,
            8'd9, 8'd8, 8'd7, 8'd29, 8'd6, 8'd27, -8'd14, -8'd28, -8'd39,
            -8'd12, 8'd7, -8'd65, -8'd37, 8'd8, -8'd56, -8'd17, 8'd9, -8'd13,
            -8'd12, -8'd21, 8'd9, 8'd47, 8'd36, 8'd3, 8'd9, -8'd5, 8'd11,
            8'd27, -8'd24, 8'd6, 8'd4, -8'd22, 8'd1, -8'd17, 8'd15, 8'd2,
            -8'd46, -8'd40, -8'd27, -8'd50, -8'd37, -8'd12, -8'd8, -8'd9, 8'd17,
            -8'd18, -8'd27, -8'd49, -8'd3, -8'd19, -8'd10, -8'd1, -8'd5, 8'd17,
            8'd21, -8'd26, -8'd18, -8'd11, 8'd12, 8'd20, 8'd9, -8'd18, 8'd4,
            8'd22, 8'd26, 8'd18, 8'd37, 8'd56, 8'd50, 8'd18, -8'd6, -8'd22,
            -8'd1, -8'd7, -8'd1, 8'd20, 8'd13, -8'd6, -8'd17, -8'd54, -8'd45,
            -8'd2, -8'd6, 8'd26, -8'd27, -8'd9, 8'd6, 8'd6, -8'd11, -8'd13,
            8'd17, 8'd24, 8'd5, 8'd3, 8'd0, 8'd18, -8'd46, -8'd23, -8'd10,
            8'd70, 8'd43, 8'd99, 8'd16, -8'd18, -8'd17, 8'd44, 8'd116, 8'd38,
            -8'd2, -8'd11, 8'd19, -8'd16, -8'd17, -8'd23, 8'd22, -8'd21, -8'd6,
            -8'd19, 8'd12, 8'd8, 8'd20, 8'd16, -8'd5, -8'd19, -8'd55, -8'd6,
            -8'd6, 8'd5, 8'd21, 8'd21, 8'd36, -8'd4, -8'd43, -8'd52, -8'd32,
            -8'd2, 8'd10, 8'd26, 8'd19, 8'd24, 8'd2, -8'd1, -8'd31, -8'd16,
            8'd12, 8'd28, 8'd14, 8'd105, 8'd57, -8'd57, 8'd53, 8'd88, 8'd127,
            -8'd10, 8'd25, 8'd17, 8'd10, 8'd21, 8'd8, 8'd20, 8'd22, -8'd10,
            -8'd23, 8'd1, 8'd6, -8'd15, -8'd10, -8'd26, 8'd21, 8'd21, -8'd9,
            -8'd8, -8'd3, 8'd24, 8'd1, 8'd25, -8'd39, -8'd39, -8'd53, -8'd23,
            -8'd2, 8'd21, -8'd33, 8'd2, 8'd43, 8'd48, 8'd32, -8'd20, -8'd16,
            8'd14, 8'd54, 8'd7, -8'd10, -8'd46, 8'd6, -8'd18, 8'd18, -8'd3,
            -8'd18, 8'd28, 8'd48, 8'd22, -8'd37, -8'd47, -8'd8, -8'd36, 8'd15,
            8'd16, 8'd20, 8'd19, -8'd4, 8'd8, -8'd13, -8'd14, -8'd44, -8'd29,
            8'd25, -8'd13, -8'd14, 8'd11, 8'd8, 8'd19, -8'd15, -8'd19, -8'd18,
            8'd58, 8'd4, -8'd31, -8'd45, 8'd7, 8'd23, 8'd32, -8'd27, -8'd37,
            8'd0, 8'd17, 8'd11, 8'd28, 8'd12, 8'd8, -8'd9, 8'd20, 8'd13,
            -8'd2, 8'd20, 8'd4, -8'd6, 8'd16, -8'd5, -8'd23, -8'd26, -8'd17,
            8'd24, -8'd8, -8'd27, 8'd29, 8'd81, 8'd72, 8'd63, 8'd29, 8'd27,
            8'd4, -8'd36, -8'd27, 8'd26, -8'd5, -8'd35, -8'd2, -8'd32, -8'd24,
            8'd7, 8'd20, 8'd30, 8'd19, 8'd36, 8'd38, -8'd21, -8'd21, 8'd1,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd43, -8'd62, -8'd35, -8'd83, 8'd25, 8'd62, 8'd81, 8'd75, 8'd9,
            -8'd27, -8'd12, 8'd22, -8'd15, -8'd20, 8'd33, -8'd22, 8'd36, 8'd28,
            8'd24, -8'd12, 8'd3, -8'd7, -8'd15, -8'd90, -8'd61, -8'd45, -8'd12,
            -8'd2, -8'd1, -8'd19, -8'd61, 8'd1, 8'd23, 8'd13, 8'd18, 8'd53,
            8'd22, 8'd15, 8'd12, 8'd0, 8'd27, -8'd1, -8'd4, 8'd8, -8'd13,
            -8'd14, -8'd29, 8'd27, -8'd2, -8'd10, -8'd26, 8'd12, -8'd19, 8'd12,
            8'd20, -8'd2, 8'd39, 8'd12, -8'd40, -8'd21, -8'd36, -8'd55, -8'd33,
            8'd11, 8'd2, 8'd1, -8'd10, 8'd6, 8'd10, 8'd6, 8'd20, 8'd11,
            8'd23, 8'd20, 8'd20, -8'd26, -8'd35, 8'd16, -8'd20, 8'd63, 8'd45,
            -8'd24, -8'd17, 8'd4, -8'd8, -8'd19, 8'd45, 8'd1, 8'd19, 8'd13,
            8'd16, 8'd11, 8'd24, -8'd5, -8'd11, 8'd26, 8'd26, 8'd25, 8'd20,
            8'd1, -8'd13, -8'd5, -8'd43, -8'd29, 8'd49, -8'd21, 8'd1, 8'd18,
            -8'd7, 8'd18, 8'd31, -8'd22, 8'd25, 8'd21, 8'd79, 8'd57, 8'd4,
            8'd0, -8'd23, 8'd24, 8'd23, -8'd22, -8'd8, -8'd19, -8'd30, 8'd17,
            -8'd41, -8'd13, -8'd47, -8'd63, -8'd16, 8'd31, 8'd9, 8'd56, 8'd20,
            8'd0, -8'd6, 8'd18, -8'd33, -8'd5, 8'd9, 8'd25, 8'd28, 8'd25,
            -8'd37, -8'd36, -8'd8, -8'd62, 8'd13, 8'd24, 8'd22, 8'd15, 8'd47,
            -8'd34, 8'd17, -8'd100, -8'd103, -8'd43, 8'd45, 8'd107, 8'd120, 8'd127,
            -8'd29, 8'd6, 8'd7, 8'd22, -8'd11, 8'd4, -8'd11, 8'd12, -8'd4,
            8'd22, -8'd17, -8'd19, -8'd17, 8'd29, 8'd15, 8'd10, 8'd7, 8'd29,
            -8'd53, -8'd48, -8'd60, -8'd71, -8'd3, 8'd57, 8'd15, 8'd20, 8'd51,
            8'd22, 8'd27, 8'd2, 8'd7, -8'd45, -8'd29, 8'd16, 8'd31, 8'd26,
            -8'd6, -8'd23, -8'd35, -8'd36, 8'd9, 8'd29, 8'd55, 8'd14, -8'd22,
            -8'd32, -8'd46, -8'd29, -8'd55, 8'd40, 8'd38, 8'd66, 8'd64, 8'd9,
            -8'd16, -8'd44, 8'd0, -8'd12, 8'd15, 8'd21, -8'd17, 8'd13, -8'd21,
            8'd4, 8'd21, -8'd5, 8'd10, 8'd22, -8'd14, -8'd18, 8'd0, -8'd20,
            8'd18, 8'd4, 8'd27, 8'd5, -8'd43, -8'd81, -8'd38, -8'd47, -8'd71,
            8'd2, 8'd15, 8'd18, 8'd17, 8'd18, 8'd1, 8'd5, -8'd16, 8'd18,
            -8'd27, 8'd26, -8'd23, 8'd19, -8'd2, -8'd7, -8'd26, 8'd23, -8'd9,
            8'd28, 8'd54, 8'd32, 8'd15, -8'd5, -8'd82, -8'd27, 8'd58, 8'd24,
            -8'd65, -8'd13, -8'd65, -8'd110, -8'd126, -8'd86, -8'd64, 8'd44, -8'd33,
            -8'd8, 8'd32, -8'd23, -8'd11, -8'd16, 8'd32, -8'd24, 8'd47, 8'd21,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd33, -8'd4, -8'd74, 8'd52, 8'd11, -8'd65, 8'd8, -8'd67, -8'd69,
            8'd22, 8'd6, -8'd16, 8'd28, -8'd20, -8'd8, 8'd15, -8'd30, -8'd3,
            -8'd16, -8'd1, 8'd39, 8'd13, 8'd64, 8'd17, 8'd32, 8'd60, -8'd8,
            8'd23, -8'd23, -8'd19, 8'd0, 8'd51, -8'd38, 8'd40, 8'd24, 8'd19,
            8'd6, -8'd10, 8'd32, 8'd18, -8'd4, -8'd11, 8'd18, 8'd0, 8'd9,
            8'd12, 8'd42, 8'd2, 8'd42, 8'd20, 8'd37, 8'd7, 8'd35, 8'd36,
            8'd11, 8'd25, -8'd15, 8'd37, -8'd4, 8'd40, 8'd46, 8'd5, 8'd3,
            -8'd19, 8'd4, 8'd7, 8'd12, 8'd26, -8'd26, -8'd10, 8'd0, 8'd0,
            -8'd10, -8'd8, -8'd28, -8'd51, -8'd41, -8'd52, 8'd17, 8'd4, -8'd29,
            8'd8, -8'd29, -8'd24, 8'd78, 8'd13, -8'd9, 8'd96, -8'd24, -8'd46,
            8'd2, -8'd21, 8'd9, 8'd25, 8'd21, -8'd1, 8'd9, -8'd15, 8'd29,
            8'd16, -8'd39, -8'd71, 8'd50, -8'd30, -8'd11, 8'd63, 8'd34, -8'd28,
            -8'd31, 8'd9, -8'd45, -8'd105, -8'd25, -8'd38, -8'd76, -8'd84, -8'd32,
            -8'd12, -8'd29, -8'd10, -8'd1, 8'd9, -8'd15, -8'd27, 8'd28, 8'd26,
            8'd35, 8'd28, -8'd61, 8'd60, 8'd20, -8'd66, 8'd85, -8'd13, -8'd40,
            8'd40, 8'd5, -8'd55, 8'd101, 8'd30, -8'd63, 8'd63, -8'd27, -8'd19,
            8'd61, -8'd6, -8'd19, 8'd55, -8'd24, -8'd58, 8'd76, 8'd6, -8'd38,
            -8'd64, -8'd126, -8'd70, -8'd27, -8'd79, -8'd76, 8'd10, -8'd102, 8'd26,
            8'd9, 8'd0, -8'd11, 8'd23, 8'd13, -8'd19, -8'd27, -8'd26, 8'd1,
            8'd11, 8'd26, -8'd26, 8'd0, -8'd3, -8'd12, -8'd18, -8'd26, 8'd14,
            8'd45, -8'd29, -8'd68, 8'd39, -8'd41, -8'd25, 8'd106, -8'd23, 8'd11,
            -8'd34, 8'd16, -8'd24, -8'd53, -8'd21, 8'd3, -8'd15, -8'd56, -8'd1,
            8'd8, -8'd33, -8'd25, 8'd80, 8'd25, -8'd75, 8'd46, 8'd37, -8'd35,
            8'd25, -8'd37, -8'd42, 8'd26, -8'd50, -8'd99, 8'd26, -8'd41, 8'd1,
            8'd38, -8'd2, -8'd9, 8'd59, -8'd8, 8'd1, 8'd32, 8'd30, -8'd34,
            8'd1, -8'd30, 8'd1, -8'd17, 8'd1, -8'd26, 8'd6, 8'd26, 8'd1,
            8'd57, 8'd18, -8'd11, 8'd95, 8'd95, 8'd58, 8'd53, -8'd98, 8'd100,
            -8'd21, 8'd20, 8'd21, 8'd33, 8'd25, -8'd8, 8'd14, -8'd9, 8'd22,
            -8'd6, -8'd1, -8'd33, 8'd10, 8'd7, -8'd9, -8'd7, -8'd22, -8'd29,
            -8'd58, -8'd42, -8'd6, -8'd127, -8'd48, -8'd49, -8'd93, -8'd100, -8'd23,
            -8'd11, 8'd42, -8'd7, 8'd60, 8'd87, 8'd2, 8'd31, 8'd104, -8'd34,
            -8'd27, 8'd3, -8'd73, 8'd28, -8'd10, -8'd39, -8'd5, -8'd57, -8'd1,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd109, -8'd58, -8'd45, 8'd3, -8'd11, -8'd6, 8'd81, -8'd112, 8'd72,
            -8'd23, 8'd61, 8'd79, -8'd77, -8'd118, -8'd50, -8'd28, 8'd116, 8'd37,
            -8'd77, -8'd66, 8'd74, -8'd124, 8'd121, -8'd102, 8'd61, 8'd65, 8'd30,
            8'd71, 8'd100, -8'd57, -8'd4, 8'd106, -8'd3, -8'd8, -8'd12, 8'd20,
            -8'd112, 8'd119, 8'd104, 8'd102, -8'd67, 8'd78, 8'd21, -8'd112, -8'd95,
            8'd62, -8'd98, 8'd125, 8'd125, 8'd36, 8'd22, 8'd99, -8'd11, 8'd95,
            8'd40, 8'd3, -8'd3, -8'd80, 8'd24, -8'd56, -8'd7, -8'd109, -8'd54,
            -8'd110, -8'd6, 8'd7, -8'd47, -8'd61, -8'd18, 8'd15, 8'd105, -8'd84,
            -8'd12, 8'd29, -8'd115, -8'd56, 8'd19, 8'd63, -8'd26, 8'd81, -8'd29,
            8'd32, -8'd58, 8'd7, -8'd111, -8'd31, 8'd26, 8'd76, -8'd24, -8'd109,
            8'd102, -8'd89, -8'd96, -8'd6, -8'd108, -8'd72, 8'd85, 8'd17, -8'd100,
            8'd16, -8'd90, -8'd25, 8'd120, -8'd90, 8'd27, -8'd25, -8'd38, 8'd74,
            -8'd100, 8'd6, 8'd38, -8'd7, -8'd90, -8'd123, -8'd99, -8'd79, -8'd87,
            8'd70, 8'd53, -8'd20, -8'd78, -8'd45, -8'd15, -8'd38, -8'd1, -8'd111,
            8'd27, -8'd22, -8'd84, 8'd66, 8'd108, -8'd77, -8'd118, -8'd127, -8'd122,
            8'd41, -8'd44, -8'd125, 8'd13, 8'd125, -8'd5, -8'd49, -8'd6, -8'd6,
            8'd37, -8'd49, 8'd28, -8'd101, -8'd4, 8'd19, -8'd73, 8'd86, -8'd109,
            -8'd120, 8'd107, 8'd115, -8'd50, 8'd15, -8'd39, -8'd103, -8'd123, -8'd47,
            8'd126, 8'd12, -8'd14, -8'd46, 8'd73, 8'd22, -8'd36, 8'd84, -8'd3,
            -8'd84, 8'd122, 8'd27, 8'd2, 8'd118, 8'd32, 8'd4, 8'd18, -8'd99,
            -8'd125, 8'd127, 8'd122, -8'd41, 8'd118, 8'd31, 8'd41, -8'd62, -8'd105,
            -8'd72, 8'd12, 8'd15, 8'd91, 8'd100, -8'd55, 8'd83, -8'd78, 8'd11,
            -8'd104, 8'd57, 8'd2, -8'd81, -8'd21, -8'd14, -8'd33, -8'd56, 8'd31,
            8'd99, -8'd53, -8'd7, -8'd121, 8'd59, 8'd36, -8'd46, -8'd29, -8'd85,
            -8'd105, -8'd35, -8'd112, 8'd50, 8'd40, -8'd3, 8'd35, 8'd68, -8'd6,
            8'd44, -8'd97, -8'd37, 8'd10, 8'd111, 8'd111, -8'd12, 8'd96, -8'd9,
            -8'd16, 8'd9, -8'd19, 8'd22, 8'd102, 8'd33, 8'd118, -8'd75, 8'd50,
            -8'd107, -8'd48, -8'd13, 8'd11, -8'd88, -8'd58, 8'd42, -8'd7, -8'd99,
            8'd105, 8'd121, -8'd90, 8'd51, -8'd39, 8'd55, -8'd53, -8'd43, 8'd50,
            -8'd111, -8'd6, 8'd49, 8'd106, -8'd92, 8'd66, 8'd6, -8'd12, 8'd110,
            8'd67, -8'd15, -8'd122, 8'd105, 8'd37, -8'd116, -8'd49, 8'd109, 8'd37,
            -8'd91, 8'd67, -8'd18, -8'd61, -8'd4, 8'd110, 8'd100, -8'd122, -8'd66,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd2, 8'd40, -8'd12, -8'd28, -8'd58, -8'd34, -8'd59, 8'd55, 8'd86,
            8'd22, 8'd52, 8'd18, 8'd30, 8'd5, -8'd58, -8'd57, -8'd29, -8'd7,
            -8'd14, -8'd25, -8'd35, 8'd4, 8'd43, 8'd14, -8'd21, -8'd11, -8'd28,
            -8'd23, 8'd54, 8'd40, 8'd39, 8'd33, -8'd45, -8'd43, -8'd61, 8'd2,
            8'd24, 8'd20, -8'd20, 8'd9, 8'd10, -8'd24, 8'd20, 8'd17, 8'd5,
            -8'd40, -8'd48, -8'd29, -8'd2, -8'd6, 8'd30, 8'd39, 8'd8, 8'd15,
            -8'd8, -8'd44, -8'd10, -8'd32, 8'd29, 8'd36, -8'd15, 8'd38, -8'd19,
            -8'd20, 8'd27, 8'd12, 8'd27, 8'd26, -8'd4, -8'd1, -8'd13, 8'd7,
            8'd6, 8'd42, 8'd71, 8'd59, 8'd66, 8'd1, -8'd31, -8'd35, 8'd1,
            8'd31, 8'd27, 8'd11, 8'd3, 8'd6, -8'd54, -8'd62, -8'd11, 8'd3,
            -8'd25, -8'd15, 8'd28, -8'd23, -8'd28, -8'd21, -8'd24, -8'd22, -8'd17,
            8'd23, 8'd11, 8'd59, -8'd23, -8'd38, -8'd45, -8'd67, -8'd1, 8'd0,
            -8'd40, -8'd18, -8'd54, 8'd21, 8'd7, 8'd25, 8'd62, 8'd50, 8'd59,
            -8'd3, -8'd12, -8'd42, 8'd3, -8'd9, -8'd13, -8'd11, 8'd0, -8'd8,
            8'd31, 8'd17, 8'd53, -8'd12, -8'd39, -8'd64, -8'd29, -8'd22, 8'd35,
            8'd1, 8'd3, 8'd42, -8'd15, -8'd34, -8'd24, -8'd64, -8'd13, 8'd43,
            -8'd4, 8'd55, 8'd65, 8'd6, -8'd23, -8'd66, -8'd72, -8'd19, 8'd23,
            -8'd10, 8'd69, 8'd50, 8'd34, 8'd16, 8'd60, 8'd9, 8'd87, 8'd113,
            8'd27, 8'd11, 8'd19, 8'd19, -8'd23, 8'd25, -8'd8, -8'd29, -8'd11,
            -8'd7, 8'd21, -8'd29, -8'd20, -8'd6, 8'd18, 8'd21, -8'd11, 8'd11,
            8'd2, 8'd25, 8'd58, 8'd11, -8'd25, -8'd27, -8'd73, 8'd3, 8'd14,
            -8'd23, -8'd40, 8'd8, 8'd19, 8'd42, -8'd19, 8'd15, -8'd14, -8'd24,
            8'd9, 8'd23, -8'd4, -8'd5, -8'd58, -8'd63, -8'd58, -8'd12, 8'd56,
            8'd16, 8'd21, 8'd30, -8'd36, -8'd69, -8'd49, -8'd24, 8'd47, 8'd39,
            8'd17, 8'd7, 8'd17, 8'd22, -8'd39, -8'd46, -8'd56, -8'd25, 8'd29,
            8'd20, 8'd16, 8'd19, 8'd27, 8'd19, -8'd23, 8'd4, -8'd16, 8'd28,
            -8'd16, 8'd15, -8'd30, -8'd2, -8'd67, -8'd120, -8'd75, -8'd75, -8'd92,
            8'd8, -8'd13, -8'd27, 8'd18, 8'd8, 8'd20, -8'd2, -8'd15, 8'd3,
            -8'd28, 8'd12, -8'd21, 8'd29, 8'd26, -8'd1, 8'd1, 8'd8, 8'd1,
            -8'd90, -8'd14, 8'd30, 8'd70, 8'd91, 8'd69, 8'd15, -8'd14, -8'd2,
            8'd6, 8'd24, 8'd72, 8'd7, 8'd20, -8'd70, -8'd72, -8'd127, -8'd124,
            -8'd5, 8'd2, 8'd59, 8'd15, -8'd5, -8'd52, -8'd114, -8'd82, 8'd20,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd77, -8'd95, 8'd102, -8'd38, -8'd37, -8'd120, -8'd104, -8'd7, -8'd125,
            8'd80, 8'd41, 8'd3, -8'd57, 8'd94, 8'd81, -8'd36, 8'd61, 8'd106,
            -8'd83, 8'd78, -8'd55, 8'd4, -8'd76, -8'd79, -8'd22, -8'd107, 8'd68,
            8'd109, -8'd83, 8'd36, -8'd73, 8'd7, 8'd95, 8'd68, 8'd65, 8'd10,
            8'd15, -8'd53, -8'd16, 8'd112, -8'd52, -8'd96, 8'd74, -8'd37, 8'd42,
            8'd13, -8'd8, -8'd26, -8'd114, -8'd55, 8'd79, -8'd105, 8'd85, -8'd101,
            -8'd121, 8'd53, 8'd72, 8'd27, -8'd1, -8'd97, -8'd7, 8'd54, 8'd48,
            -8'd57, 8'd105, -8'd43, -8'd12, -8'd27, -8'd119, -8'd76, -8'd100, 8'd103,
            -8'd118, -8'd91, -8'd117, 8'd54, 8'd78, -8'd79, -8'd114, -8'd65, -8'd81,
            8'd4, 8'd18, -8'd20, 8'd85, -8'd58, 8'd61, 8'd45, -8'd44, -8'd43,
            -8'd54, 8'd79, 8'd4, -8'd31, 8'd58, 8'd14, 8'd104, 8'd25, 8'd46,
            8'd95, -8'd50, -8'd89, 8'd40, 8'd75, 8'd35, -8'd6, -8'd127, -8'd68,
            8'd72, -8'd109, -8'd111, -8'd42, 8'd18, -8'd84, -8'd102, -8'd5, -8'd92,
            -8'd9, 8'd70, 8'd88, -8'd111, 8'd116, 8'd93, -8'd79, -8'd85, 8'd27,
            -8'd40, -8'd100, -8'd95, -8'd67, 8'd54, -8'd23, -8'd43, -8'd41, -8'd77,
            8'd21, -8'd87, -8'd52, -8'd75, 8'd11, -8'd11, -8'd17, -8'd37, -8'd127,
            -8'd121, 8'd111, -8'd88, -8'd20, 8'd57, -8'd9, -8'd25, 8'd94, 8'd47,
            -8'd14, 8'd78, 8'd72, -8'd8, 8'd76, 8'd39, -8'd81, 8'd7, -8'd21,
            -8'd57, 8'd90, 8'd82, -8'd94, 8'd58, -8'd119, -8'd66, 8'd25, -8'd61,
            -8'd97, 8'd96, -8'd61, -8'd103, -8'd4, 8'd10, 8'd54, 8'd13, -8'd28,
            8'd69, 8'd8, 8'd96, -8'd33, 8'd100, 8'd60, 8'd24, 8'd77, 8'd59,
            8'd57, -8'd11, -8'd83, 8'd59, 8'd47, -8'd117, -8'd6, -8'd123, 8'd103,
            -8'd6, -8'd9, -8'd22, 8'd6, -8'd115, -8'd24, 8'd108, -8'd7, 8'd105,
            -8'd78, -8'd90, -8'd16, -8'd11, -8'd61, -8'd8, 8'd65, 8'd82, 8'd17,
            8'd45, -8'd46, -8'd81, 8'd9, 8'd14, 8'd107, 8'd43, -8'd78, -8'd109,
            -8'd109, 8'd80, 8'd110, 8'd3, 8'd18, -8'd94, 8'd35, -8'd67, 8'd107,
            8'd35, -8'd49, -8'd74, 8'd47, 8'd33, 8'd68, 8'd20, 8'd79, -8'd117,
            -8'd107, -8'd87, 8'd42, -8'd77, -8'd109, -8'd73, -8'd33, -8'd111, -8'd115,
            8'd116, -8'd10, -8'd41, 8'd44, -8'd40, 8'd27, 8'd7, 8'd91, -8'd99,
            8'd90, -8'd9, -8'd15, -8'd32, 8'd78, 8'd112, -8'd99, -8'd57, -8'd39,
            8'd61, -8'd36, -8'd73, 8'd39, -8'd42, -8'd32, -8'd48, 8'd38, -8'd120,
            -8'd109, 8'd25, 8'd38, -8'd113, -8'd65, 8'd42, 8'd96, 8'd6, -8'd18,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd11, 8'd38, 8'd48, 8'd26, 8'd18, -8'd33, 8'd21, 8'd15, -8'd37,
            -8'd38, 8'd1, 8'd36, 8'd11, 8'd11, -8'd7, 8'd28, -8'd7, -8'd12,
            -8'd92, -8'd91, -8'd9, -8'd47, 8'd24, 8'd46, -8'd16, -8'd42, -8'd4,
            -8'd12, 8'd5, 8'd38, 8'd34, 8'd34, 8'd12, 8'd15, 8'd16, -8'd18,
            -8'd26, -8'd10, -8'd18, -8'd8, -8'd18, -8'd24, 8'd0, 8'd2, -8'd7,
            -8'd40, -8'd29, -8'd88, -8'd28, -8'd52, -8'd6, -8'd90, -8'd122, -8'd85,
            -8'd72, -8'd64, -8'd69, -8'd16, 8'd16, 8'd22, -8'd38, -8'd28, -8'd37,
            8'd11, 8'd21, -8'd24, 8'd6, -8'd4, 8'd22, -8'd25, 8'd3, -8'd23,
            -8'd36, -8'd15, 8'd60, -8'd20, 8'd30, 8'd0, -8'd11, -8'd29, 8'd4,
            -8'd3, 8'd25, 8'd5, 8'd23, 8'd11, -8'd11, 8'd24, -8'd13, -8'd27,
            8'd22, -8'd18, 8'd17, -8'd2, -8'd20, -8'd13, 8'd3, -8'd20, 8'd17,
            -8'd62, 8'd4, 8'd17, 8'd24, 8'd7, -8'd28, -8'd6, 8'd2, -8'd19,
            8'd74, 8'd69, -8'd59, -8'd43, -8'd103, 8'd37, -8'd105, 8'd5, -8'd27,
            8'd10, 8'd3, 8'd6, -8'd3, -8'd20, -8'd16, -8'd30, 8'd14, 8'd23,
            -8'd6, 8'd32, 8'd24, 8'd23, 8'd24, -8'd45, 8'd38, -8'd3, -8'd29,
            -8'd22, 8'd8, 8'd26, 8'd35, -8'd7, -8'd40, -8'd6, -8'd35, -8'd31,
            -8'd40, 8'd17, 8'd40, 8'd18, 8'd25, -8'd29, 8'd21, -8'd36, -8'd4,
            8'd8, 8'd72, 8'd71, 8'd106, 8'd127, 8'd73, 8'd40, -8'd6, 8'd42,
            -8'd16, -8'd24, 8'd28, -8'd7, 8'd22, 8'd3, 8'd11, 8'd5, -8'd17,
            8'd15, 8'd8, -8'd26, 8'd5, -8'd16, 8'd5, -8'd17, -8'd4, -8'd27,
            -8'd23, 8'd42, 8'd31, 8'd35, 8'd25, -8'd2, 8'd23, -8'd5, -8'd1,
            -8'd39, -8'd4, -8'd8, -8'd65, -8'd18, 8'd13, -8'd21, -8'd5, -8'd22,
            -8'd9, 8'd32, 8'd8, 8'd8, 8'd9, -8'd41, -8'd2, -8'd3, -8'd13,
            8'd5, 8'd62, 8'd47, 8'd19, 8'd17, -8'd38, 8'd42, -8'd23, -8'd11,
            -8'd35, -8'd3, -8'd19, 8'd9, -8'd15, -8'd32, -8'd7, 8'd23, -8'd59,
            8'd7, 8'd4, -8'd17, -8'd18, -8'd12, 8'd20, -8'd6, -8'd21, -8'd24,
            -8'd58, -8'd6, 8'd24, -8'd32, -8'd78, -8'd70, -8'd23, -8'd5, -8'd33,
            -8'd19, 8'd12, -8'd14, -8'd7, 8'd15, -8'd27, -8'd12, 8'd22, 8'd3,
            -8'd15, 8'd20, 8'd20, -8'd11, -8'd12, 8'd14, -8'd22, -8'd23, -8'd27,
            -8'd10, -8'd53, -8'd17, -8'd79, -8'd42, 8'd17, -8'd96, -8'd44, 8'd1,
            -8'd76, 8'd14, 8'd81, 8'd61, 8'd125, 8'd39, 8'd66, 8'd33, 8'd61,
            -8'd29, -8'd7, 8'd72, -8'd15, 8'd30, -8'd49, 8'd38, -8'd24, -8'd19,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd44, -8'd1, -8'd24, 8'd22, 8'd42, 8'd22, 8'd2, 8'd22, 8'd48,
            8'd15, -8'd52, -8'd40, -8'd9, 8'd17, -8'd10, 8'd5, 8'd1, 8'd7,
            -8'd4, -8'd21, -8'd18, -8'd15, -8'd52, -8'd11, -8'd47, -8'd69, -8'd41,
            -8'd25, -8'd14, -8'd45, -8'd13, -8'd12, 8'd10, 8'd17, 8'd32, -8'd15,
            -8'd10, -8'd12, 8'd24, 8'd10, -8'd21, 8'd9, 8'd11, 8'd24, -8'd19,
            -8'd31, 8'd5, -8'd9, -8'd37, -8'd38, 8'd4, -8'd62, -8'd75, -8'd34,
            8'd7, -8'd3, -8'd9, -8'd28, -8'd54, -8'd14, -8'd32, -8'd61, -8'd38,
            -8'd25, -8'd1, -8'd11, -8'd13, 8'd5, 8'd25, -8'd15, -8'd26, -8'd3,
            8'd5, -8'd34, 8'd19, 8'd29, -8'd11, -8'd1, 8'd33, 8'd48, 8'd1,
            -8'd2, -8'd68, -8'd63, -8'd6, 8'd19, -8'd40, 8'd34, 8'd19, 8'd19,
            -8'd9, 8'd19, -8'd27, 8'd12, -8'd10, -8'd26, -8'd11, 8'd15, -8'd10,
            -8'd9, -8'd35, -8'd60, 8'd37, -8'd12, -8'd27, 8'd12, 8'd24, -8'd11,
            8'd16, 8'd24, 8'd19, 8'd30, 8'd31, 8'd52, -8'd13, 8'd1, 8'd18,
            8'd2, 8'd26, 8'd11, 8'd6, 8'd28, -8'd15, -8'd2, -8'd7, 8'd18,
            -8'd2, -8'd17, -8'd65, 8'd35, -8'd22, 8'd14, -8'd10, 8'd27, 8'd33,
            -8'd13, -8'd16, -8'd69, 8'd16, 8'd30, 8'd0, 8'd29, 8'd40, 8'd17,
            -8'd11, -8'd10, -8'd63, 8'd13, 8'd0, -8'd17, 8'd10, -8'd9, 8'd16,
            8'd7, 8'd53, 8'd57, -8'd36, -8'd70, -8'd21, 8'd39, -8'd55, 8'd2,
            8'd13, 8'd9, 8'd2, -8'd22, 8'd20, -8'd11, 8'd26, -8'd25, 8'd13,
            -8'd15, 8'd13, 8'd23, 8'd26, -8'd23, -8'd24, 8'd6, -8'd16, 8'd24,
            -8'd24, -8'd24, -8'd64, -8'd8, 8'd11, -8'd36, 8'd25, -8'd18, 8'd16,
            8'd4, -8'd33, 8'd40, 8'd27, 8'd7, -8'd33, 8'd48, 8'd21, 8'd8,
            8'd30, 8'd10, -8'd57, 8'd17, 8'd16, 8'd27, -8'd5, 8'd24, 8'd60,
            8'd22, -8'd14, -8'd51, 8'd11, 8'd21, 8'd20, -8'd12, 8'd12, 8'd44,
            8'd13, 8'd4, -8'd55, 8'd38, 8'd29, -8'd15, 8'd9, 8'd13, 8'd13,
            8'd26, 8'd9, -8'd22, 8'd14, -8'd27, 8'd16, 8'd19, -8'd8, -8'd6,
            8'd20, -8'd41, -8'd38, 8'd53, 8'd65, -8'd73, 8'd40, 8'd127, 8'd16,
            8'd10, -8'd3, -8'd14, 8'd7, 8'd12, -8'd19, -8'd29, -8'd10, 8'd9,
            8'd12, 8'd18, 8'd18, 8'd3, 8'd11, -8'd25, -8'd16, 8'd19, -8'd15,
            -8'd16, -8'd2, 8'd26, 8'd22, -8'd29, 8'd14, 8'd30, 8'd58, 8'd8,
            8'd46, 8'd25, -8'd16, -8'd18, -8'd62, 8'd26, -8'd2, -8'd30, 8'd29,
            8'd30, -8'd54, -8'd36, 8'd58, 8'd2, -8'd61, 8'd46, 8'd55, 8'd36,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd88, 8'd77, -8'd20, -8'd29, 8'd1, -8'd21, -8'd14, -8'd37, 8'd45,
            8'd75, -8'd15, 8'd84, 8'd31, -8'd69, -8'd45, -8'd111, 8'd54, -8'd100,
            -8'd65, 8'd20, -8'd65, 8'd14, -8'd8, 8'd40, -8'd23, 8'd5, 8'd77,
            8'd76, 8'd90, 8'd83, -8'd81, 8'd93, -8'd88, 8'd60, 8'd47, -8'd98,
            8'd18, 8'd91, 8'd27, -8'd62, -8'd3, 8'd95, 8'd35, 8'd81, 8'd108,
            -8'd108, 8'd0, 8'd52, -8'd59, -8'd36, -8'd87, -8'd64, 8'd56, 8'd48,
            8'd46, -8'd60, -8'd19, 8'd2, 8'd24, -8'd71, 8'd26, 8'd43, 8'd47,
            -8'd65, 8'd58, 8'd24, -8'd39, 8'd53, 8'd49, 8'd34, -8'd5, 8'd65,
            -8'd96, -8'd41, 8'd6, -8'd85, -8'd12, 8'd84, -8'd58, 8'd36, 8'd19,
            -8'd34, 8'd86, -8'd39, -8'd1, -8'd38, 8'd73, -8'd101, -8'd87, 8'd21,
            8'd42, 8'd38, -8'd13, -8'd100, -8'd88, 8'd74, 8'd53, -8'd52, -8'd93,
            8'd25, -8'd70, -8'd22, -8'd94, 8'd56, -8'd15, 8'd28, -8'd122, -8'd92,
            -8'd34, -8'd76, -8'd103, -8'd29, -8'd40, -8'd18, 8'd43, 8'd18, -8'd32,
            -8'd37, -8'd85, 8'd69, 8'd15, 8'd100, 8'd38, -8'd94, -8'd50, -8'd85,
            8'd73, 8'd1, -8'd60, 8'd19, 8'd80, 8'd12, -8'd68, -8'd5, 8'd60,
            -8'd89, -8'd127, 8'd65, -8'd97, -8'd33, -8'd41, -8'd6, -8'd27, -8'd126,
            -8'd59, 8'd0, -8'd26, -8'd4, -8'd23, -8'd97, 8'd59, -8'd37, -8'd44,
            -8'd81, -8'd46, 8'd69, -8'd47, 8'd5, 8'd54, -8'd29, -8'd30, 8'd106,
            8'd56, 8'd59, -8'd73, 8'd104, 8'd47, 8'd94, 8'd16, -8'd83, 8'd32,
            8'd93, 8'd42, 8'd79, 8'd85, -8'd15, -8'd25, 8'd5, 8'd57, -8'd95,
            8'd8, -8'd52, -8'd37, 8'd73, 8'd64, -8'd45, 8'd25, -8'd70, 8'd54,
            -8'd23, 8'd38, -8'd95, -8'd121, 8'd44, 8'd61, -8'd29, -8'd81, 8'd84,
            -8'd14, -8'd56, -8'd66, -8'd109, 8'd28, -8'd46, -8'd89, -8'd37, 8'd49,
            -8'd62, 8'd57, -8'd34, 8'd33, -8'd18, -8'd124, -8'd17, 8'd1, -8'd81,
            -8'd11, -8'd18, -8'd101, -8'd52, 8'd50, -8'd54, -8'd36, 8'd6, 8'd33,
            -8'd37, 8'd8, -8'd71, 8'd83, -8'd82, 8'd9, 8'd105, 8'd66, -8'd108,
            8'd52, -8'd118, -8'd89, -8'd70, -8'd37, -8'd10, -8'd105, 8'd73, -8'd103,
            -8'd77, -8'd33, 8'd54, 8'd41, -8'd31, -8'd57, 8'd94, 8'd25, -8'd89,
            8'd18, 8'd32, 8'd64, 8'd45, 8'd108, -8'd34, 8'd10, 8'd98, 8'd101,
            8'd54, 8'd0, 8'd50, 8'd65, -8'd22, 8'd32, 8'd27, -8'd90, -8'd56,
            -8'd51, 8'd39, -8'd77, -8'd7, 8'd34, 8'd20, 8'd59, -8'd84, -8'd2,
            -8'd111, 8'd23, -8'd87, -8'd122, 8'd56, 8'd41, -8'd85, -8'd37, 8'd76,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            -8'd31, 8'd11, -8'd28, -8'd36, -8'd12, -8'd1, 8'd5, -8'd40, 8'd7,
            -8'd19, 8'd24, 8'd28, -8'd6, 8'd0, -8'd3, -8'd60, -8'd3, 8'd37,
            8'd14, -8'd13, 8'd69, 8'd28, -8'd26, -8'd5, -8'd2, 8'd0, -8'd81,
            8'd28, 8'd31, 8'd1, -8'd26, -8'd5, 8'd15, -8'd9, 8'd17, 8'd2,
            -8'd8, 8'd13, 8'd18, -8'd12, 8'd20, 8'd0, 8'd10, -8'd4, 8'd14,
            -8'd5, -8'd35, -8'd60, -8'd18, -8'd24, -8'd108, -8'd22, -8'd6, -8'd92,
            -8'd38, -8'd47, -8'd34, 8'd35, -8'd16, -8'd24, -8'd18, 8'd6, -8'd64,
            -8'd16, 8'd17, 8'd14, 8'd28, 8'd16, -8'd1, -8'd27, -8'd25, -8'd23,
            8'd12, -8'd24, 8'd43, 8'd4, -8'd10, 8'd0, 8'd29, 8'd14, -8'd11,
            8'd11, 8'd33, -8'd10, -8'd8, 8'd1, 8'd13, -8'd28, 8'd20, 8'd13,
            -8'd26, -8'd23, -8'd26, 8'd0, -8'd8, 8'd21, -8'd26, -8'd18, 8'd13,
            -8'd7, -8'd4, -8'd21, -8'd21, 8'd42, 8'd21, -8'd42, -8'd33, 8'd33,
            -8'd8, -8'd32, 8'd6, 8'd41, -8'd64, 8'd23, 8'd54, -8'd26, -8'd38,
            8'd16, 8'd2, -8'd30, -8'd16, -8'd5, -8'd13, 8'd15, 8'd10, 8'd2,
            -8'd18, -8'd11, -8'd23, 8'd3, 8'd5, -8'd33, -8'd54, -8'd8, 8'd36,
            8'd17, 8'd15, 8'd22, -8'd22, -8'd2, 8'd4, -8'd60, -8'd30, 8'd28,
            8'd14, 8'd35, 8'd28, -8'd35, -8'd23, 8'd9, -8'd50, 8'd20, 8'd42,
            8'd77, -8'd44, 8'd69, 8'd54, 8'd52, -8'd73, 8'd64, -8'd48, -8'd127,
            -8'd30, 8'd13, 8'd9, -8'd30, 8'd4, -8'd11, 8'd25, 8'd12, 8'd29,
            -8'd10, 8'd21, -8'd29, 8'd7, -8'd11, -8'd2, 8'd18, 8'd26, 8'd16,
            -8'd6, 8'd14, 8'd17, -8'd42, 8'd9, -8'd43, -8'd25, -8'd53, 8'd6,
            8'd14, 8'd50, 8'd25, 8'd11, 8'd19, -8'd47, 8'd7, 8'd51, 8'd35,
            -8'd11, 8'd31, 8'd30, -8'd37, 8'd19, 8'd61, -8'd24, -8'd58, 8'd40,
            -8'd25, -8'd10, -8'd14, -8'd32, 8'd10, -8'd14, -8'd23, -8'd18, -8'd5,
            -8'd26, 8'd32, 8'd6, -8'd18, 8'd32, 8'd1, -8'd52, -8'd37, 8'd29,
            8'd3, -8'd29, 8'd4, -8'd27, -8'd8, 8'd20, 8'd17, 8'd12, 8'd4,
            8'd26, 8'd91, 8'd50, -8'd37, 8'd86, 8'd101, -8'd37, 8'd13, 8'd127,
            -8'd16, 8'd1, 8'd32, 8'd24, -8'd14, 8'd9, -8'd24, -8'd25, -8'd1,
            8'd9, -8'd8, -8'd18, 8'd4, -8'd19, -8'd3, 8'd27, -8'd24, -8'd18,
            8'd63, -8'd21, -8'd20, -8'd10, -8'd11, -8'd46, 8'd6, 8'd55, 8'd37,
            8'd37, 8'd32, 8'd107, 8'd9, -8'd19, 8'd38, -8'd39, -8'd57, -8'd9,
            8'd52, 8'd33, -8'd12, -8'd10, 8'd17, -8'd21, 8'd11, 8'd62, 8'd59, 
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0
        };

 
        for (i = 0; i < KER_SIZE; i = i + 4) begin
            ram.mem[1500 + (i / 4)][ 7: 0] = filter_data[8*(KER_SIZE - 1 - i) +: 8];
            ram.mem[1500 + (i / 4)][15: 8] = filter_data[8*(KER_SIZE - 2 - i) +: 8];
            ram.mem[1500 + (i / 4)][23:16] = filter_data[8*(KER_SIZE - 3 - i) +: 8];
            ram.mem[1500 + (i / 4)][31:24] = filter_data[8*(KER_SIZE - 4 - i) +: 8];
        end

        // $display("KERNEL RESULT");
        // for (int i = 1500; i < 1500 + KER_SIZE/4; i = i + 1) begin
        //     $display("%d %d %d %d", 
        //         $signed(ram.mem[i][ 7: 0]), 
        //         $signed(ram.mem[i][15: 8]), 
        //         $signed(ram.mem[i][23:16]), 
        //         $signed(ram.mem[i][31:24])
        //     ); 
        // end
        // $display("*************");
        // Bias
        bias_data = {
            -32'd28517, 32'd2966, 32'd5775, 32'd5654, -32'd11145, 32'd7002, 32'd8439, -32'd9378, 32'd8529, -32'd489, -32'd38044, -32'd34300, 32'd4925, -32'd28784, -32'd1970, 32'd60, -32'd8178, -32'd26840, -32'd28935, -32'd31502, -32'd10251, 32'd6148, -32'd3370, -32'd8798, 32'd7343, -32'd44597, -32'd6740, -32'd31376, -32'd15323, 32'd3003, -32'd31031, -32'd2781
        };

        for (i = 0; i < BIS_SIZE; i = i + 1) begin
            ram.mem[1400 + i] = bias_data[32*(BIS_SIZE - 1 - i) +: 32];
        end

    end
/*******************/

`endif 

    // Module init
    al_accel uut (
        .al_accel_cfgreg_di     (al_accel_cfgreg_di),
        .al_accel_cfgreg_sel    (al_accel_cfgreg_sel),
        .al_accel_cfgreg_wenb   (al_accel_cfgreg_wenb),

        .al_accel_rdata         (al_accel_rdata),
        .al_accel_raddr         (al_accel_raddr),
        .al_accel_renb          (al_accel_renb),
        .al_accel_mem_read_ready    (al_accel_mem_read_ready),
        .al_accel_mem_write_ready   (al_accel_mem_write_ready),

        .al_accel_wdata         (al_accel_wdata),
        .al_accel_waddr         (al_accel_waddr),
        .al_accel_wenb          (al_accel_wenb),
        .al_accel_wstrb         (al_accel_wstrb),

        .al_accel_flow_enb      (al_accel_flow_enb),
        .al_accel_flow_resetn   (resetn),

        .clk    (clk),
        .resetn (resetn)
    );

    al_accel_mem ram (
        .renb   (al_accel_renb),
        .raddr  (al_accel_raddr[31:2]),
        .rdata  (al_accel_rdata),

        .wenb   (al_accel_wenb),
        .wstrb  (al_accel_wstrb),
        .waddr  (al_accel_waddr[31:2]),
        .wdata  (al_accel_wdata),

        .clk    (clk)
    );

    // For display value
    task display_matrix (
        input integer base_addr,  
        input integer width,       
        input integer height,      
        input integer channels    
    );
        begin
            integer channel, row, col, idx, mem_idx, val_idx;
            reg signed [7:0] value;
                        
            for (channel = 0; channel < channels; channel = channel + 1) begin
                $display("Channel %0d:", channel);
                
                for (row = 0; row < height; row = row + 1) begin
                    for (col = 0; col < width; col = col + 1) begin
                        // Tính vị trí trong bộ nhớ
                        idx = channel * (width * height) + row * width + col;
                        mem_idx = base_addr + idx / 4;
                        val_idx = idx % 4;
                        
                        if (val_idx == 0) value = ram.mem[mem_idx][ 7: 0];
                        else if (val_idx == 1) value = ram.mem[mem_idx][15: 8];
                        else if (val_idx == 2) value = ram.mem[mem_idx][23:16];
                        else value = ram.mem[mem_idx][31:24];
                        
                        $write("%d ", value);
                    end
                    $display(""); 
                end
                $display("*************");
            end
        end
    endtask


    // Debug Info
    initial begin
        $dumpfile("accel_vcd/al_accel_tb.vcd");
        $dumpvars(0, al_accel_tb);

        repeat (`TIME_TO_REPEAT) begin
			repeat (100000) @(posedge clk);
		end
        $display("HARDWARE RESULT");
        display_matrix(4000, OUTPUT_WIDTH, OUTPUT_HEIGHT, OUTPUT_DEPTH);

		$finish;
    end
endmodule

module al_accel_mem #(
	parameter integer WORDS = 32768
) (
    input              renb,
    input       [17:0] raddr,
    output reg  [31:0] rdata,

    input              wenb,
	input       [ 3:0] wstrb,
	input       [17:0] waddr,
	input       [31:0] wdata,
	
    input clk
);
	reg [31:0] mem [WORDS - 1:0];

	always @(posedge clk) begin
        if (renb)
            rdata <= mem[raddr];
        
        if (wenb) begin
            if (wstrb[0]) mem[waddr][ 7: 0] <= wdata[ 7: 0];
            if (wstrb[1]) mem[waddr][15: 8] <= wdata[15: 8];
            if (wstrb[2]) mem[waddr][23:16] <= wdata[23:16];
            if (wstrb[3]) mem[waddr][31:24] <= wdata[31:24];
        end
	end
endmodule



// waddr in mem [31:2] and raddr in mem [31:2]



