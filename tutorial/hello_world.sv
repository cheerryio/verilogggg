`include "uvm_macros.svh"
interface dut_if;
    logic clk,rst_n;
    logic cmd;
    logic [7:0] addr;
    logic [7:0] data;
endinterface
module dut(dut_if dif);
    import uvm_pkg::*;
    always_ff @(posedge dif.clk)
    begin
        `uvm_info("",$sformatf("cmd=%b, addr=%d, data=%d",dif.cmd,dif.addr,dif.data),UVM_MEDIUM);
    end
endmodule
package my_pkg;
    import uvm_pkg::*;
    class my_transaction extends uvm_sequence_item;
        `uvm_object_utils(my_transaction);
        rand bit cmd;
        rand int addr;
        rand int data;
        constraint addr_limit {addr>=0 && addr<=255;}
        constraint data_limit {data>=0 && data<=255;}
        function new(string name="my_transaction");
            super.new(name);
        endfunction
        function string convert2string;
            return $sformatf("cmd=%b, addr=%d, data=%d",cmd,addr,data);
        endfunction
        function void do_copy(uvm_object rhs);
            my_transaction tx;
            $cast(tx,rhs);
            cmd=tx.cmd;
            addr=tx.addr;
            data=tx.data;
        endfunction
        function bit do_compare(uvm_object rhs,uvm_comparer comparer);
            my_transaction tx;
            bit status=1;
            $cast(tx,rhs);
            status &= (cmd==tx.cmd);
            status &= (addr==tx.addr);
            status &= (data==tx.data);
            return status;
        endfunction
    endclass

    typedef uvm_sequencer #(my_transaction) my_sequencer;

    class my_sequence extends uvm_sequence #(my_transaction);
        `uvm_object_utils(my_sequence);
        function new(string name="my_sequence");
            super.new(name);
        endfunction
        task body;
            if(starting_phase!=null)
                starting_phase.raise_objection(this);
            repeat(8)
            begin
                req=my_transaction::type_id::create("req");
                start_item(req);
                if(!req.randomize())
                    `uvm_error("","req randomize error");
                finish_item(req);
            end
            if(starting_phase!=null)
                starting_phase.drop_objection(this);
        endtask
    endclass
    class my_driver extends uvm_driver #(my_transaction);
        `uvm_component_utils(my_driver);
        virtual dut_if dut_vi;
        function new(string name="my_driver",uvm_component parent=null);
            super.new(name,parent);
        endfunction
        function void build_phase(uvm_phase phase);
            if(!uvm_config_db #(virtual dut_if)::get(this,"","dut_if",dut_vi))
                `uvm_error("","uvm_config_db::get fail!"); 
        endfunction
        task run_phase(uvm_phase phase);
            forever
            begin
                seq_item_port.get_next_item(req);
                @(posedge dut_vi.clk);
                dut_vi.cmd  <= req.cmd;
                dut_vi.addr <= req.addr;
                dut_vi.data <= req.data;
                seq_item_port.item_done();
            end
        endtask
    endclass
    class my_env extends uvm_env;
        `uvm_component_utils(my_env);
        my_driver m_driver;
        my_sequencer m_sequencer;
        function new(string name="my_env",uvm_component parent=null);
            super.new(name,parent);
        endfunction
        function void build_phase(uvm_phase phase);
            m_driver=my_driver::type_id::create("m_driver",this);
            m_sequencer=my_sequencer::type_id::create("m_sequencer",this);
        endfunction
        function void connect_phase(uvm_phase phase);
            m_driver.seq_item_port.connect(m_sequencer.seq_item_export);
        endfunction
    endclass
    class my_test extends uvm_test;
        `uvm_component_utils(my_test);
        my_env m_env;
        function new(string name="my_test",uvm_component parent=null);
            super.new(name,parent);
        endfunction
        function void build_phase(uvm_phase phase);
            m_env=my_env::type_id::create("m_env",this);
        endfunction
        task run_phase(uvm_phase phase);
            my_sequence seq;
            seq=my_sequence::type_id::create("seq");
            if(!seq.randomize())
                `uvm_error("","seq randomize error");
            seq.starting_phase=phase;
            seq.start(m_env.m_sequencer);
        endtask
    endclass
endpackage

module hello_world;
    import uvm_pkg::*;
    import my_pkg::*;
    dut_if dut_if1();
    dut dut1(.dif(dut_if1));
    initial begin
        dut_if1.clk=1;
        forever #50 dut_if1.clk=~dut_if1.clk;
    end
    initial begin
        uvm_config_db #(virtual dut_if)::set(null,"*","dut_if",dut_if1);
        uvm_top.finish_on_completion=1;
        run_test("my_test");
    end
endmodule