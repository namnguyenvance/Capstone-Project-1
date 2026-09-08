module al_accel_mac(
    input signed [ 7:0]  mac_wdi_0,
    input signed [ 7:0]  mac_wdi_1,
    input signed [ 7:0]  mac_wdi_2,

    input signed [31:0]  mac_idi_0,
    input signed [31:0]  mac_idi_1,
    input signed [31:0]  mac_idi_2,
    input signed [31:0]  mac_idi_3,
    input signed [31:0]  mac_idi_4,
    input signed [31:0]  mac_idi_5,
    input signed [31:0]  mac_idi_6,
    input signed [31:0]  mac_idi_7,

    output  [31:0]  mac_odo,

    output mac_load,

    // Ctrl Sigs
    input   enb,
    output  rdy,
    input   clk,
    input   resetn
);
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

    reg [ 3:0] state;
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
                EIGHT_C : state <= LOAD; // state <= FINISH;
                FINISH  : state <= LOAD;
                default : state <= LOAD;
            endcase
        end
    end

    reg [ 2:0] isel;
    reg [31:0] mac_acc;
    always @(*) begin
        case(isel) 
            3'd0: mac_acc = mac_idi_0;
            3'd1: mac_acc = mac_idi_1;
            3'd2: mac_acc = mac_idi_2;
            3'd3: mac_acc = mac_idi_3;
            3'd4: mac_acc = mac_idi_4;
            3'd5: mac_acc = mac_idi_5;
            3'd6: mac_acc = mac_idi_6;
            3'd7: mac_acc = mac_idi_7;
        endcase
    end

    wire [ 7:0] us_mac_wdi_0;
    wire [ 7:0] us_mac_wdi_2;
    wire [ 7:0] us_mac_wdi_1;
    assign us_mac_wdi_0 = (mac_wdi_0[7]) ? ~mac_wdi_0 + 1 : mac_wdi_0;
    assign us_mac_wdi_1 = (mac_wdi_1[7]) ? ~mac_wdi_1 + 1 : mac_wdi_1;
    assign us_mac_wdi_2 = (mac_wdi_2[7]) ? ~mac_wdi_2 + 1 : mac_wdi_2;

    reg rdy, mac_load;
    always @(*) begin
        case (state)
            LOAD    : begin
                mac_load = 1'd1;
                rdy  = 1'd0;
                isel = 3'd0; 
            end

            ONE_C   : begin
                mac_load = 1'd0;
                rdy  = 1'd0;
                isel = {us_mac_wdi_2[7], us_mac_wdi_1[7], us_mac_wdi_0[7]}; 
            end
                
            TWO_C   : begin
                mac_load = 1'd0;
                rdy  = 1'd0;
                isel = {us_mac_wdi_2[6], us_mac_wdi_1[6], us_mac_wdi_0[6]}; 
            end
                
            THREE_C : begin
                mac_load = 1'd0;
                rdy  = 1'd0;
                isel = {us_mac_wdi_2[5], us_mac_wdi_1[5], us_mac_wdi_0[5]}; 
            end
            
            FOUR_C  : begin
                mac_load = 1'd0;
                rdy  = 1'd0;
                isel = {us_mac_wdi_2[4], us_mac_wdi_1[4], us_mac_wdi_0[4]}; 
            end

            FIVE_C  : begin
                mac_load = 1'd0;
                rdy  = 1'd0;
                isel = {us_mac_wdi_2[3], us_mac_wdi_1[3], us_mac_wdi_0[3]}; 
            end

            SIX_C   : begin
                mac_load = 1'd0;
                rdy  = 1'd0;
                isel = {us_mac_wdi_2[2], us_mac_wdi_1[2], us_mac_wdi_0[2]}; 
            end

            SEVEN_C : begin
                mac_load = 1'd0;
                rdy  = 1'd0;
                isel = {us_mac_wdi_2[1], us_mac_wdi_1[1], us_mac_wdi_0[1]}; 
            end

            EIGHT_C : begin
                mac_load = 1'd0;
                rdy  = 1'd1;
                isel = {us_mac_wdi_2[0], us_mac_wdi_1[0], us_mac_wdi_0[0]};  
            end
            
            FINISH  : begin
                mac_load = 1'd0;
                rdy  = 1'd0;
                isel = 3'd0;
            end

            default: begin
                mac_load = 1'd0;
                rdy  = 1'd0;
                isel = 3'd0; 
            end
        endcase
    end

    reg signed [31:0] mac_sum;
    always @(posedge clk) begin
        if (!resetn) begin
            mac_sum <= 32'd0;
        end 
        else if (enb) begin
            case(state) 
                LOAD    : mac_sum <= 32'd0;
                ONE_C   : mac_sum <= (mac_acc + mac_sum) << 1;
                TWO_C   : mac_sum <= (mac_acc + mac_sum) << 1;
                THREE_C : mac_sum <= (mac_acc + mac_sum) << 1;
                FOUR_C  : mac_sum <= (mac_acc + mac_sum) << 1;
                FIVE_C  : mac_sum <= (mac_acc + mac_sum) << 1;
                SIX_C   : mac_sum <= (mac_acc + mac_sum) << 1;
                SEVEN_C : mac_sum <= (mac_acc + mac_sum) << 1;
                EIGHT_C : mac_sum <= (mac_acc + mac_sum);
                FINISH  : mac_sum <= mac_sum;
            endcase
        end
    end
    assign mac_odo = mac_sum;
endmodule