`timescale 1ns/10ps

module interpDeci #( parameter W = 10 )(
    input wire clk, rst_n, eni, eno,
    input wire signed [W-1:0] in,
    output logic signed [W-1:0] out
);
    logic signed [W-1:0] candi;
    always_ff@(posedge clk) begin
        if(!rst_n) candi <= '0;
        else if(eni) candi <= in;
        else if(eno) candi <= '0;
    end
    always_ff@(posedge clk) begin
        if(!rst_n) out <= '0;
        else if(eno) out <= candi;
    end
endmodule
