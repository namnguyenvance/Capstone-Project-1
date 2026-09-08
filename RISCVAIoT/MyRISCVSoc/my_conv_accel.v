`default_nettype none

module my_conv_accel (
    input wire clk,
    input wire resetn,
    
    // CPU Bus Interface
    input wire [5:0] addr,       // 6-bit register address (word-aligned offsets)
    input wire write_en,         // Write enable from CPU
    input wire [31:0] wdata,     // Write data
    output reg [31:0] rdata      // Read data to CPU
);

    // Internal storage:
    // Image input matrix: 25 registers
    reg signed [31:0] img [0:24];
    // Kernel matrix: 9 registers
    reg signed [31:0] ker [0:8];
    // Control status register
    reg done_reg;

    integer i;

    // Combinatorial 2D Convolution Engine
    // Output size: 3x3 (9 elements)
    wire signed [31:0] out_val [0:8];

    // Offset calculations for 2D convolution:
    // Output(r, c) = sum_{kr, kc} img(r+kr, c+kc) * ker(kr, kc)
    // Row 0
    assign out_val[0] = img[0]*ker[0] + img[1]*ker[1] + img[2]*ker[2] +
                        img[5]*ker[3] + img[6]*ker[4] + img[7]*ker[5] +
                        img[10]*ker[6] + img[11]*ker[7] + img[12]*ker[8];

    assign out_val[1] = img[1]*ker[0] + img[2]*ker[1] + img[3]*ker[2] +
                        img[6]*ker[3] + img[7]*ker[4] + img[8]*ker[5] +
                        img[11]*ker[6] + img[12]*ker[7] + img[13]*ker[8];

    assign out_val[2] = img[2]*ker[0] + img[3]*ker[1] + img[4]*ker[2] +
                        img[7]*ker[3] + img[8]*ker[4] + img[9]*ker[5] +
                        img[12]*ker[6] + img[13]*ker[7] + img[14]*ker[8];

    // Row 1
    assign out_val[3] = img[5]*ker[0] + img[6]*ker[1] + img[7]*ker[2] +
                        img[10]*ker[3] + img[11]*ker[4] + img[12]*ker[5] +
                        img[15]*ker[6] + img[16]*ker[7] + img[17]*ker[8];

    assign out_val[4] = img[6]*ker[0] + img[7]*ker[1] + img[8]*ker[2] +
                        img[11]*ker[3] + img[12]*ker[4] + img[13]*ker[5] +
                        img[16]*ker[6] + img[17]*ker[7] + img[18]*ker[8];

    assign out_val[5] = img[7]*ker[0] + img[8]*ker[1] + img[9]*ker[2] +
                        img[12]*ker[3] + img[13]*ker[4] + img[14]*ker[5] +
                        img[17]*ker[6] + img[18]*ker[7] + img[19]*ker[8];

    // Row 2
    assign out_val[6] = img[10]*ker[0] + img[11]*ker[1] + img[12]*ker[2] +
                        img[15]*ker[3] + img[16]*ker[4] + img[17]*ker[5] +
                        img[20]*ker[6] + img[21]*ker[7] + img[22]*ker[8];

    assign out_val[7] = img[11]*ker[0] + img[12]*ker[1] + img[13]*ker[2] +
                        img[16]*ker[3] + img[17]*ker[4] + img[18]*ker[5] +
                        img[21]*ker[6] + img[22]*ker[7] + img[23]*ker[8];

    assign out_val[8] = img[12]*ker[0] + img[13]*ker[1] + img[14]*ker[2] +
                        img[17]*ker[3] + img[18]*ker[4] + img[19]*ker[5] +
                        img[22]*ker[6] + img[23]*ker[7] + img[24]*ker[8];

    // Write Logic
    always @(posedge clk) begin
        if (!resetn) begin
            for (i = 0; i < 25; i = i + 1) img[i] <= 32'sd0;
            for (i = 0; i < 9;  i = i + 1) ker[i] <= 32'sd0;
            done_reg <= 1'b0;
        end else begin
            if (write_en) begin
                if (addr >= 6'd0 && addr <= 6'd24) begin
                    img[addr] <= $signed(wdata);
                end else if (addr >= 6'd28 && addr <= 6'd36) begin
                    ker[addr - 6'd28] <= $signed(wdata);
                end else if (addr == 6'd60) begin
                    // Write any value to Control/Status to trigger
                    done_reg <= 1'b1;
                end
            end else if (done_reg) begin
                // Reset done register after it has been read or on reset
                // In our simple case, it stays high until reset or next start
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
