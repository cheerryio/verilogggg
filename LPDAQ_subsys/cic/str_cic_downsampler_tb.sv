`timescale 1ns/10ps

module str_cic_downsampler_tb();
    bit clk,rst_n;
    bit signed [31:0] cos;
    bit [31:0] in,out;
    bit ivalid,iready,ovalid,oready;
    initial begin
        forever #5 clk=~clk;
    end
    initial begin
        rst_n=1'b0;
        #50;
        rst_n=1'b1;
    end
    initial begin
        ivalid=1'b1;
        oready=1'b1;
    end
    always_ff @( posedge clk ) begin
        if(!rst_n) begin
            in<='0;
        end
        else begin
            in=in+1'b1;
        end
    end
    orthDds #(32,32,13) theOrthDdsInst_10000Hz(clk,rst_n,ivalid,32'd42949672,32'd0,,cos);  ///< 10000Hz
    str_cic_downsampler #(32,4,1,4) the_str_cic_downsampler_Inst(
        clk,rst_n,
        in,
        ivalid,iready,
        out,
        ovalid,oready
    );
endmodule