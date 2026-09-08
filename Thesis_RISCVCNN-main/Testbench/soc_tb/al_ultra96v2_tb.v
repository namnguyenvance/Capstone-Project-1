`timescale 1 ns / 1 ps

`define TIME_TO_REPEAT  500
module al_ultra96v2_wrapper ();
    reg clk;
    reg enb;
    always #5 clk = ~clk;   // 100 MHz clock -> period 10 ns

    // UART 115200 baud
    localparam integer SER_FULL_PERIOD = 868;   // số chu kỳ clock cho 1 bit
    localparam integer SER_HALF_PERIOD = 434;   // nửa bit
    event ser_sample;

    initial begin
        clk = 0;
        enb = 0;
        #50;
        enb = 1;
        // $dumpfile("accel_vcd/al_ultra96v2_tb.vcd");
        // $dumpvars(0, al_ultra96v2_wrapper);

        repeat (`TIME_TO_REPEAT) begin
            repeat (50000) @(posedge clk);
        end
        $display("\nTotal: %d x 50 000 Clock Cycles", `TIME_TO_REPEAT);
        $finish;
    end        

    wire [1:0] leds;
    
    reg ser_rx;
    wire ser_tx;

    reg ps_read_fin;
    wire [31:0] ps_data;
    wire ps_read_rdy;

    integer index;

    fs_zcu106 uut (
        .clk      (clk),
        .leds     (leds),
        .ser_rx   (ser_rx),
        .ser_tx   (ser_tx),
        .enb      (enb)
    );

    /*****************/
    /* Write UART Part */
    reg [7:0] buffer;

    always begin
        @(negedge ser_tx);  // phát hiện start bit

        repeat (SER_HALF_PERIOD) @(posedge clk);
        -> ser_sample; // sample start bit

        repeat (8) begin
            repeat (SER_FULL_PERIOD) @(posedge clk);
            buffer = {ser_tx, buffer[7:1]};
            -> ser_sample; // sample data bit
        end

        repeat (SER_FULL_PERIOD) @(posedge clk);
        -> ser_sample; // sample stop bit

        $write("%c", buffer);
        $fflush();
    end

    // ser_rx generating...
    localparam STR_LEN = 8;
    reg [8*STR_LEN - 1:0] str_buf;

    initial begin
        str_buf = "92345679";
        ser_rx  = 1'b1; // idle = 1
    end 

endmodule
