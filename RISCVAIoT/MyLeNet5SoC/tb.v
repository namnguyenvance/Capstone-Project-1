`timescale 1ns / 1ps

module tb;
    reg clk;
    reg resetn;
    wire [7:0] leds;
    wire ser_tx;
    reg ser_rx;

    // Clock generator (50MHz -> 20ns period)
    always #10 clk = ~clk;

    // Instantiate SoC
    my_soc uut (
        .clk(clk),
        .resetn(resetn),
        .leds(leds),
        .ser_tx(ser_tx),
        .ser_rx(ser_rx)
    );

    // UART Receiver logic
    reg [7:0] buffer;
    always begin
        @(negedge ser_tx); // Wait for start bit (falling edge)
        #170;              // Move to the middle of the start bit (8.5 clock cycles = 170ns, lands on negedge clk)
        
        repeat (8) begin
            #320;          // Move to the middle of the next data bit (16 clock cycles = 320ns)
            buffer = {ser_tx, buffer[7:1]};
        end
        
        #320;              // Wait for stop bit
        $write("%c", buffer);
        $fflush();
    end

    // Monitor LED changes
    always @(leds) begin
        // Print LED changes on a new line to not mess up UART outputs
        $display("\n[%0t ns] LED change: %b", $time, leds);
    end

    reg [7:0] tmp_mem [0:262143];
    integer i;

    initial begin
        clk = 0;
        resetn = 0;
        ser_rx = 1;

        // Load firmware program into a temporary byte memory
        $readmemh("firmware.hex", tmp_mem);

        // Pack bytes into 32-bit words for uut.ram (65536 words = 256KB)
        for (i = 0; i < 65536; i = i + 1) begin
            uut.ram[i][ 7: 0] = tmp_mem[4*i];
            uut.ram[i][15: 8] = tmp_mem[4*i + 1];
            uut.ram[i][23:16] = tmp_mem[4*i + 2];
            uut.ram[i][31:24] = tmp_mem[4*i + 3];
        end

        // Hold reset for 100ns
        #100;
        resetn = 1;

        // Run simulation for 2,000,000,000ns (100,000,000 clock cycles)
        #2000000000;
        $display("\n[%0t ns] Simulation finished.", $time);
        $finish;
    end

endmodule
