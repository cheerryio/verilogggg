`ifndef __MY_ENV_SV__
`define __MY_ENV_SV__

`include "uvm_macros.svh"
`include "../agents/my_driver.sv"
`include "../agents/my_monitor.sv"
`include "../agents/my_agent.sv"
`include "../agents/my_transaction.sv"
`include "../agents/my_scoreboard.sv"
`include "../ref_model/my_model.sv"
import uvm_pkg::*;

class my_env extends uvm_env;
    my_agent i_agt,o_agt;
    my_model mdl;
    my_scoreboard scb;
    uvm_tlm_analysis_fifo #(my_transaction) agt_mdl_fifo;
    uvm_tlm_analysis_fifo #(my_transaction) mdl_scb_fifo;
    uvm_tlm_analysis_fifo #(my_transaction) agt_scb_fifo;
    `uvm_component_utils(my_env);

    function new(string name="my_env",uvm_component parent=null);
        super.new(name,parent);
    endfunction

    extern virtual function void build_phase(uvm_phase phase);
    extern virtual function void connect_phase(uvm_phase phase);
endclass

function void my_env::build_phase(uvm_phase phase);
    super.build_phase(phase);
    i_agt=my_agent::type_id::create("i_agt",this);
    o_agt=my_agent::type_id::create("o_agt",this);
    i_agt.is_active=UVM_ACTIVE;
    o_agt.is_active=UVM_PASSIVE;
    mdl=my_model::type_id::create("mdl",this);
    scb=my_scoreboard::type_id::create("scb",this);
    agt_mdl_fifo=new("agt_mdl_fifo",this);
    mdl_scb_fifo=new("mdl_scb_fifo",this);
    agt_scb_fifo=new("agt_scb_fifo",this);
endfunction

function void my_env::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    i_agt.mon.ap.connect(agt_mdl_fifo.analysis_export);
    mdl.port.connect(agt_mdl_fifo.blocking_get_export);
    mdl.ap.connect(mdl_scb_fifo.analysis_export);
    scb.expected_port.connect(mdl_scb_fifo.blocking_get_export);
    o_agt.mon.ap.connect(agt_scb_fifo.analysis_export);
    scb.actual_port.connect(agt_scb_fifo.blocking_get_export);
endfunction

`endif