`timescale 1ns/10ps

module pcf8563_if_top #(
    parameter integer DIV=500,
    parameter integer GAP=100000000
)(
    input wire clk,rst_n,en,
    input wire start,
    output wire [7:0] rdata,
    output wire done,

    (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 IIC SCL_I" *)
    input wire scl_i,
    (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 IIC SCL_O" *)
    output wire scl_o,
    (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 IIC SCL_T" *)
    output wire scl_t,
    (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 IIC SDA_I" *)
    input wire sda_i,
    (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 IIC SDA_O" *)
    output wire sda_o,
    (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 IIC SDA_T" *)
    output wire sda_t
);
    pcf8563_if #(.DIV(DIV),.GAP(GAP)) the_pcf8563_if_Inst(
        clk,rst_n,en,
        start,
        rdata,
        done,
        scl_i,scl_o,scl_t,
        sda_i,sda_o,sda_t
    );
endmodule