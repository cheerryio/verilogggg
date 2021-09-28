`timescale 100ns/10ns

`include "common.sv"

interface axi_stream #(
    parameter integer DW=24
)(
    input wire s_axis_aclk,s_axis_aresetn
);
    logic valid;
    logic ready;
    logic last;
    logic signed [DW-1:0] data;
endinterface

module down_sample_tb;
import My_pkg::*;
    bit clk,rst_n;
    bit signed [23:0] cos;
    bit signed [19:0] cos1,cos2,cos3;
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
    axi_stream #(24) adc_if(clk,rst_n),v_if(clk,rst_n);
    always_ff @( posedge clk ) begin
        adc_if.valid<=v.valid;
        v_if.ready<=1'b1;
    end
    //orthDds #(32,24,13) theOrthDdsInst(clk,rst_n,adc_if.valid&adc_if.ready,32'd429496729,32'd0,,cos);
    orthDds #(32,20,13) theOrthDdsInst_10000Hz(clk,rst_n,adc_if.valid&adc_if.ready,32'd429496729,32'd0,,cos1);  ///< 10000Hz
    orthDds #(32,20,13) theOrthDdsInst_1000Hz(clk,rst_n,adc_if.valid&adc_if.ready,32'd42949672,32'd0,,cos2);   ///< 1000Hz
    orthDds #(32,20,13) theOrthDdsInst_100Hz(clk,rst_n,adc_if.valid&adc_if.ready,32'd4294967,32'd0,,cos3);    ///< 100Hz
    always_ff @( posedge clk ) begin
        if(adc_if.valid&&adc_if.ready) begin
            cos<=cos1+cos2+cos3;
        end
    end
    down_sample #(24) the_down_sample_Inst(
        clk,rst_n,
        adc_if.valid,adc_if.ready,
        cos,
        v_if.valid,v_if.ready,
        v_if.last,
        v_if.data
    );
    /*
    cic_deci_stream #(24,4,1,4) the_cic_deci_stream_Inst(
        clk,rst_n,
        adc_if.valid,adc_if.ready,cos,
        v_if.valid,v_if.ready,v_if.data
    );
    */
endmodule

module down_sample #(
    parameter integer DW=24,
    parameter integer LAST=16000
)(
    input wire clk,rst_n,
    input wire s_axis_tvalid,
    output logic s_axis_tready,
    input wire [DW-1:0] s_axis_tdata,

    output logic m_axis_tvalid,
    input wire m_axis_tready,
    output logic m_axis_tlast,
    output logic [DW-1:0] m_axis_tdata
);
    logic [$clog2(LAST)-1:0] last_cnt;
    axi_stream #(
        .DW(DW)
    )cic_fir1_if(clk,rst_n),fir1_fir2_if(clk,rst_n),
    fir2_fir3_if(clk,rst_n),fir3_fir4_if(clk,rst_n);
    cic_deci_stream #(DW,5,1,4) the_cic_deci_stream_Inst(
        clk,rst_n,
        s_axis_tvalid,s_axis_tready,
        s_axis_tdata,
        cic_fir1_if.valid,cic_fir1_if.ready,
        cic_fir1_if.data
    );
    // window kaiser beta=8 fs=4096 fc=1024 order=12
    fir_deci_stream #(DW,
    13,'{
        0.0,0.00243079,0.0,-0.03915077,0.0,0.28671006,
        0.50001983,
        0.28671006,0.0,-0.03915077,0.0,0.00243079,0.0
        },2)fir1(
            clk,rst_n,
            cic_fir1_if.valid,cic_fir1_if.ready,
            cic_fir1_if.data,
            fir1_fir2_if.valid,fir1_fir2_if.ready,
            fir1_fir2_if.data
    );
    // window kaiser beta=8 fs=2048 fc=512 order=18
    fir_deci_stream #(DW,
    19,'{
        0.00008272,0.0,-0.00297138,0.0,
        0.01820091,0.0,-0.06923229,0.0,0.30391226,
        0.50001558,
        0.30391226,0.0,-0.06923229,0.0,0.01820091,
        0.0,-0.00297138,0.0,0.00008272
        },2)fir2(
            clk,rst_n,
            fir1_fir2_if.valid,fir1_fir2_if.ready,
            fir1_fir2_if.data,
            fir2_fir3_if.valid,fir2_fir3_if.ready,
            fir2_fir3_if.data
    );
    // window kaiser beta=8 fs=1024 fc=256 order=12
    fir_deci_stream #(DW,
    27,'{
        0.00005726,0.0,-0.00096161,0.0,
        0.00452250,0.0,-0.01411732,0.0,
        0.03586591,0.0,-0.08672204,0.0,0.31134482,
        0.50002094,
        0.31134482,0.0,-0.08672204,0.0,0.03586591,
        0.0,-0.01411732,0.0,0.00452250,
        0.0,-0.00096161,0.0,0.00005726
        },2)fir3(
            clk,rst_n,
            fir2_fir3_if.valid,fir2_fir3_if.ready,
            fir2_fir3_if.data,
            fir3_fir4_if.valid,fir3_fir4_if.ready,
            fir3_fir4_if.data
    );
    // equiriple Density factor=20 fs=512 fpass=150 fstop=200 order=31
    fir_deci_stream #(DW,
    32,'{
        -0.00294735,-0.00537131,0.00316313,0.00365788,
        -0.00963999,0.00472148,0.01102961,-0.02079470,
        0.00617741,0.02699597,-0.04296176,0.00725225,
        0.06787134,-0.10892211,0.00781940,
        0.54633122,0.54633122,
        0.00781940,-0.10892211,0.06787134,
        0.00725225,-0.04296176,0.02699597,0.00617741,
        -0.02079470,0.01102961,0.00472148,-0.00963999,
        0.00365788,0.00316313,-0.00537131,-0.00294735
        },1)fir4(
            clk,rst_n,
            fir3_fir4_if.valid,fir3_fir4_if.ready,
            fir3_fir4_if.data,
            m_axis_tvalid,m_axis_tready,
            m_axis_tdata
    );
    always_ff @( posedge clk ) begin
        if(!rst_n) begin
            last_cnt<='0;
        end
        else begin
            if(last_cnt==LAST-1) begin
                last_cnt<='0;
            end
            else if(m_axis_tvalid&&m_axis_tready) begin
                last_cnt=last_cnt+1'b1;
            end
        end
    end
    assign m_axis_tlast=(last_cnt==LAST-1);
endmodule