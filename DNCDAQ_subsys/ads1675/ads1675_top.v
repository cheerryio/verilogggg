`timescale 1ns/10ps

module ads1675_top #(
    parameter integer DW=32,
    parameter integer SDW=48,
    parameter integer LAST=20000
)(
    (* X_INTERFACE_INFO = "xilinx.com:interface:diff_clock:1.0 SCLK CLK_P" *)
    (* X_INTERFACE_PARAMETER = "FREQ_HZ 96000000" *)
    input wire SCLK_clk_p,
    (* X_INTERFACE_INFO = "xilinx.com:interface:diff_clock:1.0 SCLK CLK_N" *)
    input wire SCLK_clk_n,
    (* X_INTERFACE_INFO = "xilinx.com:interface:diff_analog_io:1.0 DRDY V_P" *)
    input wire DRDY_v_p,
    (* X_INTERFACE_INFO = "xilinx.com:interface:diff_analog_io:1.0 DRDY V_N" *)
    input wire DRDY_v_n,
    (* X_INTERFACE_INFO = "xilinx.com:interface:diff_analog_io:1.0 DOUT V_P" *)
    input wire DOUT_v_p,
    (* X_INTERFACE_INFO = "xilinx.com:interface:diff_analog_io:1.0 DOUT V_N" *)
    input wire DOUT_v_n,

    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 SCLK_clk_p CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF m_axis, ASSOCIATED_RESET rst_n, FREQ_HZ 96000000" *)
    output wire sclk,
    input wire rst_n,external_en,
    // configure
    output wire [2:0] dr,
    output wire fpath,ll_cfg,lvds,clk_sel,
    // control
    output wire cs_n,start,pown,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis TREADY" *)
    input wire m_axis_tready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis TVALID" *)
    output wire m_axis_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis TLAST" *)
    output wire m_axis_tlast,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis TDATA" *)
    output wire signed [DW-1:0] m_axis_tdata
);
    ads1675_source_32M_sample_rate_2M #(.DW(DW),.SDW(48),.LAST(LAST))
    the_ads1675_source_32M_sample_rate_2M_Inst(
        SCLK_clk_p,SCLK_clk_n,
        DRDY_v_p,DRDY_v_n,
        DOUT_v_p,DOUT_v_n,
        sclk,rst_n,external_en,
        dr,
        fpath,ll_cfg,lvds,clk_sel,
        cs_n,start,pown,
        m_axis_tready,m_axis_tvalid,
        m_axis_tlast,
        m_axis_tdata
    );
endmodule