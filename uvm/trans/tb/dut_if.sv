`ifndef __DUT_IF_SV__
`define __DUT_IF_SV__

interface dut_if #(
    parameter int DW=8
)(
    input wire clk,rst_n
);
    logic [DW-1:0] data;
    logic valid;
endinterface

`endif