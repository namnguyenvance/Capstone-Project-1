module fs_accel_act_func_unit(
    // Data Sigs
    input  signed [31:0] act_func_di,
    output signed [31:0] act_func_do,

    // Config Sigs
    input  [3:0] act_func_typ
);

    // Define activation function types
    localparam 
        RELU    = 4'd0,
        RELU6   = 4'd1,
        SIGMOID = 4'd2,
        TANH    = 4'd3,
        NO_FUNC = 4'd4;
 
    // Intermediate register for output
    reg signed [31:0] act_func_data;

    always @(*) begin
        // Default value
        act_func_data = act_func_di;

        case (act_func_typ)
            RELU : begin
                // ReLU: max(0, x)
                act_func_data = (act_func_di > 0) ? act_func_di : 0;
            end

            RELU6 : begin
                // ReLU6: min(max(0, x), 6)
                if (act_func_di > 6)
                    act_func_data = 6;
                else if (act_func_di > 0)
                    act_func_data = act_func_di;
                else
                    act_func_data = 0;
            end

            SIGMOID : begin
                // Sigmoid implementation (placeholder, needs LUT or approximation)
                // Example: act_func_data = sigmoid_approximation(act_func_di);
                act_func_data = 0; // Replace with actual implementation
            end

            TANH : begin
                // Tanh implementation (placeholder, needs LUT or approximation)
                // Example: act_func_data = tanh_approximation(act_func_di);
                act_func_data = 0; // Replace with actual implementation
            end 

            default: begin
                // No function: pass-through
                act_func_data = act_func_di;
            end
        endcase
    end

    // Assign the result to the output
    assign act_func_do = act_func_data;

endmodule
