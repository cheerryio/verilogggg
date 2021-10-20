`timescale 1ns/10ps

module str_deci #(
    parameter integer DW=10,
    parameter integer DECI=5
)(
    input wire clk,rst_n,
    input wire signed [DW-1:0] in,
    input wire ivalid,
    output logic iready,
    output logic signed [DW-1:0] out,
    output logic ovalid,
    input wire oready
);
    wire ish,osh;
    logic signed [DW-1:0] candi;
    logic co;
    counter #(DECI) the_counter_W(clk,rst_n,ish,co);
    assign ish=ivalid&iready;
    assign osh=ovalid&oready;
    assign iready=osh|~ovalid;
    always_ff @( posedge clk ) begin
        if(!rst_n) begin
            ovalid<=1'b0;
        end
        else begin
            if(co) begin
                ovalid<=1'b1;
            end
            else if(osh) begin
                ovalid<=1'b0;
            end
        end
    end
    always_ff@(posedge clk) begin
        if(!rst_n) begin
            candi<='0;
        end
        else if(ish) begin
            candi<=in;
        end
        else if(osh) begin
            candi<='0;
        end
    end
    always_ff@(posedge clk) begin
        if(!rst_n) begin
            out<='0;
        end
        else if(co) begin
            out<=candi;
        end
    end

    property check_deci;
        int LCount;
        @(posedge clk) disable iff(!rst_n)
        (
            (osh,LCount=0) ##1
            (ish,LCount=LCount+1)[*0:DECI] ##1 (LCount==DECI-1) |-> (osh)
        );
    endproperty
    assert property(check_deci);
endmodule