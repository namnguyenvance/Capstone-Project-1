`default_nettype none

/*
 * Pointwise (1x1) Convolution Accelerator
 * 
 * Computes a parallel dot product:
 *   result = sum(input[i] * weight[i]) for i = 0..depth-1
 * 
 * Accelerates 1x1 pointwise convolutions in TinyMobileNet:
 *   PW1: input_depth=16 (28x28 spatial, 16->32 channels)
 *   PW2: input_depth=32 (14x14 spatial, 32->48 channels)
 *   PW3: input_depth=48 (7x7 spatial, 48->64 channels)
 *
 * Usage flow (software):
 *   1. Write DEPTH register once per layer
 *   2. For each spatial position:
 *      a. Load INPUT[0..depth-1] with input values (+ zero-point offset)
 *      b. For each output channel:
 *         - Load WEIGHT[0..depth-1] with filter weights
 *         - Write CTRL = 1 to trigger computation
 *         - Read RESULT for the dot product
 *
 * Memory Map (base = 0x02000400, 1KB window):
 *   0x000 - 0x0FC: Input buffer  (64 x int32, reg indices 0-63)
 *   0x100 - 0x1FC: Weight buffer (64 x int32, reg indices 64-127)
 *   0x200:         Depth register (reg index 128)
 *   0x204:         Control register (reg index 129, write 1 to compute)
 *   0x208:         Result register (reg index 130, read dot product)
 *   0x300 - 0x33C: Packed weight alias (16 words, reg indices 192-207)
 *                 Byte 0 -> lane 4*k; bytes sign-extended into legacy storage.
 *                 Aligned full-word writes only; reads return zero.
 */
module my_pw_conv_accel (
    input wire clk,
    input wire resetn,
    
    // CPU Bus Interface
    input wire [7:0] addr,       // 8-bit register address (from mem_addr[9:2])
    input wire write_en,         // Write enable from CPU
    input wire [31:0] wdata,     // Write data
    output reg [31:0] rdata      // Read data to CPU
);

    // ==========================================
    // Storage
    // ==========================================
    
    // Input vector buffer (up to 64 elements)
    reg signed [31:0] input_buf [0:63];
    // Weight vector buffer (up to 64 elements)
    reg signed [31:0] weight_buf [0:63];
    // Number of elements for dot product (1-64)
    reg [6:0] depth_reg;
    // Computed dot product result
    reg signed [31:0] result_reg;
    // Computation done flag
    reg done_reg;

    // Loop variables
    integer i;
    
    // Temporary accumulator for dot product (blocking assignment)
    reg signed [31:0] temp_sum;
    integer j;

    // ==========================================
    // Write Logic + Dot Product Computation
    // ==========================================
    always @(posedge clk) begin
        if (!resetn) begin
            for (i = 0; i < 64; i = i + 1) begin
                input_buf[i] <= 32'sd0;
                weight_buf[i] <= 32'sd0;
            end
            depth_reg  <= 7'd0;
            result_reg <= 32'sd0;
            done_reg   <= 1'b0;
        end else if (write_en) begin
            // Input buffer: registers 0-63
            if (addr <= 8'd63) begin
                input_buf[addr[5:0]] <= $signed(wdata);
            end
            // Weight buffer: registers 64-127
            else if (addr >= 8'd64 && addr <= 8'd127) begin
                weight_buf[addr[5:0]] <= $signed(wdata);
            end
            // Packed alias: four signed int8 weights, lowest lane in low byte.
            else if (addr >= 8'd192 && addr <= 8'd207) begin
                weight_buf[{addr[3:0], 2'b00}] <= $signed({{24{wdata[7]}}, wdata[7:0]});
                weight_buf[{addr[3:0], 2'b01}] <= $signed({{24{wdata[15]}}, wdata[15:8]});
                weight_buf[{addr[3:0], 2'b10}] <= $signed({{24{wdata[23]}}, wdata[23:16]});
                weight_buf[{addr[3:0], 2'b11}] <= $signed({{24{wdata[31]}}, wdata[31:24]});
            end
            // Depth register: register 128
            else if (addr == 8'd128) begin
                depth_reg <= wdata[6:0];
            end
            // Control register: register 129 - trigger dot product
            else if (addr == 8'd129) begin
                /*
                 * Compute dot product using parallel multiply + accumulate.
                 * 
                 * temp_sum uses blocking assignments (=) for immediate 
                 * sequential computation within this clock edge.
                 * result_reg uses non-blocking (<=) to register the output.
                 * 
                 * This is a standard Verilog pattern: blocking for temporaries,
                 * non-blocking for actual register outputs.
                 */
                temp_sum = 32'sd0;
                for (j = 0; j < 64; j = j + 1) begin
                    if (j < depth_reg)
                        temp_sum = temp_sum + input_buf[j] * weight_buf[j];
                end
                result_reg <= temp_sum;
                done_reg   <= 1'b1;
            end
        end
    end

    // ==========================================
    // Read Logic (combinational)
    // ==========================================
    always @(*) begin
        if (addr <= 8'd63) begin
            rdata = $unsigned(input_buf[addr[5:0]]);
        end else if (addr >= 8'd64 && addr <= 8'd127) begin
            rdata = $unsigned(weight_buf[addr[5:0]]);
        end else if (addr == 8'd128) begin
            rdata = {25'd0, depth_reg};
        end else if (addr == 8'd129) begin
            rdata = {31'd0, done_reg};
        end else if (addr == 8'd130) begin
            rdata = $unsigned(result_reg);
        end else begin
            rdata = 32'd0;
        end
    end

endmodule
