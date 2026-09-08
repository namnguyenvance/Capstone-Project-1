`default_nettype none

module my_quant_accel (
    input wire clk,
    input wire resetn,
    
    // CPU Bus Interface
    input wire [3:0] addr,       // 4-bit register address (word-aligned offsets: 0, 4, 8, C, 10)
    input wire write_en,         // Write enable from CPU
    input wire [31:0] wdata,     // Write data
    output reg [31:0] rdata      // Read data to CPU
);

    // Registers
    reg signed [31:0] raw_val;
    reg signed [31:0] multiplier;
    reg [31:0] shift;

    // Output Registers
    reg signed [31:0] quant_out;
    reg done_reg;

    // Combinatorial Logic for Quantization
    wire signed [63:0] ab_64 = raw_val * multiplier;
    wire signed [31:0] nudge = (ab_64 >= 0) ? (1 << 30) : (1 - (1 << 30));
    wire signed [63:0] ab_64_nudge = ab_64 + nudge;
    wire signed [31:0] ab_x2_high32 = ab_64_nudge >>> 31;

    wire [31:0] mask = (1 << shift) - 1;
    wire [31:0] remainder = ab_x2_high32 & mask;
    wire [31:0] threshold = (mask >> 1) + (ab_x2_high32 < 0 ? 1 : 0);
    wire signed [31:0] result = (ab_x2_high32 >>> shift) + ((remainder > threshold) ? 1 : 0);

    // Write Logic
    always @(posedge clk) begin
        if (!resetn) begin
            raw_val <= 32'd0;
            multiplier <= 32'd0;
            shift <= 32'd0;
            quant_out <= 32'd0;
            done_reg <= 1'b0;
        end else begin
            if (write_en) begin
                if (addr == 4'd0) begin
                    raw_val <= $signed(wdata);
                    done_reg <= 1'b0; // clear done flag on new data
                end else if (addr == 4'd1) begin // offset 0x04
                    multiplier <= $signed(wdata);
                end else if (addr == 4'd2) begin // offset 0x08
                    shift <= wdata;
                end else if (addr == 4'd4) begin // offset 0x10
                    quant_out <= result; // Sample the combinatorial result
                    done_reg <= 1'b1;
                end
            end
        end
    end

    // Read Logic
    always @* begin
        if (addr == 4'd0) begin
            rdata = $unsigned(raw_val);
        end else if (addr == 4'd1) begin // offset 0x04
            rdata = $unsigned(multiplier);
        end else if (addr == 4'd2) begin // offset 0x08
            rdata = shift;
        end else if (addr == 4'd3) begin // offset 0x0C
            rdata = $unsigned(quant_out);
        end else if (addr == 4'd4) begin // offset 0x10
            rdata = {31'd0, done_reg};
        end else begin
            rdata = 32'd0;
        end
    end

endmodule
