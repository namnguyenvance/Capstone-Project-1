`default_nettype none

module my_soc (
    input wire clk,
    input wire resetn,
    output reg [7:0] leds,
    output wire ser_tx,
    input wire ser_rx
);

    // Memory interface signals from CPU
    wire mem_valid;
    wire mem_instr;
    wire mem_ready;
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [3:0] mem_wstrb;
    wire [31:0] mem_rdata;

    // SRAM Memory (65536 words = 256KB RAM)
    localparam RAM_SIZE = 65536;
    reg [31:0] ram [0:RAM_SIZE-1];

    // Decode memory access
    wire ram_sel      = mem_valid && (mem_addr < (RAM_SIZE * 4));
    wire led_sel      = mem_valid && (mem_addr == 32'h03000000);
    wire uart_div_sel = mem_valid && (mem_addr == 32'h02000004);
    wire uart_dat_sel = mem_valid && (mem_addr == 32'h02000008);
    // Accelerator Selection (Address range: 0x02000010 - 0x0200001C)
    wire accel_sel    = mem_valid && (mem_addr[31:4] == 28'h0200001);
    // 2D Convolution Accelerator Selection (Address range: 0x02000100 - 0x020001FF)
    wire conv_accel_sel = mem_valid && (mem_addr[31:8] == 24'h020001);
    // Quantization Accelerator Selection (Address range: 0x02000200 - 0x020002FF)
    wire quant_accel_sel = mem_valid && (mem_addr[31:8] == 24'h020002);

    // RAM read/write logic
    reg [31:0] ram_rdata;
    reg ram_ready;

    always @(posedge clk) begin
        if (!resetn) begin
            ram_ready <= 1'b0;
        end else begin
            ram_ready <= 1'b0;
            if (ram_sel && !mem_ready) begin
                ram_ready <= 1'b1;
                if (mem_wstrb[0]) ram[mem_addr[17:2]][7:0]   <= mem_wdata[7:0];
                if (mem_wstrb[1]) ram[mem_addr[17:2]][15:8]  <= mem_wdata[15:8];
                if (mem_wstrb[2]) ram[mem_addr[17:2]][23:16] <= mem_wdata[23:16];
                if (mem_wstrb[3]) ram[mem_addr[17:2]][31:24] <= mem_wdata[31:24];
                ram_rdata <= ram[mem_addr[17:2]];
            end
        end
    end

    // LED Register Logic
    reg led_ready;
    always @(posedge clk) begin
        if (!resetn) begin
            leds <= 8'h00;
            led_ready <= 1'b0;
        end else begin
            led_ready <= 1'b0;
            if (led_sel && !mem_ready) begin
                led_ready <= 1'b1;
                if (mem_wstrb[0]) leds <= mem_wdata[7:0];
            end
        end
    end

    // UART Control Signals
    wire [31:0] uart_div_do;
    wire [31:0] uart_dat_do;
    wire reg_dat_wait;

    wire [3:0] reg_div_we = uart_div_sel ? mem_wstrb : 4'b0000;
    wire reg_dat_we       = uart_dat_sel && (mem_wstrb != 4'b0000);
    wire reg_dat_re       = uart_dat_sel && (mem_wstrb == 4'b0000);

    // Instantiate simpleuart
    simpleuart #(
        .DEFAULT_DIV(15)
    ) uart (
        .clk(clk),
        .resetn(resetn),
        .ser_tx(ser_tx),
        .ser_rx(ser_rx),
        .reg_div_we(reg_div_we),
        .reg_div_di(mem_wdata),
        .reg_div_do(uart_div_do),
        .reg_dat_we(reg_dat_we),
        .reg_dat_re(reg_dat_re),
        .reg_dat_di(mem_wdata),
        .reg_dat_do(uart_dat_do),
        .reg_dat_wait(reg_dat_wait)
    );

    // Accelerator Control Signals
    wire [31:0] accel_rdata;
    wire accel_write_en = accel_sel && (mem_wstrb != 4'b0000) && !mem_ready;
    reg accel_ready;

    always @(posedge clk) begin
        if (!resetn) begin
            accel_ready <= 1'b0;
        end else begin
            accel_ready <= accel_sel && !mem_ready;
        end
    end

    // Instantiate our Accelerator
    my_accel accel (
        .clk(clk),
        .resetn(resetn),
        .addr(mem_addr[3:2]), // Address offset: 10 -> 00, 14 -> 01, 18 -> 10
        .write_en(accel_write_en),
        .wdata(mem_wdata),
        .rdata(accel_rdata)
    );

    // 2D Convolution Accelerator Control Signals
    wire [31:0] conv_accel_rdata;
    wire conv_accel_write_en = conv_accel_sel && (mem_wstrb != 4'b0000) && !mem_ready;
    reg conv_accel_ready;

    always @(posedge clk) begin
        if (!resetn) begin
            conv_accel_ready <= 1'b0;
        end else begin
            conv_accel_ready <= conv_accel_sel && !mem_ready;
        end
    end

    // Instantiate 2D Convolution Accelerator
    my_conv_accel conv_accel (
        .clk(clk),
        .resetn(resetn),
        .addr(mem_addr[7:2]), // 6-bit register offset (0x02000100 to 0x020001FF)
        .write_en(conv_accel_write_en),
        .wdata(mem_wdata),
        .rdata(conv_accel_rdata)
    );

    // Hardware Quantization Accelerator Control Signals
    wire [31:0] quant_accel_rdata;
    wire quant_accel_write_en = quant_accel_sel && (mem_wstrb != 4'b0000) && !mem_ready;
    reg quant_accel_ready;

    always @(posedge clk) begin
        if (!resetn) begin
            quant_accel_ready <= 1'b0;
        end else begin
            quant_accel_ready <= quant_accel_sel && !mem_ready;
        end
    end

    // Instantiate Hardware Quantization Accelerator
    my_quant_accel quant_accel (
        .clk(clk),
        .resetn(resetn),
        .addr(mem_addr[5:2]), // 4-bit register offset
        .write_en(quant_accel_write_en),
        .wdata(mem_wdata),
        .rdata(quant_accel_rdata)
    );

    // Bus response mux
    assign mem_ready = ram_ready || led_ready || uart_div_sel || (uart_dat_sel && !reg_dat_wait) || accel_ready || conv_accel_ready || quant_accel_ready;
    assign mem_rdata = ram_ready        ? ram_rdata   : 
                       uart_div_sel     ? uart_div_do : 
                       uart_dat_sel     ? uart_dat_do : 
                       accel_ready      ? accel_rdata :
                       conv_accel_ready ? conv_accel_rdata :
                       quant_accel_ready? quant_accel_rdata :
                       32'h00000000;

    // Instantiate CPU Core
    picorv32 #(
        .PROGADDR_RESET(32'h00000000),
        .STACKADDR(32'h00040000),
        .BARREL_SHIFTER(1),
        .COMPRESSED_ISA(0),
        .ENABLE_COUNTERS(1),
        .ENABLE_MUL(1),
        .ENABLE_DIV(0),
        .ENABLE_IRQ(0)
    ) cpu (
        .clk         (clk),
        .resetn      (resetn),
        .mem_valid   (mem_valid),
        .mem_instr   (mem_instr),
        .mem_ready   (mem_ready),
        .mem_addr    (mem_addr),
        .mem_wdata   (mem_wdata),
        .mem_wstrb   (mem_wstrb),
        .mem_rdata   (mem_rdata)
    );

endmodule
