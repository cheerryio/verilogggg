`timescale 1ns/10ps

module down_convertion_sys_tb #(
    parameter integer DW    = 24,
    parameter integer PW    = 32,
    parameter integer LC_DW = 12
)(
);
    logic clk,rst_n,en;
    logic signed [DW-1:0] in;
    (* mark_debug="true" *) logic signed [DW-1:0] ibb,qbb;
    logic signed [DW-1:0] sin_in,cos_in;
    logic signed [31:0] freq,freq_in;
    initial begin
        clk=0;
        en=1;
        forever #50 clk=~clk;
    end
    initial begin
        rst_n=0;
        #100 rst_n=1;
    end
    real freqr=4e5; // 20kHz
    always_ff @( posedge clk ) begin
        freq <= 2.0**32*(20.0/512.0);
    end
    real freqr_in=2.4e4;    //24kHz
    always_ff @( posedge clk ) begin
        freq_in <= 2.0**32*freqr_in/10e6;
    end
    logic en512000;
    counter #(20) cnt512000(clk,rst_n,1'b1,en512000);
    orthDds #(PW, DW, 13) theOrthDdsInst(clk, rst_n, 1'b1, freq_in, 32'sd0,sin_in,cos_in);
    assign in=cos_in;
    downConvertionSys #(DW,PW,LC_DW)
    theDownConvertionSys(clk,rst_n,en512000,freq,in,ibb,qbb);
endmodule

/**
* en: come from AD's frame sync, drive the en of orthDds,512ksps, take as 512kHz
*/
module down_conversion_sys #(
    parameter integer DW    = 24,
    parameter integer PW    = 32,
    parameter integer LC_DW = 12
)(
    input wire clk, rst_n, en,
    input wire signed [PW-1:0] freq,
    input wire signed [DW-1:0] in,              //Q1.23
    output logic signed [DW-1:0] iout, qout,
    output logic valid
);
    logic signed [LC_DW-1:0] lc_sin, lc_cos;
    logic signed [DW-1:0] idec102400, qdec102400, idec51200, qdec51200, idec25600, qdec25600;
    logic signed [DW-1:0] ifil102400, qfil102400, ifil51200, qfil51200;
    logic signed [DW-1:0] imix, qmix;
    logic en512000,en102400,en51200,en25600;
    assign en512000=en;
    counter #(5) cnt102400(clk,rst_n,en512000,en102400);
    counter #(2) cnt51200 (clk,rst_n,en102400,en51200);
    counter #(2) cnt25600 (clk,rst_n,en51200,en25600);
    orthDds #(PW, 12, 13)
    theOrthDdsInst(clk, rst_n, en512000, freq, 32'sd0, lc_sin, lc_cos);
    always_ff@( posedge clk )
    begin
        if(!rst_n)
        begin
            imix <= '0;
            qmix <= '0;
        end
        else if(en512000)
        begin
            imix <= ((LC_DW+DW)'(in) * (LC_DW+DW)'( lc_cos)) >>> (LC_DW-1);
            qmix <= ((LC_DW+DW)'(in) * (LC_DW+DW)'(-lc_sin)) >>> (LC_DW-1);
        end
    end
    cicDownSampler #(DW,5,1,4)
    theiCicDownSamplerInst_512000(clk,rst_n,en512000,en102400,imix,idec102400),
    theqCicDownSamplerInst_512000(clk,rst_n,en512000,en102400,qmix,qdec102400);
    // low pass fir, sample rate:1024Hz, stop rate:256Hz
    fir #(DW, 13, '{
        0.0000,0.0090,-0.0000,-0.0572,0.0000,0.2984,0.4996,
        0.2984,0.0000,-0.0572,-0.0000,0.0090,-0.0000
    })  iFilter102400(clk, rst_n, en102400, idec102400, ifil102400),
        qFilter102400(clk, rst_n, en102400, qdec102400, qfil102400);
    interpDeci #(DW)
    theiDeci102400(clk,rst_n,en102400,en51200,ifil102400,idec51200),
    theqDeci102400(clk,rst_n,en102400,en51200,qfil102400,qdec51200);

    // low pass fir, sample rate:512Hz, stop rate:128Hz
    fir #(DW, 27, '{
        0.0020,-0.0000,-0.0038,0.0000,0.0098,-0.0000,-0.0220,0.0000,0.0447,-0.0000,-0.0937,0.0000,
        0.3135,0.4991,0.3135,0.0000,-0.0937,-0.0000,0.0447,0.0000,-0.0220,-0.0000,0.0098,0.0000,
        -0.0038,-0.0000,0.0020

    })  iFilter51200(clk, rst_n, en51200, idec51200, ifil51200),
        qFilter51200(clk, rst_n, en51200, qdec51200, qfil51200);
    interpDeci #(DW)
    theiDeci51200(clk, rst_n, en51200, en25600, ifil51200, idec25600),
    theqDeci51200(clk, rst_n, en51200, en25600, qfil51200, qdec25600);
    assign iout = idec25600;
    assign qout = qdec25600;
    assign valid = en25600;
endmodule