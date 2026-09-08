module fs_accel_acc_matrix(
    // Data Sigs
    input signed [31:0] acc_matrix_bps_0,
    input signed [31:0] acc_matrix_bps_1,
    input signed [31:0] acc_matrix_bps_2,

    input signed [31:0] acc_matrix_di_0_0,
    input signed [31:0] acc_matrix_di_0_1,
    input signed [31:0] acc_matrix_di_0_2,
    input signed [31:0] acc_matrix_di_1_0,
    input signed [31:0] acc_matrix_di_1_1,
    input signed [31:0] acc_matrix_di_1_2,
    input signed [31:0] acc_matrix_di_2_0,
    input signed [31:0] acc_matrix_di_2_1,
    input signed [31:0] acc_matrix_di_2_2,

    output signed [31:0] acc_matrix_do_0,
    output signed [31:0] acc_matrix_do_1,
    output signed [31:0] acc_matrix_do_2,

    // Config Sigs
    input   acc_matrix_bps_load,
    // input   acc_matrix_inter_sum_load,
    input   acc_matrix_bps_write,
    input   acc_matrix_inter_sum_write,

    // Mandatory Sigs
    input   enb,
    input   clk,
    input   resetn
);
    wire signed [31:0] inter_sum_0;
    wire signed [31:0] inter_sum_1;
    wire signed [31:0] inter_sum_2;

    assign inter_sum_0  = acc_matrix_di_0_0 + acc_matrix_di_1_0 + acc_matrix_di_2_0;

    assign inter_sum_1  = acc_matrix_di_0_1 + acc_matrix_di_1_1 + acc_matrix_di_2_1;

    assign inter_sum_2  = acc_matrix_di_0_2 + acc_matrix_di_1_2 + acc_matrix_di_2_2;

    reg [31:0]  acc_matrix_bps_0_reg,
                acc_matrix_bps_1_reg,
                acc_matrix_bps_2_reg;

    reg [31:0]  acc_matrix_inter_sum_0_reg,
                acc_matrix_inter_sum_1_reg,
                acc_matrix_inter_sum_2_reg;
    
    reg [31:0]  acc_matrix_bps_0_write,
                acc_matrix_bps_1_write,
                acc_matrix_bps_2_write;

    always @(posedge clk) begin
        if (!resetn) begin
            acc_matrix_bps_0_reg <= 0;
            acc_matrix_bps_1_reg <= 0;
            acc_matrix_bps_2_reg <= 0;

            acc_matrix_inter_sum_0_reg <= 0;
            acc_matrix_inter_sum_1_reg <= 0;
            acc_matrix_inter_sum_2_reg <= 0;

            acc_matrix_bps_0_write <= 0;
            acc_matrix_bps_1_write <= 0;
            acc_matrix_bps_2_write <= 0;

        end 
        else if (enb) begin 
            if (acc_matrix_bps_load) begin
                acc_matrix_bps_0_reg <= acc_matrix_bps_0;
                acc_matrix_bps_1_reg <= acc_matrix_bps_1;
                acc_matrix_bps_2_reg <= acc_matrix_bps_2;
            end 
            
            // if (acc_matrix_inter_sum_load) begin
            //     acc_matrix_inter_sum_0_reg <= acc_matrix_bps_0_reg + inter_sum_0;
            //     acc_matrix_inter_sum_1_reg <= acc_matrix_bps_1_reg + inter_sum_1;
            //     acc_matrix_inter_sum_2_reg <= acc_matrix_bps_2_reg + inter_sum_2;
            // end
            if (acc_matrix_bps_write) begin
                acc_matrix_bps_0_write <= acc_matrix_bps_0_reg;
                acc_matrix_bps_1_write <= acc_matrix_bps_1_reg;
                acc_matrix_bps_2_write <= acc_matrix_bps_2_reg;
            end

            if (acc_matrix_inter_sum_write) begin
                acc_matrix_inter_sum_0_reg <= acc_matrix_bps_0_write + inter_sum_0;
                acc_matrix_inter_sum_1_reg <= acc_matrix_bps_1_write + inter_sum_1;
                acc_matrix_inter_sum_2_reg <= acc_matrix_bps_2_write + inter_sum_2;
            end
        end
    end

    assign acc_matrix_do_0 = acc_matrix_inter_sum_0_reg;
    assign acc_matrix_do_1 = acc_matrix_inter_sum_1_reg;
    assign acc_matrix_do_2 = acc_matrix_inter_sum_2_reg;
endmodule
