`timescale 100ns/10ns
`include "common.sv"

module fir_deci_stream_tb;
import My_pkg::*;
    bit clk,rst_n;
    bit s_axis_tvalid,s_axis_tready;
    bit m_axis_tvalid,m_axis_tready;
    bit signed [23:0] sin,cos;
    bit signed [23:0] out;
    MyValid v;
    initial begin
        forever #5 clk=~clk;
    end
    initial begin
        rst_n=1'b0;
        #50;
        rst_n=1'b1;
    end
    initial begin
        v=new;
        #25;
        @(posedge clk);
        forever begin
            @(posedge clk);
            v.randomize();
        end
    end
    initial begin
        m_axis_tready=1'b1;
    end
    always_ff @( posedge clk ) begin
        s_axis_tvalid<=v.valid;
    end
    orthDds #(32,24,13) theOrthDdsInst(clk,rst_n,s_axis_tvalid&s_axis_tready,32'd858993459,32'd0,sin,cos);
    fir_deci_stream #(
        24,13,
        '{-0.022595,-0.052253,-0.042290,0.031868,0.154701,
        0.271103,0.318932,0.271103,0.154701,0.031868,
        -0.042290,-0.052253,-0.022595},
        /*2*/1
    )the_fir_deci_stream_Inst(
        clk,rst_n,
        s_axis_tvalid,s_axis_tready,cos,
        m_axis_tvalid,m_axis_tready,out
    );
endmodule

module fir_deci_stream #(
    parameter integer DW = 24,
    parameter integer TAPS = 8,
    parameter real COEF[TAPS] = '{TAPS{0.124}},
    parameter integer DECI = 2
)(
    input wire clk,rst_n,
    input wire s_axis_tvalid,
    output logic s_axis_tready,
    input wire [DW-1:0] s_axis_tdata,

    output logic m_axis_tvalid,
    input wire m_axis_tready,
    output logic [DW-1:0] m_axis_tdata
);
    logic s_en,m_en;
    logic co_deci;
    assign s_en=s_axis_tvalid&s_axis_tready;
    assign m_en=m_axis_tvalid&m_axis_tready;
    counter #(DECI) the_deci_counter(clk,rst_n,s_en,co_deci);
    fir #(DW,TAPS,COEF) theFir_Inst(
        clk,rst_n,s_en,
        s_axis_tdata,
        m_axis_tdata
    );
    /// drive s_axis_tready and m_axis_tvalid
    always_ff @( posedge clk ) begin
        if(!rst_n) begin
            m_axis_tvalid<=1'b0;
        end
        else begin
            if(co_deci) begin
                m_axis_tvalid<=1'b1;
            end
            else if(m_en) begin
                m_axis_tvalid<=1'b0;
            end
        end
    end
    assign s_axis_tready=~(m_axis_tvalid&~m_axis_tready);
endmodule

