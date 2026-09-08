module al_accel_cp_unit(
    // Data Sigs
    input signed  [7:0] cp_di_0,
    input signed  [7:0] cp_di_1,
    input signed  [7:0] cp_di_2,
    // output reg    [7:0] cp_do,
    output        [7:0] cp_do,

    // Ctrl Sigs
    input               cp_clr,
    input               cp2h_enb,
    input               cp2w_enb,

    input   enb,

    // Mandatory Sigs
    input   clk,
    input   resetn
);
    wire signed [7:0] cp_di_01_max;
    assign cp_di_01_max  = (cp_di_0 > cp_di_1) ? cp_di_0 : cp_di_1 ;

    wire signed [7:0] cp_di_012_max;
    assign cp_di_012_max = (cp_di_01_max > cp_di_2) ? cp_di_01_max : cp_di_2 ;

    wire signed [7:0] cp_do_01_max;
    assign cp_do_01_max  = (cp_data_0 > cp_data_1) ? cp_data_0 : cp_data_1 ;

    wire signed [7:0] cp_do_012_max;
    assign cp_do_012_max = (cp_do_01_max > cp_data_2) ? cp_do_01_max : cp_data_2 ;

    reg signed [7:0] cp_data_2, cp_data_1, cp_data_0;
    always @(posedge clk) begin
        if (!resetn) begin
            cp_data_0 <= 0;
            cp_data_1 <= 0;
            cp_data_2 <= 0;

            // cp_do <= 0;
        end 
        else if (enb) begin
            if (!cp_clr) begin
                cp_data_0 <= (cp2h_enb) ? cp_di_01_max : cp_di_012_max;
                cp_data_1 <= cp_data_0;
                cp_data_2 <= cp_data_1;
            end
            // else begin
                // cp_do <= cp_do_012_max;
            // end
        end
    end 

    assign cp_do = (cp2w_enb) ? cp_do_01_max: cp_do_012_max;
endmodule    