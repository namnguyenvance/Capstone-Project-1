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
            repeat (2) @(negedge clk);
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
        // Disabled write, read-only RESULT, and every unused address.
        @(negedge clk); addr = 0; wdata = 0; write_en = 0;
        @(negedge clk); check_reg(0, 32'h80000000);
        write_reg(130, 32'hffffffff); check_reg(130, 0);
        for (i = 131; i < 256; i = i + 1) begin
            write_reg(i, 32'hffffffff); check_reg(i, 0);
        end
        check_reg(128, 48); check_reg(130, 0);
        $display("[PASS] register addressing");

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
