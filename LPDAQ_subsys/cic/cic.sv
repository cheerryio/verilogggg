module cicDownSampler_tb #(

)(

);
    localparam integer W = 10;
    logic clk,rst_n;
    initial begin
        clk=0;
        forever #50 clk=~clk;
    end
    initial begin
        rst_n=0;
        #100 rst_n=1;
    end
    logic en50,en25;
    counter #(2)
    theCounterInst50(clk,rst_n,1'b1,en50);
    counter #(4)
    theCounterInst25(clk,rst_n,1'b1,en25);
    logic signed [W-1:0] in,out;
    always_ff @( posedge clk ) begin
        if(!rst_n) begin in<='0; end
        else in<=in+1'b1;
    end
    cicDownSampler #()
    theCicDownSamplerInst(clk,rst_n,en50,en25,in,out);
endmodule

module integrator #(
    parameter integer W = 10
)(
    input wire clk, rst_n, en,
    input wire signed [W-1:0] in,
    output logic signed [W-1:0] out
);
    always_ff@(posedge clk) begin
        if(!rst_n) out <= '0;
        else if(en) out <= out + in;
    end
endmodule

module comb #(
    parameter integer W = 10,
    parameter integer M = 2
)(
    input wire clk, rst_n, en,
    input wire signed [W-1:0] in,
    output logic signed [W-1:0] out
);
    logic signed [W-1:0] dly[M];    // apply delay Zexp-M
    generate
        if(M>1)
        begin
            always_ff @( posedge clk ) begin
                if(!rst_n) dly <= '{M{'0}};
                else if(en) dly[0:M-1] <= {in, dly[0:M-2]};
            end
        end
        else
        begin
            always_ff @( posedge clk ) begin
                if(!rst_n) dly <= '{M{'0}};
                else if(en) dly[0] <= in;
            end
        end
    endgenerate
    always_ff @( posedge clk ) begin
        if(!rst_n) out <= '0;
        else if(en) out <= in-dly[M-1];
    end
endmodule

module cic_downsampler #(
    parameter integer W = 10,   // in data width
    parameter integer R = 4,    // down sample rate
    parameter integer M = 2,    // delat
    parameter integer N = 2     // how many cic level
)(
    input wire clk, rst_n, eni, eno,
    input wire signed [W-1:0] in,
    output logic signed [W-1:0] out
);
    localparam real GAIN = (real'(R) * M)**(N);
    localparam integer DW = W + $clog2((longint'(R) * M)**(N)); // change to "DW = W + $clog2((longint'(R) * M)**(N))" if your vivado, quartus or something else does not support $ceil or $ln.
    logic signed [DW-1:0] intgs_data[N+1];
    assign intgs_data[0] = in;
    generate
        for(genvar k = 0; k < N; k++) begin : Intgs
            integrator #(DW) theIntg(
                clk, rst_n, eni, intgs_data[k], intgs_data[k+1]);
        end
    endgenerate
    logic signed [DW-1:0] combs_data[N+1];
    interpDeci #(DW) theDeci(
        clk, rst_n, eni, eno, intgs_data[N], combs_data[0]);
    generate
        for(genvar k = 0; k < N; k++) begin : Combs
            comb #(DW, M) theComb(
                clk, rst_n, eno, combs_data[k], combs_data[k+1]);
        end
    endgenerate
    // Q1.(DW-1)
    wire signed [DW-1:0] attn = (1.0 / GAIN * 2.0**(DW-1));
    always_ff@(posedge clk) begin
        if(!rst_n) out <= '0;
        else if(eno) out <= ((2*DW)'(combs_data[N])*(2*DW)'(attn)) >>> (DW-1);
    end
endmodule
