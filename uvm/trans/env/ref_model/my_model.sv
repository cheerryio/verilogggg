`ifndef __MY_MODEL_SV__
`define __MY_MODEL_SV__

`include "uvm_macros.svh"
`include "../agents/my_transaction.sv"

// it receives data from DUT input monitor and sends expected data to scoreboard
class my_model extends uvm_component;
    uvm_blocking_get_port #(my_transaction) port;
    uvm_analysis_port #(my_transaction) ap;
    `uvm_component_utils(my_model);

    function new(string name="my_model",uvm_component parent=null);
        super.new(name,parent);
    endfunction

    extern virtual function void build_phase(uvm_phase phase);
    extern virtual task main_phase(uvm_phase phase);
endclass

function void my_model::build_phase(uvm_phase phase);
    super.build_phase(phase);
    port=new("port",this);
    ap=new("ap",this);
endfunction

task my_model::main_phase(uvm_phase phase);
    my_transaction tr;
    my_transaction new_tr;
    super.main_phase(phase);
    while(1) begin
        port.get(tr);
        new_tr=new("new_tr");
        new_tr.copy(tr);
        ap.write(new_tr);
        `uvm_info(get_full_name(),"send to scoreboard",UVM_MEDIUM);
    end
endtask
`endif