`ifndef __MY_SCOREBOARD_SV__
`define __MY_SCOREBOARD_SV__

`include "uvm_macros.svh"
`include "./my_transaction.sv"

class my_scoreboard extends uvm_scoreboard;
    uvm_blocking_get_port #(my_transaction) expected_port;
    uvm_blocking_get_port #(my_transaction) actual_port;
    my_transaction expected_tr,actual_tr;
    `uvm_component_utils(my_scoreboard);

    function new(string name="my_scoreboard",uvm_component parent=null);
        super.new(name,parent);
    endfunction

    extern virtual function void build_phase(uvm_phase phase);
    extern virtual task main_phase(uvm_phase phase);
endclass

function void my_scoreboard::build_phase(uvm_phase phase);
    super.build_phase(phase);
    expected_port=new("expected_port",this);
    actual_port=new("actual_port",this);
endfunction

task my_scoreboard::main_phase(uvm_phase phase);
    fork
        begin
            while(1) begin
                expected_port.get(expected_tr);
                `uvm_info(get_full_name(),"get expected transaction",UVM_MEDIUM);
            end
        end
        begin
            while(1) begin
                actual_port.get(actual_tr);
                `uvm_info(get_full_name(),"get actual transaction",UVM_MEDIUM);
            end
        end
    join
endtask

`endif