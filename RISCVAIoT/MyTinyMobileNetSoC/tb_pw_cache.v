`timescale 1ns/1ps
`default_nettype none

// Production resident-cache arithmetic and state safety. The second instance
// computes each batch through the existing Level 4 packed-bank interface.
module tb_pw_cache;
    reg clk = 0;
    always #5 clk = ~clk;
    reg resetn = 0;
    reg [7:0] addr = 0, legacy_addr = 0;
    reg write_en = 0, legacy_write_en = 0;
    reg [31:0] wdata = 0, legacy_wdata = 0;
    wire [31:0] rdata, legacy_rdata;
    wire rvalid, legacy_rvalid;
    my_pw_conv_accel dut(clk, resetn, addr, write_en, wdata, rdata, rvalid);
    my_pw_conv_accel legacy(clk, resetn, legacy_addr, legacy_write_en,
        legacy_wdata, legacy_rdata, legacy_rvalid);

    reg signed [7:0] weights [0:511];
    reg signed [31:0] inputs [0:15];
    reg [31:0] expected [0:3], packed_word;
    reg [31:0] seed = 32'h7351cafe;
    integer i, lane, group_index, position, bank, word_index, phase;
    integer cycles, checks = 0;

    function [31:0] next_random(input [31:0] x);
        reg [31:0] t;
        begin
            t = x ^ (x << 13);
            t = t ^ (t >> 17);
            next_random = t ^ (t << 5);
        end
    endfunction

    // Independent wide arithmetic; truncate only at the dot-product boundary.
    function [31:0] reference_dot(input integer channel);
        reg signed [63:0] sum;
        integer n;
        begin
            sum = 0;
            for (n = 0; n < 16; n = n + 1)
                sum = sum + inputs[n] * weights[channel*16+n];
            reference_dot = sum[31:0];
        end
    endfunction

    task check(input bit condition, input string message);
        begin
            checks = checks + 1;
            if (!condition) $fatal(1, "%s", message);
        end
    endtask

    task write_reg(input [7:0] index, input [31:0] value);
        begin
            @(negedge clk); addr = index; wdata = value; write_en = 1;
            @(posedge clk); #1;
            @(negedge clk); write_en = 0;
        end
    endtask

    task legacy_write(input [7:0] index, input [31:0] value);
        begin
            @(negedge clk); legacy_addr = index; legacy_wdata = value; legacy_write_en = 1;
            @(posedge clk); #1;
            @(negedge clk); legacy_write_en = 0;
        end
    endtask

    task reset;
        begin
            @(negedge clk); resetn = 0;
            @(posedge clk); #1;
            @(negedge clk); resetn = 1;
        end
    endtask

    task unavailable;
        begin
            addr = 132; #1;
            check(!rvalid && rdata === 0, "invalid results cannot expose stale data");
        end
    endtask

    task preload;
        integer n;
        begin
            write_reg(137, 0);
            for (n = 0; n < 128; n = n + 1) begin
                packed_word = {weights[4*n+3], weights[4*n+2], weights[4*n+1], weights[4*n]};
                write_reg(138, packed_word);
                addr = 137; #1;
                check(rdata == n+1, "preload auto-increment/addressing");
            end
            addr = 140; #1;
            check(rdata[2] === 1, "all 128 words mark preload complete");
            for (n = 0; n < 512; n = n + 1)
                check(dut.cache_rows[n/16][(n%16)*8 +: 8] === weights[n],
                    "all signed bytes stored in channel-major little-endian order");
            addr = 138; #1;
            check(rvalid && rdata == 0, "packed cache preload port reads zero");
        end
    endtask

    task prepare_legacy(input integer group_number);
        integer b, w, n;
        begin
            for (b = 0; b < 4; b = b + 1) begin
                expected[b] = reference_dot(group_number*4+b);
                for (w = 0; w < 4; w = w + 1) begin
                    n = (group_number*4+b)*16+w*4;
                    legacy_write(192+b*16+w,
                        {weights[n+3], weights[n+2], weights[n+1], weights[n]});
                end
            end
            legacy_write(131, 1);
            repeat (4) begin @(posedge clk); #1; end
        end
    endtask

    task compare_results;
        integer b;
        begin
            for (b = 0; b < 4; b = b + 1) begin
                addr = 132+b; legacy_addr = 132+b; #1;
                check(rvalid && legacy_rvalid && rdata === expected[b] && rdata === legacy_rdata,
                    "cached result equals independent arithmetic and legacy batch");
            end
        end
    endtask

    initial begin
        reset(); unavailable(); write_reg(139, 0);
        addr = 140; #1;
        check(rdata == 8, "incomplete preload rejects cached trigger");
        for (i = 0; i < 512; i = i + 1) begin
            case (i%4)
                0: weights[i] = -128;
                1: weights[i] = -1;
                2: weights[i] = 0;
                3: weights[i] = 127;
            endcase
            // Distinct first lane identifies every channel and every group.
            if (i%16 == 0) weights[i] = i/16-16;
        end

        // Consecutive asserted DATA writes increment once per compute edge.
        write_reg(137, 0);
        @(negedge clk); addr = 138; wdata = 32'h7f00ff80; write_en = 1;
        @(posedge clk); #1;
        @(negedge clk); wdata = 32'h80ff007f;
        @(posedge clk); #1; write_en = 0;
        check(dut.cache_index == 2 && dut.cache_loaded[1:0] == 3 &&
            dut.cache_rows[0][63:0] == 64'h80ff007f7f00ff80, "consecutive preload writes");
        write_reg(137, 0);
        @(negedge clk); addr = 138; wdata = 32'h89abcdef; write_en = 0;
        @(posedge clk); #1;
        check(dut.cache_loaded === 0 && dut.cache_index === 0 &&
            dut.cache_rows[0][31:0] === 32'h7f00ff80, "disabled preload write");
        preload();
        write_reg(139, 8); unavailable(); addr = 140; #1;
        check(rdata == 12, "invalid group retains weights and invalidates results");
        write_reg(139, 32'hffffffff); unavailable();
        write_reg(128, 16); legacy_write(128, 16);

        for (position = 0; position < 784; position = position + 1) begin
            for (lane = 0; lane < 16; lane = lane + 1) begin
                seed = next_random(seed);
                inputs[lane] = position == 0 ? (lane%2 ? 32'h80000000 : 32'h7fffffff) :
                    position == 1 ? -128+lane+128 : $signed(seed);
                write_reg(lane, inputs[lane]); legacy_write(lane, inputs[lane]);
            end
            for (group_index = 0; group_index < 8; group_index = group_index + 1) begin
                prepare_legacy(group_index);
                write_reg(139, group_index); unavailable(); cycles = 0;
                // Busy trigger/input/DEPTH/preload writes, including completion edge.
                addr = 139; wdata = 7; write_en = 1;
                while (!dut.batch_done) begin
                    @(posedge clk); #1; cycles = cycles + 1;
                    case (cycles)
                        1: begin addr = 0; wdata = 32'h12345678; end
                        2: begin addr = 128; wdata = 64; end
                        3: begin addr = 138; wdata = 32'h7fffffff; end
                    endcase
                end
                write_en = 0;
                check(cycles == 4, "cached trigger to first/all valid is four cycles");
                compare_results();
                addr = 0; #1;
                check(rdata === inputs[0], "busy INPUT write ignored");
                addr = 128; #1;
                check(rdata == 16, "busy DEPTH write ignored");
                addr = 140; #1;
                check(rdata == 6, "busy trigger/preload cannot alter cache validity");
            end
        end

        write_reg(64, 32'h80000000); addr = 64; #1;
        check(rdata === 32'h80000000, "legacy scalar weight retains int32 semantics");
        write_reg(139, 0); repeat (4) begin @(posedge clk); #1; end
        addr = 132; #1;
        check(rvalid && rdata === reference_dot(0), "legacy weight overwrite cannot modify cache");

        // Abort before each of the four compute phases; validity never survives reset.
        for (phase = 0; phase < 4; phase = phase + 1) begin
            if (phase != 0) preload();
            write_reg(139, 0);
            repeat (phase) begin @(posedge clk); #1; end
            if (phase != 0) @(negedge clk);
            resetn = 0;
            @(posedge clk); #1;
            write_en = 0; resetn = 1; unavailable(); addr = 140; #1;
            check(rdata == 0, "reset aborts batch and invalidates cache at every phase");
            write_reg(139, 0); unavailable();
        end

        write_reg(137, 127); write_reg(138, 32'h7f00ff80);
        addr = 140; #1; check(!rdata[2], "one word is not a complete preload");
        write_reg(139, 0); unavailable();
        write_reg(138, 32'h12345678);
        check(dut.cache_index == 128 && dut.cache_rows[31][127:96] === 32'h7f00ff80,
            "preload index saturates without wrapping or overwriting");
        write_reg(137, 32'hffffffff); addr = 137; #1;
        check(rdata == 128, "invalid preload index saturates");
        @(negedge clk); resetn = 0; write_en = 1; addr = 139;
        @(posedge clk); #1; write_en = 0; resetn = 1; unavailable();

        // A second distinct complete tensor exercises reuse and all bank identities.
        for (i = 0; i < 512; i = i + 1) begin seed = next_random(seed); weights[i] = seed[7:0]; end
        for (lane = 0; lane < 16; lane = lane + 1) begin
            seed = next_random(seed); inputs[lane] = $signed(seed);
            write_reg(lane, inputs[lane]); legacy_write(lane, inputs[lane]);
        end
        legacy_write(128, 16); preload();
        for (group_index = 0; group_index < 8; group_index = group_index + 1) begin
            prepare_legacy(group_index); write_reg(139, group_index);
            repeat (4) begin @(posedge clk); #1; end
            compare_results();
        end
        $display("[PASS] PW1 cache: %0d assertions; all 32 channels, 784 resident positions, signed/wrap/state/reset/preload", checks);
        $display("[MEASURE] cached trigger -> first/all valid: exactly 4 cycles");
        $finish;
    end
    initial begin #10000000; $fatal(1, "cache test timeout"); end
endmodule
`default_nettype wire
