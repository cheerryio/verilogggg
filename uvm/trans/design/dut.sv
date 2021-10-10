`timescale 1ns/10ps

module dut #(
    parameter int DW=8
)(
    input wire clk,rst_en,en,
    input wire [DW-1:0] rxd,
    input wire rx_dv,
    output logic [DW-1:0] txd,
    output logic tx_en
);
    always_ff @( posedge clk ) begin
        if(!rst_en) begin
            txd<='0;
            tx_en<='0;
        end
        else if(en) begin
            txd<=rxd;
            tx_en<=rx_dv;
        end
    end
endmodule