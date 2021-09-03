`timescale 1ns/10ps

module data_diff_tb;
    bit clk,rst_n;
    initial begin
        forever #5 clk=~clk;
    end
    initial begin
        rst_n=1'b0;
        #30;
        rst_n=1'b1;
    end
    bit signed [23:0] sin;
    orthDds #(32,24,13) theOrthDds_1000Hz_Inst(clk,rst_n,1'b1,32'd85899,32'sd0,,);
    initial begin
        #50;
        sin=32'd1;
        #50;
        sin=32'd95899;
        #50;
        sin=32'd1;
        #50;
        sin=-32'sd1;
    end
    data_diff #(24) thedata_diff_tb_Inst(clk,rst_n,1'b1,32'd85899,sin);
endmodule

module data_diff #(
    parameter integer DW = 24
)(
    input wire clk,rst_n,en,
    input wire signed [DW-1:0] threshold,
    (*mark_debug="true"*) input wire signed [DW-1:0] data,
    (*mark_debug="true"*) output logic co
);
    (*mark_debug="true"*) logic signed [DW-1:0] last_data;
    always_ff @( posedge clk ) begin
        if(!rst_n) begin
            last_data<='0;
        end
        else if(en) begin
            last_data<=data;
        end
    end
    assign co=(data-last_data)>threshold;
endmodule