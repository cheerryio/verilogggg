`timescale 1ns/10ps

module orthDds #(
    parameter integer PW=32,
    parameter integer DW=12,
    parameter integer AW=13
)(
    input wire clk,rst_n,en,
    input wire signed [PW-1:0] freq,phase,
    output logic signed [DW-1:0] sin,cos
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
