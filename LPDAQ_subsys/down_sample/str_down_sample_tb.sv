`timescale 1ns/10ps
`include "../common.sv"

module str_down_sample_tb();
    bit clk,rst_n;
    bit signed [23:0] cos;
    bit signed [19:0] cos1,cos2,cos3;
    initial begin
        forever #5 clk=~clk;
    end
    initial begin
        rst_n=1'b0;
        #50;
        rst_n=1'b1;
    end
    axi_stream_proto #(24) adc_if(clk,rst_n),v_if(clk,rst_n);
    always_ff @( posedge clk ) begin
        v_if.ready<=1'b1;
    end
    counter #(195) the_counter_512000(clk,rst_n,1'b1,adc_if.valid);
    orthDds #(32,20,13) theOrthDdsInst_10000Hz(clk,rst_n,1'b1,32'd429496,32'd0,,cos1);  ///< 10000Hz
    orthDds #(32,20,13) theOrthDdsInst_1000Hz(clk,rst_n,1'b1,32'd42949,32'd0,,cos2);   ///< 1000Hz
    orthDds #(32,20,13) theOrthDdsInst_100Hz(clk,rst_n,1'b1,32'd4294,32'd0,,cos3);    ///< 100Hz
    always_ff @( posedge clk ) begin
        if(adc_if.valid&&adc_if.ready) begin
            cos<=cos1+cos2+cos3;
        end
    end
    str_down_sample #(.DW(24),.LAST(10)) the_str_down_sample_Inst(
        clk,rst_n,
        cos,
        adc_if.valid,adc_if.ready,
        v_if.data,
        v_if.last,
        v_if.valid,v_if.ready
    );
endmodule