`timescale 100ns/10ns

class MyValid;
    rand bit valid;
    constraint my_valid_constraint {valid dist{0:=5,1:=95};}
endclass

module cic_deci_stream_tb;
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
    cic_deci_stream #(24,4,1,4) the_cic_deci_stream_Inst(
        clk,rst_n,
        s_axis_tvalid,s_axis_tready,cos,
        m_axis_tvalid,m_axis_tready,out
    );
endmodule

module cic_deci_stream #(
    parameter integer DW = 24,
    parameter integer R = 125,
    parameter integer M = 1,
    parameter integer N = 4
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
    counter #(R) the_deci_counter(clk,rst_n,s_en,co_deci);
    cicDownSampler #(DW,R,M,N) the_cic_Inst(
        clk,rst_n,s_en,m_en,
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