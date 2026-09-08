module fs_accel_pu (
    // Input feature map window (3x3)
    input  wire signed [7:0] pu_idi_0,
    input  wire signed [7:0] pu_idi_1,
    input  wire signed [7:0] pu_idi_2,
    input  wire signed [7:0] pu_idi_3,
    input  wire signed [7:0] pu_idi_4,
    input  wire signed [7:0] pu_idi_5,
    input  wire signed [7:0] pu_idi_6,
    input  wire signed [7:0] pu_idi_7,
    input  wire signed [7:0] pu_idi_8,

    // Input offset 
    input  wire signed [31:0] pu_input_offset,

    // Kernel weights (3x3)
    input  wire signed [7:0] pu_wdi_0_0,
    input  wire signed [7:0] pu_wdi_0_1,
    input  wire signed [7:0] pu_wdi_0_2,
    input  wire signed [7:0] pu_wdi_1_0,
    input  wire signed [7:0] pu_wdi_1_1,
    input  wire signed [7:0] pu_wdi_1_2,
    input  wire signed [7:0] pu_wdi_2_0,
    input  wire signed [7:0] pu_wdi_2_1,
    input  wire signed [7:0] pu_wdi_2_2,

    // Output: accumulated sum of 9 products
    output reg signed [31:0] pu_odo,
    output reg               rdy,

    // Ctrl
    input  wire              clk,
    input  wire              resetn,
    input  wire              enb
);

    // Wires from PE multipliers
    wire signed [31:0] pe_out [0:8];

    // Instantiate 9 PE
    fs_accel_pe pe00 (.pe_in0(pu_idi_0), .pe_in1(pu_wdi_0_0), .pe_offset(pu_input_offset), .pe_out(pe_out[0]));
    fs_accel_pe pe01 (.pe_in0(pu_idi_1), .pe_in1(pu_wdi_0_1), .pe_offset(pu_input_offset), .pe_out(pe_out[1]));
    fs_accel_pe pe02 (.pe_in0(pu_idi_2), .pe_in1(pu_wdi_0_2), .pe_offset(pu_input_offset), .pe_out(pe_out[2]));
    fs_accel_pe pe10 (.pe_in0(pu_idi_3), .pe_in1(pu_wdi_1_0), .pe_offset(pu_input_offset), .pe_out(pe_out[3]));
    fs_accel_pe pe11 (.pe_in0(pu_idi_4), .pe_in1(pu_wdi_1_1), .pe_offset(pu_input_offset), .pe_out(pe_out[4]));
    fs_accel_pe pe12 (.pe_in0(pu_idi_5), .pe_in1(pu_wdi_1_2), .pe_offset(pu_input_offset), .pe_out(pe_out[5]));
    fs_accel_pe pe20 (.pe_in0(pu_idi_6), .pe_in1(pu_wdi_2_0), .pe_offset(pu_input_offset), .pe_out(pe_out[6]));
    fs_accel_pe pe21 (.pe_in0(pu_idi_7), .pe_in1(pu_wdi_2_1), .pe_offset(pu_input_offset), .pe_out(pe_out[7]));
    fs_accel_pe pe22 (.pe_in0(pu_idi_8), .pe_in1(pu_wdi_2_2), .pe_offset(pu_input_offset), .pe_out(pe_out[8]));

    // Adder tree (combinational)
    wire signed [31:0] s1_0 = pe_out[0] + pe_out[1] + pe_out[2];
    wire signed [31:0] s1_1 = pe_out[3] + pe_out[4] + pe_out[5];
    wire signed [31:0] s1_2 = pe_out[6] + pe_out[7] + pe_out[8];

    wire signed [31:0] sum_next = s1_0 + s1_1 + s1_2;

    // Register output
    always @(posedge clk) begin
        if (!resetn) begin
            pu_odo <= 0;
            rdy    <= 0;
        end else if (enb) begin
            pu_odo <= sum_next;
            rdy    <= 1;
        end else begin
            rdy    <= 0;
        end
    end

endmodule
