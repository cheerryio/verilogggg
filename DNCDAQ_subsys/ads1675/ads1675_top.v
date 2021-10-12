`timescale 1ns/10ps

module ads1675_top #(
    parameter integer DW=24,
    parameter integer SDW=48,
    parameter integer DROP=50
)(
    (*dont_touch="yes",iob="true"*) input wire sclk_p,
    (*dont_touch="yes",iob="true"*) input wire sclk_n,
    (*dont_touch="yes",iob="true"*) input wire drdy_p,
    (*dont_touch="yes",iob="true"*) input wire drdy_n,
    (*dont_touch="yes",iob="true"*) input wire dout_p,
    (*dont_touch="yes",iob="true"*) input wire dout_n,
    output wire sclk,
    input wire rst_n,en,
    // configure
    output wire dr0,dr1,dr2,
    output wire fpath,ll_cfg,lvds,clk_sel,
    // control
    output wire cs_n,start,pown,
    output wire signed [DW-1:0] data,
    output wire valid
);
    ads1675_source_32M_sample_rate_2M #(.DW(DW),.SDW(48),.DROP(50))
    the_ads1675_source_32M_sample_rate_2M_Inst(
        sclk_p,sclk_n,
        drdy_p,drdy_n,
        dout_p,dout_n,
        sclk,rst_n,en,
        dr0,dr1,dr2,
        fpath,ll_cfg,lvds,clk_sel,
        cs_n,start,pown,
        data,
        valid
    );
endmodule