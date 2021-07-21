`timescale 1ns/10ps

module counter_tb #(

)(

);
    logic clk,rst_n,en;
    initial begin
        clk=0;
        en=1;
        forever #50 clk=~clk;
    end
    initial begin
        rst_n=0;
        #100 rst_n=1;
    end
    logic co2,co62;
    counter #( 2) theCounterTbInst2(clk,rst_n,en,co2);
    counter #(62) theCounterTbInst62(clk,rst_n,en,co62);
endmodule

module counter #(
    parameter integer N = 64
)(
    input wire clk,rst_n,en,
    output logic co
);
    logic [$clog2(N)-1:0] cnt;
    always_ff @( posedge clk ) begin
        if(!rst_n) begin cnt <= '0; end
        else if(en)
        begin
            if(cnt<N-1) cnt<=cnt+1'b1;
            else cnt<='0;
        end
    end
    assign co=en & cnt==N-1;
endmodule