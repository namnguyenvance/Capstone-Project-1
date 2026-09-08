module fs_accel_cp (
    // Data Signals
    input   signed [7:0] cp_di,   
    output  signed [7:0] cp_do,  
      
    // Control Signals
    input   enb,                 

    // Mandatory Signals
    input   clk,                   
    input   resetn                 
);

    reg signed [7:0] max_value;

    always @(posedge clk) begin
        if (!resetn) begin
            max_value <= -128;  
        end else if (enb) begin
            if(cp_di > max_value) begin
                 max_value <= cp_di;
            end 
        end
    end

    assign cp_do = max_value;

endmodule
