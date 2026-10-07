`timescale 1ns/1ps
`default_nettype none

module tb_pw_batch4_prototype;
    reg clk = 0;
    always #5 clk = ~clk;
    reg resetn = 0;
    reg [7:0] addr = 0;
    reg write_en = 0;
    reg [31:0] wdata = 0;
    wire [31:0] rdata;
    wire rvalid, busy, done;
    my_pw_batch4_prototype dut (.*);

    // Four independent production Level 2 dot products are the RTL oracle.
    wire [31:0] legacy_result [0:3];
    wire [7:0] legacy_addr = addr == 8'd131 ? 8'd129 :
        addr >= 8'd192 ? {4'b1100, addr[3:0]} : addr;
    genvar b;
    generate
        for (b = 0; b < 4; b = b + 1) begin: reference_duts
            wire selected = addr < 8'd192 || addr[5:4] == b;
            wire accepted = write_en && !busy && selected;
            my_pw_conv_accel reference_dut (.clk(clk), .resetn(resetn),
                .addr(legacy_addr), .write_en(accepted), .wdata(wdata),
                .rdata());
            assign legacy_result[b] = reference_dut.result_reg;
        end
    endgenerate

    reg signed [31:0] inputs [0:63];
    reg signed [31:0] weights [0:255];
    reg [31:0] expected [0:3];
    reg [31:0] rng = 32'h51a7c0de;
    integer depths [0:7];
    integer checks = 0, batches = 0, wrap_batches = 0;
    integer min_latency = 1000, max_latency = 0;
    integer d, mode, trial, bank, lane, n;
    reg [31:0] word_value;

    task check(input bit condition, input string message);
        begin
            checks = checks + 1;
            if (!condition) $fatal(1, "%s", message);
        end
    endtask

    function automatic [31:0] random_word;
        begin
            rng = rng ^ (rng << 13);
            rng = rng ^ (rng >> 17);
            rng = rng ^ (rng << 5);
            random_word = rng;
        end
    endfunction

    task write_reg(input [7:0] index, input [31:0] value);
        begin
            @(negedge clk); addr = index; wdata = value; write_en = 1;
            @(negedge clk); write_en = 0;
        end
    endtask

    task probe(input [7:0] index, input [31:0] value, input bit valid);
        begin
            @(negedge clk); addr = index; write_en = 0;
            #1;
            check(rvalid === valid, $sformatf("rvalid addr %0d", index));
            check(rdata === value, $sformatf("read addr %0d expected %h got %h", index, value, rdata));
        end
    endtask

    task reset_dut;
        begin
            @(negedge clk); resetn = 0; write_en = 1;
            addr = 255; wdata = 32'h7f00ff80;
            @(posedge clk); #1;
            check(!busy && !done, "reset clears busy/done");
            check(!rvalid, "reset suppresses valid");
            @(negedge clk); resetn = 1; write_en = 0;
            for (integer i = 0; i < 64; i = i + 1) begin
                inputs[i] = 0;
                probe(i[7:0], 0, 1);
            end
            for (integer i = 0; i < 256; i = i + 1) begin
                weights[i] = 0;
                check(dut.weight_buf[i] === 8'd0, "reset weight storage");
            end
            probe(128, 0, 1); probe(136, 0, 1);
            for (integer i = 0; i < 4; i = i + 1) probe(132+i, 0, 0);
        end
    endtask

    task load_vectors(input integer pattern);
        reg [31:0] x;
        reg [7:0] w;
        begin
            for (integer i = 0; i < 64; i = i + 1) begin
                case (pattern)
                    0: x = 0;
                    1: case (i % 4)
                        0: x = 32'h80000000;
                        1: x = 32'h7fffffff;
                        2: x = 32'hffffffff;
                        3: x = 32'd1;
                    endcase
                    2: x = (i * 37 % 256); // int8 input + offset 128
                    3: x = random_word();
                    5: x = $signed(8'(i * 37)) - 32'sd17;
                    default: x = i + 1;
                endcase
                inputs[i] = $signed(x);
                write_reg(i[7:0], x);
            end
            for (integer k = 0; k < 4; k = k + 1) begin
                for (integer g = 0; g < 16; g = g + 1) begin
                    word_value = 0;
                    for (integer byte_index = 0; byte_index < 4; byte_index = byte_index + 1) begin
                        case (pattern)
                            0: w = 0;
                            1: case ((byte_index + k) % 4)
                                0: w = 8'h80;
                                1: w = 8'hff;
                                2: w = 8'h00;
                                3: w = 8'h7f;
                            endcase
                            2: w = (g*4 + byte_index + k) % 2 ? 8'hff : 8'h7f;
                            3: w = random_word();
                            default: w = k == 2 ? 8'd1 : 8'd0;
                        endcase
                        weights[k*64 + g*4 + byte_index] = $signed(w);
                        word_value[byte_index*8 +: 8] = w;
                    end
                    write_reg(192 + k*16 + g, word_value);
                    for (integer j = 0; j < 4; j = j + 1)
                        check($signed(dut.weight_buf[k*64+g*4+j]) === weights[k*64+g*4+j],
                            "packed byte order/sign/bank mapping");
                end
            end
        end
    endtask

    task calculate_expected(input integer depth);
        reg signed [63:0] sum, product;
        bit wrapped;
        begin
            wrapped = 0;
            for (integer k = 0; k < 4; k = k + 1) begin
                sum = 0;
                for (integer i = 0; i < 64; i = i + 1) begin
                    if (i < depth) begin
                        product = inputs[i];
                        product = product * weights[k*64+i];
                        sum = sum + product;
                    end
                end
                expected[k] = sum[31:0];
                if (sum > 64'sh7fffffff || sum < -64'sh80000000) wrapped = 1;
            end
            if (wrapped) wrap_batches = wrap_batches + 1;
        end
    endtask

    task run_batch(input integer depth, input integer attack);
        integer latency;
        begin
            write_reg(128, depth);
            calculate_expected(depth & 127);
            @(negedge clk); addr = 131; wdata = 0; write_en = 1;
            @(posedge clk); #1;
            check(busy && !done, "trigger accepted, old done cleared (CTRL data ignored)");
            check(dut.batch_depth == (depth & 127), "depth snapshot");
            for (integer k = 0; k < 4; k = k + 1)
                check(legacy_result[k] === expected[k], "independent Level 2 oracle");
            latency = 0;
            for (integer cycle = 1; cycle <= 4; cycle = cycle + 1) begin
                @(negedge clk);
                write_en = attack != 0;
                if (attack) begin
                    if (attack == 2) begin addr = 131; wdata = 1; end
                    else case (cycle)
                        1: begin addr = 128; wdata = 0; end
                        2: begin addr = 0; wdata = 32'hdeadbeef; end
                        3: begin addr = 192; wdata = 32'hdeadbeef; end
                        4: begin addr = 131; wdata = 1; end
                    endcase
                end else addr = 132 + (cycle-1);
                #1;
                if (!attack) check(!rvalid && rdata == 0, "no old/partial results exposed while busy");
                @(posedge clk); #1;
                latency = latency + 1;
                check(dut.batch_depth == (depth & 127), "snapshot stable during compute");
                if (cycle < 4) check(busy && !done, "no early completion");
                else check(!busy && done, "completion on edge four");
                // Check all result addresses at each compute edge, even
                // when an illegal busy write was presented on that edge.
                for (integer k = 0; k < 4; k = k + 1) begin
                    addr = 132 + k;
                    #0.1;
                    check(rvalid === (cycle == 4), "atomic result validity");
                    check(rdata === (cycle == 4 ? expected[k] : 32'd0),
                        "invalid results masked; completed results correct");
                end
            end
            @(negedge clk); write_en = 0;
            for (integer k = 0; k < 4; k = k + 1) probe(132+k, expected[k], 1);
            probe(136, 2, 1);
            if (attack) begin
                probe(128, depth & 127, 1);
                probe(0, inputs[0], 1);
                for (integer j = 0; j < 4; j = j + 1)
                    check($signed(dut.weight_buf[j]) === weights[j], "busy weight write ignored");
            end
            check(latency == 4, "exact batch latency");
            if (latency < min_latency) min_latency = latency;
            if (latency > max_latency) max_latency = latency;
            batches = batches + 1;
        end
    endtask

    initial begin
        depths[0]=1; depths[1]=3; depths[2]=16; depths[3]=17;
        depths[4]=32; depths[5]=48; depths[6]=63; depths[7]=64;
        reset_dut();
        $display("[PASS] reset and invalid results");
        for (d = 0; d < 8; d = d + 1) begin
            for (mode = 0; mode < 4; mode = mode + 1) begin
                load_vectors(mode);
                run_batch(depths[d], mode == 1);
                // Back-to-back batches without a reset or INPUT reload.
                run_batch(depths[d], 0);
            end
            for (trial = 0; trial < 20; trial = trial + 1) begin
                load_vectors(3);
                run_batch(depths[d], trial % 2);
            end
            run_batch(depths[d], 2); // trigger held high through every busy edge
            load_vectors(5); run_batch(depths[d], 0); // negative input offset
            $display("[PASS] depth %0d: edges, offsets, zero, seeded random, Level 2 equivalence", depths[d]);
        end
        load_vectors(4); run_batch(64, 0);
        check(expected[0] == 0 && expected[1] == 0 && expected[2] == 2080 && expected[3] == 0,
            "bank isolation");
        for (n = 192; n < 256; n = n + 1) probe(n[7:0], 0, 1);
        // write_en=0 must not change INPUT/DEPTH/weights or trigger work.
        @(negedge clk); addr=0; wdata=32'hffffffff; write_en=0;
        @(posedge clk); #1; check(dut.input_buf[0] == inputs[0], "write_en=0 input");
        @(negedge clk); addr=192;
        @(posedge clk); #1; check(dut.weight_buf[0] == 0, "write_en=0 weight");
        @(negedge clk); addr=128;
        @(posedge clk); #1; check(dut.depth_reg == 64, "write_en=0 depth");
        @(negedge clk); addr=131;
        @(posedge clk); #1; check(!busy && done, "write_en=0 trigger");
        $display("[PASS] bank isolation, packed reads, write_en=0, busy writes/triggers");
        // Reset at every possible compute phase, including completion edge.
        for (n = 0; n < 4; n = n + 1) begin
            load_vectors(1); write_reg(128, 64);
            write_reg(131, 1);
            repeat (n) @(negedge clk);
            // write_reg returns at the negedge before bank 0 computation.
            // Assert here (without another negedge wait) to abort exactly
            // at compute edges 1,2,3,4 respectively.
            resetn = 0; addr = 131; write_en = 1; wdata = 1;
            @(posedge clk); #1;
            check(!busy && !done && !rvalid, "reset wins over compute/trigger");
            @(negedge clk); resetn = 1; write_en = 0;
            repeat (6) @(posedge clk);
            #1; check(!busy && !done, "reset aborts without delayed completion");
            reset_dut();
            run_batch(64, 0);
        end
        $display("[PASS] reset abort at all four compute phases and restart");
        // Match the existing seven-bit DEPTH behavior at domain edges.
        load_vectors(2); run_batch(0, 0); run_batch(65, 0); run_batch(127, 0); run_batch(128, 0);
        check(wrap_batches > 0, "wraparound vectors exercised");
        $display("[PASS] modulo-32-bit overflow and depth boundary behavior");
        $display("[MEASURE] trigger -> first valid result: %0d cycles", min_latency);
        $display("[MEASURE] trigger -> all four valid: %0d cycles (min=%0d max=%0d)", max_latency, min_latency, max_latency);
        $display("ALL PROTOTYPE TESTS PASSED: %0d batches, %0d assertions, %0d wraparound batches", batches, checks, wrap_batches);
        $finish;
    end
    initial begin
        #10000000;
        $fatal(1, "test timeout");
    end
endmodule

`default_nettype wire
