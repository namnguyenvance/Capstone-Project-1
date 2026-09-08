module al_accel_pool_tb;

    // Testbench Signals
    reg signed [7:0] pool_di;      // Dữ liệu đầu vào
    reg [3:0] sel_demux;           // Tín hiệu lựa chọn cho demux
    reg [3:0] sel_mux;             // Tín hiệu lựa chọn cho mux
    reg mpbuf_ld_wrn;              // Tín hiệu load/write cho buffer
    reg enb;                       // Tín hiệu enable
    reg clk;                       // Xung clock
    reg resetn;                    // Tín hiệu reset (active low)
    reg cp_enb;
    wire signed [7:0] pool_do;     // Dữ liệu đầu ra

    // Instance of the DUT (Device Under Test)
    al_accel_pool dut (
        .pool_di(pool_di),
        .sel_demux(sel_demux),
        .sel_mux(sel_mux),
        .mpbuf_ld_wrn(mpbuf_ld_wrn),
        .cp_enb(cp_enb),
        .enb(enb),
        .clk(clk),
        .resetn(resetn),
        .pool_do(pool_do)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // Xung clock với chu kỳ 10 đơn vị thời gian
    end

    // Test sequence
    initial begin
        // Reset the DUT
        resetn = 0;
        mpbuf_ld_wrn = 1; // Cho phép ghi vào buffer
        enb = 0;
        sel_demux = 0;
        sel_mux = 4'b0000;
        pool_di = 8'b00000000; // Dữ liệu đầu vào ban đầu
        #10;

        // Bỏ reset và bật enable
        resetn = 1;
        enb = 1;
        cp_enb = 1;
        #5;
        // Test: sel_demux từ 0 -> 12
        $display("Testing sel_demux from 0 -> 12");
        // Sel 0
        pool_di = $random;  #10;
        $display("sel_demux=%0d, pool_di=%0d",
                     sel_demux, pool_di);
        pool_di = $random; #10;
         $display("sel_demux=%0d, pool_di=%0d",
                     sel_demux, pool_di);

        // Sel 1
        pool_di = $random; #10; sel_demux = 1;
        $display("sel_demux=%0d, pool_di=%0d",
                     sel_demux, pool_di);
        pool_di = $random; #10;
        $display("sel_demux=%0d, pool_di=%0d",
                     sel_demux, pool_di);

        // Sel 2
        pool_di = $random; #10; sel_demux = 2;
        $display("sel_demux=%0d, pool_di=%0d",
                     sel_demux, pool_di);
        pool_di = $random; #10;
        $display("sel_demux=%0d, pool_di=%0d",
                     sel_demux, pool_di);
        
        // Sel 3
        pool_di = $random; #10; sel_demux = 3;
        $display("sel_demux=%0d, pool_di=%0d",
                     sel_demux, pool_di);
        pool_di = $random; #10;
        $display("sel_demux=%0d, pool_di=%0d",
                     sel_demux, pool_di);
        
        // Sel 4
        pool_di = $random; #10; sel_demux = 4;
        $display("sel_demux=%0d, pool_di=%0d",
                     sel_demux, pool_di);
        pool_di = $random; #10;
        $display("sel_demux=%0d, pool_di=%0d",
                     sel_demux, pool_di);

        // Sel 5
        pool_di = $random; #10; sel_demux = 5;
        $display("sel_demux=%0d, pool_di=%0d",
                     sel_demux, pool_di);
        pool_di = $random; #10;
        $display("sel_demux=%0d, pool_di=%0d",
                     sel_demux, pool_di);
        
        // Sel 6
        pool_di = $random; #10; sel_demux = 6;
        $display("sel_demux=%0d, pool_di=%0d",
                     sel_demux, pool_di);
        pool_di = $random; #10;
        $display("sel_demux=%0d, pool_di=%0d",
                     sel_demux, pool_di);
        
        // Sel 7
        pool_di = $random; #10; sel_demux = 7;
        $display("sel_demux=%0d, pool_di=%0d",
                     sel_demux, pool_di);
        pool_di = $random; #10;
        $display("sel_demux=%0d, pool_di=%0d",
                     sel_demux, pool_di);

        // Sel 8
        pool_di = $random; #10; sel_demux = 8;
        $display("sel_demux=%0d, pool_di=%0d",
                     sel_demux, pool_di);
        pool_di = $random; #10;
        $display("sel_demux=%0d, pool_di=%0d",
                     sel_demux, pool_di);

        // Sel 9
        pool_di = $random; #10; sel_demux = 9;
        $display("sel_demux=%0d, pool_di=%0d",
                     sel_demux, pool_di);
        pool_di = $random; #10;
        $display("sel_demux=%0d, pool_di=%0d",
                     sel_demux, pool_di);

        // Sel 10
        pool_di = $random; #10; sel_demux = 10;
        $display("sel_demux=%0d, pool_di=%0d",
                     sel_demux, pool_di);
        pool_di = $random; #10;
        $display("sel_demux=%0d, pool_di=%0d",
                     sel_demux, pool_di);

        // Sel 11
        pool_di = $random; #10; sel_demux = 11;
        $display("sel_demux=%0d, pool_di=%0d",
                     sel_demux, pool_di);
        pool_di = $random; #10;
        $display("sel_demux=%0d, pool_di=%0d",
                     sel_demux, pool_di);
        // Sel 12
        pool_di = $random; #10; sel_demux = 12;
        $display("sel_demux=%0d, pool_di=%0d",
                     sel_demux, pool_di);
        pool_di = $random; #10;
        $display("sel_demux=%0d, pool_di=%0d",
                     sel_demux, pool_di); 





        repeat(13) begin
            $strobe("sel_mux=%0d, pool_do=%0d",
                     sel_mux, pool_do);
            #10;
            sel_mux++;
            
        end

        $finish; 
    end

    initial begin
        $dumpfile("accel_vcd/al_accel_pool_tb.vcd");
        $dumpvars(0, al_accel_pool_tb);
    end

endmodule
