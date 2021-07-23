`include "uvm_pkg.sv"
module hello_world_example;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    shortint var_a;
    int var_b;
    longint var_c;
    initial begin
        `uvm_info("INFO","hello verilog",UVM_LOW);
    end
    initial begin
        $display("var_a:%d bits, var_b:%d bits, var_c:%d bits",$bits(var_a),$bits(var_b),$bits(var_c));
        #1;
        var_a='h7fff;
        var_b='h7fff_ffff;
        var_c='h7fff_ffff_ffff_ffff;
        #1;
        var_a+=1;var_b+=1;var_c+=1;
    end
    initial begin
        //$monitor("var_a:%d, var_b:%d, var_c:%d",var_a,var_b,var_c);
    end
    initial begin
        automatic string dialog="Hello!";
        string num;
        $display("%s",dialog);
        foreach(dialog[i]) begin
            //$display("%s",{5{dialog[i]}});
        end
        num.bintoa(5'b01111);
        $display("bintoa:%s",num);
        num.itoa(314);
        $display("itoa:%s",num);
    end
    initial begin
        typedef enum {BLACK[3:5]=4} color_set;
        color_set color;
        color=BLACK5;$display("color:%d, name:%s",color,color.name());
        // enum strict type checking
        // invalid because of type checking
        //color=4;
        // valid due to type cast
        color=color_set'(4);$display("color:%d, name:%s",color,color.name());
    end
    initial begin
        bit clk;
        int counter;
        while(counter<10) begin
            counter++;
            $display("counter:%0d",counter);
        end
        forever #50 clk=~clk;
    end
    event event_a;
    initial begin
        #20;->event_a;
    end
    initial begin
        $display("[%0t] wait for event_a to trigger A",$time);
        @(event_a);
        $display("[%0t] event_a triggered A",$time);
    end
    initial begin
        $display("[%0t] wait for event_a to trigger B",$time);
        wait(event_a.triggered);
        $display("[%0t] event_a triggered B",$time);
    end
endmodule:hello_world_example