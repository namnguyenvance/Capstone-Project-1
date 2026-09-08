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

module fs_picosoc (
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
	parameter [63:0] DMEM_SIZE = 65536;
	parameter [63:0] IMEM_SIZE = 262144;

	parameter [31:0] STACKADDR 		= 4*DMEM_SIZE; 	  // end of memory
	parameter [31:0] PROGADDR_RESET = 32'h 0010_0000; // 1 MB into flash
	parameter [31:0] PROGADDR_IRQ 	= 32'h 0000_0000;

	// parameter integer DMEM_DELAY = 1;
	// parameter integer IMEM_DELAY = 1; 
	// integer i;

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

	reg al_accel_ctrl_ready;
	wire [31:0] al_accel_ctrl_rdata;

	wire al_accel_renb, al_accel_wenb;
	wire [ 3:0] al_accel_wstrb;
	wire [31:0] al_accel_wdata;
	wire [31:0] al_accel_waddr;
	wire [31:0] al_accel_raddr;

	// IO Memory

	// assign iomem_valid 	= mem_valid && (mem_addr[31:24] > 8'h 02);
	// assign iomem_wstrb 	= mem_wstrb;
	// assign iomem_addr 	= mem_addr;
	// assign iomem_wdata 	= mem_wdata;

	// wire [31:0] iomem_raddr;

	wire cpu_iomem_ready, al_accel_iomem_ready;

	wire cpu_iomem_renb, cpu_iomem_wenb;
	assign cpu_iomem_renb = mem_valid && mem_addr[31:24] > 8'h 02 && mem_wstrb == 4'b 0;
	assign cpu_iomem_wenb = mem_valid && mem_addr[31:24] > 8'h 02 && mem_wstrb != 4'b 0;


	wire al_accel_iomem_renb;
	assign al_accel_iomem_renb = al_accel_renb && al_accel_raddr[31:24] > 8'h 02;

	assign iomem_valid 	= (cpu_iomem_renb | al_accel_iomem_renb) | cpu_iomem_wenb;
	assign iomem_addr 	= (al_accel_iomem_renb) ? al_accel_raddr : mem_addr;
	assign iomem_wstrb 	= mem_wstrb;
	assign iomem_wdata 	= mem_wdata;

	assign cpu_iomem_ready = (cpu_iomem_renb | cpu_iomem_wenb) && iomem_ready;
	assign al_accel_iomem_ready = (al_accel_raddr[31:24] > 8'h 02) && iomem_ready;

	// pico_switch_read_bus iomem_switch(
	// 	.cpu_renb		(cpu_iomem_renb),
	// 	.al_accel_renb	(al_accel_iomem_renb),

	// 	.cpu_raddr		(mem_addr),
	// 	.al_accel_raddr	(al_accel_raddr),
		
	// 	.cpu_valid		(cpu_iomem_renb),
	// 	.al_accel_valid	(al_accel_iomem_renb),

	// 	.bus_raddr		(iomem_raddr), 

	// 	.clk	(clk),
	// 	.resetn	(resetn)
	// );

	// UART
	wire        simpleuart_reg_div_sel = mem_valid && (mem_addr == 32'h 0200_0004);
	wire [31:0] simpleuart_reg_div_do;

	wire        simpleuart_reg_dat_sel = mem_valid && (mem_addr == 32'h 0200_0008);
	wire [31:0] simpleuart_reg_dat_do;
	wire        simpleuart_reg_dat_wait;

	wire al_accel_cfgreg_wenb;
	wire al_accel_flow_enb;
	wire [4:0] al_accel_cfgreg_sel;

	wire al_accel_cfg_mem_valid;
	assign al_accel_cfg_mem_valid = mem_valid 
	                             && (mem_addr >= 32'h 0200_1000) && (mem_addr <= 32'h 0200_1050)
								 && mem_wstrb != 4'b 0;

	// RAM Switcher
	reg cpu_ram_read_ready, cpu_ram_write_ready;

	wire cpu_ram_ready;
	assign cpu_ram_ready = cpu_ram_read_ready | cpu_ram_write_ready;

	wire cpu_dmem_renb , cpu_dmem_wenb;
	assign cpu_dmem_renb = mem_valid && !mem_ready && mem_addr < 4*DMEM_SIZE && mem_wstrb == 4'b 0;
	assign cpu_dmem_wenb = mem_valid && !mem_ready && mem_addr < 4*DMEM_SIZE && mem_wstrb != 4'b 0;

	reg al_accel_ram_read_ready, al_accel_ram_write_ready;

	wire al_accel_dmem_renb, al_accel_dmem_wenb;
	assign al_accel_dmem_renb = al_accel_renb && al_accel_raddr < 4*DMEM_SIZE;
	assign al_accel_dmem_wenb = al_accel_wenb && al_accel_waddr < 4*DMEM_SIZE;
	
	wire [31:0] ram_rdata;

	// IMEM Switcher
	reg	cpu_imem_ready;

	wire cpu_imem_renb;
	assign cpu_imem_renb = mem_valid && !mem_ready && mem_addr >= 4*DMEM_SIZE && mem_addr < 32'h 0200_0000 && mem_wstrb == 4'b 0;
	

	reg al_accel_imem_ready;

	wire al_accel_imem_renb;
	assign al_accel_imem_renb = al_accel_renb && al_accel_raddr >= 4*DMEM_SIZE && al_accel_raddr < 32'h 0200_0000;

	wire [31:0] imem_rdata;

	// Logic Combinational
	assign mem_ready = cpu_iomem_ready 
					|| cpu_imem_ready 
					|| cpu_ram_ready
					|| al_accel_ctrl_ready
					|| simpleuart_reg_div_sel 
					|| (simpleuart_reg_dat_sel && !simpleuart_reg_dat_wait);

	assign mem_rdata =  cpu_iomem_ready ? iomem_rdata : 
						cpu_imem_ready ? imem_rdata :
						cpu_ram_ready ? ram_rdata  : 
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

	// Instruction Memory
	wire cpu_bus_imem_read_ready, al_accel_bus_imem_read_ready;
	wire 		imem_renb;
	wire [31:0] imem_raddr;

	pico_switch_read_bus imem_switch(
		.cpu_renb		(cpu_imem_renb),
		.al_accel_renb	(al_accel_imem_renb),

		.cpu_raddr		(mem_addr),
		.al_accel_raddr	(al_accel_raddr),
		
		.cpu_valid		(cpu_imem_renb),
		.al_accel_valid	(al_accel_imem_renb),

		.cpu_read_ready			(cpu_bus_imem_read_ready),
		.al_accel_read_ready	(al_accel_bus_imem_read_ready),

		.bus_renb		(imem_renb),
		.bus_raddr		(imem_raddr), 

		.clk	(clk),
		.resetn	(resetn)
	);

	always @(posedge clk) begin
		cpu_imem_ready <= cpu_imem_renb && cpu_bus_imem_read_ready;

		al_accel_imem_ready <= al_accel_imem_renb && al_accel_bus_imem_read_ready;
	end

	picosoc_imem #(
		.IMEM_SIZE(IMEM_SIZE)
	) imem (
		.renb 	(imem_renb),
		.raddr 	(imem_raddr[19:2]),
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

	// New part
	wire cpu_bus_ram_read_ready, al_accel_bus_ram_read_ready;
	wire cpu_bus_ram_write_ready, al_accel_bus_ram_write_ready;
	wire 		ram_renb;
	wire [31:0] ram_raddr;
	wire		ram_wenb;
	wire [ 3:0] ram_wstrb;
	wire [31:0] ram_waddr;
	wire [31:0] ram_wdata;

	pico_switch_read_bus ram_read_switch (
		.cpu_renb		(cpu_dmem_renb),
		.al_accel_renb	(al_accel_dmem_renb),

		.cpu_raddr		(mem_addr),
		.al_accel_raddr	(al_accel_raddr),
		
		.cpu_valid		(cpu_dmem_renb),
		.al_accel_valid	(al_accel_dmem_renb),

		.cpu_read_ready			(cpu_bus_ram_read_ready),
		.al_accel_read_ready	(al_accel_bus_ram_read_ready),

		.bus_renb		(ram_renb),
		.bus_raddr		(ram_raddr), 

		.clk	(clk),
		.resetn	(resetn)
	);

	pico_switch_write_bus ram_write_switch (
		.cpu_wenb		(cpu_dmem_wenb),
		.al_accel_wenb	(al_accel_dmem_wenb),

		.cpu_wstrb		(mem_wstrb),
		.al_accel_wstrb	(al_accel_wstrb),

		.cpu_waddr		(mem_addr),
		.al_accel_waddr	(al_accel_waddr),

		.cpu_wdata		(mem_wdata),
		.al_accel_wdata	(al_accel_wdata),

		.cpu_valid		(cpu_dmem_wenb),
		.al_accel_valid	(al_accel_dmem_wenb), 
		
		.cpu_write_ready		(cpu_bus_ram_write_ready),
		.al_accel_write_ready	(al_accel_bus_ram_write_ready),

		.bus_wenb	(ram_wenb),
		.bus_wstrb	(ram_wstrb),
		.bus_waddr	(ram_waddr),
		.bus_wdata	(ram_wdata),

		.clk	(clk),
		.resetn	(resetn)
	);

	always @(posedge clk) begin
		cpu_ram_read_ready  <= cpu_dmem_renb && cpu_bus_ram_read_ready;

		cpu_ram_write_ready <= cpu_dmem_wenb && cpu_bus_ram_write_ready;

		al_accel_ram_read_ready  <= al_accel_dmem_renb && al_accel_bus_ram_read_ready;

		al_accel_ram_write_ready <= al_accel_dmem_wenb && al_accel_bus_ram_write_ready;
	end

	picosoc_dmem #(
		.DMEM_SIZE(DMEM_SIZE)
	) dmem (
		.renb	(ram_renb),
		.raddr	(ram_raddr[19:2]),
		.rdata	(ram_rdata),

		.wenb	(ram_wenb),
		.wstrb  (ram_wstrb),
		.waddr	(ram_waddr[19:2]),
		.wdata 	(ram_wdata),

		.clk	(clk)	
	);

	wire al_accel_cal_fin;

	always @(posedge clk) begin
		al_accel_ctrl_ready <= mem_valid && !mem_ready && (mem_addr >= 32'h 0200_1000) && (mem_addr <= 32'h 0200_1050);
	end

	fs_accel_pico_ctrl accel_controller (
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

	fs_accel accelerator (
        .al_accel_cfgreg_di     (mem_wdata),
        .al_accel_cfgreg_sel    (al_accel_cfgreg_sel),
        .al_accel_cfgreg_wenb   (al_accel_cfgreg_wenb),

        .al_accel_rdata         (
			(al_accel_raddr[31:24] > 8'h 02) ? iomem_rdata :
			(al_accel_raddr >= 4*DMEM_SIZE && al_accel_raddr < 32'h 0200_0000) ? imem_rdata : ram_rdata
		),
        .al_accel_raddr         (al_accel_raddr),
        .al_accel_renb          (al_accel_renb),
        .al_accel_mem_read_ready     (al_accel_ram_read_ready | al_accel_imem_ready | al_accel_iomem_ready),
		// .al_accel_mem_read_ready     (al_accel_ram_read_ready | al_accel_imem_ready),
		.al_accel_mem_write_ready    (al_accel_ram_write_ready),

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

module pico_switch_write_bus(
	input 	cpu_wenb,
	input	al_accel_wenb,

	input [ 3:0] cpu_wstrb,
	input [ 3:0] al_accel_wstrb,

	input [31:0] cpu_waddr,
	input [31:0] al_accel_waddr,

	input [31:0] cpu_wdata,
	input [31:0] al_accel_wdata,

	input	cpu_valid,
	input	al_accel_valid,

	output reg cpu_write_ready,
	output reg al_accel_write_ready,

	output 		  bus_wenb,
	output [ 3:0] bus_wstrb,
	output [31:0] bus_waddr,
	output [31:0] bus_wdata,

	// Mandatory Sigs
    input   clk,
    input   resetn
);

	localparam 
		IDLE 			= 1'd 0, 
		AL_ACCEL_TURN	= 1'd 1;

	reg state;
	always @(posedge clk) begin
		if (!resetn) begin
			state <= IDLE;
		end
		else begin
			case (state)
				IDLE: begin
					if (cpu_valid)
						state <= IDLE;
					else if (al_accel_valid)
						state <= AL_ACCEL_TURN;
				end

				AL_ACCEL_TURN: begin
					if (!al_accel_valid)
						state <= IDLE;
				end
			endcase
		end
	end

	always @(*) begin
		al_accel_write_ready = 0;
		cpu_write_ready = 0;
		case (state)
			IDLE: begin
				if (cpu_valid) 
					cpu_write_ready = 1;
				else if (al_accel_valid) 
					al_accel_write_ready = 1;
			end

			// AL_ACCEL_TURN:
				// if (al_accel_valid) al_accel_write_ready = 1;
		endcase
	end

	assign bus_wenb  = 	(state == IDLE) ? (cpu_wenb | al_accel_wenb) :
						(state == AL_ACCEL_TURN) ? al_accel_wenb : 0;


	assign bus_wstrb = 	(state == IDLE) ? (cpu_valid ? cpu_wstrb : al_accel_valid ? al_accel_wstrb : 0) :
						(state == AL_ACCEL_TURN) ? al_accel_wstrb : 0;

	assign bus_waddr = 	(state == IDLE) ? (cpu_valid ? cpu_waddr : al_accel_valid ? al_accel_waddr : 0) :
						(state == AL_ACCEL_TURN) ? al_accel_waddr : 0;

	assign bus_wdata = 	(state == IDLE) ? (cpu_valid ? cpu_wdata : al_accel_valid ? al_accel_wdata : 0) :
						(state == AL_ACCEL_TURN) ? al_accel_wdata : 0;

endmodule 

module pico_switch_read_bus(
	input 	cpu_renb,
	input	al_accel_renb,

	input [31:0] cpu_raddr,
	input [31:0] al_accel_raddr,

	input	cpu_valid,
	input	al_accel_valid,

	output reg cpu_read_ready,
	output reg al_accel_read_ready,

	output 		  bus_renb,
	output [31:0] bus_raddr,

	// Mandatory Sigs
    input   clk,
    input   resetn
);
	localparam 
		IDLE 			= 1'd 0, 
		AL_ACCEL_TURN	= 1'd 1;

	reg state;
	always @(posedge clk) begin
		if (!resetn) begin
			state <= IDLE;
		end
		else begin
			case (state)
				IDLE: begin
					if (cpu_valid)
						state <= IDLE;
					else if (al_accel_valid)
						state <= AL_ACCEL_TURN;
				end

				AL_ACCEL_TURN: begin
					if (!al_accel_valid)
						state <= IDLE;
				end
			endcase
		end
	end

	always @(*) begin
		al_accel_read_ready = 0;
		cpu_read_ready = 0;
		case (state)
			IDLE: begin
				if (cpu_valid) 
					cpu_read_ready = 1;
				else if (al_accel_valid) 
					al_accel_read_ready = 1; 
			end
		endcase
	end

	// assign bus_renb  = 	(state == IDLE) ? (cpu_valid ? cpu_renb  : al_accel_valid ? al_accel_renb  : 0) :
	// 					(state == AL_ACCEL_TURN) ? al_accel_renb : 0;

	assign bus_renb  = 	(state == IDLE) ? (cpu_renb  | al_accel_renb) :
						(state == AL_ACCEL_TURN) ? al_accel_renb : 0;

	assign bus_raddr = 	(state == IDLE) ? (cpu_valid ? cpu_raddr : al_accel_valid ? al_accel_raddr : 0) :
						(state == AL_ACCEL_TURN) ? al_accel_raddr : 0;

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
    parameter IMEM_SIZE = 32768
) (
    input              renb,
    input       [17:0] raddr,
    output reg  [31:0] rdata,

    input              wenb,
    input       [17:0] waddr,
    input       [31:0] wdata,
	
    input              clk
);
    // Instruction Memory
    reg [31:0] memory [0:IMEM_SIZE-1];

    initial begin
    	$readmemh("/home/manhtr/Desktop/RISCV_CNN/RISC_CNN_DSP/New_RISCV_CNN/Source/firmware.mem", memory);
	end


    always @(posedge clk) begin
        if (renb)
            rdata <= memory[raddr];
        if (wenb)
            memory[waddr] <= wdata;
    end

endmodule

