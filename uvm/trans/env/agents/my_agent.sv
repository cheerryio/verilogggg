`ifndef __MY_AGENT_SV__
`define __MY_AGENT_SV__

`include "uvm_macros.svh"
`include "../agents/my_driver.sv"
`include "../agents/my_monitor.sv"
`include "../agents/my_sequencer.sv"
import uvm_pkg::*;

class my_agent extends uvm_agent;
    my_driver drv;
    my_monitor mon;
    my_sequencer sqr;
    uvm_analysis_port #(my_transaction) ap;
    `uvm_component_utils(my_agent);

    function new(string name="my_agent",uvm_component parent=null);
        super.new(name,parent);
    endfunction

    extern virtual function void build_phase(uvm_phase phase);
    extern virtual function void connect_phase(uvm_phase phase);
endclass

function void my_agent::build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(is_active==UVM_ACTIVE) begin
        sqr=my_sequencer::type_id::create("sqr",this);
        drv=my_driver::type_id::create("drv",this);
    end
    mon=my_monitor::type_id::create("mon",this);
endfunction

function void my_agent::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if(is_active==UVM_ACTIVE) begin
        drv.seq_item_port.connect(sqr.seq_item_export);
    end
    ap=mon.ap;
endfunction

`endif