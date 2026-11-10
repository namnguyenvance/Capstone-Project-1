`default_nettype none

module my_accel (
    input wire clk,
    input wire resetn,
    
    // Interface to the Bus
    input wire [1:0] addr,       // 2-bit address offset
    input wire write_en,         // Write enable from CPU
    input wire [31:0] wdata,     // Write data from CPU
    output reg [31:0] rdata      // Read data to CPU
);

    // Internal Registers
    // Map:
    // Offset 0 (addr = 0): Input Register A
    // Offset 1 (addr = 1): Input Register B
    // Offset 2 (addr = 2): Output Product (A * B)
    reg [31:0] reg_a;
    reg [31:0] reg_b;
    
    // Hardware Multiplier Unit (Performs calculation instantly in hardware!)
    wire [31:0] product = reg_a * reg_b;

    // Bus Write Logic
    always @(posedge clk) begin
        if (!resetn) begin
            reg_a <= 32'd0;
            reg_b <= 32'd0;
        end else begin
            if (write_en) begin
                case (addr)
                    2'b00: reg_a <= wdata;
                    2'b01: reg_b <= wdata;
                    default: ; // Other addresses are read-only or unused
                endcase
            end
        end
    end

    // Bus Read Logic
    always @* begin
        case (addr)
            2'b00:   rdata = reg_a;
            2'b01:   rdata = reg_b;
            2'b10:   rdata = product;
            default: rdata = 32'd0;
        endcase
    end

endmodule
