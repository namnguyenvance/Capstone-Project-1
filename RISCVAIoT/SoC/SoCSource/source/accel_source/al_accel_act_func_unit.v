module al_accel_act_func_unit(
    // Data Sigs
    input  signed [31:0] act_func_di,
    output signed [31:0] act_func_do,

    // Config Sigs
    input  [3:0] act_func_typ
);

    localparam 
        RELU    = 4'd0,
        RELU6   = 4'd1,
        SIGMOID = 4'd2,
        TANH    = 4'd3,
        NO_FUNC = 4'd4;
 
    reg [7:0] act_func_data;
    always @(*) begin
        act_func_data = act_func_di;
        case (act_func_typ)
            RELU : begin
                act_func_data = (act_func_di > 0) ? act_func_di : 0;
            end

            RELU6 : begin
                act_func_data = (act_func_di > 0) ? ((act_func_di < 6) ? act_func_di : 6) : 0;
            end

            SIGMOID : begin
                // NEED IMPLEMENTATION
                act_func_data = act_func_di;
            end

            TANH : begin
                // NEED IMPLEMENTATION
                act_func_data = act_func_di;
            end 
        endcase
    end

    assign act_func_do = act_func_data;

endmodule