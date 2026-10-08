`timescale 1ns/1ps
`default_nettype none

// Exercise the ACTUAL my_soc PW decoder/registered handshake. The CPU's
// bus outputs are overridden; no firmware inference is executed.
module tb_pw_bus;
    reg clk = 0;
    always #5 clk = ~clk;
    reg resetn = 0;
    reg request = 0;
    reg [31:0] address = 32'h02000400, data = 0;
    reg [3:0] strobes = 0;
    wire [7:0] leds;
    wire ser_tx;
    my_soc soc (.clk(clk), .resetn(resetn), .leds(leds), .ser_tx(ser_tx), .ser_rx(1'b1));
    integer cycles, checks = 0, early_cycles, cached_early_cycles, word_index;
    reg [31:0] value;

    task check(input bit condition, input string message);
        begin
            checks = checks + 1;
            if (!condition) $fatal(1, "%s", message);
        end
    endtask

    // Ready is sampled before NBA at rising edges, exactly as the CPU
    // samples it. Ordinary transactions therefore take TWO sample edges.
    task access(input integer index, input bit write_access, input [31:0] payload);
        bit ack;
        begin
            @(negedge clk);
            address = 32'h02000400 + 4*index;
            data = payload; strobes = write_access ? 4'hf : 4'h0; request = 1;
            #1; check(!soc.mem_ready, "no stale acknowledgement at new request");
            cycles = 0; ack = 0;
            while (!ack) begin
                @(posedge clk);
                ack = soc.mem_ready;
                cycles = cycles + 1;
                if (ack) value = soc.mem_rdata;
                if (!write_access && index >= 132 && index <= 135 && ack)
                    check(soc.pw_conv_accel_rvalid, "invalid batch result acknowledged");
                #1;
                check(cycles < 20, "no deadlock after valid trigger");
            end
            // Deassert without consuming another bus edge. Next access
            // starts at the immediately following negedge (no idle bubble).
            request = 0; strobes = 0;
        end
    endtask

    initial begin
        force soc.mem_valid = request;
        force soc.mem_instr = 1'b0;
        force soc.mem_addr = address;
        force soc.mem_wdata = data;
        force soc.mem_wstrb = strobes;
        repeat (2) @(negedge clk);
        resetn = 1;
        access(0, 1, 3); check(cycles == 2, "legacy INPUT write timing");
        access(64, 1, -7); check(cycles == 2, "legacy WEIGHT write timing");
        access(128, 1, 1); check(cycles == 2, "legacy DEPTH write timing");
        access(129, 1, 0); check(cycles == 2, "legacy CTRL write timing");
        access(130, 0, 0); check(cycles == 2 && value == -21, "legacy RESULT read timing/value");
        access(129, 0, 0); check(cycles == 2 && value == 1, "legacy sticky done timing");
        access(208, 1, 2); access(224, 1, 4); access(240, 1, 6);
        access(131, 1, 0); check(cycles == 2, "batch trigger timing");
        access(132, 0, 0); early_cycles = cycles;
        check(cycles == 5 && value == -21, "early batch read waits then returns bank 0");
        access(133, 0, 0); check(cycles == 2 && value == 6, "bank 1 normal completed read");
        access(134, 0, 0); check(cycles == 2 && value == 12, "bank 2 normal completed read");
        access(135, 0, 0); check(cycles == 2 && value == 18, "bank 3 normal completed read");
        access(136, 0, 0); check(cycles == 2 && value == 2, "status normal timing");
        // A second trigger invalidates the previous published results.
        access(0, 1, 5); access(131, 1, 1);
        access(133, 0, 0); check(cycles == 5 && value == 10, "no stale result on consecutive batch");
        // Busy writes must ACK normally but must not alter the datapath.
        access(131, 1, 1); access(0, 1, 99);
        check(cycles == 2, "busy write acknowledgement unchanged");
        access(0, 0, 0); check(cycles == 2 && value == 5, "busy input write ignored");
        access(132, 0, 0); check(value == -35, "busy write leaves batch result intact");
        access(131, 1, 1); access(131, 1, 1);
        check(cycles == 2, "busy trigger acknowledgement unchanged");
        access(136, 0, 0); check(value == 2, "busy trigger did not restart engine");
        // Before any trigger, an invalid result read must not acknowledge.
        @(negedge clk); resetn = 0; request = 0;
        @(negedge clk); resetn = 1; request = 1; address = 32'h02000610; strobes = 0;
        repeat (6) begin
            @(posedge clk); check(!soc.mem_ready, "reset result remains unacknowledged"); #1;
        end
        @(negedge clk); resetn = 0; request = 0;
        @(negedge clk); resetn = 1;
        access(131, 1, 1); access(135, 0, 0); check(value == 0, "reset and retrigger recover");
        // Cache registers use the existing 1 KiB decode and normal write ACK.
        access(139, 1, 0); check(cycles == 2, "incomplete cache trigger ACK");
        access(140, 0, 0); check(value == 8, "incomplete cache rejects/invalidates trigger");
        access(137, 1, 0); check(cycles == 2, "cache index normal ACK");
        for (word_index=0; word_index<128; word_index=word_index+1) begin
            // Channel c has only weight[0]=c-16; all remaining weights zero.
            access(138, 1, word_index%4 == 0 ? ((word_index/4-16)&255) : 0);
            check(cycles == 2, "preload write normal ACK");
            access(137, 0, 0);
            check(cycles == 2 && value == word_index+1, "one auto-increment per bus write");
        end
        access(138, 0, 0); check(value == 0, "preload port read zero");
        access(140, 0, 0); check(value == 4, "complete preload status");
        for (word_index=0; word_index<16; word_index=word_index+1)
            access(word_index, 1, word_index == 0 ? 5 : 0);
        access(139, 1, 2); check(cycles == 2, "cached trigger normal ACK");
        access(132, 0, 0); cached_early_cycles=cycles;
        check(cycles == 5 && value == -40, "cached early result waits and sign extends");
        access(135, 0, 0); check(cycles == 2 && value == -25, "cached bank 3 result");
        access(139, 1, 7);
        access(135, 0, 0); check(cycles == 5 && value == 75, "cached group change cannot return stale result");
        access(139, 1, 0); access(137, 1, 0);
        check(cycles == 2, "busy preload-index write ACK");
        access(140, 0, 0); check(value == 6, "busy preload-index write ignored");
        access(137, 0, 0); check(value == 128, "busy index write did not reset pointer");
        access(132, 0, 0); check(value == -80, "busy write preserves cached arithmetic");
        access(139, 1, 8); access(140, 0, 0);
        check(value == 12, "invalid group retains weights but invalidates results");
        // Rejected triggers must never acknowledge a stale result.
        @(negedge clk); request=1; address=32'h02000610; strobes=0;
        repeat (6) begin
            @(posedge clk); check(!soc.mem_ready, "rejected cached result remains unacknowledged"); #1;
        end
        request=0;
        access(139, 1, 1); access(132, 0, 0);
        check(cycles == 5 && value == -60, "valid cached trigger recovers after rejection");
        // Reset aborts a cached computation and invalidates the preload.
        access(139, 1, 1);
        @(negedge clk); resetn=0; request=0;
        @(negedge clk); resetn=1;
        access(140, 0, 0); check(value == 0, "reset clears cache/batch validity");
        access(139, 1, 0); access(140, 0, 0); check(value == 8, "reset cache requires preload again");
        $display("[PASS] actual SoC PW decoder/handshake, early reads, legacy timing, busy ACKs, reset");
        $display("[MEASURE] ordinary access: 2 CPU sample edges; early result: %0d; extra stall: %0d cycles", early_cycles, early_cycles-2);
        $display("[MEASURE] cached early result: %0d sample edges; extra stall: %0d cycles", cached_early_cycles, cached_early_cycles-2);
        $display("[PASS] cache decode/preload/group, busy ACKs, stale-read stall, reset/rejection recovery");
        $display("ALL PW BUS TESTS PASSED: %0d assertions", checks);
        $finish;
    end
    initial begin #100000; $fatal(1, "bus test timeout"); end
endmodule

`default_nettype wire
