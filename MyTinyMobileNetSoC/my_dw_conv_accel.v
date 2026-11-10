`default_nettype none

/*
 * Depthwise Convolution Accelerator
 * 
 * This accelerator is fundamentally different from the standard conv accelerator
 * (my_conv_accel.v) in how it is USED, not in its internal computation:
 * 
 * Standard Conv Accel (my_conv_accel.v):
 *   - Called N times per output tile (N = input channels)
 *   - Each call accumulates into the output (software does the accumulation)
 *   - Used for standard convolution where each output pixel depends on ALL input channels
 * 
 * Depthwise Conv Accel (this module):
 *   - Called ONCE per channel per output tile
 *   - NO cross-channel accumulation needed
 *   - Each channel is completely independent
 *   - Used for depthwise separable convolution (MobileNet's core operation)
 * 
 * Both compute: 3x3 kernel × 5x5 input → 3x3 output
 * But the software usage pattern is completely different!
 * 
 * Memory Map (base = 0x02000300):
 *   0x300 - 0x360: Image patch registers (25 words, single channel)
 *   0x370 - 0x394: Kernel registers (9 words, single channel filter)
 *   0x3A0 - 0x3C4: Output registers (9 words, convolution results)
 *   0x3F0:         Control/Start register (write 1 to compute)
 */
module my_dw_conv_accel (
    input wire clk,
    input wire resetn,
    
    // CPU Bus Interface
    input wire [5:0] addr,       // 6-bit register address (word-aligned offsets)
    input wire write_en,         // Write enable from CPU
    input wire [31:0] wdata,     // Write data
    output reg [31:0] rdata      // Read data to CPU
);

    // Internal storage:
    // Image input patch: 5x5 = 25 registers (single channel)
    reg signed [31:0] img [0:24];
    // Kernel: 3x3 = 9 registers (single channel)
    reg signed [31:0] ker [0:8];
    // Control status register
    reg done_reg;

    integer i;

    // Output values: 3x3 = 9 results
    reg signed [31:0] out_val [0:8];

    // Write Logic
    always @(posedge clk) begin
        if (!resetn) begin
            for (i = 0; i < 25; i = i + 1) img[i] <= 32'sd0;
            for (i = 0; i < 9;  i = i + 1) ker[i] <= 32'sd0;
            for (i = 0; i < 9;  i = i + 1) out_val[i] <= 32'sd0;
            done_reg <= 1'b0;
        end else begin
            if (write_en) begin
                if (addr >= 6'd0 && addr <= 6'd24) begin
                    img[addr] <= $signed(wdata);
                end else if (addr >= 6'd28 && addr <= 6'd36) begin
                    ker[addr - 6'd28] <= $signed(wdata);
                end else if (addr == 6'd60) begin
                    // Compute depthwise convolution for single channel
                    // 3x3 kernel sliding over 5x5 input → 3x3 output
                    // 
                    // This is the same math as standard conv, but the key
                    // difference is at the SOFTWARE level:
                    //   - No accumulation across channels
                    //   - Each result is final (just add bias + quantize)
                    
                    // Row 0
                    out_val[0] <= img[0]*ker[0] + img[1]*ker[1] + img[2]*ker[2] +
                                  img[5]*ker[3] + img[6]*ker[4] + img[7]*ker[5] +
                                  img[10]*ker[6] + img[11]*ker[7] + img[12]*ker[8];

                    out_val[1] <= img[1]*ker[0] + img[2]*ker[1] + img[3]*ker[2] +
                                  img[6]*ker[3] + img[7]*ker[4] + img[8]*ker[5] +
                                  img[11]*ker[6] + img[12]*ker[7] + img[13]*ker[8];

                    out_val[2] <= img[2]*ker[0] + img[3]*ker[1] + img[4]*ker[2] +
                                  img[7]*ker[3] + img[8]*ker[4] + img[9]*ker[5] +
                                  img[12]*ker[6] + img[13]*ker[7] + img[14]*ker[8];

                    // Row 1
                    out_val[3] <= img[5]*ker[0] + img[6]*ker[1] + img[7]*ker[2] +
                                  img[10]*ker[3] + img[11]*ker[4] + img[12]*ker[5] +
                                  img[15]*ker[6] + img[16]*ker[7] + img[17]*ker[8];

                    out_val[4] <= img[6]*ker[0] + img[7]*ker[1] + img[8]*ker[2] +
                                  img[11]*ker[3] + img[12]*ker[4] + img[13]*ker[5] +
                                  img[16]*ker[6] + img[17]*ker[7] + img[18]*ker[8];

                    out_val[5] <= img[7]*ker[0] + img[8]*ker[1] + img[9]*ker[2] +
                                  img[12]*ker[3] + img[13]*ker[4] + img[14]*ker[5] +
                                  img[17]*ker[6] + img[18]*ker[7] + img[19]*ker[8];

                    // Row 2
                    out_val[6] <= img[10]*ker[0] + img[11]*ker[1] + img[12]*ker[2] +
                                  img[15]*ker[3] + img[16]*ker[4] + img[17]*ker[5] +
                                  img[20]*ker[6] + img[21]*ker[7] + img[22]*ker[8];

                    out_val[7] <= img[11]*ker[0] + img[12]*ker[1] + img[13]*ker[2] +
                                  img[16]*ker[3] + img[17]*ker[4] + img[18]*ker[5] +
                                  img[21]*ker[6] + img[22]*ker[7] + img[23]*ker[8];

                    out_val[8] <= img[12]*ker[0] + img[13]*ker[1] + img[14]*ker[2] +
                                  img[17]*ker[3] + img[18]*ker[4] + img[19]*ker[5] +
                                  img[22]*ker[6] + img[23]*ker[7] + img[24]*ker[8];

                    done_reg <= 1'b1;
                end
            end else if (done_reg) begin
                // done stays high until next reset or start
            end
        end
    end

    // Read Logic
    always @* begin
        if (addr >= 6'd0 && addr <= 6'd24) begin
            rdata = $unsigned(img[addr]);
        end else if (addr >= 6'd28 && addr <= 6'd36) begin
            rdata = $unsigned(ker[addr - 6'd28]);
        end else if (addr >= 6'd40 && addr <= 6'd48) begin
            rdata = $unsigned(out_val[addr - 6'd40]);
        end else if (addr == 6'd60) begin
            rdata = {31'd0, done_reg};
        end else begin
            rdata = 32'd0;
        end
    end

endmodule
