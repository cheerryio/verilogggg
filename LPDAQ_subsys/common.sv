package My_pkg;
    class MyStream;
        rand bit valid;
        rand bit ready;
        constraint my_valid_constraint {valid dist{0:=50,1:=50};}
        constraint my_ready_constraint {ready dist{0:=5,1:=95};}
    endclass
endpackage

interface axi_stream_proto #(
    parameter integer DW=24
)(
    input wire clk,rst_n
);
    logic valid;
    logic ready;
    logic last;
    logic signed [DW-1:0] data;
endinterface