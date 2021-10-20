`timescale 1ns/10ps

module pcf8563_if_tb();
    bit clk;
    bit rst_n,en;
    bit start;
    bit [7:0] rdata;
    bit done;
    wire scl;
    tri0 sda;
    always #5 clk=~clk;
    initial begin
        rst_n=1'b0;
        #50;
        rst_n=1'b1;
        en=1'b1;
    end
    initial begin
        wait(rst_n);
        @(posedge clk);
        start=1'b0;
        repeat(3) begin
            repeat(100000) @(posedge clk);
            start=1'b1;
            @(posedge clk);
            start=1'b0;
        end
    end
    pcf8563_if the_pcf8563_if_Inst(
        clk,rst_n,en,
        start,rdata,
        done,
        scl,sda
    );
endmodule