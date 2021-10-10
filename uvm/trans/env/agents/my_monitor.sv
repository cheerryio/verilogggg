`ifndef __MY_MONITOR_SV__
`define __MY_MONITOR_SV__

`include "uvm_macros.svh"
`include "./my_transaction.sv"
`include "../../tb/dut_if.sv"
import uvm_pkg::*;
class my_monitor extends uvm_monitor;
    virtual dut_if vif;
    my_transaction tr;
    uvm_analysis_port #(my_transaction) ap;
    `uvm_component_utils(my_monitor);

    function new(string name="my_monitor",uvm_component parent=null);
        super.new(name,parent);
    endfunction

    extern virtual function void build_phase(uvm_phase phase);
    extern virtual task main_phase(uvm_phase phase);
    extern task collection_one_packet(my_transaction tr);
endclass

function void my_monitor::build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap=new("ap",this);
    if(!uvm_config_db #(virtual dut_if)::get(this,"","vif",vif)) begin
        `uvm_fatal(get_full_name(),"fail to get vif");
    end
endfunction

task my_monitor::main_phase(uvm_phase phase);
    wait(vif.rst_n);
    while(1) begin
        tr=new("tr");
        collection_one_packet(tr);
        ap.write(tr);
    end
endtask

task my_monitor::collection_one_packet(my_transaction tr);
    while(!vif.valid) begin
        @(posedge vif.clk);
    end
    if(vif.valid) begin
        tr.data=vif.data;
        @(posedge vif.clk);
    end
    `uvm_info(get_full_name(),"get data",UVM_MEDIUM);
endtask

`endif