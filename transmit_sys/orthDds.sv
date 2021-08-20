`timescale 1ns/10ps

module orthDds_tb #(

)(

);
    logic clk,rst_n,en;
    initial begin
        clk=0;
        en=1;
        forever #50 clk=~clk;
    end
    initial begin
        rst_n=0;
        #100 rst_n=1;
    end
    real freqr = 2e4, fstepr = 49e6/(1e-3*100e6); // from 1MHz to 50MHz in 1ms
    logic signed [31:0] freq;
    always@(posedge clk) begin
        freq <= 2.0**32 * freqr / 10e6; // frequency to freq control word
    end
    logic signed [31:0] phase = '0;
    logic signed [11:0] sin,cos;
    orthDds #(32, 12, 13) theOrthDdsInst(clk, rst_n, 1'b1, freq, 32'sd0,sin,cos);
endmodule

module orthDds #(
    parameter PW = 32, DW = 12, AW = 13
)(
    input wire clk, rst_n, en,
    input wire signed [PW - 1 : 0] freq, phase,
    output logic signed [DW - 1 : 0] sin, cos
);
    localparam LEN = 2**AW;
    localparam real PI = 3.1415926535897932;
    logic signed [DW-1 : 0] sine[LEN];
    int fd;
    initial begin
        for(int i = 0; i < LEN; i++) begin
            sine[i] = $sin(2.0 * PI * i / LEN) * (2.0**(DW-1) - 1.0);
            //$readmemh("C:\\Users\\dn\\source\\repos\\DownConvertionSys\\data.hex",sine);
        end
    end
    logic [PW-1 : 0] phaseAcc, phSum0, phSum1;
    always_ff@(posedge clk) begin
        if(!rst_n) phaseAcc <= '0;
        else if(en) phaseAcc <= phaseAcc + freq;
    end
    always_ff@(posedge clk) begin
        if(!rst_n) begin
            phSum0 <= '0;
            phSum1 <= (PW)'(1) <<< (PW-2); // 90deg
        end
        else if(en) begin
            phSum0 <= phaseAcc + phase;
            phSum1 <= phaseAcc + phase + ((PW)'(1) <<< (PW-2));
        end
    end
    always_ff@(posedge clk) begin
        if(!rst_n) sin <= '0;
        else if(en) sin <= sine[phSum0[PW-1 -: AW]];
    end
    always_ff@(posedge clk) begin
        if(!rst_n) cos <= '0;
        else if(en) cos <= sine[phSum1[PW-1 -: AW]];
    end
endmodule
