`ifndef __MY_DRIVER_SV__
`define __MY_DRIVER_SV__

`include "uvm_macros.svh"
`include "../../tb/dut_if.sv"
`include "./my_transaction.sv"
import uvm_pkg::*;
class my_driver extends uvm_driver #(my_transaction);
    virtual dut_if vif;
    my_transaction tr;
    `uvm_component_utils(my_driver);
    function new(string name="my_driver",uvm_component parent=null);
        super.new(name,parent);
    endfunction
    extern virtual function void build_phase(uvm_phase phase);
    extern virtual task main_phase(uvm_phase phase);
    extern task drive_one_packet(my_transaction tr);
endclass

function void my_driver::build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db #(virtual dut_if)::get(this,"","vif",vif)) begin
        `uvm_fatal(get_full_name(),"get vif fail");
    end
endfunction

task my_driver::main_phase(uvm_phase phase);
    vif.data<='0;
    vif.valid<='0;
    wait(vif.rst_n);
    @(posedge vif.clk);
    while(1) begin
        seq_item_port.get_next_item(req);
        drive_one_packet(req);
        seq_item_port.item_done(); 
    end
endtask

task my_driver::drive_one_packet(my_transaction tr);
    vif.data<=tr.data;
    vif.valid<=1'b1;
    @(posedge vif.clk);
    vif.valid<=1'b0;
    `uvm_info(get_full_name(),"drive data",UVM_MEDIUM);
endtask

`endif