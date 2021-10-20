`timescale 1ns/10ps

module iic_master_tb();
    bit clk;
    bit rst_n,en;
    bit start;
    bit [6:0] dev_addr;
    bit [7:0] reg_addr;
    bit [7:0] wdata,rdata;
    bit done;
    wire scl;
    tri0 sda;
    logic co;
    always #5 clk=~clk;
    initial begin
        rst_n=1'b0;
        #50;
        rst_n=1'b1;
        en=1'b1;
    end
    initial begin
        dev_addr=7'h51;
        reg_addr=8'h02;
        wdata=8'b0000_1111;
    end
    counter #(50000) the_counter(clk,rst_n,en,co);
    iic_master the_iic_master_Inst(
        clk,rst_n,en,
        co,
        dev_addr,reg_addr,
        1'b1,
        wdata,rdata,
        done,
        scl,sda
    );
endmodule