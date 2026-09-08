module fs_accel_config_regs (
    // Data Sigs
    input  [31:0] config_data,
    input  [ 4:0] config_sel,

    // Feedback Sigs
    input  [ 3:0] output_quant_buf_outsel,

    // Memory
    output reg [31:0] i_base_addr,
    output reg [31:0] kw_base_addr,
    output reg [31:0] o_base_addr,
    output reg [31:0] b_base_addr,
    output reg [31:0] ps_base_addr,

    output reg [ 3:0] cfg_layer_typ,
    output reg [ 3:0] cfg_act_func_typ,

    output reg [ 3:0] stride_width,
    output reg [ 3:0] stride_height, 

    output reg [15:0] weight_kernel_patch_width,
    output reg [15:0] weight_kernel_patch_height,

    output reg [15:0] kernel_ifm_depth,
    output reg [15:0] nok_ofm_depth,

    output reg [15:0] ifm_width,
    output reg [15:0] ifm_height,

    output reg [15:0] ofm_width,
    output reg [15:0] ofm_height,

    output reg [15:0] input2D_size,
    output reg [15:0] output2D_size,

    output reg [31:0] kernel3D_size,

    output [31:0] output_multiplier_0,
    output [31:0] output_multiplier_1,
    output [31:0] output_multiplier_2,

    output [ 7:0] output_shift_0,
    output [ 7:0] output_shift_1,
    output [ 7:0] output_shift_2,

    output reg [31:0] input_offset,
    output reg [31:0] output_offset,

    output reg [15:0] ofm_pool_height,
    output reg [15:0] ofm_pool_width,

    output reg [31:0] output2D_pool_size,

    // Ctrl Sigs
    input   config_wen,

    // Mandatory Sigs
    input   clk,
    input   resetn
);
    /* Mem config */ 
    // // Register 0
    // reg [31:0] i_base_addr;

    // // Register 1
    // reg [31:0] kw_base_addr;

    // // Register 2
    // reg [31:0] o_base_addr;

    // // Register 3
    // reg [31:0] b_base_addr;

    // // Register 4
    // reg [31:0] ps_base_addr;

    // /* Layer */
    // // Register 5
    // reg [ 3:0] cfg_layer_typ;
    // reg [ 3:0] cfg_act_func_typ; 
    // reg [ 3:0] stride_width;
    // reg [ 3:0] stride_height;

    // // Register 6
    // reg [15:0] weight_kernel_patch_width; 
    // reg [15:0] weight_kernel_patch_height;

    // // Register 7
    // reg [15:0] kernel_ifm_depth; 
    // reg [15:0] nok_ofm_depth;

    // // Register 8
    // reg [15:0] ifm_width;
    // reg [15:0] ifm_height;   

    // // Register 9
    // reg [15:0] ofm_width; 
    // reg [15:0] ofm_height;  

    // /* Pre-Cal Config */
    // // Register 10
    // reg [15:0] input2D_size;
    // reg [15:0] output2D_size;
    
    // // Register 11
    // reg [31:0] kernel3D_size;

    /* Quantize */ 
    // Register 12
    reg [ 5:0] output_quant_buf_insel;

    // Register 13
    reg [31:0] output_multiplier_buf[36 - 1: 0];

    // Register 14
    reg [ 7:0] output_shift_buf[36 - 1:0];

    // // Register 15
    // reg [31:0] input_offset;

    // // Register 16
    // reg [31:0] output_offset;

    integer i;
    /*****************************/
    always @(posedge clk) begin
        if (!resetn) begin
            i_base_addr                 <= 0;
            kw_base_addr                <= 0;
            o_base_addr                 <= 0;
            b_base_addr                 <= 0;
            ps_base_addr                <= 0;
            cfg_layer_typ               <= 0; 
            cfg_act_func_typ            <= 0;
            stride_width                <= 0;
            stride_height               <= 0;
            weight_kernel_patch_width   <= 0;
            weight_kernel_patch_height  <= 0;
            kernel_ifm_depth            <= 0;
            nok_ofm_depth               <= 0;
            ifm_width                   <= 0;
            ifm_height                  <= 0;
            ofm_width                   <= 0;
            ofm_height                  <= 0;
            input_offset                <= 0;
            output_offset               <= 0;
            input2D_size                <= 0;
            output2D_size               <= 0;
            kernel3D_size               <= 0;

            output_quant_buf_insel      <= 0;
            for (i = 0; i < 36; i = i + 1) begin
                output_multiplier_buf[i]    <= 0;
                output_shift_buf[i]         <= 0;
            end
            ofm_pool_height                 <= 0;
            ofm_pool_width                  <= 0;
            output2D_pool_size              <= 0;  
            
        end else if (config_wen) begin
            case (config_sel)
                5'd  0: i_base_addr                                                     <= config_data;
                5'd  1: kw_base_addr                                                    <= config_data;
                5'd  2: o_base_addr                                                     <= config_data;
                5'd  3: b_base_addr                                                     <= config_data;
                5'd  4: ps_base_addr                                                    <= config_data;
                5'd  5: {stride_height, stride_width, cfg_act_func_typ, cfg_layer_typ}  <= config_data[15:0];
                5'd  6: {weight_kernel_patch_height, weight_kernel_patch_width}         <= config_data;
                5'd  7: {nok_ofm_depth, kernel_ifm_depth}                               <= config_data;
                5'd  8: {ifm_height, ifm_width}                                         <= config_data;
                5'd  9: {ofm_height, ofm_width}                                         <= config_data;
                5'd 10: {output2D_size, input2D_size}                                   <= config_data;
                5'd 11: kernel3D_size                                                   <= config_data;

                // For quantize
                5'd 12: output_quant_buf_insel                                          <= config_data[ 7:0];
                5'd 13: output_multiplier_buf[output_quant_buf_insel]                   <= config_data;
                5'd 14: output_shift_buf[output_quant_buf_insel]                        <= config_data[ 7:0];
                5'd 15: input_offset                                                    <= config_data;
                5'd 16: output_offset                                                   <= config_data;
                5'd 17: {ofm_pool_height, ofm_pool_width}                               <= config_data;
                5'd 18: output2D_pool_size                                              <= config_data;
            endcase
        end
    end

    reg [32*3 - 1:0] output_multiplier;
    reg [ 8*3 - 1:0] output_shift;

    always @(*) begin
        output_multiplier   = 0;
        output_shift        = 0;
        case (output_quant_buf_outsel)
            4'd  1: begin
                output_multiplier   = {output_multiplier_buf[2], output_multiplier_buf[1], output_multiplier_buf[0]};
                output_shift        = {output_shift_buf[2],      output_shift_buf[1],      output_shift_buf[0]};
            end

            4'd  2: begin
                output_multiplier   = {output_multiplier_buf[5], output_multiplier_buf[4], output_multiplier_buf[3]};
                output_shift        = {output_shift_buf[5],      output_shift_buf[4],      output_shift_buf[3]};
            end
            
            4'd  3: begin
                output_multiplier   = {output_multiplier_buf[8], output_multiplier_buf[7], output_multiplier_buf[6]};
                output_shift        = {output_shift_buf[8],      output_shift_buf[7],      output_shift_buf[6]};
            end

            4'd  4: begin
                output_multiplier   = {output_multiplier_buf[11], output_multiplier_buf[10], output_multiplier_buf[9]};
                output_shift        = {output_shift_buf[11],      output_shift_buf[10],      output_shift_buf[9]};
            end

            4'd  5: begin
                output_multiplier   = {output_multiplier_buf[14], output_multiplier_buf[13], output_multiplier_buf[12]};
                output_shift        = {output_shift_buf[14],      output_shift_buf[13],      output_shift_buf[12]};
            end

            4'd  6: begin
                output_multiplier   = {output_multiplier_buf[17], output_multiplier_buf[16], output_multiplier_buf[15]};
                output_shift        = {output_shift_buf[17],      output_shift_buf[16],      output_shift_buf[15]};
            end

            4'd  7: begin
                output_multiplier   = {output_multiplier_buf[20], output_multiplier_buf[19], output_multiplier_buf[18]};
                output_shift        = {output_shift_buf[20],      output_shift_buf[19],      output_shift_buf[18]};
            end

            4'd  8: begin
                output_multiplier   = {output_multiplier_buf[23], output_multiplier_buf[22], output_multiplier_buf[21]};
                output_shift        = {output_shift_buf[23],      output_shift_buf[22],      output_shift_buf[21]};
            end

            4'd  9: begin
                output_multiplier   = {output_multiplier_buf[26], output_multiplier_buf[25], output_multiplier_buf[24]};
                output_shift        = {output_shift_buf[26],      output_shift_buf[25],      output_shift_buf[24]};
            end

            4'd 10: begin
                output_multiplier   = {output_multiplier_buf[29], output_multiplier_buf[28], output_multiplier_buf[27]};
                output_shift        = {output_shift_buf[29],      output_shift_buf[28],      output_shift_buf[27]};
            end

            4'd 11: begin
                output_multiplier   = {output_multiplier_buf[32], output_multiplier_buf[31], output_multiplier_buf[30]};
                output_shift        = {output_shift_buf[32],      output_shift_buf[31],      output_shift_buf[30]};
            end

            4'd 12: begin
                output_multiplier   = {output_multiplier_buf[35], output_multiplier_buf[34], output_multiplier_buf[33]};
                output_shift        = {output_shift_buf[35],      output_shift_buf[34],      output_shift_buf[33]};
            end
        endcase
    end

    assign output_multiplier_0 = output_multiplier[31: 0];
    assign output_multiplier_1 = output_multiplier[63:32];
    assign output_multiplier_2 = output_multiplier[95:64];

    assign output_shift_0 = output_shift[ 7: 0];
    assign output_shift_1 = output_shift[15: 8];
    assign output_shift_2 = output_shift[23:16];

endmodule