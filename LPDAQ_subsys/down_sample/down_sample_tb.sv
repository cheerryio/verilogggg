`timescale 1ns/10ps

module down_sample_tb();
    bit clk,rst_n;
    bit signed [23:0] in,out;
    bit signed [19:0] cos1,cos2,cos3;
    logic en512000;
    logic valid;
    initial begin
        forever #5 clk=~clk;    ///< 100MHz clk
    end
    initial begin
        rst_n=1'b0;
        #50;
        rst_n=1'b1;
    end
    counter #(195) the_counter_512000(clk,rst_n,1'b1,en512000);
    //orthDds #(32,24,13) theOrthDdsInst(clk,rst_n,adc_if.valid&adc_if.ready,32'd429496729,32'd0,,cos);
    orthDds #(32,20,13) theOrthDdsInst_10000Hz(clk,rst_n,1'b1,32'd429496,32'd0,,cos1);  ///< 10000Hz
    orthDds #(32,20,13) theOrthDdsInst_1000Hz(clk,rst_n,1'b1,32'd42949,32'd0,,cos2);   ///< 1000Hz
    orthDds #(32,20,13) theOrthDdsInst_100Hz(clk,rst_n,1'b1,32'd4294,32'd0,,cos3);    ///< 100Hz
    always_ff @( posedge clk ) begin
        in<=cos1+cos2+cos3;
    end
    down_sample #(24) the_down_sample_Inst(
        clk,rst_n,
        en512000,in,
        valid,out
    );
endmodule