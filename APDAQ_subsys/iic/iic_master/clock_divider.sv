`timescale 1ns/10ps


module clock_divider #(
    parameter int DIV=500
)(
    input wire clk,rst_n,en,
    output logic clk0,
    output logic high_mid,low_mid,
    output logic fall
);
    parameter int DIV_SEL0=(DIV>>1)-1;              // all mid
    parameter int DIV_SEL1=(DIV>>2)-1;              // high mid
    parameter int DIV_SEL2=(DIV_SEL0+DIV_SEL1)+1;   // low mid
    parameter int DIV_SEL3=(DIV>>1)+1;              // fall
    logic [$clog2(DIV)-1:0] cnt;
    always_ff @( posedge clk ) begin
        if(!rst_n) begin
            cnt<='0;
        end
        else if(en) begin
            if(cnt<DIV-1) begin
                cnt<=cnt+1'b1;
            end
            else begin
                cnt<='0;
            end
        end
    end
    assign clk0=cnt<=DIV_SEL0?1'b1:1'b0;
    assign high_mid=(cnt==DIV_SEL1);
    assign low_mid=(cnt==DIV_SEL2);
    assign fall=(cnt==DIV_SEL3);
endmodule