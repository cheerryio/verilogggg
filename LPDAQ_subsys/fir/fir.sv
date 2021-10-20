`timescale 1ns/10ps

module fir #(
    parameter DW=24,
    parameter TAPS=8,
    parameter real COEF[TAPS]='{TAPS{0.124}}
)(
    input wire clk,rst_n,en,
    input wire signed [DW-1:0] in,    // Q1.23
    output logic signed [DW-1:0] out  // Q1.23
);
    localparam N = TAPS-1;
    logic signed [DW-1:0] coef[TAPS];
    logic signed [DW-1:0] prod[TAPS];
    logic signed [DW-1:0] delay[TAPS];
    generate
        for(genvar t=0; t<TAPS;t++) begin
            assign coef[t]=COEF[t]*2.0**(DW-1.0);
            assign prod[t]=((2*DW)'(in)*(2*DW)'(coef[t]))>>>(DW-1);
        end
    endgenerate
    generate
        for(genvar t=0; t<TAPS;t++) begin
            always_ff@(posedge clk) begin
                if(!rst_n) delay[t]<='0;
                else if(en) begin
                    if(t == 0) delay[0]<=prod[N - t];
                    else delay[t] <= prod[N-t]+delay[t-1];
                end
            end
        end
    endgenerate
    assign out = delay[N];
endmodule