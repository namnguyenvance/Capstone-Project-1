module ultra96v2 (
	output ser_tx,
	input ser_rx,
	output [1:0] leds,
	input clk,
	input enb
);
	reg [6:0] reset_cnt = 0;
	wire resetn = &reset_cnt;

	always @(posedge clk) begin
		if (!enb)
			reset_cnt <= 0;
		else 
			reset_cnt <= reset_cnt + !resetn;
	end

	reg [31:0] gpio;
	assign leds = gpio;
	
	wire        iomem_valid;
	reg         iomem_ready;
	wire [3:0]  iomem_wstrb;
	wire [31:0] iomem_addr;
	wire [31:0] iomem_wdata;
	reg  [31:0] iomem_rdata;

	always @(posedge clk) begin
        if (!resetn) begin
            gpio        <= 32'h0;
            iomem_ready <= 1'b0;
            iomem_rdata <= 32'h0;
        end else begin
            iomem_ready <= 1'b0;  
            if (iomem_valid && iomem_addr == 32'h0300_0000 && !iomem_ready) begin
                iomem_ready <= 1'b1;
                iomem_rdata <= gpio;
                if (iomem_wstrb[0]) gpio[ 7: 0] <= iomem_wdata[ 7: 0];
                if (iomem_wstrb[1]) gpio[15: 8] <= iomem_wdata[15: 8];
                if (iomem_wstrb[2]) gpio[23:16] <= iomem_wdata[23:16];
                if (iomem_wstrb[3]) gpio[31:24] <= iomem_wdata[31:24];
            end
        end
    end

	picosoc soc (
		.clk          (clk         ),
		.resetn       (resetn      ),

		.ser_tx       (ser_tx      ),
		.ser_rx       (ser_rx      ),

		.irq_5        (1'b0        ),
		.irq_6        (1'b0        ),
		.irq_7        (1'b0        ),

		.iomem_valid  (iomem_valid ),
		.iomem_ready  (iomem_ready ),
		.iomem_wstrb  (iomem_wstrb ),
		.iomem_addr   (iomem_addr  ),
		.iomem_wdata  (iomem_wdata ),
		.iomem_rdata  (iomem_rdata ),

		.ins_mem_wenb 	(1'b0),
		.ins_mem_waddr	(32'b0),
		.ins_mem_wdata	(32'b0)
	);

endmodule
