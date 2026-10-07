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
 *   0x20C:         Batch trigger/status (index 131, read {done,busy})
 *   0x210 - 0x21C: Batch results (indices 132-135, reads stall until done)
 *   0x220:         Batch status (index 136, read {done,busy})
 *   0x340 - 0x3FC: Packed signed-int8 weight banks 1-3 (indices 208-255)
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
    output reg [31:0] rdata,     // Read data to CPU
    output reg rvalid           // Only batch-result reads can be invalid
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

    // Additional banks retain packed signed-int8 semantics. Bank 0 above
    // MUST remain int32 for legacy scalar writes/readback.
    reg signed [7:0] batch_weights [0:191];
    reg [6:0] batch_depth;
    reg [1:0] batch_bank;
    reg batch_busy, batch_done;
    reg [31:0] batch_results [0:3];
    wire [31:0] tree [1:127];
    wire [6:0] active_depth = batch_busy ? batch_depth : depth_reg;
    genvar lane, node;
    generate
        for (lane = 0; lane < 64; lane = lane + 1) begin: products
            wire signed [7:0] byte_weight = batch_bank == 2'd1 ? batch_weights[lane] :
                batch_bank == 2'd2 ? batch_weights[64+lane] : batch_weights[128+lane];
            wire signed [31:0] selected_weight = !batch_busy || batch_bank == 2'd0 ?
                weight_buf[lane] : {{24{byte_weight[7]}}, byte_weight};
            assign tree[64+lane] = lane < active_depth ? input_buf[lane] * selected_weight : 32'd0;
        end
        for (node = 1; node < 64; node = node + 1) begin: reduction
            assign tree[node] = tree[2*node] + tree[2*node+1];
        end
    endgenerate

    // Batch trigger snapshots DEPTH; INPUT/weights stay stable because all
    // busy writes (including triggers on completion edge) are ignored.
    // Four compute edges publish all results together. Legacy RESULT/done
    // remain independent; reset has priority over all operations.
    // Loop variables
    integer i;
    
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
            for (i = 0; i < 192; i = i + 1) batch_weights[i] <= 8'sd0;
            for (i = 0; i < 4; i = i + 1) batch_results[i] <= 32'd0;
            batch_depth <= 7'd0;
            batch_bank <= 2'd0;
            batch_busy <= 1'b0;
            batch_done <= 1'b0;
        end else if (batch_busy) begin
            batch_results[batch_bank] <= tree[1];
            if (batch_bank == 2'd3) begin
                batch_busy <= 1'b0;
                batch_done <= 1'b1;
            end else batch_bank <= batch_bank + 2'd1;
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
                // Same one-edge legacy computation, with modulo-32-bit
                // products/addition; the tree is shared with batch mode.
                result_reg <= tree[1];
                done_reg   <= 1'b1;
            end else if (addr == 8'd131) begin
                batch_depth <= depth_reg;
                batch_bank <= 2'd0;
                batch_busy <= 1'b1;
                batch_done <= 1'b0;
            end else if (addr >= 8'd208) begin
                batch_weights[(addr-8'd208)*8'd4] <= $signed(wdata[7:0]);
                batch_weights[(addr-8'd208)*8'd4+8'd1] <= $signed(wdata[15:8]);
                batch_weights[(addr-8'd208)*8'd4+8'd2] <= $signed(wdata[23:16]);
                batch_weights[(addr-8'd208)*8'd4+8'd3] <= $signed(wdata[31:24]);
            end
        end
    end

    // ==========================================
    // Read Logic (combinational)
    // ==========================================
    always @(*) begin
        rvalid = 1'b1;
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
        end else if (addr == 8'd131 || addr == 8'd136) begin
            rdata = {30'd0, batch_done, batch_busy};
        end else if (addr >= 8'd132 && addr <= 8'd135) begin
            rvalid = resetn && batch_done;
            rdata = rvalid ? batch_results[addr[1:0]] : 32'd0;
        end else begin
            rdata = 32'd0;
        end
    end

endmodule
