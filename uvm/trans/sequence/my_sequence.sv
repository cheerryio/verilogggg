`ifndef __MY_SEQUENCE_SV__
`define __MY_SEQUENCE_SV__

`include "uvm_macros.svh"
`include "../env/agents/my_transaction.sv"
import uvm_pkg::*;

class my_sequence extends uvm_sequence #(my_transaction);
    my_transaction tr;
    `uvm_object_utils(my_sequence);

    function new(string name="my_sequence");
        super.new(name);
    endfunction

    extern virtual task body();
endclass

task my_sequence::body();
    repeat(10) begin
        tr=new("tr");
        assert(tr.randomize());
        `uvm_do(tr);
    end
endtask

`endif