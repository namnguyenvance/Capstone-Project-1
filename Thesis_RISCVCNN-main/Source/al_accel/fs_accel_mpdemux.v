module fs_accel_mpdemux  (
    // Data Sigs
    input signed [7:0] din, 
    input [3:0] sel,        
    output reg signed [7:0] do_0, 
    output reg signed [7:0] do_1, 
    output reg signed [7:0] do_2,
    output reg signed [7:0] do_3, 
    output reg signed [7:0] do_4,
    output reg signed [7:0] do_5, 
    output reg signed [7:0] do_6, 
    output reg signed [7:0] do_7,
    output reg signed [7:0] do_8, 
    output reg signed [7:0] do_9, 
    output reg signed [7:0] do_10, 
    output reg signed [7:0] do_11,
    output reg signed [7:0] do_12,

    // Mandatory Sigs
    input resetn  
);

    always @(*) begin
        if (!resetn) begin
            do_0  = -128;
            do_1  = -128;
            do_2  = -128;
            do_3  = -128;
            do_4  = -128;
            do_5  = -128;
            do_6  = -128;
            do_7  = -128;
            do_8  = -128;
            do_9  = -128;
            do_10 = -128;
            do_11 = -128;
            do_12 = -128;
        end else begin
            do_0  = (sel == 4'b0000) ? din : -128;
            do_1  = (sel == 4'b0001) ? din : -128;
            do_2  = (sel == 4'b0010) ? din : -128;
            do_3  = (sel == 4'b0011) ? din : -128;
            do_4  = (sel == 4'b0100) ? din : -128;
            do_5  = (sel == 4'b0101) ? din : -128;
            do_6  = (sel == 4'b0110) ? din : -128;
            do_7  = (sel == 4'b0111) ? din : -128;
            do_8  = (sel == 4'b1000) ? din : -128;
            do_9  = (sel == 4'b1001) ? din : -128;
            do_10 = (sel == 4'b1010) ? din : -128;
            do_11 = (sel == 4'b1011) ? din : -128;
            do_12 = (sel == 4'b1100) ? din : -128;
        end
    end

endmodule
