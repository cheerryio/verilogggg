`timescale 1ns/10ps

module ad5543_tb();
    bit aclk,areset_n;
    bit [15:0] cos;
    bit sclk,sdi,cs_n;
    bit signed [15:0] data;

    always #10 aclk=~aclk;
    initial begin
        areset_n=1'b0;
        repeat(5) @(posedge aclk);
        areset_n=1'b1;
    end

    orthDds #(32,16,13) theOrthDds_1000Hz_Inst(aclk,areset_n,1'b1,32'd85899,32'sd0,,cos);

    ad5543 #(16,48) the_ad5543_Inst (
        aclk,areset_n,
        1'b1,1'b1,,
        cos,
        sclk,sdi,cs_n
    );
    ad5543_model #(16) the_ad5543_model_Inst(
        sclk,sdi,cs_n,
        data
    );
endmodule
