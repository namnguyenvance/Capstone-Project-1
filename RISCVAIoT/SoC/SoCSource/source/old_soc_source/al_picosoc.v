`ifndef PICORV32_REGS
`ifdef PICORV32_V
//`error "picosoc.v must be read before picorv32.v!"
`endif

`define PICORV32_REGS picosoc_regs
`endif

// `ifndef PICOSOC_MEM
// `define PICOSOC_MEM picosoc_dmem
// `endif

`define PICOSOC_V

module al_picosoc (
	input clk,
	input resetn,

	output        iomem_valid,
	input         iomem_ready,
	output [ 3:0] iomem_wstrb,
	output [31:0] iomem_addr,
	output [31:0] iomem_wdata,
	input  [31:0] iomem_rdata,

	input         ins_mem_wenb,
    input  [31:0] ins_mem_waddr,
    input  [31:0] ins_mem_wdata,

	input  irq_5,
	input  irq_6,
	input  irq_7,

	output ser_tx,
	input  ser_rx
);
	/* Parameter Defination */
	parameter [0:0] BARREL_SHIFTER = 1;
	parameter [0:0] ENABLE_MUL = 1;
	parameter [0:0] ENABLE_DIV = 1;
	parameter [0:0] ENABLE_FAST_MUL = 0;
	parameter [0:0] ENABLE_COMPRESSED = 1;
	parameter [0:0] ENABLE_COUNTERS = 1;
	parameter [0:0] ENABLE_IRQ_QREGS = 0;

	// parameter integer DMEM_SIZE = 4096;
	// parameter integer DMEM_SIZE = 2048;
	parameter [63:0] DMEM_SIZE = 16384;
	parameter [63:0] IMEM_SIZE = 16384;

	parameter [31:0] STACKADDR 		= 4*DMEM_SIZE; 	  // end of memory
	parameter [31:0] PROGADDR_RESET = 32'h 0010_0000; // 1 MB into flash
	parameter [31:0] PROGADDR_IRQ 	= 32'h 0000_0000;

	parameter integer DMEM_DELAY = 1;
	parameter integer IMEM_DELAY = 1; 
	integer i;

	/* Interrupt Declearation and Assignment */
	reg [31:0] irq;
	wire irq_stall = 0;
	wire irq_uart = 0;

	always @* begin
		irq = 0;
		irq[3] = irq_stall;
		irq[4] = irq_uart;
		irq[5] = irq_5;
		irq[6] = irq_6;
		irq[7] = irq_7;
	end

	/* Signal Declearation */
	wire mem_valid;
	wire mem_instr;
	wire mem_ready;
	wire [31:0] mem_addr;
	wire [31:0] mem_wdata;
	wire  [3:0] mem_wstrb;
	wire [31:0] mem_rdata;

	// assign iomem_valid = mem_valid && (mem_addr[31:24] > 8'h 01);
	assign iomem_valid 	= mem_valid && (mem_addr[31:24] > 8'h 02);
	assign iomem_wstrb 	= mem_wstrb;
	assign iomem_addr 	= mem_addr;
	assign iomem_wdata 	= mem_wdata;

	wire        simpleuart_reg_div_sel = mem_valid && (mem_addr == 32'h 0200_0004);
	wire [31:0] simpleuart_reg_div_do;

	wire        simpleuart_reg_dat_sel = mem_valid && (mem_addr == 32'h 0200_0008);
	wire [31:0] simpleuart_reg_dat_do;
	wire        simpleuart_reg_dat_wait;

	reg [IMEM_DELAY - 1:0] imem_ready;
	wire [31:0] imem_rdata;

	reg [DMEM_DELAY - 1:0] cpu_ram_ready, al_accel_ram_read_ready, al_accel_ram_write_ready;
	wire [31:0] ram_rdata;

	wire 			cpu_renb , cpu_wenb;
	wire [17:0] 	cpu_raddr, cpu_waddr;

	assign cpu_renb = mem_valid &&  mem_addr < 4*DMEM_SIZE;
	assign cpu_wenb = mem_valid && !mem_ready && mem_addr < 4*DMEM_SIZE && mem_wstrb != 4'b 0;
	assign cpu_raddr = mem_addr[19:2];
	assign cpu_waddr = mem_addr[19:2];

	wire 	is_cpu_get_ram;
	assign  is_cpu_get_ram = cpu_renb | cpu_wenb;

	wire al_accel_renb, al_accel_wenb;

	wire	is_al_accel_get_ram;
	assign	is_al_accel_get_ram = al_accel_renb | al_accel_wenb;

	wire al_accel_cfgreg_wenb;
	wire al_accel_flow_enb;
	wire [4:0] al_accel_cfgreg_sel;

	wire al_accel_cfg_mem_valid;
	assign al_accel_cfg_mem_valid = mem_valid 
	                             && (mem_addr >= 32'h 0200_1000) && (mem_addr <= 32'h 0200_1050)
								 && mem_wstrb != 4'b 0;

	reg al_accel_ctrl_ready;
	wire [31:0] al_accel_ctrl_rdata;

	wire  [3:0] al_accel_wstrb;
	wire [31:0] al_accel_wdata;
	wire [31:0] al_accel_waddr;
	wire [31:0] al_accel_raddr;

	wire al_accel_cal_fin;

	assign mem_ready = (iomem_valid && iomem_ready) 
					|| imem_ready[IMEM_DELAY - 1]    & imem_ready[0]
					|| cpu_ram_ready[DMEM_DELAY - 1] & cpu_ram_ready[0] 
					|| al_accel_ctrl_ready
					|| simpleuart_reg_div_sel 
					|| (simpleuart_reg_dat_sel && !simpleuart_reg_dat_wait);

	assign mem_rdata = (iomem_valid && iomem_ready) ? iomem_rdata : 
						imem_ready[IMEM_DELAY - 1]    & imem_ready[0] 	 ? imem_rdata :
						cpu_ram_ready[DMEM_DELAY - 1] & cpu_ram_ready[0] ? ram_rdata  : 
						al_accel_ctrl_ready 	? al_accel_ctrl_rdata 	: 
						simpleuart_reg_div_sel 	? simpleuart_reg_div_do :
						simpleuart_reg_dat_sel 	? simpleuart_reg_dat_do :
						32'h 0000_0000;
	
	/* Module Instantiate */
	picorv32 #(
		.STACKADDR(STACKADDR),
		.PROGADDR_RESET(PROGADDR_RESET),
		.PROGADDR_IRQ(PROGADDR_IRQ),
		.BARREL_SHIFTER(BARREL_SHIFTER),
		.COMPRESSED_ISA(ENABLE_COMPRESSED),
		.ENABLE_COUNTERS(ENABLE_COUNTERS),
		.ENABLE_MUL(ENABLE_MUL),
		.ENABLE_DIV(ENABLE_DIV),
		.ENABLE_FAST_MUL(ENABLE_FAST_MUL),
		.ENABLE_IRQ(1),
		.ENABLE_IRQ_QREGS(ENABLE_IRQ_QREGS)
	) cpu (
		.clk         (clk        ),
		.resetn      (resetn     ),
		.mem_valid   (mem_valid  ),
		.mem_instr   (mem_instr  ),
		.mem_ready   (mem_ready  ),
		.mem_addr    (mem_addr   ),
		.mem_wdata   (mem_wdata  ),
		.mem_wstrb   (mem_wstrb  ),
		.mem_rdata   (mem_rdata  ),
		.irq         (irq        )
	);

	always @(posedge clk) begin
		imem_ready[0] <= mem_valid && !mem_ready && mem_addr >= 4*DMEM_SIZE && mem_addr < 32'h 0200_0000;
		if (IMEM_DELAY > 1) begin
			for (i = 1; i < IMEM_DELAY; i = i + 1) begin
				imem_ready[i] <= imem_ready[i - 1];
			end
		end
	end

	picosoc_imem #(
		.IMEM_SIZE(IMEM_SIZE)
	) imem (
		.renb 	(mem_valid && mem_addr >= 4*DMEM_SIZE && mem_addr < 32'h 0200_0000),
		.raddr 	(mem_addr[19:2]),
		.rdata 	(imem_rdata),

		.wenb	(ins_mem_wenb),
		.waddr	(ins_mem_waddr[19:2]),
		.wdata	(ins_mem_wdata),

		.clk	(clk)
	);	

	simpleuart simpleuart (
		.clk         (clk         ),
		.resetn      (resetn      ),

		.ser_tx      (ser_tx      ),
		.ser_rx      (ser_rx      ),

		.reg_div_we  (simpleuart_reg_div_sel ? mem_wstrb : 4'b 0000),
		.reg_div_di  (mem_wdata),
		.reg_div_do  (simpleuart_reg_div_do),

		.reg_dat_we  (simpleuart_reg_dat_sel ? mem_wstrb[0] : 1'b 0),
		.reg_dat_re  (simpleuart_reg_dat_sel && !mem_wstrb),
		.reg_dat_di  (mem_wdata),
		.reg_dat_do  (simpleuart_reg_dat_do),
		.reg_dat_wait(simpleuart_reg_dat_wait)
	);

	always @(posedge clk) begin
		cpu_ram_ready[0] <= mem_valid && !mem_ready && mem_addr < 4*DMEM_SIZE;
		for (i = 1; i < DMEM_DELAY; i = i + 1) 
			cpu_ram_ready[i] <= cpu_ram_ready[i - 1];

		if (!al_accel_renb) begin
			for (i = 0; i < DMEM_DELAY; i = i + 1) 
				al_accel_ram_read_ready[i] <= 0;
		end else begin
			al_accel_ram_read_ready[0] <= al_accel_raddr < 4*DMEM_SIZE && al_accel_renb;

			if (DMEM_DELAY > 1) begin
				for (i = 1; i < DMEM_DELAY; i = i + 1)
					al_accel_ram_read_ready[i] 	<= al_accel_ram_read_ready[i - 1];
			end
		end

		if (!al_accel_wenb) begin
			for (i = 0; i < DMEM_DELAY; i = i + 1) 
				al_accel_ram_write_ready[i] <= 0;
		end else begin
			al_accel_ram_write_ready[0] <= al_accel_waddr < 4*DMEM_SIZE && al_accel_wenb && al_accel_wstrb != 4'd 0;

			if (DMEM_DELAY > 1) begin
				for (i = 1; i < DMEM_DELAY; i = i + 1)
					al_accel_ram_write_ready[i] 	<= al_accel_ram_write_ready[i - 1];
			end
		end
	end

	picosoc_dmem #(
		.DMEM_SIZE(DMEM_SIZE)
	) dmem (
		.renb 	(is_cpu_get_ram ? cpu_renb  : is_al_accel_get_ram ? al_accel_renb        :  1'd 0),
		.raddr 	(is_cpu_get_ram ? cpu_raddr : is_al_accel_get_ram ? al_accel_raddr[19:2] : 18'd 0),
		.rdata	(ram_rdata),

		.wenb	(is_cpu_get_ram ? cpu_wenb  : is_al_accel_get_ram ? al_accel_wenb		 :  1'd 0),
		.wstrb  (is_cpu_get_ram ? mem_wstrb : is_al_accel_get_ram ? al_accel_wstrb	     :  4'd 0),
		.waddr	(is_cpu_get_ram ? cpu_waddr : is_al_accel_get_ram ? al_accel_waddr[19:2] : 18'd 0),
		.wdata 	(is_cpu_get_ram ? mem_wdata : is_al_accel_get_ram ? al_accel_wdata		 : 32'd 0),

		.clk(clk)
	);

	always @(posedge clk) begin
		al_accel_ctrl_ready <= mem_valid && !mem_ready && (mem_addr >= 32'h 0200_1000) && (mem_addr <= 32'h 0200_1050);
	end

	al_accel_pico_ctrl accel_controller (
		.al_accel_mem_valid		(al_accel_cfg_mem_valid),
		.al_accel_ctrl_waddr	(mem_addr),
		.al_accel_ctrl_wdata	(mem_wdata),

		.al_accel_ctrl_raddr	(mem_addr),
		.al_accel_ctrl_rdata	(al_accel_ctrl_rdata),

		.al_accel_cal_fin		(al_accel_cal_fin),

		.al_accel_cfgreg_sel	(al_accel_cfgreg_sel),
		.al_accel_cfgreg_wenb	(al_accel_cfgreg_wenb),

		.al_accel_flow_enb		(al_accel_flow_enb),
		.al_accel_flow_resetn	(al_accel_flow_resetn),

		.clk	(clk),
		.resetn	(resetn)
	);

	al_accel accelerator (
        .al_accel_cfgreg_di     (mem_wdata),
        .al_accel_cfgreg_sel    (al_accel_cfgreg_sel),
        .al_accel_cfgreg_wenb   (al_accel_cfgreg_wenb),

        .al_accel_rdata         (ram_rdata),
        .al_accel_raddr         (al_accel_raddr),
        .al_accel_renb          (al_accel_renb),
        .al_accel_mem_read_ready     (al_accel_ram_read_ready[DMEM_DELAY - 1]),
		.al_accel_mem_write_ready    (al_accel_ram_write_ready[DMEM_DELAY - 1]),

        .al_accel_wdata         (al_accel_wdata),
        .al_accel_waddr         (al_accel_waddr),
        .al_accel_wenb          (al_accel_wenb),
        .al_accel_wstrb         (al_accel_wstrb),

        .al_accel_flow_enb      (al_accel_flow_enb),
        .al_accel_flow_resetn   (al_accel_flow_resetn),
		.al_accel_cal_fin		(al_accel_cal_fin),

        .clk    (clk),
        .resetn (resetn)
    );
endmodule

// Implementation note:
// Replace the following two modules with wrappers for your SRAM cells.

module picosoc_regs (
	input clk, wen,
	input [5:0] waddr,
	input [5:0] raddr1,
	input [5:0] raddr2,
	input [31:0] wdata,
	output [31:0] rdata1,
	output [31:0] rdata2
);
	reg [31:0] regs [0:31];

	always @(posedge clk)
		if (wen) regs[waddr[4:0]] <= wdata;

	assign rdata1 = regs[raddr1[4:0]];
	assign rdata2 = regs[raddr2[4:0]];
endmodule


module picosoc_dmem #(
	parameter integer DMEM_SIZE = 256
) (
    input              renb,
    input       [17:0] raddr,
    output reg  [31:0] rdata,

    input              wenb,
	input       [ 3:0] wstrb,
	input       [17:0] waddr,
	input       [31:0] wdata,
	
    input clk
);
	reg [31:0] mem [0:DMEM_SIZE - 1];

	always @(posedge clk) begin
        if (renb)
            rdata <= mem[raddr];
        
        if (wenb) begin
            if (wstrb[0]) mem[waddr][ 7: 0] <= wdata[ 7: 0];
            if (wstrb[1]) mem[waddr][15: 8] <= wdata[15: 8];
            if (wstrb[2]) mem[waddr][23:16] <= wdata[23:16];
            if (wstrb[3]) mem[waddr][31:24] <= wdata[31:24];
        end
	end
endmodule

module picosoc_imem #(
	parameter [63:0] IMEM_SIZE = 32768
) (
    input              renb,
    input       [17:0] raddr,
    output reg  [31:0] rdata,
	input              wenb,
    input       [17:0] waddr,
    input	    [31:0] wdata,

    input clk
);
	reg [31:0]   memory [0:IMEM_SIZE - 1];

	always @(posedge clk) begin
        if (renb) rdata <= memory[raddr];
		if (wenb) memory[waddr] <= wdata;
	end

endmodule

module pico_switch_bus(

);

endmodule
