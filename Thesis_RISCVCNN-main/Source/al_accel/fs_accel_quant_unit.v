module fs_accel_quant_unit(
    // Data Sigs
    input   [31:0]  quant_di,
    output  [31:0]  quant_do,
    input   [ 7:0]  quant_rshift,

    // LUT
    input   [63:0] quant_lut_val_0,
    input   [63:0] quant_lut_val_1,
    input   [63:0] quant_lut_val_2,
    input   [63:0] quant_lut_val_3,
    input   [63:0] quant_lut_val_4,
    input   [63:0] quant_lut_val_5,
    input   [63:0] quant_lut_val_6,
    input   [63:0] quant_lut_val_7,
    input   [63:0] quant_lut_val_8,
    input   [63:0] quant_lut_val_9,
    input   [63:0] quant_lut_val_10,
    input   [63:0] quant_lut_val_11,
    input   [63:0] quant_lut_val_12,
    input   [63:0] quant_lut_val_13,
    input   [63:0] quant_lut_val_14,
    input   [63:0] quant_lut_val_15,

    // Ctrl Sigs
    input   enb,
    output  rdy,

    // Mandatory Sigs
    input   clk,
    input   resetn  
);
    // Signal Declearation
    wire        quant_sdi;
    wire [63:0] quant_udi;
    reg  [31:0] quant_di_reg;

    reg  [63:0] quant_mul_result;
    reg  [63:0] quant_mul_acc;
    reg  [ 3:0] quant_sel;
    reg         quant_load;

    reg  [ 3:0] state;

    wire [63:0] quant_mul_result_add_nudge;

    wire [31:0] quant_himul_result;

    wire [31:0] mask, remainder, threshold;

    wire [31:0] quant_shift_result;

    // Convert Signed to Unsigned
    assign  quant_sdi = quant_di_reg[31];
    assign  quant_udi = (quant_sdi) ? ~quant_di_reg + 1 : quant_di_reg;


    // Mul Register
    always @(posedge clk) begin
        if (!resetn) begin
            quant_di_reg <= 0;
        end 
        else if (enb) begin
            if (quant_load) begin
                quant_di_reg <= quant_di;
            end
        end
    end

    // Multiply Data
    localparam 
        LOAD    = 4'd0,
        ONE_C   = 4'd1,
        TWO_C   = 4'd2,
        THREE_C = 4'd3,
        FOUR_C  = 4'd4,
        FIVE_C  = 4'd5,
        SIX_C   = 4'd6,
        SEVEN_C = 4'd7,
        EIGHT_C = 4'd8,
        FINISH  = 4'd9; 

    // FSM Transition
    always @(posedge clk) begin
        if (!resetn) 
            state <= LOAD;
        else if (enb) begin
            case(state) 
                LOAD    : state <= ONE_C;
                ONE_C   : state <= TWO_C;
                TWO_C   : state <= THREE_C;
                THREE_C : state <= FOUR_C;
                FOUR_C  : state <= FIVE_C;
                FIVE_C  : state <= SIX_C;
                SIX_C   : state <= SEVEN_C;
                SEVEN_C : state <= EIGHT_C;
                EIGHT_C : state <= FINISH;
                FINISH  : state <= LOAD;
                default : state <= LOAD;
            endcase
        end
    end

    // Sel Sig
    always @(*) begin
        case(quant_sel) 
            4'd  0: quant_mul_acc = quant_lut_val_0;
            4'd  1: quant_mul_acc = quant_lut_val_1;
            4'd  2: quant_mul_acc = quant_lut_val_2;
            4'd  3: quant_mul_acc = quant_lut_val_3;
            4'd  4: quant_mul_acc = quant_lut_val_4;
            4'd  5: quant_mul_acc = quant_lut_val_5;
            4'd  6: quant_mul_acc = quant_lut_val_6;
            4'd  7: quant_mul_acc = quant_lut_val_7;
            4'd  8: quant_mul_acc = quant_lut_val_8;
            4'd  9: quant_mul_acc = quant_lut_val_9;
            4'd 10: quant_mul_acc = quant_lut_val_10;
            4'd 11: quant_mul_acc = quant_lut_val_11;
            4'd 12: quant_mul_acc = quant_lut_val_12;
            4'd 13: quant_mul_acc = quant_lut_val_13;
            4'd 14: quant_mul_acc = quant_lut_val_14;
            4'd 15: quant_mul_acc = quant_lut_val_15;
        endcase
    end

    // FSM Behavior
    always @(*) begin
        quant_load = 1'd0;
        quant_sel = 4'd0;
        case (state)
            LOAD    : 
                quant_load = 1'd1;

            ONE_C   : 
                quant_sel = quant_udi[31:28]; 
                
            TWO_C   : 
                quant_sel = quant_udi[27:24]; 
                
            THREE_C : 
                quant_sel = quant_udi[23:20]; 
            
            FOUR_C  : 
                quant_sel = quant_udi[19:16]; 

            FIVE_C  : 
                quant_sel = quant_udi[15:12]; 

            SIX_C   : 
                quant_sel = quant_udi[11: 8]; 

            SEVEN_C : 
                quant_sel = quant_udi[ 7: 4]; 

            EIGHT_C : 
                quant_sel = quant_udi[ 3: 0];  
        endcase
    end

    // Store Data
    always @(posedge clk) begin
        if (!resetn) begin
            quant_mul_result <= 64'h 000000000000000;
        end 
        else if (enb) begin
            case(state) 
                LOAD    : quant_mul_result <= 64'h 000000000000000;  // 64'h 000000040000000;
                ONE_C   : quant_mul_result <= (quant_mul_acc + quant_mul_result) << 4; // * 2 ^ 4
                TWO_C   : quant_mul_result <= (quant_mul_acc + quant_mul_result) << 4;
                THREE_C : quant_mul_result <= (quant_mul_acc + quant_mul_result) << 4;
                FOUR_C  : quant_mul_result <= (quant_mul_acc + quant_mul_result) << 4;
                FIVE_C  : quant_mul_result <= (quant_mul_acc + quant_mul_result) << 4;
                SIX_C   : quant_mul_result <= (quant_mul_acc + quant_mul_result) << 4;
                SEVEN_C : quant_mul_result <= (quant_mul_acc + quant_mul_result) << 4;
                EIGHT_C : quant_mul_result <= (quant_mul_acc + quant_mul_result);
                FINISH  : quant_mul_result <= quant_mul_result;
            endcase
        end
    end

    // SaturatingRoundingDoublingHighMul //
    assign quant_mul_result_add_nudge = quant_mul_result + 64'h 000000040000000;

    assign quant_himul_result = quant_mul_result_add_nudge[62:31];
    
    // RoundingDivideByPOT //    
    assign mask = (1 << quant_rshift) - 1;
    assign remainder = quant_himul_result & mask;
    assign threshold = (mask >> 1);

    assign quant_shift_result = (remainder > threshold) ? ((quant_himul_result >> quant_rshift) + 1) : (quant_himul_result >> quant_rshift);

    // Output value
    wire [31:0] quant_do_tmp;
    assign quant_do_tmp = (quant_sdi) ? ~quant_shift_result + 1 : quant_shift_result;
    assign rdy = (state == FINISH);
    assign quant_do = rdy ? quant_do_tmp : quant_do;
endmodule