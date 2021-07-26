
`timescale 1ns/10ps

module xor_tb;
    logic [9:0] A0,A1;
    logic [9:0] C0,C1;
    xorf #(10) theXorfInst0(A0,1'b0,C0);
    xorf #(10) theXorfInst1(A1,1'b1,C1);
    initial begin
        A0=10'd1023;
        A1=10'd0;
        #10;
        $display("C0=%d",C0);
        $display("C1=%d",C1);
    end
endmodule

module xorf #(
    parameter integer DW=10
)(
    input wire [DW-1:0] A,
    input wire B,
    output logic [DW-1:0] C
);
    assign C=A^({DW{B}});
endmodule