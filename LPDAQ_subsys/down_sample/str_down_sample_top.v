`timescale 1ns/10ps

module str_down_sample_top #(
    parameter integer DW=24,
    parameter integer LAST=16000
)(
    input wire clk,rst_n,
    input wire [DW-1:0] s_axis_tdata,
    input wire s_axis_tvalid,
    output wire s_axis_tready,

    output wire [DW-1:0] m_axis_tdata,
    output wire m_axis_tlast,
    output wire m_axis_tvalid,
    input wire m_axis_tready
);
    str_down_sample #(DW,LAST) the_str_down_sample_Inst(
        clk,rst_n,
        s_axis_tdata,
        s_axis_tvalid,s_axis_tready,
        m_axis_tdata,
        m_axis_tlast,
        m_axis_tvalid,m_axis_tready
    );
endmodule