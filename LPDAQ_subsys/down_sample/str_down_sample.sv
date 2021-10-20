`timescale 1ns/10ps

`include "../common.sv"

module str_down_sample #(
    parameter integer DW=24,
    parameter integer LAST=16000
)(
    input wire clk,rst_n,
    input wire signed [DW-1:0] s_axis_tdata,
    input wire s_axis_tvalid,
    output logic s_axis_tready,

    (*mark_debug="true"*) output logic signed [DW-1:0] m_axis_tdata,
    output logic m_axis_tlast,
    (*mark_debug="true"*) output logic m_axis_tvalid,
    input wire m_axis_tready
);
    logic [$clog2(LAST)-1:0] last_cnt;
    axi_stream_proto #(
        .DW(DW)
    )st_if(clk,rst_n),ed_if(clk,rst_n),
    cic_slice_if(clk,rst_n),slice_fir1_if(clk,rst_n),
    fir1_deci1_if(clk,rst_n),deci1_fir2_if(clk,rst_n),
    fir2_deci2_if(clk,rst_n),deci2_fir3_if(clk,rst_n),
    fir3_deci3_if(clk,rst_n),deci3_fir4_if(clk,rst_n);
    assign st_if.data=s_axis_tdata;
    assign st_if.valid=s_axis_tvalid;
    assign s_axis_tready=st_if.ready;
    assign m_axis_tdata=ed_if.data;
    assign m_axis_tlast=ed_if.last;
    assign m_axis_tvalid=ed_if.valid;
    assign ed_if.ready=m_axis_tready;
    str_cic_downsampler #(DW,125,1,4) the_str_cic_downsampler_Inst(
        clk,rst_n,
        st_if.data,
        st_if.valid,st_if.ready,
        cic_slice_if.data,
        cic_slice_if.valid,cic_slice_if.ready
    );
    str_reg_slice #(24) the_str_reg_slice_Inst(
        clk,rst_n,
        cic_slice_if.data,1'b0,
        cic_slice_if.valid,cic_slice_if.ready,
        slice_fir1_if.data,slice_fir1_if.last,
        slice_fir1_if.valid,slice_fir1_if.ready
    );
    // window kaiser beta=8 fs=4096 fc=1024 order=12
    str_fir #(DW,13,'{
        0.0,0.00243079,0.0,-0.03915077,0.0,0.28671006,
        0.50001983,
        0.28671006,0.0,-0.03915077,0.0,0.00243079,0.0
        })the_str_fir1(
            clk,rst_n,
            slice_fir1_if.data,
            slice_fir1_if.valid,slice_fir1_if.ready,
            fir1_deci1_if.data,
            fir1_deci1_if.valid,fir1_deci1_if.ready
    );
    str_deci #(DW,2) the_str_deci1(
        clk,rst_n,
        fir1_deci1_if.data,
        fir1_deci1_if.valid,fir1_deci1_if.ready,
        deci1_fir2_if.data,
        deci1_fir2_if.valid,deci1_fir2_if.ready
    );
    // window kaiser beta=8 fs=2048 fc=512 order=18
    str_fir #(DW,19,'{
        0.00008272,0.0,-0.00297138,0.0,
        0.01820091,0.0,-0.06923229,0.0,0.30391226,
        0.50001558,
        0.30391226,0.0,-0.06923229,0.0,0.01820091,
        0.0,-0.00297138,0.0,0.00008272
        })the_str_fir2(
            clk,rst_n,
            deci1_fir2_if.data,
            deci1_fir2_if.valid,deci1_fir2_if.ready,
            fir2_deci2_if.data,
            fir2_deci2_if.valid,fir2_deci2_if.ready
    );
    str_deci #(DW,2) the_str_deci2(
        clk,rst_n,
        fir2_deci2_if.data,
        fir2_deci2_if.valid,fir2_deci2_if.ready,
        deci2_fir3_if.data,
        deci2_fir3_if.valid,deci2_fir3_if.ready
    );
    // window kaiser beta=8 fs=1024 fc=256 order=12
    str_fir #(DW,27,'{
        0.00005726,0.0,-0.00096161,0.0,
        0.00452250,0.0,-0.01411732,0.0,
        0.03586591,0.0,-0.08672204,0.0,0.31134482,
        0.50002094,
        0.31134482,0.0,-0.08672204,0.0,0.03586591,
        0.0,-0.01411732,0.0,0.00452250,
        0.0,-0.00096161,0.0,0.00005726
        })the_str_fir3(
            clk,rst_n,
            deci2_fir3_if.data,
            deci2_fir3_if.valid,deci2_fir3_if.ready,
            fir3_deci3_if.data,
            fir3_deci3_if.valid,fir3_deci3_if.ready
    );
    str_deci #(DW,2) the_str_deci3(
        clk,rst_n,
        fir3_deci3_if.data,
        fir3_deci3_if.valid,fir3_deci3_if.ready,
        deci3_fir4_if.data,
        deci3_fir4_if.valid,deci3_fir4_if.ready
    );
    // equiriple Density factor=20 fs=512 fpass=150 fstop=200 order=31
    str_fir #(DW,32,'{
        -0.00294735,-0.00537131,0.00316313,0.00365788,
        -0.00963999,0.00472148,0.01102961,-0.02079470,
        0.00617741,0.02699597,-0.04296176,0.00725225,
        0.06787134,-0.10892211,0.00781940,
        0.54633122,0.54633122,
        0.00781940,-0.10892211,0.06787134,
        0.00725225,-0.04296176,0.02699597,0.00617741,
        -0.02079470,0.01102961,0.00472148,-0.00963999,
        0.00365788,0.00316313,-0.00537131,-0.00294735
        })the_str_fir4(
            clk,rst_n,
            deci3_fir4_if.data,
            deci3_fir4_if.valid,deci3_fir4_if.ready,
            ed_if.data,
            ed_if.valid,ed_if.ready
    );
    counter #(LAST) the_last_counter(clk,rst_n,ed_if.valid&ed_if.ready,ed_if.last);
    
    property check_deci;
        int LCount;
        @(posedge clk) disable iff(!rst_n)
        (
            (ed_if.valid&ed_if.ready,LCount=0) ##1
            (st_if.valid&st_if.ready,LCount=LCount+1)[*0:1000] ##1 (LCount==(1000-1)) |-> (ed_if.valid&ed_if.ready)
        );
    endproperty
    assert property(check_deci);
endmodule