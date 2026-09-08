module al_accel_lut (
    // Data Sigs
    input  signed [ 7:0] lut_idi_0,
    input  signed [ 7:0] lut_idi_1,
    input  signed [ 7:0] lut_idi_2,

    output signed [31:0] lut_do_0,
    output signed [31:0] lut_do_1,
    output signed [31:0] lut_do_2,
    output signed [31:0] lut_do_3,
    output signed [31:0] lut_do_4,
    output signed [31:0] lut_do_5,
    output signed [31:0] lut_do_6,
    output signed [31:0] lut_do_7,

    input   lut_wdi_sbit_0,
    input   lut_wdi_sbit_1,
    input   lut_wdi_sbit_2,
    // Config Sigs
    input signed  [31:0] lut_input_offset,

    // Ctrl Sigs
    input   lut_ld_wrn,

    // Mandotory Sigs
    input   enb,
    input   clk,
    input   resetn
);
    wire signed [ 8:0] lut_part_of_input_offset;
    assign lut_part_of_input_offset = lut_input_offset[8:0];

    // wire signed [31:0]  input_ADD_offset_0,
    //                     input_ADD_offset_1,
    //                     input_ADD_offset_2;
    // assign input_ADD_offset_0 = lut_idi_0 + lut_input_offset;
    // assign input_ADD_offset_1 = lut_idi_1 + lut_input_offset;
    // assign input_ADD_offset_2 = lut_idi_2 + lut_input_offset;

    wire signed [ 9:0]  input_ADD_offset_0,
                        input_ADD_offset_1,
                        input_ADD_offset_2;
    assign input_ADD_offset_0 = lut_idi_0 + lut_part_of_input_offset;
    assign input_ADD_offset_1 = lut_idi_1 + lut_part_of_input_offset;
    assign input_ADD_offset_2 = lut_idi_2 + lut_part_of_input_offset;

    wire lut_idi_sbit_0, lut_idi_sbit_1, lut_idi_sbit_2;
    // assign lut_idi_sbit_0 = input_ADD_offset_0[31];
    // assign lut_idi_sbit_1 = input_ADD_offset_1[31];
    // assign lut_idi_sbit_2 = input_ADD_offset_2[31];
    assign lut_idi_sbit_0 = input_ADD_offset_0[8];
    assign lut_idi_sbit_1 = input_ADD_offset_1[8];
    assign lut_idi_sbit_2 = input_ADD_offset_2[8];


    // wire [31:0] us_lut_idi[2:0];
    wire [10:0] us_lut_idi[2:0];
    assign us_lut_idi[0] = (lut_idi_sbit_0) ? ~input_ADD_offset_0 + 1 : input_ADD_offset_0;
    assign us_lut_idi[1] = (lut_idi_sbit_1) ? ~input_ADD_offset_1 + 1 : input_ADD_offset_1;
    assign us_lut_idi[2] = (lut_idi_sbit_2) ? ~input_ADD_offset_2 + 1 : input_ADD_offset_2;

    wire signed [31:0] flut_val[2:0]; 
    assign flut_val[0] = (lut_idi_sbit_0 ^ lut_wdi_sbit_0) ? -us_lut_idi[0] : us_lut_idi[0];
    assign flut_val[1] = (lut_idi_sbit_1 ^ lut_wdi_sbit_1) ? -us_lut_idi[1] : us_lut_idi[1];
    assign flut_val[2] = (lut_idi_sbit_2 ^ lut_wdi_sbit_2) ? -us_lut_idi[2] : us_lut_idi[2];


    // reg [31:0] lut_data[7:0];
    reg signed [31:0]   lut_data_0,
                        lut_data_1,
                        lut_data_2,
                        lut_data_3,
                        lut_data_4,
                        lut_data_5,
                        lut_data_6,
                        lut_data_7;

    always @(posedge clk) begin
        if (!resetn) begin
            lut_data_0 <= 0;
            lut_data_1 <= 0;
            lut_data_2 <= 0;
            lut_data_3 <= 0;
            lut_data_4 <= 0;
            lut_data_5 <= 0;
            lut_data_6 <= 0;
            lut_data_7 <= 0;
        end 
        else if (enb) begin
            if (lut_ld_wrn) begin
                lut_data_0 <= 0;
                lut_data_1 <= flut_val[0];
                lut_data_2 <= flut_val[1];
                lut_data_3 <= flut_val[1] + flut_val[0];
                lut_data_4 <= flut_val[2];
                lut_data_5 <= flut_val[2] + flut_val[0];
                lut_data_6 <= flut_val[2] + flut_val[1];
                lut_data_7 <= flut_val[2] + flut_val[1] + flut_val[0];
            end
        end
    end

    assign lut_do_0 = lut_data_0;
    assign lut_do_1 = lut_data_1;
    assign lut_do_2 = lut_data_2;
    assign lut_do_3 = lut_data_3;
    assign lut_do_4 = lut_data_4;
    assign lut_do_5 = lut_data_5;
    assign lut_do_6 = lut_data_6;
    assign lut_do_7 = lut_data_7;
endmodule

    // wire lut_idi_sbit_0;
    // wire lut_idi_sbit_1;
    // wire lut_idi_sbit_2;
    // assign lut_idi_sbit_0 = lut_idi_0[7];
    // assign lut_idi_sbit_1 = lut_idi_1[7];
    // assign lut_idi_sbit_2 = lut_idi_2[7];


    // wire [ 7:0] us_lut_idi[2:0];
    // assign us_lut_idi[0] = (lut_idi_sbit_0) ? ~lut_idi_0 + 1 : lut_idi_0;
    // assign us_lut_idi[1] = (lut_idi_sbit_1) ? ~lut_idi_1 + 1 : lut_idi_1;
    // assign us_lut_idi[2] = (lut_idi_sbit_2) ? ~lut_idi_2 + 1 : lut_idi_2;

    // wire signed [ 8:0] flut_val[2:0]; 
    // assign flut_val[0] = (lut_idi_sbit_0 ^ lut_wdi_sbit_0) ? -us_lut_idi[0] : us_lut_idi[0];
    // assign flut_val[1] = (lut_idi_sbit_1 ^ lut_wdi_sbit_1) ? -us_lut_idi[1] : us_lut_idi[1];
    // assign flut_val[2] = (lut_idi_sbit_2 ^ lut_wdi_sbit_2) ? -us_lut_idi[2] : us_lut_idi[2];