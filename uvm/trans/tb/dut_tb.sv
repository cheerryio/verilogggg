`timescale 1ns/10ps
`include "uvm_macros.svh"
`include "dut_if.sv"
`include "../tests/basic_test.sv"
import uvm_pkg::*;
module dut_tb();
    bit clk,rst_n;
    dut_if input_if(clk,rst_n),output_if(clk,rst_n);
    initial forever #5 clk=~clk;
    initial #50 rst_n=1'b1;
    dut #(.DW(8)) the_dut_Inst(
        clk,rst_n,1'b1,
        input_if.data,input_if.valid,
        output_if.data,output_if.valid
    );
    initial begin
        uvm_config_db #(virtual dut_if)::set(null,"uvm_test_top.env.i_agt.drv","vif",input_if);
        uvm_config_db #(virtual dut_if)::set(null,"uvm_test_top.env.i_agt.mon","vif",input_if);
        uvm_config_db #(virtual dut_if)::set(null,"uvm_test_top.env.o_agt.mon","vif",output_if);
        run_test("basic_test");
    end

endmodule
