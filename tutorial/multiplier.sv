`include "uvm_macros.svh"

`define DATA_WIDTH 8
interface mul_if #(
    parameter integer DW=8
);
    logic clk,rst_n,en;
    logic [DW-1:0] A,B;
    logic [2*DW-1:0] C;
endinterface
package mul_pkg;
import uvm_pkg::*;
    class mul_item extends uvm_sequence_item;
        rand bit [`DATA_WIDTH-1:0] A;
        rand bit [`DATA_WIDTH-1:0] B;
        bit [2*`DATA_WIDTH:0] C;
    
        `uvm_object_utils_begin(mul_item)
            `uvm_field_int(A,UVM_DEFAULT)
            `uvm_field_int(B,UVM_DEFAULT)
            `uvm_field_int(C,UVM_DEFAULT)
        `uvm_object_utils_end
    
        function new(string name="mul_item");
            super.new(name);
        endfunction

        virtual function string convert2str();
            return $sformatf("A=%d, B=%d, C=%d",A,B,C);
        endfunction
    endclass

    class mul_driver extends uvm_driver #(mul_item);
        `uvm_component_utils(mul_driver)
        virtual mul_if mvif;

        function new(string name="mul_driver",uvm_component parent);
            super.new(name,parent);
        endfunction

        virtual function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            if(!uvm_config_db #(virtual mul_if)::get(this,"","mul_if",mvif))
                `uvm_fatal("DRV","cant get virtual mul_if")
        endfunction

        virtual task run_phase(uvm_phase phase);
            super.run_phase(phase);
            forever begin
                mul_item item;
                `uvm_info(this.get_type_name(),$sformatf("waiting for item from sequence"),UVM_MEDIUM)
                seq_item_port.get_next_item(item);
                this.drive_item(item);
                seq_item_port.item_done();
            end
        endtask

        virtual task drive_item(mul_item item);
            @(posedge mvif.clk);
            mvif.rst_n<=1'b1;
            mvif.en<=1'b1;
            mvif.A<=item.A;
            mvif.B<=item.B;
        endtask
    endclass

    class mul_monitor extends uvm_monitor;
        `uvm_component_utils(mul_monitor)
        uvm_analysis_port #(mul_item) mul_analysis_port;
        virtual mul_if mvif;

        function new(string name="mul_monitor",uvm_component parent);
            super.new(name,parent);
        endfunction

        virtual function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            mul_analysis_port=new("mul_analysis_port",this);
            if(!uvm_config_db #(virtual mul_if)::get(this,"","mul_if",mvif))
                `uvm_fatal(this.get_type_name(),"cant get vitual mul_if")
        endfunction

        virtual task run_phase(uvm_phase phase);
            super.run_phase(phase);
            forever begin
                @(posedge mvif.clk);
                if(1) begin
                    mul_item item=new;
                    item.A=mvif.A;
                    item.B=mvif.B;
                    item.C=mvif.C;
                    `uvm_info(this.get_type_name(),$sformatf("monitor finds packet"),UVM_MEDIUM);
                    mul_analysis_port.write(item); 
                end
            end
        endtask
    endclass

    class mul_agent extends uvm_agent;
        `uvm_component_utils(mul_agent)

        uvm_sequencer #(mul_item) s0;
        mul_driver d0;
        mul_monitor m0;

        function new(string name="mul_agent",uvm_component parent=null);
            super.new(name,parent);
        endfunction

        virtual function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            s0=uvm_sequencer #(mul_item)::type_id::create("s0",this);
            m0=mul_monitor::type_id::create("m0",this);
            d0=mul_driver::type_id::create("d0",this);
        endfunction

        virtual function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            d0.seq_item_port.connect(s0.seq_item_export);
        endfunction
    endclass

    class mul_scoreboard extends uvm_scoreboard;
        `uvm_component_utils(mul_scoreboard)
        uvm_analysis_imp #(mul_item,mul_scoreboard) mul_analysis_imp;
        function new(string name="mul_scoreboard",uvm_component parent);
            super.new(name,parent);
        endfunction

        virtual function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            mul_analysis_imp=new("mul_analysis_imp",this);
        endfunction

        virtual function write(mul_item item);
            `uvm_info(this.get_type_name(),$sformatf("%s",item.convert2str()),UVM_MEDIUM);
        endfunction
    endclass

    class mul_env extends uvm_env;
        `uvm_component_utils(mul_env)

        mul_agent a0;
        mul_scoreboard sb0;

        function new(string name="mul_env",uvm_component parent);
            super.new(name,parent);
        endfunction

        virtual function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            a0=mul_agent::type_id::create("a0",this);
            sb0=mul_scoreboard::type_id::create("sb0",this);
        endfunction

        virtual function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            a0.m0.mul_analysis_port.connect(sb0.mul_analysis_imp);
        endfunction
    endclass

    class mul_seq extends uvm_sequence;
        `uvm_object_utils(mul_seq);
        function new(string name="mul_seq");
            super.new(name);
        endfunction
        
        int num=10;
        virtual task body;
            for(int i=0;i<num;i++) begin
                mul_item item=mul_item::type_id::create("item");
                start_item(item);
                item.randomize();
                finish_item(item);
            end
            `uvm_info(this.get_type_name(),$sformatf("finish generating item %0d times",num),UVM_MEDIUM);
        endtask
    endclass

    class mul_test extends uvm_test;
        `uvm_component_utils(mul_test)

        mul_env e0;

        function new(string name="mul_test",uvm_component parent);
            super.new(name,parent);
        endfunction

        virtual function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            e0=mul_env::type_id::create("e0",this);
        endfunction

        virtual task run_phase(uvm_phase phase);
            mul_seq seq=mul_seq::type_id::create("seq");
            phase.raise_objection(this);
            seq.start(e0.a0.s0);
            phase.drop_objection(this);
        endtask
    endclass
endpackage

module mul_tb;
import uvm_pkg::*;
import mul_pkg::*;
    mul_if #(`DATA_WIDTH) mif();
    initial begin
        mif.clk=0;
        forever #50 mif.clk=~mif.clk;
    end
    initial begin
        uvm_config_db #(virtual mul_if)::set(null,"*","mul_if",mif);
        uvm_top.finish_on_completion=1;
        run_test("mul_test");
    end
    mul themulTbInst(.mif(mif));
endmodule

module mul(mul_if mif);
    assign mif.C=mif.A*mif.B;
endmodule