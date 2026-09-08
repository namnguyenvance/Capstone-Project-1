module fs_accel_pico_ctrl (
/* SoC Sigs */
    input           al_accel_mem_valid,
    input  [31:0]   al_accel_ctrl_waddr,
    input  [31:0]   al_accel_ctrl_wdata,

    input  [31:0]   al_accel_ctrl_raddr,
    output [31:0]   al_accel_ctrl_rdata,

/* Alpha Accelerator Sigs */
    input          al_accel_cal_fin,

    output reg [ 4:0]   al_accel_cfgreg_sel, 
    output reg          al_accel_cfgreg_wenb,

    output reg          al_accel_flow_enb,
    output              al_accel_flow_resetn,
/* Mandatory Sigs */

    input clk,
	input resetn
);

// Register  0:     32'h 0200_1000
// Register  1:     32'h 0200_1004
// Register  2:     32'h 0200_1008
// Register  3:     32'h 0200_100C
// Register  4:     32'h 0200_1010
// Register  5:     32'h 0200_1014
// Register  6:     32'h 0200_1018
// Register  7:     32'h 0200_101C
// Register  8:     32'h 0200_1020
// Register  9:     32'h 0200_1024
// Register 10:     32'h 0200_1028
// Register 11:     32'h 0200_102C
// Register 12:     32'h 0200_1030
// Register 13:     32'h 0200_1034
// Register CTRL:   32'h 0200_1040 
    localparam 
        REG_0_ADDR      = 32'h 0200_1000,
        REG_1_ADDR      = 32'h 0200_1004,
        REG_2_ADDR      = 32'h 0200_1008,
        REG_3_ADDR      = 32'h 0200_100C,
        REG_4_ADDR      = 32'h 0200_1010,
        REG_5_ADDR      = 32'h 0200_1014,
        REG_6_ADDR      = 32'h 0200_1018,
        REG_7_ADDR      = 32'h 0200_101C,
        REG_8_ADDR      = 32'h 0200_1020,
        REG_9_ADDR      = 32'h 0200_1024,
        REG_10_ADDR     = 32'h 0200_1028,
        REG_11_ADDR     = 32'h 0200_102C,
        REG_12_ADDR     = 32'h 0200_1030,
        REG_13_ADDR     = 32'h 0200_1034,
        REG_14_ADDR     = 32'h 0200_1038,
        REG_15_ADDR     = 32'h 0200_103C,
        REG_16_ADDR     = 32'h 0200_1040,
        REG_17_ADDR     = 32'h 0200_1044,
        REG_18_ADDR     = 32'h 0200_1048,
        REG_CTRL_ADDR   = 32'h 0200_1050;

    localparam
        RST = 2'd 0,
        CFG = 2'd 1,
        RUN = 2'd 2,
        FIN = 2'd 3;

    reg al_accel_flow_reset;

    reg [1:0] state;

    always @(posedge clk) begin
        if (!resetn) 
            state <= RST;
        else begin
            case (state)
                RST: 
                if (al_accel_mem_valid && al_accel_ctrl_waddr == REG_CTRL_ADDR) begin
                    if (al_accel_ctrl_wdata == 32'd 1) 
                        state <= CFG;
                    else if (al_accel_ctrl_wdata == 32'd 2)
                        state <= RUN; 
                end

                CFG: 
                if (al_accel_mem_valid && al_accel_ctrl_waddr == REG_CTRL_ADDR) begin
                    if (al_accel_ctrl_wdata == 32'd 0) 
                        state <= RST;
                    else if (al_accel_ctrl_wdata == 32'd 2)
                        state <= RUN; 
                end

                RUN: 
                if (al_accel_mem_valid && al_accel_ctrl_waddr == REG_CTRL_ADDR) begin
                    if (al_accel_ctrl_wdata == 32'd 0) 
                        state <= RST;
                end 
                else if (al_accel_cal_fin) begin
                    state <= FIN;
                end

                FIN: 
                if (al_accel_mem_valid && al_accel_ctrl_waddr == REG_CTRL_ADDR) begin
                    if (al_accel_ctrl_wdata == 32'd 0) 
                        state <= RST;
                end
            endcase
        end
    end

    always @(*) begin
        al_accel_cfgreg_wenb = 1'b 0;
        al_accel_flow_enb    = 1'b 0;
        al_accel_flow_reset  = 1'b 0;
        al_accel_cfgreg_sel  = 5'd 19;
        
        case (state) 
            RST: begin
                al_accel_flow_reset = 1'b 1;
            end

            CFG: begin
                al_accel_cfgreg_wenb = 1'b 1;
                if (al_accel_mem_valid) begin
                    case (al_accel_ctrl_waddr)
                        REG_0_ADDR:     al_accel_cfgreg_sel = 5'd 0;
                        REG_1_ADDR:     al_accel_cfgreg_sel = 5'd 1;
                        REG_2_ADDR:     al_accel_cfgreg_sel = 5'd 2;
                        REG_3_ADDR:     al_accel_cfgreg_sel = 5'd 3;
                        REG_4_ADDR:     al_accel_cfgreg_sel = 5'd 4;
                        REG_5_ADDR:     al_accel_cfgreg_sel = 5'd 5; 
                        REG_6_ADDR:     al_accel_cfgreg_sel = 5'd 6; 
                        REG_7_ADDR:     al_accel_cfgreg_sel = 5'd 7;
                        REG_8_ADDR:     al_accel_cfgreg_sel = 5'd 8;
                        REG_9_ADDR:     al_accel_cfgreg_sel = 5'd 9;
                        REG_10_ADDR:    al_accel_cfgreg_sel = 5'd 10;
                        REG_11_ADDR:    al_accel_cfgreg_sel = 5'd 11; 
                        REG_12_ADDR:    al_accel_cfgreg_sel = 5'd 12;
                        REG_13_ADDR:    al_accel_cfgreg_sel = 5'd 13;
                        REG_14_ADDR:    al_accel_cfgreg_sel = 5'd 14;
                        REG_15_ADDR:    al_accel_cfgreg_sel = 5'd 15;
                        REG_16_ADDR:    al_accel_cfgreg_sel = 5'd 16;
                        REG_17_ADDR:    al_accel_cfgreg_sel = 5'd 17;
                        REG_18_ADDR:    al_accel_cfgreg_sel = 5'd 18;
                    endcase
                end
            end

            RUN: begin
                al_accel_flow_enb    = 1'b 1;
            end

            FIN: begin

            end
        endcase
    end

    assign al_accel_ctrl_rdata  = (al_accel_ctrl_raddr == REG_CTRL_ADDR) ? {30'd 0, state} : 32'h FFFF_FFFF;
    assign al_accel_flow_resetn = ~al_accel_flow_reset;
endmodule