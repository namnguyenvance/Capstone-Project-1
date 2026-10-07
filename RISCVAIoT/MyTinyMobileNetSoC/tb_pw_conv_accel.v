`timescale 1ns/1ps
`default_nettype none

module tb_pw_conv_accel;
    reg clk = 0;
    always #5 clk = ~clk;
    reg resetn = 0;
    reg [7:0] addr = 0;
    reg write_en = 0;
    reg [31:0] wdata = 0;
    wire [31:0] rdata;
    my_pw_conv_accel dut (.clk(clk), .resetn(resetn), .addr(addr),
        .write_en(write_en), .wdata(wdata), .rdata(rdata));

    reg signed [31:0] inputs [0:63];
    reg signed [31:0] weights [0:63];
    reg signed [31:0] edges [0:6];
    reg [31:0] rng = 32'h51a7c0de;
    integer checks = 0;
    integer vectors = 0;
    integer i, a, b, d, k, lane;
    reg [31:0] observed, old_result;

    // Drive away from the sampling edge; reads occur after NBA settling.
    task write_reg(input [7:0] index, input [31:0] value);
        begin
            @(negedge clk);
            addr = index; wdata = value; write_en = 1;
            @(negedge clk);
            write_en = 0;
        end
    endtask

    task read_reg(input [7:0] index, output [31:0] value);
        begin
            @(negedge clk);
            addr = index; write_en = 0;
            #1 value = rdata;
        end
    endtask

    task check_reg(input [7:0] index, input [31:0] expected);
        reg [31:0] actual;
        begin
            read_reg(index, actual);
            checks = checks + 1;
            if (actual !== expected)
                $fatal(1, "register %0d expected %h, got %h", index, expected, actual);
        end
    endtask

    task reset_dut;
        begin
            @(negedge clk); resetn = 0;
            // Reset must win even with a write presented.
            addr = 0; wdata = 32'hdeadbeef; write_en = 1;
            @(negedge clk); addr = 207; wdata = 32'h7f00ff80;
            @(negedge clk);
            resetn = 1; write_en = 0;
            for (integer n = 0; n < 128; n = n + 1) check_reg(n, 0);
            check_reg(128, 0); check_reg(129, 0); check_reg(130, 0);
        end
    endtask

    task fill(input integer x, input integer w);
        begin
            for (integer n = 0; n < 64; n = n + 1) begin
                inputs[n] = x; weights[n] = w;
            end
        end
    endtask

    task load_vectors;
        begin
            for (integer n = 0; n < 64; n = n + 1) begin
                write_reg(n, inputs[n]); write_reg(64+n, weights[n]);
            end
        end
    endtask

    function [31:0] pack_group(input integer base_lane);
        begin
            pack_group = {weights[base_lane+3][7:0], weights[base_lane+2][7:0],
                          weights[base_lane+1][7:0], weights[base_lane][7:0]};
        end
    endfunction

    task load_packed_weights(input integer depth);
        integer n;
        begin
            for (n = 0; n + 3 < depth; n = n + 4)
                write_reg(192+n/4, pack_group(n));
            for (; n < depth; n = n + 1) write_reg(64+n, weights[n]);
        end
    endtask

    // Independent wide reference; modulo 2^32 only at the comparison boundary.
    task compute_check(input integer depth);
        reg signed [63:0] sum, x, w;
        begin
            sum = 0;
            for (integer n = 0; n < depth; n = n + 1) begin
                x = inputs[n]; w = weights[n]; sum = sum + x*w;
            end
            write_reg(128, depth);
            write_reg(129, 1);
            check_reg(130, sum[31:0]); check_reg(129, 1);
            vectors = vectors + 1;
        end
    endtask

    task run_vector(input integer depth);
        begin load_vectors; compute_check(depth); end
    endtask

    function [31:0] next_random(input [31:0] state);
        reg [31:0] v;
        begin
            v = state ^ (state << 13);
            v = v ^ (v >> 17);
            next_random = v ^ (v << 5);
        end
    endfunction

    // Informational comparisons never affect the required pass/fail result.
    task characterize(input [255:0] label_text, input [7:0] index,
                      input [31:0] baseline);
        reg [31:0] actual;
        begin
            read_reg(index, actual);
            $display("[INFO] %0s: observed 0x%08h (baseline 0x%08h)",
                     label_text, actual, baseline);
        end
    endtask

    initial begin
        #100000000;
        $fatal(1, "simulation watchdog expired");
    end

    initial begin
        reset_dut;
        fill(-128, 127); run_vector(64);
        // Synchronous reset: no change before the next rising edge.
        @(negedge clk); addr = 130; #1 old_result = rdata;
        resetn = 0; #1;
        checks = checks + 1;
        if (rdata !== old_result) $fatal(1, "reset acted asynchronously");
        @(posedge clk); #1;
        checks = checks + 1;
        if (rdata !== 0) $fatal(1, "reset did not clear at rising edge");
        reset_dut;
        $display("[PASS] reset");

        for (i = 0; i < 64; i = i + 1) begin
            write_reg(i, 32'h80000000+i);
            write_reg(64+i, 32'h12340000+i);
        end
        for (i = 0; i < 64; i = i + 1) begin
            check_reg(i, 32'h80000000+i);
            check_reg(64+i, 32'h12340000+i);
        end
        write_reg(128, 48); check_reg(128, 48);
        // Disabled write, read-only RESULT, unused addresses, and reset
        // readback of the newly assigned batch/packed-bank addresses.
        @(negedge clk); addr = 0; wdata = 0; write_en = 0;
        @(negedge clk); check_reg(0, 32'h80000000);
        write_reg(130, 32'hffffffff); check_reg(130, 0);
        for (i = 131; i < 256; i = i + 1) begin
            if (i >= 137 && i < 192) write_reg(i, 32'hffffffff);
            check_reg(i, 0);
        end
        check_reg(128, 48); check_reg(130, 0);
        $display("[PASS] register addressing");

        // Every packed address, byte order, sign extension and neighbor safety.
        fill(123456, 32'h12345678); load_vectors;
        write_reg(128, 1); write_reg(129, 1); read_reg(130, old_result);
        for (k = 0; k < 16; k = k + 1) begin
            weights[4*k]=-128; weights[4*k+1]=-1;
            weights[4*k+2]=0; weights[4*k+3]=127;
            write_reg(192+k, 32'h7f00ff80);
            check_reg(192+k, 0);
            for (i=0; i<64; i=i+1) begin
                check_reg(64+i, weights[i]); check_reg(i, inputs[i]);
            end
            check_reg(128, 1); check_reg(130, old_result); check_reg(129, 1);
        end
        // Scalar after packed, then packed after scalar (including wide int32).
        write_reg(65, 32'h89abcdef); check_reg(65, 32'h89abcdef);
        check_reg(64,-128); check_reg(66,0); check_reg(67,127);
        write_reg(192, 32'h01020304);
        check_reg(64,4); check_reg(65,3); check_reg(66,2); check_reg(67,1);
        // Disabled packed write must not affect any of its four lanes.
        @(negedge clk); addr=192; wdata=32'hffffffff; write_en=0;
        @(negedge clk);
        check_reg(64,4); check_reg(65,3); check_reg(66,2); check_reg(67,1);
        // Back-to-back packed writes, first and last groups.
        @(negedge clk); addr=192; wdata=32'h7f00ff80; write_en=1;
        @(negedge clk); addr=207; wdata=32'h80ff007f;
        @(negedge clk); write_en=0;
        check_reg(64,-128); check_reg(65,-1); check_reg(66,0); check_reg(67,127);
        check_reg(124,127); check_reg(125,0); check_reg(126,-1); check_reg(127,-128);
        reset_dut; // Includes a packed write while reset is asserted.
        // A packed write after reset must leave done/result/depth untouched.
        write_reg(192,32'h7f00ff80);
        check_reg(128,0); check_reg(129,0); check_reg(130,0);
        // Exhaust all 256 byte encodings in each byte position.
        for (a=0; a<256; a=a+1) begin
            for (i=0; i<4; i=i+1) begin
                weights[i]=0;
            end
            for (lane=0; lane<4; lane=lane+1) begin
                weights[lane]=$signed(a[7:0]);
                write_reg(192,pack_group(0));
                for (i=0; i<4; i=i+1) check_reg(64+i,weights[i]);
                weights[lane]=0;
            end
        end
        // Legacy versus packed computation, including tails and excluded lanes.
        for (k=0; k<8; k=k+1) begin
            case (k) 0:d=1; 1:d=3; 2:d=16; 3:d=17;
                     4:d=32; 5:d=48; 6:d=63; 7:d=64; endcase
            for (a=0; a<20; a=a+1) begin
                for (i=0; i<64; i=i+1) begin
                    rng=next_random(rng); inputs[i]=$signed(rng[7:0])+128;
                    rng=next_random(rng); weights[i]=$signed(rng[7:0]);
                end
                run_vector(d); read_reg(130,old_result);
                // Poison active lanes so a missing packed or tail write fails.
                for (i=0; i<d; i=i+1) write_reg(64+i,32'h12345678);
                load_packed_weights(d);
                for (i=0; i<64; i=i+1) check_reg(64+i,weights[i]);
                compute_check(d); check_reg(130,old_result);
            end
        end
        $display("[PASS] packed weights: addressing, signed bytes, reset, overwrites, tails, equivalence");
        reset_dut;

        edges[0]=-128; edges[1]=-127; edges[2]=-1; edges[3]=0;
        edges[4]=1; edges[5]=126; edges[6]=127;
        // Exhaustive signed int8 multiplication, keeping inactive lanes loaded.
        fill(99, -77); load_vectors;
        for (a = -128; a <= 127; a = a + 1)
            for (b = -128; b <= 127; b = b + 1) begin
                inputs[0]=a; weights[0]=b;
                write_reg(0,a); write_reg(64,b); compute_check(1);
            end
        $display("[PASS] exhaustive signed int8 products (65536 vectors)");

        for (k = 0; k < 5; k = k + 1) begin
            case (k) 0:d=1; 1:d=16; 2:d=32; 3:d=48; 4:d=64; endcase
            fill(0,0); run_vector(d);
            fill(0,-128); run_vector(d);
            fill(127,0); run_vector(d);
            for (a=0; a<7; a=a+1)
                for (b=0; b<7; b=b+1) begin
                    fill(edges[a],edges[b]); run_vector(d);
                end
            // Mixed signs and cancellation, including a +/-1 residue.
            fill(1,1);
            for (i=0; i<d; i=i+1) weights[i]=(i%2) ? -1 : 1;
            run_vector(d);
            inputs[0]=2; run_vector(d);
            inputs[0]=0; run_vector(d);
            // One active lane at a time; all excluded lanes contain sentinels.
            for (lane=0; lane<d; lane=lane+1) begin
                fill(127,127);
                for (i=0; i<d; i=i+1) begin inputs[i]=0; weights[i]=0; end
                inputs[lane]=-128; weights[lane]=127; run_vector(d);
            end
            // Firmware offset-adjusted operands are deliberately wider than int8.
            for (i=0; i<64; i=i+1) begin
                case (i%3) 0:inputs[i]=-255; 1:inputs[i]=128; 2:inputs[i]=255; endcase
                weights[i]=edges[i%7];
            end
            run_vector(d);
            for (a=0; a<100; a=a+1) begin
                for (i=0; i<64; i=i+1) begin
                    rng=next_random(rng); inputs[i]=$signed(rng[7:0]);
                    rng=next_random(rng); weights[i]=$signed(rng[7:0]);
                end
                run_vector(d);
            end
            $display("[PASS] depth %0d", d);
        end

        // Reuse loaded inputs across weights and vice versa; results stay latched.
        fill(3,-7); run_vector(64);
        read_reg(130,old_result);
        for (i=0; i<64; i=i+1) begin weights[i]=i-32; write_reg(64+i,weights[i]); end
        check_reg(130,old_result); compute_check(64);
        read_reg(130,old_result);
        for (i=0; i<64; i=i+1) begin inputs[i]=127-i; write_reg(i,inputs[i]); end
        check_reg(130,old_result); compute_check(64);
        compute_check(1); compute_check(48); compute_check(16);
        compute_check(32); compute_check(64);
        // Back-to-back writes on consecutive rising edges.
        @(negedge clk); addr=0; wdata=5; write_en=1; inputs[0]=5;
        @(negedge clk); addr=64; wdata=-9; weights[0]=-9;
        @(negedge clk); addr=128; wdata=1;
        @(negedge clk); addr=129; wdata=1;
        @(negedge clk); write_en=0;
        check_reg(130,-45); check_reg(129,1); vectors=vectors+1;
        $display("[PASS] reuse, depth transitions, consecutive writes");
        $display("REQUIRED: %0d assertions, %0d dot-product vectors", checks, vectors);

        $display("BASELINE CHARACTERIZATION (informational only)");
        write_reg(0,6); write_reg(64,-7); write_reg(128,1);
        write_reg(129,0); characterize("CTRL=0 triggers",130,-42);
        write_reg(0,7); write_reg(129,2); characterize("CTRL=2 triggers",130,-49);
        write_reg(0,8); write_reg(129,32'hffffffff);
        characterize("CTRL=ffffffff triggers",130,-56);
        write_reg(0,9); write_reg(128,16);
        characterize("done after operand/depth writes",129,1);
        fill(1,1); load_vectors;
        write_reg(128,0); write_reg(129,1); characterize("DEPTH=0 result",130,0);
        write_reg(128,65); write_reg(129,1); characterize("DEPTH=65 result",130,64);
        write_reg(128,127); write_reg(129,1); characterize("DEPTH=127 result",130,64);
        write_reg(128,128); characterize("DEPTH=128 readback",128,0);
        write_reg(129,1); characterize("DEPTH=128 result",130,0);
        write_reg(128,129); characterize("DEPTH=129 readback",128,1);
        write_reg(129,1); characterize("DEPTH=129 result",130,1);

        write_reg(128,1); write_reg(0,65536); write_reg(64,65536);
        write_reg(129,1); characterize("product overflow",130,0);
        write_reg(128,2); write_reg(0,1073741824); write_reg(1,1073741824);
        write_reg(64,1); write_reg(65,1); write_reg(129,1);
        characterize("positive accumulator overflow",130,32'h80000000);
        write_reg(0,-1073741825); write_reg(1,-1073741825); write_reg(129,1);
        characterize("negative accumulator overflow",130,32'h7ffffffe);
        write_reg(128,1); write_reg(0,32'h80000000); write_reg(64,-1);
        write_reg(129,1); characterize("INT32_MIN times -1",130,32'h80000000);
        write_reg(128,3); write_reg(0,1073741824); write_reg(1,1073741824);
        write_reg(2,-1073741824); write_reg(64,1); write_reg(65,1); write_reg(66,1);
        write_reg(129,1); characterize("overflow then cancellation",130,32'h40000000);

        write_reg(128,1); write_reg(0,2); write_reg(64,3);
        @(negedge clk); addr=129; wdata=0; write_en=1;
        @(negedge clk); addr=130; #1;
        $display("[INFO] held CTRL first result: %0d (baseline 6)", $signed(rdata));
        // Change inputs through the public port without dropping write_en.
        addr=0; wdata=4;
        @(negedge clk); addr=129; wdata=0;
        @(negedge clk); addr=130; #1;
        $display("[INFO] held write_en retrigger result: %0d (baseline 12)", $signed(rdata));
        addr=129;
        repeat (3) @(negedge clk);
        write_en=0;
        characterize("consecutive held CTRL result",130,12);
        $display("ALL REQUIRED TESTS PASSED");
        $finish;
    end
endmodule

`timescale 1ns/1ps
`default_nettype none

module tb_pw_conv_accel_batch;
    reg clk = 0;
    always #5 clk = ~clk;
    reg resetn = 0;
    reg [7:0] addr = 0;
    reg write_en = 0;
    reg [31:0] wdata = 0;
    wire [31:0] rdata;
    wire rvalid, busy, done;
    assign busy = dut.batch_busy;
    assign done = dut.batch_done;
    my_pw_conv_accel dut (.clk(clk), .resetn(resetn), .addr(addr),
        .write_en(write_en), .wdata(wdata), .rdata(rdata), .rvalid(rvalid));
    function automatic signed [31:0] stored_weight(input integer index);
        stored_weight = index < 64 ? dut.weight_buf[index] :
            $signed(dut.batch_weights[index-64]);
    endfunction

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
            check(rvalid, "ordinary register reads stay valid during reset");
            @(negedge clk); resetn = 1; write_en = 0;
            for (integer i = 0; i < 64; i = i + 1) begin
                inputs[i] = 0;
                probe(i[7:0], 0, 1);
            end
            for (integer i = 0; i < 256; i = i + 1) begin
                weights[i] = 0;
                check(stored_weight(i) === 32'd0, "reset weight storage");
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
                        check(stored_weight(k*64+g*4+j) === weights[k*64+g*4+j],
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
                    else if (attack == 3) begin addr = 129; wdata = 0; end
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
        write_reg(0, 32'h80000000); inputs[0] = 32'sh80000000;
        write_reg(64, 65537); weights[0] = 65537;
        write_reg(128, 1); write_reg(129, 0);
        probe(64, 65537, 1); probe(130, 32'h80000000, 1); probe(129, 1, 1);
        // A software reference checks full-width bank 0; reference banks
        // 1..3 also saw the scalar write, so reload their packed weights.
        for (integer k = 1; k < 4; k = k + 1)
            write_reg(192+k*16, k == 2 ? 32'h01010101 : 0);
        run_batch(1, 2);
        run_batch(1, 3); // legacy CTRL is also ignored while batch-busy
        probe(130, 32'h80000000, 1); probe(129, 1, 1);
        write_reg(0, 3); inputs[0] = 3;
        write_reg(64, -65537); weights[0] = -65537;
        write_reg(129, 7); probe(130, -196611, 1);
        for (integer k = 0; k < 4; k = k + 1) probe(132+k, expected[k], 1);
        $display("[PASS] wide legacy bank 0, mixed modes, independent RESULT/done");
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
            check(!busy && !done, "reset wins over compute/trigger");
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
