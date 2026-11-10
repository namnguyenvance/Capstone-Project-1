`timescale 1ns/1ps
`default_nettype none

// Standalone experiment only: not connected to my_soc.v.
// Word indices in the existing 1 KiB PW window:
//   0..63 INPUT: signed int32, read/write
//   128 DEPTH: low 7 bits, read/write; snapshotted on trigger
//   131 BATCH_CTRL: any write triggers when idle; read {done,busy}
//   132..135 BATCH_RESULT: read only, rvalid=done
//   136 STATUS: read {done,busy}
//   192..255 PACKED_WEIGHT: 16 words per bank, write only/read zero
// Packed byte 0 is the lowest lane; weights are signed int8.
// Legacy CTRL/RESULT/scalar WEIGHT are intentionally not implemented here.
//
// A trigger clears done and invalidates ALL result reads. The next four
// rising edges compute banks 0,1,2,3 using ONE shared 64-lane datapath.
// Results publish atomically on edge 4; done stays set until trigger/reset.
// All writes while busy are ignored, including on the completion edge.
// Reset is synchronous, active low, and has priority over writes/compute.
// No bus-ready integration: a future adapter MUST honor rvalid for reads.
module my_pw_batch4_prototype (
    input wire clk,
    input wire resetn,
    input wire [7:0] addr,
    input wire write_en,
    input wire [31:0] wdata,
    output reg [31:0] rdata,
    output reg rvalid,
    output reg busy,
    output reg done
);
    reg signed [31:0] input_buf [0:63];
    reg signed [7:0] weight_buf [0:255];
    reg [6:0] depth_reg, batch_depth;
    reg [1:0] bank;
    reg [31:0] result_buf [0:3];
    wire [31:0] tree [1:127];
    integer i;

    // Truncate each product and each adder to 32 bits. Modular addition
    // permits this balanced tree to match Level 2's ordered accumulation.
    genvar lane, node;
    generate
        for (lane = 0; lane < 64; lane = lane + 1) begin: products
            wire signed [7:0] selected_weight;
            wire signed [31:0] extended_weight;
            assign selected_weight = weight_buf[{bank, 6'b000000} + lane];
            assign extended_weight = {{24{selected_weight[7]}}, selected_weight};
            assign tree[64 + lane] = (lane < batch_depth) ?
                input_buf[lane] * extended_weight : 32'd0;
        end
        for (node = 1; node < 64; node = node + 1) begin: reduction
            assign tree[node] = tree[2*node] + tree[2*node + 1];
        end
    endgenerate

    always @(posedge clk) begin
        if (!resetn) begin
            for (i = 0; i < 64; i = i + 1) input_buf[i] <= 32'sd0;
            for (i = 0; i < 256; i = i + 1) weight_buf[i] <= 8'sd0;
            for (i = 0; i < 4; i = i + 1) result_buf[i] <= 32'd0;
            depth_reg <= 7'd0;
            batch_depth <= 7'd0;
            bank <= 2'd0;
            busy <= 1'b0;
            done <= 1'b0;
        end else if (busy) begin
            result_buf[bank] <= tree[1];
            if (bank == 2'd3) begin
                busy <= 1'b0;
                done <= 1'b1;
            end else bank <= bank + 2'd1;
        end else if (write_en) begin
            if (addr <= 8'd63) input_buf[addr[5:0]] <= $signed(wdata);
            else if (addr == 8'd128) depth_reg <= wdata[6:0];
            else if (addr == 8'd131) begin
                batch_depth <= depth_reg;
                bank <= 2'd0;
                busy <= 1'b1;
                done <= 1'b0;
            end else if (addr >= 8'd192) begin
                weight_buf[{addr[5:0], 2'b00}] <= $signed(wdata[7:0]);
                weight_buf[{addr[5:0], 2'b01}] <= $signed(wdata[15:8]);
                weight_buf[{addr[5:0], 2'b10}] <= $signed(wdata[23:16]);
                weight_buf[{addr[5:0], 2'b11}] <= $signed(wdata[31:24]);
            end
        end
    end

    always @(*) begin
        rdata = 32'd0;
        rvalid = resetn;
        if (addr <= 8'd63) rdata = input_buf[addr[5:0]];
        else if (addr == 8'd128) rdata = {25'd0, depth_reg};
        else if (addr == 8'd131 || addr == 8'd136)
            rdata = {30'd0, done, busy};
        else if (addr >= 8'd132 && addr <= 8'd135) begin
            rvalid = resetn && done;
            if (rvalid) rdata = result_buf[addr[1:0]];
        end
    end
endmodule

`default_nettype wire
