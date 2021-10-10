`ifndef __MY_SEQUENCER_SV__
`define __MY_SEQUENCER_SV__

`include "uvm_macros.svh"
`include "./my_transaction.sv"
import uvm_pkg::*;

class my_sequencer extends uvm_sequencer #(my_transaction);
    `uvm_component_utils(my_sequencer);
    function new(string name="my_sequencer",uvm_component parent=null);
        super.new(name,parent);
    endfunction

endclass
`endif