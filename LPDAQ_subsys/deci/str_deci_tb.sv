`timescale 1ns/10ps

module str_deci_tb();
    bit clk,rst_n;
    localparam int STG = 2;
    initial begin
        forever begin
            #5 clk=~clk;
        end
    end
    initial begin
        rst_n=1'b0;
        #50;
        rst_n=1'b1;
    end
    bit [31:0] in,out;
    bit valid[STG+1];
    bit ready[STG+1];
    initial begin
        valid[0]=1'b1;
        ready[STG]=1'b1;
    end
    always_ff @( posedge clk ) begin
        if(!rst_n) begin
            in<='0;
        end
        else begin
            in=in+1'b1;
        end
    end
    str_deci #(32,5) the_str_deci_Inst1(
        clk,rst_n,
        in,
        valid[0],ready[0],
        out,
        valid[1],ready[1]
    );
    str_deci #(32,6) the_str_deci_Inst2(
        clk,rst_n,
        in,
        valid[1],ready[1],
        out,
        valid[2],ready[2]
    );
    property check_deci;
        int LCount;
        @(posedge clk) disable iff(!rst_n)
        (
            (valid[STG]&ready[STG],LCount=0) ##1
            (valid[0]&ready[0],LCount=LCount+1)[*0:30] ##1 (LCount==30-1) |-> (valid[STG]&ready[STG])
        );
    endproperty
    assert property(check_deci);
endmodule