module fs_accel_pe(
    input  signed [7:0]  pe_in0,     // input pixel
    input  signed [7:0]  pe_in1,     // weight
    input  signed [31:0]  pe_offset,  // offset for this input
    output signed [31:0] pe_out
);
    // For input_offset
    wire signed [ 8:0] pe_part_of_input_offset;
    assign pe_part_of_input_offset = pe_offset[8:0];

    assign pe_out = (^pe_in0 === 1'bx) ? 32'sd0
               : (pe_in0 + pe_part_of_input_offset) * pe_in1;

endmodule
