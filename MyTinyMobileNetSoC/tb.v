`timescale 1ns / 1ps

module tb;

    reg clk = 0;
    reg resetn = 0;
    wire ser_tx;
    wire [7:0] leds;

    // Clock generator (50MHz -> 20ns period)
    always #10 clk = ~clk;

    my_soc uut (
        .clk(clk),
        .resetn(resetn),
        .leds(leds),
        .ser_tx(ser_tx),
        .ser_rx(1'b1)
    );

    reg [7:0] tmp_mem [0:262143];
    integer i;

    // Load firmware from hex file
    initial begin
        // Load firmware program into a temporary byte memory
        $readmemh("firmware.hex", tmp_mem);

        // Pack bytes into 32-bit words for uut.ram (65536 words = 256KB)
        for (i = 0; i < 65536; i = i + 1) begin
            uut.ram[i][ 7: 0] = tmp_mem[4*i];
            uut.ram[i][15: 8] = tmp_mem[4*i + 1];
            uut.ram[i][23:16] = tmp_mem[4*i + 2];
            uut.ram[i][31:24] = tmp_mem[4*i + 3];
        end
    end

    // Reset sequence
    initial begin
        resetn = 0;
        #100;
        resetn = 1;
    end

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

    // Timeout watchdog (TinyMobileNet is more complex, give more time)
    initial begin
        #500000000000; // 500ms @ 100MHz = long enough for inference
        $fatal(1, "TEST FAILURE: inference timeout");
    end

    // Monitor LEDs for completion
    always @(posedge clk) begin
        if (resetn && uut.cpu.trap === 1'b1)
            $fatal(1, "TEST FAILURE: CPU trap");
        if (leds == 8'hEE)
            $fatal(1, "TEST FAILURE: firmware configuration or reference label");
        if (leds == 8'hAA) begin
            #10000;
            $display("\n\n*** INFERENCE COMPLETED: All predictions correct (LEDs = 0xAA) ***");
            $finish;
        end
        if (leds == 8'hFF) begin
            #10000;
            $display("\n\n*** INFERENCE COMPLETED: Incorrect predictions; not an implementation verdict (LEDs = 0xFF) ***");
            $finish;
        end
    end

endmodule
