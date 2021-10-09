`timescale 1ns/10ps

`include "../common.sv"

module str_down_sample_tb();
    bit clk,rst_n;
    bit signed [23:0] cos;
    bit signed [19:0] cos1,cos2,cos3;
    initial begin
        forever #5 clk=~clk;
    end
    initial begin
        rst_n=1'b0;
        #50;
        rst_n=1'b1;
    end
    axi_stream_proto #(24) adc_if(clk,rst_n),v_if(clk,rst_n);
    always_ff @( posedge clk ) begin
        adc_if.valid<=1'b1;
        v_if.ready<=1'b1;
    end
    //orthDds #(32,24,13) theOrthDdsInst(clk,rst_n,adc_if.valid&adc_if.ready,32'd429496729,32'd0,,cos);
    orthDds #(32,20,13) theOrthDdsInst_10000Hz(clk,rst_n,adc_if.valid&adc_if.ready,32'd429496,32'd0,,cos1);  ///< 10000Hz
    orthDds #(32,20,13) theOrthDdsInst_1000Hz(clk,rst_n,adc_if.valid&adc_if.ready,32'd42949,32'd0,,cos2);   ///< 1000Hz
    orthDds #(32,20,13) theOrthDdsInst_100Hz(clk,rst_n,adc_if.valid&adc_if.ready,32'd4294,32'd0,,cos3);    ///< 100Hz
    always_ff @( posedge clk ) begin
        if(adc_if.valid&&adc_if.ready) begin
            cos<=cos1+cos2+cos3;
        end
    end
    str_down_sample #(.DW(24),.LAST(10)) the_str_down_sample_Inst(
        clk,rst_n,
        cos,
        adc_if.valid,adc_if.ready,
        v_if.data,
        v_if.valid,v_if.ready,
        v_if.last
    );
endmodule

module str_down_sample #(
    parameter integer DW=24,
    parameter integer LAST=16000
)(
    input wire clk,rst_n,
    input wire signed [DW-1:0] s_axis_tdata,
    input wire s_axis_tvalid,
    output logic s_axis_tready,

    output logic signed [DW-1:0] m_axis_tdata,
    output logic m_axis_tvalid,
    input wire m_axis_tready,
    output logic m_axis_tlast
);
    logic [$clog2(LAST)-1:0] last_cnt;
    axi_stream_proto #(
        .DW(DW)
    )cic_slice_if(clk,rst_n),slice_fir1_if(clk,rst_n),
    fir1_deci1_if(clk,rst_n),deci1_fir2_if(clk,rst_n),
    fir2_deci2_if(clk,rst_n),deci2_fir3_if(clk,rst_n),
    fir3_deci3_if(clk,rst_n),deci3_fir4_if(clk,rst_n);

    str_cic_downsampler #(DW,5,1,4) the_str_cic_downsampler_Inst(
        clk,rst_n,
        s_axis_tdata,
        s_axis_tvalid,s_axis_tready,
        cic_slice_if.data,
        cic_slice_if.valid,cic_slice_if.ready
    );
    // window kaiser beta=8 fs=4096 fc=1024 order=12
    str_fir #(DW,13,'{
        0.0,0.00243079,0.0,-0.03915077,0.0,0.28671006,
        0.50001983,
        0.28671006,0.0,-0.03915077,0.0,0.00243079,0.0
        })the_str_fir1(
            clk,rst_n,
            cic_slice_if.data,
            cic_slice_if.valid,cic_slice_if.ready,
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
            m_axis_tdata,
            m_axis_tvalid,m_axis_tready
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