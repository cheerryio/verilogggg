`timescale 1ns/10ps

module ads127l01_top #(
    parameter integer DW=24,
    parameter integer LAST=10240
)(
    input wire clk,rst_n,en,
    output wire fsmode,
    output wire format,
    output wire reset_n,
    output wire [1:0] osr,
    output wire [1:0] filter,
    output wire hr,
    output wire start,
    output wire din,
    output wire cs_n,
    output wire daisy_in,
    input wire sck,
    input wire dout,
    input wire fsync,
    output wire m_axis_tvalid,
    input  wire  m_axis_tready,
    output wire m_axis_tlast,
    output wire [DW-1:0] m_axis_tdata,
    output wire high
);
    ads127l01 #(DW,LAST) ads127l01_Inst(
        clk,rst_n,en,
        fsmode,format,reset_n,osr,filter,
        hr,start,
        din,cs_n,daisy_in,
        sck,dout,fsync,
        m_axis_tvalid,m_axis_tready,
        m_axis_tlast,
        m_axis_tdata,
        high
    );
endmodule
