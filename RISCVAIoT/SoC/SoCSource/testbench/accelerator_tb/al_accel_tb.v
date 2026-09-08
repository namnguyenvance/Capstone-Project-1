`timescale 1 ns / 1 ps

`define TIME_TO_REPEAT 6

module al_accel_tb;
    localparam 
        CONV    = 4'd 0,
        DENSE   = 4'd 1,
        POOL    = 4'd 2;

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

// Convolutional Layer
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
        PAS_SIZE = 5 * 5 * 6;

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
        al_accel_cfgreg_di   = 32'd 1000; al_accel_cfgreg_sel = 5'd 0; 

        #10 // kw_base_addr
        al_accel_cfgreg_di   = 32'd 2000;       al_accel_cfgreg_sel = 5'd 1; 

        #10 // o_base_addr
        al_accel_cfgreg_di   = 32'd 3000;       al_accel_cfgreg_sel = 5'd 2; 

        #10 // b_base_addr
        al_accel_cfgreg_di   = 32'd 4000;       al_accel_cfgreg_sel = 5'd 3; 

        #10 // ps_base_addr
        al_accel_cfgreg_di   = 32'd 5000;       al_accel_cfgreg_sel = 5'd 4; 

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
        for (i = 0; i < (7 * 7 * 3 + 1); i = i + 4) begin
            ram.mem[250 + (i / 4)][ 7: 0] = input_data[8*((7 * 7 * 3 + 1) - 1 - i) +: 8];
            ram.mem[250 + (i / 4)][15: 8] = input_data[8*((7 * 7 * 3 + 1) - 2 - i) +: 8];
            ram.mem[250 + (i / 4)][23:16] = input_data[8*((7 * 7 * 3 + 1) - 3 - i) +: 8];
            ram.mem[250 + (i / 4)][31:24] = input_data[8*((7 * 7 * 3 + 1) - 4 - i) +: 8];
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
        for (i = 0; i < (3 * 3 * 3 * 6 + 2); i = i + 4) begin
            ram.mem[500 + (i / 4)][ 7: 0] = filter_data[8*((3 * 3 * 3 * 6 + 2) - 1 - i) +: 8];
            ram.mem[500 + (i / 4)][15: 8] = filter_data[8*((3 * 3 * 3 * 6 + 2) - 2 - i) +: 8];
            ram.mem[500 + (i / 4)][23:16] = filter_data[8*((3 * 3 * 3 * 6 + 2) - 3 - i) +: 8];
            ram.mem[500 + (i / 4)][31:24] = filter_data[8*((3 * 3 * 3 * 6 + 2) - 4 - i) +: 8];
        end

        // Bias
        bias_data = {
            32'd 20, 32'd 31, 32'd 42, 32'd 54,-32'd 15, 32'd 67
        };
        for (i = 0; i < 6; i = i + 1) begin
            ram.mem[1000 + i] = bias_data[32*(6 - 1 - i) +: 32];
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
        PAS_SIZE = 5 * 5 * 6;

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
        al_accel_cfgreg_di   = 32'd 1000;       al_accel_cfgreg_sel = 5'd 0; 

        #10 // kw_base_addr
        al_accel_cfgreg_di   = 32'd 2000;       al_accel_cfgreg_sel = 5'd 1; 

        #10 // o_base_addr
        al_accel_cfgreg_di   = 32'd 3000;       al_accel_cfgreg_sel = 5'd 2; 

        #10 // b_base_addr
        al_accel_cfgreg_di   = 32'd 4000;       al_accel_cfgreg_sel = 5'd 3; 

        #10 // ps_base_addr
        al_accel_cfgreg_di   = 32'd 5000;       al_accel_cfgreg_sel = 5'd 4; 

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
        for (i = 0; i < (7 * 7 * 6 + 2); i = i + 4) begin
            ram.mem[250 + (i / 4)][ 7: 0] = input_data[8*((7 * 7 * 6 + 2) - 1 - i) +: 8];
            ram.mem[250 + (i / 4)][15: 8] = input_data[8*((7 * 7 * 6 + 2) - 2 - i) +: 8];
            ram.mem[250 + (i / 4)][23:16] = input_data[8*((7 * 7 * 6 + 2) - 3 - i) +: 8];
            ram.mem[250 + (i / 4)][31:24] = input_data[8*((7 * 7 * 6 + 2) - 4 - i) +: 8];
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
        for (i = 0; i < (3 * 3 * 6 * 6); i = i + 4) begin
            ram.mem[500 + (i / 4)][ 7: 0] = filter_data[8*((3 * 3 * 6 * 6) - 1 - i) +: 8];
            ram.mem[500 + (i / 4)][15: 8] = filter_data[8*((3 * 3 * 6 * 6) - 2 - i) +: 8];
            ram.mem[500 + (i / 4)][23:16] = filter_data[8*((3 * 3 * 6 * 6) - 3 - i) +: 8];
            ram.mem[500 + (i / 4)][31:24] = filter_data[8*((3 * 3 * 6 * 6) - 4 - i) +: 8];
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
        for (i = 0; i < 6; i = i + 1) begin
            ram.mem[1000 + i] = bias_data[32*(6 - 1 - i) +: 32];
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
        PAS_SIZE = 5 * 5 * 9;

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
        al_accel_cfgreg_di   = 32'd 1000;       al_accel_cfgreg_sel = 5'd 0; 

        #10 // kw_base_addr
        al_accel_cfgreg_di   = 32'd 2000;       al_accel_cfgreg_sel = 5'd 1; 

        #10 // o_base_addr
        al_accel_cfgreg_di   = 32'd 3000;       al_accel_cfgreg_sel = 5'd 2; 

        #10 // b_base_addr
        al_accel_cfgreg_di   = 32'd 4000;       al_accel_cfgreg_sel = 5'd 3; 

        #10 // ps_base_addr
        al_accel_cfgreg_di   = 32'd 5000;       al_accel_cfgreg_sel = 5'd 4; 

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
        for (i = 0; i < IFM_SIZE; i = i + 4) begin
            ram.mem[250 + (i / 4)][ 7: 0] = input_data[8*(IFM_SIZE - 1 - i) +: 8];
            ram.mem[250 + (i / 4)][15: 8] = input_data[8*(IFM_SIZE - 2 - i) +: 8];
            ram.mem[250 + (i / 4)][23:16] = input_data[8*(IFM_SIZE - 3 - i) +: 8];
            ram.mem[250 + (i / 4)][31:24] = input_data[8*(IFM_SIZE - 4 - i) +: 8];
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
    /////
        for (i = 0; i < KER_SIZE; i = i + 4) begin
            ram.mem[500 + (i / 4)][ 7: 0] = filter_data[8*(KER_SIZE - 1 - i) +: 8];
            ram.mem[500 + (i / 4)][15: 8] = filter_data[8*(KER_SIZE - 2 - i) +: 8];
            ram.mem[500 + (i / 4)][23:16] = filter_data[8*(KER_SIZE - 3 - i) +: 8];
            ram.mem[500 + (i / 4)][31:24] = filter_data[8*(KER_SIZE - 4 - i) +: 8];
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
            ram.mem[1000 + i] = bias_data[32*(BIS_SIZE - 1 - i) +: 32];
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
        PAS_SIZE = 3 * 3 * 6;

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
        al_accel_cfgreg_di   = 32'd 1000;       al_accel_cfgreg_sel = 5'd 0; 

        #10 // kw_base_addr
        al_accel_cfgreg_di   = 32'd 2000;       al_accel_cfgreg_sel = 5'd 1; 

        #10 // o_base_addr
        al_accel_cfgreg_di   = 32'd 3000;       al_accel_cfgreg_sel = 5'd 2; 

        #10 // b_base_addr
        al_accel_cfgreg_di   = 32'd 4000;       al_accel_cfgreg_sel = 5'd 3; 

        #10 // ps_base_addr
        al_accel_cfgreg_di   = 32'd 5000;       al_accel_cfgreg_sel = 5'd 4; 

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
        for (i = 0; i < IFM_SIZE; i = i + 4) begin
            ram.mem[250 + (i / 4)][ 7: 0] = input_data[8*(IFM_SIZE - 1 - i) +: 8];
            ram.mem[250 + (i / 4)][15: 8] = input_data[8*(IFM_SIZE - 2 - i) +: 8];
            ram.mem[250 + (i / 4)][23:16] = input_data[8*(IFM_SIZE - 3 - i) +: 8];
            ram.mem[250 + (i / 4)][31:24] = input_data[8*(IFM_SIZE - 4 - i) +: 8];
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
            ram.mem[500 + (i / 4)][ 7: 0] = filter_data[8*(KER_SIZE - 1 - i) +: 8];
            ram.mem[500 + (i / 4)][15: 8] = filter_data[8*(KER_SIZE - 2 - i) +: 8];
            ram.mem[500 + (i / 4)][23:16] = filter_data[8*(KER_SIZE - 3 - i) +: 8];
            ram.mem[500 + (i / 4)][31:24] = filter_data[8*(KER_SIZE - 4 - i) +: 8];
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
            ram.mem[1000 + i] = bias_data[32*(BIS_SIZE - 1 - i) +: 32];
        end

    end
/*******************/
`elsif CL_TC4
/* Test case 4 */
    /* 
        Description:
           - Input Feature Map's size : 7 x 7 x 6     => 294
           - Kernel's size            : 3 x 3 x 6 x 6 => 324
           - Output Feature Map's size: 5 x 5 x 6     => 150
           - Bias's size              : 6 x 4         =>  24
           - Partial-Sum's size       : 5 x 5 x 6 x 4 => 864
           - Stride's size            : 2 x 2
    */

    localparam 
        IFM_SIZE = 7 * 7 * 6     + 2,
        KER_SIZE = 3 * 3 * 6 * 6    ,
        OFM_SIZE = 3 * 3 * 6     + 2,
        BIS_SIZE = 6,
        PAS_SIZE = 5 * 5 * 6;

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
        al_accel_cfgreg_di   = 32'd 1000;       al_accel_cfgreg_sel = 5'd 0; 

        #10 // kw_base_addr
        al_accel_cfgreg_di   = 32'd 2000;       al_accel_cfgreg_sel = 5'd 1; 

        #10 // o_base_addr
        al_accel_cfgreg_di   = 32'd 3000;       al_accel_cfgreg_sel = 5'd 2; 

        #10 // b_base_addr
        al_accel_cfgreg_di   = 32'd 4000;       al_accel_cfgreg_sel = 5'd 3; 

        #10 // ps_base_addr
        al_accel_cfgreg_di   = 32'd 5000;       al_accel_cfgreg_sel = 5'd 4; 

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
        for (i = 0; i < IFM_SIZE; i = i + 4) begin
            ram.mem[250 + (i / 4)][ 7: 0] = input_data[8*(IFM_SIZE - 1 - i) +: 8];
            ram.mem[250 + (i / 4)][15: 8] = input_data[8*(IFM_SIZE - 2 - i) +: 8];
            ram.mem[250 + (i / 4)][23:16] = input_data[8*(IFM_SIZE - 3 - i) +: 8];
            ram.mem[250 + (i / 4)][31:24] = input_data[8*(IFM_SIZE - 4 - i) +: 8];
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
            ram.mem[500 + (i / 4)][ 7: 0] = filter_data[8*(KER_SIZE - 1 - i) +: 8];
            ram.mem[500 + (i / 4)][15: 8] = filter_data[8*(KER_SIZE - 2 - i) +: 8];
            ram.mem[500 + (i / 4)][23:16] = filter_data[8*(KER_SIZE - 3 - i) +: 8];
            ram.mem[500 + (i / 4)][31:24] = filter_data[8*(KER_SIZE - 4 - i) +: 8];
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
            ram.mem[1000 + i] = bias_data[32*(BIS_SIZE - 1 - i) +: 32];
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
        PAS_SIZE = 5 * 5 * 9;

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
        al_accel_cfgreg_di   = 32'd 1000;       al_accel_cfgreg_sel = 5'd 0; 

        #10 // kw_base_addr
        al_accel_cfgreg_di   = 32'd 2000;       al_accel_cfgreg_sel = 5'd 1; 

        #10 // o_base_addr
        al_accel_cfgreg_di   = 32'd 3000;       al_accel_cfgreg_sel = 5'd 2; 

        #10 // b_base_addr
        al_accel_cfgreg_di   = 32'd 4000;       al_accel_cfgreg_sel = 5'd 3; 

        #10 // ps_base_addr
        al_accel_cfgreg_di   = 32'd 5000;       al_accel_cfgreg_sel = 5'd 4; 

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
        for (i = 0; i < IFM_SIZE; i = i + 4) begin
            ram.mem[250 + (i / 4)][ 7: 0] = input_data[8*(IFM_SIZE - 1 - i) +: 8];
            ram.mem[250 + (i / 4)][15: 8] = input_data[8*(IFM_SIZE - 2 - i) +: 8];
            ram.mem[250 + (i / 4)][23:16] = input_data[8*(IFM_SIZE - 3 - i) +: 8];
            ram.mem[250 + (i / 4)][31:24] = input_data[8*(IFM_SIZE - 4 - i) +: 8];
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
    /////
        for (i = 0; i < KER_SIZE; i = i + 4) begin
            ram.mem[500 + (i / 4)][ 7: 0] = filter_data[8*(KER_SIZE - 1 - i) +: 8];
            ram.mem[500 + (i / 4)][15: 8] = filter_data[8*(KER_SIZE - 2 - i) +: 8];
            ram.mem[500 + (i / 4)][23:16] = filter_data[8*(KER_SIZE - 3 - i) +: 8];
            ram.mem[500 + (i / 4)][31:24] = filter_data[8*(KER_SIZE - 4 - i) +: 8];
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
            ram.mem[1000 + i] = bias_data[32*(BIS_SIZE - 1 - i) +: 32];
        end

    end
/*******************/
`endif

// Dense Layer
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
        PAS_SIZE =  9;

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
        al_accel_cfgreg_di   = 32'd 1000;       al_accel_cfgreg_sel = 5'd 0; 

        #10 // kw_base_addr
        al_accel_cfgreg_di   = 32'd 2000;       al_accel_cfgreg_sel = 5'd 1; 

        #10 // o_base_addr
        al_accel_cfgreg_di   = 32'd 3000;       al_accel_cfgreg_sel = 5'd 2; 

        #10 // b_base_addr
        al_accel_cfgreg_di   = 32'd 4000;       al_accel_cfgreg_sel = 5'd 3; 

        #10 // ps_base_addr
        al_accel_cfgreg_di   = 32'd 5000;       al_accel_cfgreg_sel = 5'd 4; 

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
        for (i = 0; i < IFM_SIZE; i = i + 4) begin
            ram.mem[250 + (i / 4)][ 7: 0] = input_data[8*(IFM_SIZE - 1 - i) +: 8];
            ram.mem[250 + (i / 4)][15: 8] = input_data[8*(IFM_SIZE - 2 - i) +: 8];
            ram.mem[250 + (i / 4)][23:16] = input_data[8*(IFM_SIZE - 3 - i) +: 8];
            ram.mem[250 + (i / 4)][31:24] = input_data[8*(IFM_SIZE - 4 - i) +: 8];
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
            ram.mem[500 + (i / 4)][ 7: 0] = filter_data[8*(KER_SIZE - 1 - i) +: 8];
            ram.mem[500 + (i / 4)][15: 8] = filter_data[8*(KER_SIZE - 2 - i) +: 8];
            ram.mem[500 + (i / 4)][23:16] = filter_data[8*(KER_SIZE - 3 - i) +: 8];
            ram.mem[500 + (i / 4)][31:24] = filter_data[8*(KER_SIZE - 4 - i) +: 8];
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
            ram.mem[1000 + i] = bias_data[32*(BIS_SIZE - 1 - i) +: 32];
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
        PAS_SIZE = 12;

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
        al_accel_cfgreg_di   = 32'd 1000; al_accel_cfgreg_sel = 5'd 0; 

        #10 // kw_base_addr
        al_accel_cfgreg_di   = 32'd 2000; al_accel_cfgreg_sel = 5'd 1; 

        #10 // o_base_addr
        al_accel_cfgreg_di   = 32'd 3000; al_accel_cfgreg_sel = 5'd 2; 

        #10 // b_base_addr
        al_accel_cfgreg_di   = 32'd 4000; al_accel_cfgreg_sel = 5'd 3; 

        #10 // ps_base_addr
        al_accel_cfgreg_di   = 32'd 5000; al_accel_cfgreg_sel = 5'd 4; 

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
        for (i = 0; i < IFM_SIZE; i = i + 4) begin
            ram.mem[250 + (i / 4)][ 7: 0] = input_data[8*(IFM_SIZE - 1 - i) +: 8];
            ram.mem[250 + (i / 4)][15: 8] = input_data[8*(IFM_SIZE - 2 - i) +: 8];
            ram.mem[250 + (i / 4)][23:16] = input_data[8*(IFM_SIZE - 3 - i) +: 8];
            ram.mem[250 + (i / 4)][31:24] = input_data[8*(IFM_SIZE - 4 - i) +: 8];
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
            ram.mem[500 + (i / 4)][ 7: 0] = filter_data[8*(KER_SIZE - 1 - i) +: 8];
            ram.mem[500 + (i / 4)][15: 8] = filter_data[8*(KER_SIZE - 2 - i) +: 8];
            ram.mem[500 + (i / 4)][23:16] = filter_data[8*(KER_SIZE - 3 - i) +: 8];
            ram.mem[500 + (i / 4)][31:24] = filter_data[8*(KER_SIZE - 4 - i) +: 8];
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
            ram.mem[1000 + i] = bias_data[32*(BIS_SIZE - 1 - i) +: 32];
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
        PAS_SIZE = 12;

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
        al_accel_cfgreg_di   = 32'd 1000; al_accel_cfgreg_sel = 5'd 0; 

        #10 // kw_base_addr
        al_accel_cfgreg_di   = 32'd 2000; al_accel_cfgreg_sel = 5'd 1; 

        #10 // o_base_addr
        al_accel_cfgreg_di   = 32'd 3000; al_accel_cfgreg_sel = 5'd 2; 

        #10 // b_base_addr
        al_accel_cfgreg_di   = 32'd 4000; al_accel_cfgreg_sel = 5'd 3; 

        #10 // ps_base_addr
        al_accel_cfgreg_di   = 32'd 5000; al_accel_cfgreg_sel = 5'd 4; 

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
        for (i = 0; i < IFM_SIZE; i = i + 4) begin
            ram.mem[250 + (i / 4)][ 7: 0] = input_data[8*(IFM_SIZE - 1 - i) +: 8];
            ram.mem[250 + (i / 4)][15: 8] = input_data[8*(IFM_SIZE - 2 - i) +: 8];
            ram.mem[250 + (i / 4)][23:16] = input_data[8*(IFM_SIZE - 3 - i) +: 8];
            ram.mem[250 + (i / 4)][31:24] = input_data[8*(IFM_SIZE - 4 - i) +: 8];
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
            ram.mem[500 + (i / 4)][ 7: 0] = filter_data[8*(KER_SIZE - 1 - i) +: 8];
            ram.mem[500 + (i / 4)][15: 8] = filter_data[8*(KER_SIZE - 2 - i) +: 8];
            ram.mem[500 + (i / 4)][23:16] = filter_data[8*(KER_SIZE - 3 - i) +: 8];
            ram.mem[500 + (i / 4)][31:24] = filter_data[8*(KER_SIZE - 4 - i) +: 8];
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
            ram.mem[1000 + i] = bias_data[32*(BIS_SIZE - 1 - i) +: 32];
        end

    end
/*******************/
`endif  
// /* Test case * -- Not handling */
//     /* 
//         Description:
//             - Input Feature Map's size : 18 x 1 =>  18
//             - Kernel's size            : 18 x 6 => 108
//             - Output Feature Map's size:  6 x 1 =>   6
//             - Bias's size              :  6 x 4 =>  24
//             - Partial-Sum's size       :  6 x 4 =>  24
//     */

//     // Note: Because this test case is too small. There are a bug where data is read before it was written. 

//     localparam 
//         IFM_SIZE = 18 * 1 + 2,
//         KER_SIZE = 18 * 6    ,
//         OFM_SIZE =  6 * 1 + 2,
//         BIS_SIZE =  6,
//         PAS_SIZE =  6;

//     initial begin
//         // al_accel_mem_read_ready = 1'b 0;
//         // al_accel_mem_write_ready = 1'b 0;
//         // #10
//         // repeat (2000) @(posedge clk) begin
//         //     #2 al_accel_mem_read_ready = $random;
//         // end
//         // #10 
//         al_accel_mem_read_ready    = 1'b 1;
//         al_accel_mem_write_ready   = 1'b 1;
//     end

//     initial begin
//         al_accel_cfgreg_di   = 32'd 0;       al_accel_cfgreg_sel = 5'd 0; 
//         al_accel_cfgreg_wenb =  1'd 0;
//         al_accel_flow_enb    =  1'b 0;
//         #42
//         al_accel_cfgreg_wenb =  1'd 1;
//     // Config Data
//         #10 // i_base_addr
//         al_accel_cfgreg_di   = 32'd 1000;       al_accel_cfgreg_sel = 5'd 0; 

//         #10 // kw_base_addr
//         al_accel_cfgreg_di   = 32'd 2000;       al_accel_cfgreg_sel = 5'd 1; 

//         #10 // o_base_addr
//         al_accel_cfgreg_di   = 32'd 3000;       al_accel_cfgreg_sel = 5'd 2; 

//         #10 // b_base_addr
//         al_accel_cfgreg_di   = 32'd 4000;       al_accel_cfgreg_sel = 5'd 3; 

//         #10 // ps_base_addr
//         al_accel_cfgreg_di   = 32'd 5000;       al_accel_cfgreg_sel = 5'd 4; 

//         #10 // {stride_height, stride_width, cfg_act_func_typ, cfg_layer_typ}
//         al_accel_cfgreg_di   = {16'd 0, 4'd 0, 4'd 0, NO_FUNC, DENSE}; al_accel_cfgreg_sel = 5'd 5; 

//         #10 // {weight_kernel_patch_height, weight_kernel_patch_width}
//         al_accel_cfgreg_di   = {16'd 6, 16'd 18}; al_accel_cfgreg_sel = 5'd 6; 

//         #10 // {nok_ofm_depth, kernel_ifm_depth} 
//         al_accel_cfgreg_di   = 32'd 0; al_accel_cfgreg_sel = 5'd 7;

//         #10 // {ifm_height, ifm_width}  
//         al_accel_cfgreg_di   = {16'd 1, 16'd 18}; al_accel_cfgreg_sel = 5'd 8;

//         #10 // {ofm_height, ofm_width}
//         al_accel_cfgreg_di   = {16'd 1, 16'd  6}; al_accel_cfgreg_sel = 5'd 9;

//         #10 // output_multiplier
//         al_accel_cfgreg_di   = 32'd 1073742347 ; al_accel_cfgreg_sel = 5'd 10;

//         #10 // output_shift
//         al_accel_cfgreg_di   = {24'd 0, 8'd 7} ; al_accel_cfgreg_sel = 5'd 11;

//         #10 // {output2D_size, input2D_size}  
//         al_accel_cfgreg_di   = {16'd  6, 16'd 18} ; al_accel_cfgreg_sel = 5'd 12;

//         #10 // kernel3D_size 
//         al_accel_cfgreg_di   = {16'd  0, 16'd 108} ; al_accel_cfgreg_sel = 5'd 13;

//         #10 
//         al_accel_cfgreg_wenb =  1'd 0;
//     // Flow Run
//         #10 
//         al_accel_flow_enb    =  1'd 1;
//         #1000
//         al_accel_flow_enb    =  1'd 0;
//         #200
//         al_accel_flow_enb    =  1'd 1;
// 		repeat (2000) @(posedge clk) begin
//             #2 al_accel_flow_enb = $random;
//         end
//         #10 
//         al_accel_flow_enb    =  1'd 1;
//     end

//     reg [IFM_SIZE *  8 - 1:0]  input_data ;
//     reg [KER_SIZE *  8 - 1:0]  filter_data;
//     reg [BIS_SIZE * 32 - 1:0]  bias_data  ;
//     integer i;
//     initial begin
//         for (i = 0; i < 4096; i = i + 1)
//             ram.mem[i] = 32'd 0;

//         // Input Initilization
//         input_data = {
//             8'd   1, 8'd   2,-8'd   3,-8'd   4,-8'd   5,-8'd   6,-8'd   7,-8'd   8, 8'd  90,
//             8'd  20, 8'd  25, 8'd  42, 8'd  32, 8'd  12, 8'd  66,-8'd 128, 8'd 127, 8'd  34,
//         // Padding
//             8'd   0, 8'd   0
//         };
//         for (i = 0; i < IFM_SIZE; i = i + 4) begin
//             ram.mem[250 + (i / 4)][ 7: 0] = input_data[8*(IFM_SIZE - 1 - i) +: 8];
//             ram.mem[250 + (i / 4)][15: 8] = input_data[8*(IFM_SIZE - 2 - i) +: 8];
//             ram.mem[250 + (i / 4)][23:16] = input_data[8*(IFM_SIZE - 3 - i) +: 8];
//             ram.mem[250 + (i / 4)][31:24] = input_data[8*(IFM_SIZE - 4 - i) +: 8];
//         end

//         // Kernel 
//         filter_data = {
//             8'd   2, 8'd   3, 8'd  43, 8'd  56, 8'd  11, 8'd  22,
//             8'd   2, 8'd   3, 8'd  43, 8'd  56, 8'd  11, 8'd  22,
//             8'd   2, 8'd   3, 8'd  43, 8'd  56, 8'd  11, 8'd  22,
//             8'd   4, 8'd  28, 8'd  74, 8'd  66, 8'd  43, 8'd 111,
//             8'd   4, 8'd  28, 8'd  74, 8'd  66, 8'd  43, 8'd 111,
//             8'd   4, 8'd  28, 8'd  74, 8'd  66, 8'd  43, 8'd 111,
//             8'd  90, 8'd  42, 8'd  64, 8'd  19, 8'd   1, 8'd   2,
//             8'd  90, 8'd  42, 8'd  64, 8'd  19, 8'd   1, 8'd   2,
//             8'd  90, 8'd  42, 8'd  64, 8'd  19, 8'd   1, 8'd   2,
//             8'd  98, 8'd  32, 8'd  17, 8'd  89, 8'd   1,-8'd   2,
//             8'd  98, 8'd  32, 8'd  17, 8'd  89, 8'd   1,-8'd   2,
//             8'd  98, 8'd  32, 8'd  17, 8'd  89, 8'd   1,-8'd   2,
//             8'd   6, 8'd  23, 8'd  65, 8'd  76, 8'd   1, 8'd   2,
//             8'd   6, 8'd  23, 8'd  65, 8'd  76, 8'd   1, 8'd   2,
//             8'd   6, 8'd  23, 8'd  65, 8'd  76, 8'd   1, 8'd   2,
//             8'd  43, 8'd   4,-8'd   1,-8'd  89, 8'd   1, 8'd   2,
//             8'd  43, 8'd   4,-8'd   1,-8'd  89, 8'd   1, 8'd   2,
//             8'd  43, 8'd   4,-8'd   1,-8'd  89, 8'd   1, 8'd   2
//         // Padding
//         }; 

//         for (i = 0; i < KER_SIZE; i = i + 4) begin
//             ram.mem[500 + (i / 4)][ 7: 0] = filter_data[8*(KER_SIZE - 1 - i) +: 8];
//             ram.mem[500 + (i / 4)][15: 8] = filter_data[8*(KER_SIZE - 2 - i) +: 8];
//             ram.mem[500 + (i / 4)][23:16] = filter_data[8*(KER_SIZE - 3 - i) +: 8];
//             ram.mem[500 + (i / 4)][31:24] = filter_data[8*(KER_SIZE - 4 - i) +: 8];
//         end

//         // Bias
//         bias_data = {
//             32'd   1, 
//             32'd  43, 
//             32'd  87, 
//             32'd 119,
//             32'd  46, 
//             32'd  67
//         };
//         for (i = 0; i < BIS_SIZE; i = i + 1) begin
//             ram.mem[1000 + i] = bias_data[32*(BIS_SIZE - 1 - i) +: 32];
//         end

//     end
// /*******************/

// Pool Layer
`ifdef PL_TC0
/* Test case 0 */
    /* 
        Description:
            - Input Feature Map's size : 9 x 9 x 3 => 243
            - Output Feature Map's size: 3 x 3 x 3 =>  27
            - Filter's size            : 3 x 3
            - Stride's size            : 3 x 3
    */

    localparam 
        IFM_SIZE = 9 * 9 * 3 + 1,
        OFM_SIZE = 3 * 3 * 3 + 1;

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
        al_accel_cfgreg_di   = 32'd 1000;       al_accel_cfgreg_sel = 5'd 0; 

        #10 // kw_base_addr
        al_accel_cfgreg_di   = 32'd 2000;       al_accel_cfgreg_sel = 5'd 1; 

        #10 // o_base_addr
        al_accel_cfgreg_di   = 32'd 3000;       al_accel_cfgreg_sel = 5'd 2; 

        #10 // b_base_addr
        al_accel_cfgreg_di   = 32'd 4000;       al_accel_cfgreg_sel = 5'd 3; 

        #10 // ps_base_addr
        al_accel_cfgreg_di   = 32'd 5000;       al_accel_cfgreg_sel = 5'd 4; 

        #10 // {stride_height, stride_width, cfg_act_func_typ, cfg_layer_typ}
        al_accel_cfgreg_di   = {16'd 0, 4'd 3, 4'd 3, NO_FUNC, POOL}; al_accel_cfgreg_sel = 5'd 5; 

        #10 // {weight_kernel_patch_height, weight_kernel_patch_width}
        al_accel_cfgreg_di   = {16'd 3, 16'd 3}; al_accel_cfgreg_sel = 5'd 6; 

        #10 // {nok_ofm_depth, kernel_ifm_depth} 
        al_accel_cfgreg_di   = {16'd 0, 16'd 3}; al_accel_cfgreg_sel = 5'd 7;

        #10 // {ifm_height, ifm_width}  
        al_accel_cfgreg_di   = {16'd 9, 16'd 9}; al_accel_cfgreg_sel = 5'd 8;

        #10 // {ofm_height, ofm_width}
        al_accel_cfgreg_di   = {16'd 3, 16'd 3}; al_accel_cfgreg_sel = 5'd 9;

        #10 // {output2D_size, input2D_size}  
        al_accel_cfgreg_di   = {16'd  9, 16'd 81}; al_accel_cfgreg_sel = 5'd 10;

        #10 // kernel3D_size 
        al_accel_cfgreg_di   = {16'd  0, 16'd  0}; al_accel_cfgreg_sel = 5'd 11;

        // #10 // output_multiplier
        // al_accel_cfgreg_di   = 32'd 1073742347 ; al_accel_cfgreg_sel = 5'd 13;

        // #10 // output_shift
        // al_accel_cfgreg_di   = {24'd 0, 8'd 7} ; al_accel_cfgreg_sel = 5'd 14;

        #10 
        al_accel_cfgreg_wenb =  1'd 0;
    // Flow Run
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

    reg [IFM_SIZE *  8 - 1:0]  input_data ;
    // reg [KER_SIZE *  8 - 1:0]  filter_data;
    // reg [BIS_SIZE * 32 - 1:0]  bias_data  ;
    integer i;
    initial begin
        for (i = 0; i < 4096; i = i + 1)
            ram.mem[i] = 32'd 0;

        // Input Initilization
        input_data = {
        /* z = 0 */
            8'd  11, 8'd  22, 8'd  34, 8'd  54, 8'd  67, 8'd  89, 8'd  12, 8'd  45, 8'd  79,
            8'd  22, 8'd  14, 8'd  44, 8'd  32, 8'd  18,-8'd  90, 8'd   0, 8'd  11, 8'd  21,
            8'd  21, 8'd  81,-8'd 127,-8'd 100,-8'd 109, 8'd  90, 8'd  91, 8'd  78, 8'd  13,
            8'd   1, 8'd   2, 8'd   3, 8'd   4, 8'd   5, 8'd   6, 8'd   7, 8'd   8, 8'd   9,
            8'd  10, 8'd   0, 8'd   0, 8'd   1, 8'd   7, 8'd  90, 8'd  23, 8'd  89,-8'd  10,
            8'd  11, 8'd  22, 8'd  44, 8'd  33, 8'd  55, 8'd  81, 8'd  19, 8'd  29, 8'd   0,
            8'd  11, 8'd   9, 8'd   7, 8'd   1, 8'd   1, 8'd   0,-8'd  90, 8'd   9, 8'd  11,
            8'd  21, 8'd  11, 8'd  21, 8'd  41, 8'd  15, 8'd  53, 8'd  38, 8'd  89, 8'd  78,
            8'd  11, 8'd  54, 8'd  90, 8'd 121, 8'd  32, 8'd  12, 8'd  54, 8'd  68, 8'd  90,
        /* z = 1 */
            8'd  11, 8'd  22, 8'd  34, 8'd  54, 8'd  67, 8'd  89, 8'd  12, 8'd  45, 8'd  12,
            8'd  21, 8'd  81,-8'd 127,-8'd 100,-8'd 109, 8'd  90, 8'd  91, 8'd  78, 8'd  49,
            8'd  10, 8'd   0, 8'd   0, 8'd   1, 8'd   7, 8'd  90, 8'd  23, 8'd  89, 8'd  87,
            8'd  11, 8'd   9, 8'd   7, 8'd   1, 8'd   1, 8'd   0,-8'd  90, 8'd   9, 8'd   0,
            8'd  22, 8'd  14, 8'd  44, 8'd  32, 8'd  18,-8'd  90, 8'd   0, 8'd  11, 8'd  90,
            8'd   1, 8'd   2, 8'd   3, 8'd   4, 8'd   5, 8'd   6, 8'd   7, 8'd   8, 8'd  10,
            8'd  11, 8'd  22, 8'd  44, 8'd  33, 8'd  55, 8'd  81, 8'd  19, 8'd  29,-8'd  10,
            8'd  21, 8'd  11, 8'd  21, 8'd  41, 8'd  15, 8'd  53, 8'd  38, 8'd  89,-8'd  20,
            8'd  21, 8'd   3, 8'd   4, 8'd   5, 8'd   9, 8'd  10, 8'd  11, 8'd  12, 8'd  13,
        /* z = 2 */
            8'd  10, 8'd   0, 8'd   0, 8'd   1, 8'd   7, 8'd  90, 8'd  23, 8'd  89,-8'd  10,
            8'd  11, 8'd  22, 8'd  44, 8'd  33, 8'd  55, 8'd  81, 8'd  19, 8'd  29, 8'd   0,
            8'd  11, 8'd   9, 8'd   7, 8'd   1, 8'd   1, 8'd   0,-8'd  90, 8'd   9, 8'd  11,
            8'd  21, 8'd  11, 8'd  21, 8'd  41, 8'd  15, 8'd  53, 8'd  38, 8'd  89, 8'd  78,
            8'd  11, 8'd  54, 8'd  90, 8'd 121, 8'd  32, 8'd  12, 8'd  54, 8'd  68, 8'd  90,
            8'd  10, 8'd   0, 8'd   0, 8'd   1, 8'd   7, 8'd  90, 8'd  23, 8'd  89, 8'd  87,
            8'd  11, 8'd   9, 8'd   7, 8'd   1, 8'd   1, 8'd   0,-8'd  90, 8'd   9, 8'd   0,
            8'd  22, 8'd  14, 8'd  44, 8'd  32, 8'd  18,-8'd  90, 8'd   0, 8'd  11, 8'd  90,
            8'd   1, 8'd   2, 8'd   3, 8'd   4, 8'd   5, 8'd   6, 8'd   7, 8'd   8, 8'd  10,
        // Padding
            8'd   0
        };
        for (i = 0; i < IFM_SIZE; i = i + 4) begin
            ram.mem[250 + (i / 4)][ 7: 0] = input_data[8*(IFM_SIZE - 1 - i) +: 8];
            ram.mem[250 + (i / 4)][15: 8] = input_data[8*(IFM_SIZE - 2 - i) +: 8];
            ram.mem[250 + (i / 4)][23:16] = input_data[8*(IFM_SIZE - 3 - i) +: 8];
            ram.mem[250 + (i / 4)][31:24] = input_data[8*(IFM_SIZE - 4 - i) +: 8];
        end
    end
/*******************/
`elsif PL_TC1
/* Test case 1 */
    /* 
        Description:
            - Input Feature Map's size : 7 x 7 x 3 => 147 
            - Output Feature Map's size: 3 x 3 x 3 =>  27
            - Filter's size            : 3 x 3
            - Stride's size            : 2 x 2
    */

    localparam 
        IFM_SIZE = 7 * 7 * 3 + 1,
        OFM_SIZE = 3 * 3 * 3 + 1;

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
        al_accel_cfgreg_di   = 32'd 1000;       al_accel_cfgreg_sel = 5'd 0; 

        #10 // kw_base_addr
        al_accel_cfgreg_di   = 32'd 2000;       al_accel_cfgreg_sel = 5'd 1; 

        #10 // o_base_addr
        al_accel_cfgreg_di   = 32'd 3000;       al_accel_cfgreg_sel = 5'd 2; 

        #10 // b_base_addr
        al_accel_cfgreg_di   = 32'd 4000;       al_accel_cfgreg_sel = 5'd 3; 

        #10 // ps_base_addr
        al_accel_cfgreg_di   = 32'd 5000;       al_accel_cfgreg_sel = 5'd 4; 

        #10 // {stride_height, stride_width, cfg_act_func_typ, cfg_layer_typ}
        al_accel_cfgreg_di   = {16'd 0, 4'd 2, 4'd 2, NO_FUNC, POOL}; al_accel_cfgreg_sel = 5'd 5; 

        #10 // {weight_kernel_patch_height, weight_kernel_patch_width}
        al_accel_cfgreg_di   = {16'd 3, 16'd 3}; al_accel_cfgreg_sel = 5'd 6; 

        #10 // {nok_ofm_depth, kernel_ifm_depth} 
        al_accel_cfgreg_di   = {16'd 3, 16'd 3}; al_accel_cfgreg_sel = 5'd 7;

        #10 // {ifm_height, ifm_width}  
        al_accel_cfgreg_di   = {16'd 7, 16'd 7}; al_accel_cfgreg_sel = 5'd 8;

        #10 // {ofm_height, ofm_width}
        al_accel_cfgreg_di   = {16'd 3, 16'd 3}; al_accel_cfgreg_sel = 5'd 9;

        #10 // {output2D_size, input2D_size}  
        al_accel_cfgreg_di   = {16'd 9, 16'd 49} ; al_accel_cfgreg_sel = 5'd 10;

        #10 // kernel3D_size 
        al_accel_cfgreg_di   = {16'd  0, 16'd 0} ; al_accel_cfgreg_sel = 5'd 11;

        // #10 // output_multiplier
        // al_accel_cfgreg_di   = 32'd 1073742347 ; al_accel_cfgreg_sel = 5'd 13;

        // #10 // output_shift
        // al_accel_cfgreg_di   = {24'd 0, 8'd 7} ; al_accel_cfgreg_sel = 5'd 14;

        #10 
        al_accel_cfgreg_wenb =  1'd 0;
    // Flow Run
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

    reg [IFM_SIZE *  8 - 1:0]  input_data ;
    // reg [KER_SIZE *  8 - 1:0]  filter_data;
    // reg [BIS_SIZE * 32 - 1:0]  bias_data  ;
    integer i;
    initial begin
        for (i = 0; i < 4096; i = i + 1)
            ram.mem[i] = 32'd 0;

        // Input Initilization
        input_data = {
        /* z = 0 */
            8'd  11, 8'd  22, 8'd  34, 8'd  54, 8'd  67, 8'd  89, 8'd  12,
            8'd  22, 8'd  14, 8'd  44, 8'd  32, 8'd  18,-8'd  90, 8'd   0,
            8'd  21, 8'd  81,-8'd 127,-8'd 100,-8'd 109, 8'd  90, 8'd  91,
            8'd   1, 8'd   2, 8'd   3, 8'd   4, 8'd   5, 8'd   6, 8'd   7,
            8'd  10, 8'd   0, 8'd   0, 8'd   1, 8'd   7, 8'd  90, 8'd  23,
            8'd  11, 8'd  22, 8'd  44, 8'd  33, 8'd  55, 8'd  81, 8'd  19,
            8'd  11, 8'd   9, 8'd   7, 8'd   1, 8'd   1, 8'd   0,-8'd  90,
        /* z = 1 */
            8'd  11, 8'd  22, 8'd  34, 8'd  54, 8'd  67, 8'd  89, 8'd  12,
            8'd  21, 8'd  81,-8'd 127,-8'd 100,-8'd 109, 8'd  90, 8'd  91,
            8'd  10, 8'd   0, 8'd   0, 8'd   1, 8'd   7, 8'd  90, 8'd  23,
            8'd  11, 8'd   9, 8'd   7, 8'd   1, 8'd   1, 8'd   0,-8'd  90,
            8'd  22, 8'd  14, 8'd  44, 8'd  32, 8'd  18,-8'd  90, 8'd   0,
            8'd   1, 8'd   2, 8'd   3, 8'd   4, 8'd   5, 8'd   6, 8'd   7,
            8'd  11, 8'd  22, 8'd  44, 8'd  33, 8'd  55, 8'd  81, 8'd  19,
        /* z = 2 */
            8'd  10, 8'd   0, 8'd   0, 8'd   1, 8'd   7, 8'd  90, 8'd  23,
            8'd  11, 8'd  22, 8'd  44, 8'd  33, 8'd  55, 8'd  81, 8'd  19,
            8'd  11, 8'd   9, 8'd   7, 8'd   1, 8'd   1, 8'd   0,-8'd  90,
            8'd  10, 8'd   0, 8'd   0, 8'd   1, 8'd   7, 8'd  90, 8'd  23,
            8'd  11, 8'd   9, 8'd   7, 8'd   1, 8'd   1, 8'd   0,-8'd  90,
            8'd  22, 8'd  14, 8'd  44, 8'd  32, 8'd  18,-8'd  90, 8'd   0,
            8'd   1, 8'd   2, 8'd   3, 8'd   4, 8'd   5, 8'd   6, 8'd   7,
        // Padding
            8'd   0
        };
        for (i = 0; i < IFM_SIZE; i = i + 4) begin
            ram.mem[250 + (i / 4)][ 7: 0] = input_data[8*(IFM_SIZE - 1 - i) +: 8];
            ram.mem[250 + (i / 4)][15: 8] = input_data[8*(IFM_SIZE - 2 - i) +: 8];
            ram.mem[250 + (i / 4)][23:16] = input_data[8*(IFM_SIZE - 3 - i) +: 8];
            ram.mem[250 + (i / 4)][31:24] = input_data[8*(IFM_SIZE - 4 - i) +: 8];
        end
    end
/*******************/
`elsif PL_TC2
/* Test case 2 */
    /* 
        Description:
            - Input Feature Map's size : 8 x 8 x 2 => 128 
            - Output Feature Map's size: 4 x 4 x 2 =>  32
            - Filter's size            : 2 x 2
            - Stride's size            : 2 x 2
    */

    localparam 
        IFM_SIZE = 8 * 8 * 2,
        OFM_SIZE = 4 * 4 * 2;

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
        al_accel_cfgreg_di   = 32'd 1000;       al_accel_cfgreg_sel = 5'd 0; 

        #10 // kw_base_addr
        al_accel_cfgreg_di   = 32'd 2000;       al_accel_cfgreg_sel = 5'd 1; 

        #10 // o_base_addr
        al_accel_cfgreg_di   = 32'd 3000;       al_accel_cfgreg_sel = 5'd 2; 

        #10 // b_base_addr
        al_accel_cfgreg_di   = 32'd 4000;       al_accel_cfgreg_sel = 5'd 3; 

        #10 // ps_base_addr
        al_accel_cfgreg_di   = 32'd 5000;       al_accel_cfgreg_sel = 5'd 4; 

        #10 // {stride_height, stride_width, cfg_act_func_typ, cfg_layer_typ}
        al_accel_cfgreg_di   = {16'd 0, 4'd 2, 4'd 2, NO_FUNC, POOL}; al_accel_cfgreg_sel = 5'd 5; 

        #10 // {weight_kernel_patch_height, weight_kernel_patch_width}
        al_accel_cfgreg_di   = {16'd 2, 16'd 2}; al_accel_cfgreg_sel = 5'd 6; 

        #10 // {nok_ofm_depth, kernel_ifm_depth} 
        al_accel_cfgreg_di   = {16'd 2, 16'd 2}; al_accel_cfgreg_sel = 5'd 7;

        #10 // {ifm_height, ifm_width}  
        al_accel_cfgreg_di   = {16'd 8, 16'd 8}; al_accel_cfgreg_sel = 5'd 8;

        #10 // {ofm_height, ofm_width}
        al_accel_cfgreg_di   = {16'd 4, 16'd 4}; al_accel_cfgreg_sel = 5'd 9;

        #10 // {output2D_size, input2D_size}  
        al_accel_cfgreg_di   = {16'd 16, 16'd 64}; al_accel_cfgreg_sel = 5'd 10;

        #10 // kernel3D_size 
        al_accel_cfgreg_di   = {16'd  0, 16'd  0}; al_accel_cfgreg_sel = 5'd 11;

        // #10 // output_multiplier
        // al_accel_cfgreg_di   = 32'd 1073742347 ; al_accel_cfgreg_sel = 5'd 13;

        // #10 // output_shift
        // al_accel_cfgreg_di   = {24'd 0, 8'd 7} ; al_accel_cfgreg_sel = 5'd 14;

        #10 
        al_accel_cfgreg_wenb =  1'd 0;
    // Flow Run
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

    reg [IFM_SIZE *  8 - 1:0]  input_data ;
    // reg [KER_SIZE *  8 - 1:0]  filter_data;
    // reg [BIS_SIZE * 32 - 1:0]  bias_data  ;
    integer i;
    initial begin
        for (i = 0; i < 4096; i = i + 1)
            ram.mem[i] = 32'd 0;

        // Input Initilization
        input_data = {
        /* z = 0 */
            8'd  11, 8'd  22, 8'd  34, 8'd  54, 8'd  67, 8'd  89, 8'd  12, 8'd  45,
            8'd  22, 8'd  14, 8'd  44, 8'd  32, 8'd  18,-8'd  90, 8'd   0, 8'd  11,
            8'd  21, 8'd  81,-8'd 127,-8'd 100,-8'd 109, 8'd  90, 8'd  91, 8'd  78,
            8'd   1, 8'd   2, 8'd   3, 8'd   4, 8'd   5, 8'd   6, 8'd   7, 8'd   8,
            8'd  10, 8'd   0, 8'd   0, 8'd   1, 8'd   7, 8'd  90, 8'd  23, 8'd  89,
            8'd  11, 8'd  22, 8'd  44, 8'd  33, 8'd  55, 8'd  81, 8'd  19, 8'd  29,
            8'd  11, 8'd   9, 8'd   7, 8'd   1, 8'd   1, 8'd   0,-8'd  90, 8'd   9,
            8'd  21, 8'd  11, 8'd  21, 8'd  41, 8'd  15, 8'd  53, 8'd  38, 8'd  89,
        /* z = 1*/
            8'd  11, 8'd  22, 8'd  34, 8'd  54, 8'd  67, 8'd  89, 8'd  12, 8'd  45,
            8'd  21, 8'd  81,-8'd 127,-8'd 100,-8'd 109, 8'd  90, 8'd  91, 8'd  78,
            8'd  10, 8'd   0, 8'd   0, 8'd   1, 8'd   7, 8'd  90, 8'd  23, 8'd  89,
            8'd  11, 8'd   9, 8'd   7, 8'd   1, 8'd   1, 8'd   0,-8'd  90, 8'd   9,
            8'd  22, 8'd  14, 8'd  44, 8'd  32, 8'd  18,-8'd  90, 8'd   0, 8'd  11,
            8'd   1, 8'd   2, 8'd   3, 8'd   4, 8'd   5, 8'd   6, 8'd   7, 8'd   8,
            8'd  11, 8'd  22, 8'd  44, 8'd  33, 8'd  55, 8'd  81, 8'd  19, 8'd  29,
            8'd  21, 8'd  11, 8'd  21, 8'd  41, 8'd  15, 8'd  53, 8'd  38, 8'd  89
        };
        for (i = 0; i < IFM_SIZE; i = i + 4) begin
            ram.mem[250 + (i / 4)][ 7: 0] = input_data[8*(IFM_SIZE - 1 - i) +: 8];
            ram.mem[250 + (i / 4)][15: 8] = input_data[8*(IFM_SIZE - 2 - i) +: 8];
            ram.mem[250 + (i / 4)][23:16] = input_data[8*(IFM_SIZE - 3 - i) +: 8];
            ram.mem[250 + (i / 4)][31:24] = input_data[8*(IFM_SIZE - 4 - i) +: 8];
        end
    end
/*******************/
`elsif PL_TC3
/* Test case 3 */
    /* 
        Description:
            - Input Feature Map's size : 11 x 11 x 2
            - Output Feature Map's size:  5 x  5 x 2
            - Filter's size            :   2 x 2
            - Stride's size            :   2 x 2
    */

    localparam 
        IFM_SIZE = 11 * 11 * 2 + 2,
        OFM_SIZE =  5 *  5 * 2 + 2;

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
        al_accel_cfgreg_di   = 32'd 1000;       al_accel_cfgreg_sel = 5'd 0; 

        #10 // kw_base_addr
        al_accel_cfgreg_di   = 32'd 2000;       al_accel_cfgreg_sel = 5'd 1; 

        #10 // o_base_addr
        al_accel_cfgreg_di   = 32'd 3000;       al_accel_cfgreg_sel = 5'd 2; 

        #10 // b_base_addr
        al_accel_cfgreg_di   = 32'd 4000;       al_accel_cfgreg_sel = 5'd 3; 

        #10 // ps_base_addr
        al_accel_cfgreg_di   = 32'd 5000;       al_accel_cfgreg_sel = 5'd 4; 

        #10 // {stride_height, stride_width, cfg_act_func_typ, cfg_layer_typ}
        al_accel_cfgreg_di   = {16'd 0, 4'd 2, 4'd 2, NO_FUNC, POOL}; al_accel_cfgreg_sel = 5'd 5; 

        #10 // {weight_kernel_patch_height, weight_kernel_patch_width}
        al_accel_cfgreg_di   = {16'd 2, 16'd 2}; al_accel_cfgreg_sel = 5'd 6; 

        #10 // {nok_ofm_depth, kernel_ifm_depth} 
        al_accel_cfgreg_di   = {16'd 2, 16'd 2}; al_accel_cfgreg_sel = 5'd 7;

        #10 // {ifm_height, ifm_width}  
        al_accel_cfgreg_di   = {16'd 11, 16'd 11}; al_accel_cfgreg_sel = 5'd 8;

        #10 // {ofm_height, ofm_width}
        al_accel_cfgreg_di   = {16'd  5, 16'd  5}; al_accel_cfgreg_sel = 5'd 9;

        #10 // {output2D_size, input2D_size}  
        al_accel_cfgreg_di   = {16'd 25, 16'd 121}; al_accel_cfgreg_sel = 5'd 10;

        #10 // kernel3D_size 
        al_accel_cfgreg_di   = {16'd  0, 16'd  1}; al_accel_cfgreg_sel = 5'd 11;

        // #10 // output_multiplier
        // al_accel_cfgreg_di   = 32'd 1073742347 ; al_accel_cfgreg_sel = 5'd 13;

        // #10 // output_shift
        // al_accel_cfgreg_di   = {24'd 0, 8'd 7} ; al_accel_cfgreg_sel = 5'd 14;

        #10 
        al_accel_cfgreg_wenb =  1'd 0;
    // Flow Run
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

    reg [IFM_SIZE *  8 - 1:0]  input_data ;
    // reg [KER_SIZE *  8 - 1:0]  filter_data;
    // reg [BIS_SIZE * 32 - 1:0]  bias_data  ;
    integer i;
    initial begin
        for (i = 0; i < 4096; i = i + 1)
            ram.mem[i] = 32'd 0;

        // Input Initilization
        input_data = {
        /* z = 0 */
            8'd  3,  8'd 11,  8'd 11,  8'd 11,  8'd  8,  8'd  0,  8'd  0,  8'd  0,  8'd  0,  8'd  0,  8'd  0,
            8'd  1,  8'd  0,  8'd  0,  8'd  0,  8'd 20,  8'd 59,  8'd 61,  8'd 57,  8'd 30,  8'd 22,  8'd 19,
            8'd  0,  8'd  0,  8'd  0,  8'd  0,  8'd  0,  8'd  0,  8'd  0,  8'd  0,  8'd  0,  8'd  0,  8'd  0,
            8'd  0,  8'd 17,  8'd 60,  8'd 57,  8'd 38,  8'd  6,  8'd  8,  8'd  0,  8'd  0,  8'd  0,  8'd  0,
            8'd 17,  8'd 34,  8'd 64,  8'd 83,  8'd101,  8'd120,  8'd 27,  8'd  0,  8'd  0,  8'd  6,  8'd 12,
            8'd  0,  8'd  0,  8'd  0,  8'd  0,  8'd  4,  8'd  0,  8'd  0,  8'd  0,  8'd  0,  8'd  5,  8'd  5,
            8'd  0,  8'd  0,  8'd  0,  8'd  0,  8'd 12,  8'd  0,  8'd  0,  8'd  0,  8'd  6,  8'd 18,  8'd  0,
            8'd  0,  8'd  0,  8'd  0,  8'd  6,  8'd  0,  8'd  0,  8'd  0,  8'd  0,  8'd  5,  8'd  4,  8'd  0,
            8'd  0,  8'd  0,  8'd  0,  8'd  0,  8'd  0,  8'd  0,  8'd  0,  8'd  0,  8'd 14,  8'd  0,  8'd  0,
            8'd  0,  8'd  0,  8'd  6,  8'd  0,  8'd  0,  8'd  0,  8'd 28,  8'd 24,  8'd  4,  8'd  0,  8'd  0,
            8'd  0,  8'd  0,  8'd  0,  8'd  0,  8'd  0,  8'd  0,  8'd  0,  8'd  8,  8'd  0,  8'd  0,  8'd  0,

        /* z = 1*/
            8'd  0, 8'd  2, 8'd  0, 8'd  0, 8'd  0, 8'd  0, 8'd  0, 8'd  0, 8'd  0, 8'd  0, 8'd  0,
            8'd  9, 8'd 32, 8'd  0, 8'd  0, 8'd  0, 8'd  0, 8'd  0, 8'd  0, 8'd  0, 8'd  0, 8'd  0,
            8'd  8, 8'd  4, 8'd  0, 8'd  0, 8'd  0, 8'd  0, 8'd  0, 8'd  0, 8'd  0, 8'd  0, 8'd  0,
            8'd  6, 8'd  0, 8'd  0, 8'd  0, 8'd  0, 8'd  0, 8'd  0, 8'd 61, 8'd  0, 8'd  0, 8'd  0,
            8'd  0, 8'd  0, 8'd  0, 8'd  0, 8'd  0, 8'd  0, 8'd 18, 8'd 16, 8'd  0, 8'd  0, 8'd 12,
            8'd  0, 8'd  0, 8'd  0, 8'd  0, 8'd  0, 8'd 24, 8'd130, 8'd  0, 8'd  0, 8'd  0, 8'd  2,
            8'd  0, 8'd  0, 8'd  0, 8'd  0, 8'd  9, 8'd 96, 8'd 50, 8'd  0, 8'd  0, 8'd  5, 8'd  0,
            8'd  0, 8'd  0, 8'd  0, 8'd  0, 8'd 56, 8'd121, 8'd  0, 8'd  0, 8'd  0, 8'd  0, 8'd  0,
            8'd  0, 8'd  0, 8'd  0, 8'd 25, 8'd125, 8'd  0, 8'd  0, 8'd  0, 8'd  9, 8'd  0, 8'd  0,
            8'd  0, 8'd  0, 8'd  5, 8'd 82, 8'd104, 8'd  0, 8'd  0, 8'd  0, 8'd  0, 8'd  0, 8'd  0,
            8'd  0, 8'd  0, 8'd 17, 8'd111, 8'd  0, 8'd  0, 8'd  0, 8'd  3, 8'd  0, 8'd  0, 8'd  0,
        // Padding
            8'd  0, 8'd  0
        };
        for (i = 0; i < IFM_SIZE; i = i + 4) begin
            ram.mem[250 + (i / 4)][ 7: 0] = input_data[8*(IFM_SIZE - 1 - i) +: 8];
            ram.mem[250 + (i / 4)][15: 8] = input_data[8*(IFM_SIZE - 2 - i) +: 8];
            ram.mem[250 + (i / 4)][23:16] = input_data[8*(IFM_SIZE - 3 - i) +: 8];
            ram.mem[250 + (i / 4)][31:24] = input_data[8*(IFM_SIZE - 4 - i) +: 8];
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
        .raddr  (al_accel_raddr[13:2]),
        .rdata  (al_accel_rdata),

        .wenb   (al_accel_wenb),
        .wstrb  (al_accel_wstrb),
        .waddr  (al_accel_waddr[13:2]),
        .wdata  (al_accel_wdata),

        .clk    (clk)
    );


    // Debug Info
    initial begin
        $dumpfile("out_log/accel_log/al_accel_tb.vcd");
        $dumpvars(0, al_accel_tb);

        repeat (`TIME_TO_REPEAT) begin
			repeat (1000) @(posedge clk);
		end
        // $display("FINISH LAYER");
        // for (i = 0; i < 4096; i = i + 1) begin
        //     $display("Addr %d [%d]: %d %d %d %d | %d | %h", i, (i << 2),
        //         $signed(ram.mem[i][ 7: 0]), 
        //         $signed(ram.mem[i][15: 8]), 
        //         $signed(ram.mem[i][23:16]), 
        //         $signed(ram.mem[i][31:24]),
        //         $signed(ram.mem[i]),
        //         $signed(ram.mem[i])
        //     ); 
        // end
        // $display("*************");
        $display("HARDWARE RESULT");
        for (i = 750; i < 750 + OFM_SIZE/4; i = i + 1) begin
            $display("%d %d %d %d", 
                $signed(ram.mem[i][ 7: 0]), 
                $signed(ram.mem[i][15: 8]), 
                $signed(ram.mem[i][23:16]), 
                $signed(ram.mem[i][31:24])
            ); 
        end
        $display("*************");
		$finish;
    end
endmodule

module al_accel_mem #(
	parameter integer WORDS = 4096
) (
    input              renb,
    input       [11:0] raddr,
    output reg  [31:0] rdata,

    input              wenb,
	input       [ 3:0] wstrb,
	input       [11:0] waddr,
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

