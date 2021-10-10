`ifndef __BASIC_TEST_SV__
`define __BASIC_TEST_SV__

`include "uvm_macros.svh"
`include "../sequence/my_sequence.sv"
`include "../env/top/my_env.sv"
import uvm_pkg::*;

class basic_test extends uvm_test;
    my_sequence seq;
    my_env env;
    `uvm_component_utils(basic_test);

    function new(string name="basic_test",uvm_component parent=null);
        super.new(name,parent);
    endfunction

    extern virtual function void build_phase(uvm_phase phase);
    extern virtual task main_phase(uvm_phase phase);
endclass

function void basic_test::build_phase(uvm_phase phase);
    super.build_phase(phase);
    seq=my_sequence::type_id::create("seq",this);
    env=my_env::type_id::create("env",this);
endfunction

task basic_test::main_phase(uvm_phase phase);
    phase.raise_objection(this);
    seq.start(env.i_agt.sqr);
    #1000;
    phase.drop_objection(this);
endtask

`endif