`timescale 1ns/10ps

`include "../common.sv"

module down_sample #(
    parameter integer DW=24
)(
    input wire clk,rst_n,
    input wire en512000,
    input wire signed [DW-1:0] data_i,
    output logic valid,
    output logic signed [DW-1:0] data_o
);
    logic en4096,en2048,en1024,en512;
    logic signed [DW-1:0] idec4096,idec2048,idec1024,idec512;
    logic signed [DW-1:0] ifil4096,ifil2048,ifil1024,ifil512;
    counter #(5) the_counter_512000(clk,rst_n,en512000,en4096);
    counter #(2) the_counter_4096(clk,rst_n,en4096,en2048);
    counter #(2) the_counter_2048(clk,rst_n,en2048,en1024);
    counter #(2) the_counter_1024(clk,rst_n,en1024,en512);
    cic_downsampler #(DW,5,1,4) the_cic_downsampler_Inst(
        clk,rst_n,en512000,en4096,
        data_i,idec4096
    );
    // window kaiser beta=8 fs=4096 fc=1024 order=12
    fir #(DW,13,'{
        0.0,0.00243079,0.0,-0.03915077,0.0,0.28671006,
        0.50001983,
        0.28671006,0.0,-0.03915077,0.0,0.00243079,0.0
        })fir1(clk,rst_n,en4096,idec4096,ifil4096);
    interpDeci #(DW) the_deci1(clk,rst_n,en4096,en2048,ifil4096,idec2048);
    // window kaiser beta=8 fs=2048 fc=512 order=18
    fir #(DW,19,'{
        0.00008272,0.0,-0.00297138,0.0,
        0.01820091,0.0,-0.06923229,0.0,0.30391226,
        0.50001558,
        0.30391226,0.0,-0.06923229,0.0,0.01820091,
        0.0,-0.00297138,0.0,0.00008272
        })fir2(clk,rst_n,en2048,idec2048,ifil2048);
    interpDeci #(DW) the_deci2(clk,rst_n,en2048,en1024,ifil2048,idec1024);
    // window kaiser beta=8 fs=1024 fc=256 order=12
    fir #(DW,27,'{
        0.00005726,0.0,-0.00096161,0.0,
        0.00452250,0.0,-0.01411732,0.0,
        0.03586591,0.0,-0.08672204,0.0,0.31134482,
        0.50002094,
        0.31134482,0.0,-0.08672204,0.0,0.03586591,
        0.0,-0.01411732,0.0,0.00452250,
        0.0,-0.00096161,0.0,0.00005726
        })fir3(clk,rst_n,en1024,idec1024,ifil1024);
    interpDeci #(DW) the_deci3(clk,rst_n,en1024,en512,ifil1024,idec512);
    // equiriple Density factor=20 fs=512 fpass=150 fstop=200 order=31
    fir #(DW,32,'{
        -0.00294735,-0.00537131,0.00316313,0.00365788,
        -0.00963999,0.00472148,0.01102961,-0.02079470,
        0.00617741,0.02699597,-0.04296176,0.00725225,
        0.06787134,-0.10892211,0.00781940,
        0.54633122,0.54633122,
        0.00781940,-0.10892211,0.06787134,
        0.00725225,-0.04296176,0.02699597,0.00617741,
        -0.02079470,0.01102961,0.00472148,-0.00963999,
        0.00365788,0.00316313,-0.00537131,-0.00294735
        })fir4(clk,rst_n,en512,idec512,ifil512);
    assign valid=en512;
    assign data_o=ifil512;
endmodule