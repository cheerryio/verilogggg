`timescale 1ns/10ps

module ad5543_top #(
    parameter integer DW = 16,
    parameter integer IFREQ = 96
)(
    input wire s_axis_aclk,s_axis_aresetn,
    input wire en,
    input wire s_axis_tvalid,
    output wire s_axis_tready,
    input wire [DW-1:0] s_axis_tdata,
    output wire sclk,sdi,cs_n
);
    ad5543 #(DW,IFREQ) the_ad5543_Inst(
        s_axis_aclk,s_axis_aresetn,
        en,
        s_axis_tvalid,
        s_axis_tready,
        s_axis_tdata,
        sclk,sdi,cs_n
    );
endmodule