`timescale 1ns/10ps

module str_integrator #(
    parameter integer W = 10
)(
    input wire clk,rst_n,
    input wire signed [W-1:0] in,
    input wire ivalid,
    output logic iready,
    output logic signed [W-1:0] out,
    output logic ovalid,
    input wire oready
);
    wire ish=ivalid&iready;
    wire osh=ovalid&oready;
    assign iready=osh|~ovalid;
    always_ff @( posedge clk ) begin
        if(!rst_n) begin
            ovalid<=1'b0;
        end
        else begin
            if(ish) begin
                ovalid<=1'b1;
            end
            else if(osh) begin
                ovalid<=1'b0;
            end
        end
    end
    always_ff@(posedge clk) begin
        if(!rst_n) begin
            out<='0;
        end
        else begin
            if(ish) begin
                out<=out+in;
            end
        end
    end
endmodule

module str_comb #(
    parameter integer W=10,
    parameter integer M=2
)(
    input wire clk,rst_n,
    input wire signed [W-1:0] in,
    input wire ivalid,
    output logic iready,
    output logic signed [W-1:0] out,
    output logic ovalid,
    input wire oready
);
    wire ish=ivalid&iready;
    wire osh=ovalid&oready;
    logic signed [W-1:0] dly[M];    // apply delay Zexp-M
    assign iready=osh|~ovalid;
    generate
        if(M>1)
        begin
            always_ff @( posedge clk ) begin
                if(!rst_n) begin
                    dly<='{M{'0}};
                end
                else begin
                    if(ish) begin
                        dly[0:M-1]<={in,dly[0:M-2]};
                    end
                end
            end
        end
        else
        begin
            always_ff @( posedge clk ) begin
                if(!rst_n) begin
                    dly<='{M{'0}};
                end
                else begin
                    if(ish) begin
                        dly[0]<=in; 
                    end
                end
            end
        end
    endgenerate
    always_ff @( posedge clk ) begin
        if(!rst_n) begin
            ovalid<=1'b0;
        end
        else begin
            if(ish) begin
                ovalid<=1'b1;
            end
            else if(osh) begin
                ovalid<=1'b0;
            end
        end
    end
    always_ff @( posedge clk ) begin
        if(!rst_n) begin
            out<='0;
        end
        else begin
            if(ish) begin
               out<=in-dly[M-1];
            end
        end
    end
endmodule

module str_cic_downsampler #(
    parameter integer W = 10,   // in data width
    parameter integer R = 4,    // down sample rate
    parameter integer M = 2,    // delat
    parameter integer N = 2     // how many cic level
)(
    input wire clk,rst_n,
    input wire signed [W-1:0] s_axis_tdata,
    input wire s_axis_tvalid,
    output logic s_axis_tready,
    output logic signed [W-1:0] m_axis_tdata,
    output logic m_axis_tvalid,
    input wire m_axis_tready
);
    localparam real GAIN = (real'(R) * M)**(N);
    localparam integer DW = W + $clog2((longint'(R) * M)**(N)); // change to "DW = W + $clog2((longint'(R) * M)**(N))" if your vivado, quartus or something else does not support $ceil or $ln.
    logic signed [DW-1:0] intgs_data[N+1];
    wire intgs_valid[N+1];
    wire intgs_ready[N+1];
    logic signed [DW-1:0] combs_data[N+1];
    wire combs_valid[N+1];
    wire combs_ready[N+1];
    assign intgs_data[0]=s_axis_tdata;
    assign s_axis_tready=intgs_ready[0];
    assign intgs_valid[0]=s_axis_tvalid;

    generate
        for(genvar k=0;k<N;k++) begin
            str_integrator #(DW) the_str_intgs_Inst(
                clk,rst_n,
                intgs_data[k],intgs_valid[k],intgs_ready[k],
                intgs_data[k+1],intgs_valid[k+1],intgs_ready[k+1]
            );
        end
    endgenerate
    str_deci #(DW,R) the_str_deci_Inst(
        clk,rst_n,
        intgs_data[N],intgs_valid[N],intgs_ready[N],
        combs_data[0],combs_valid[0],combs_ready[0]
    );
    generate
        for(genvar k = 0; k < N; k++) begin : Combs
            str_comb #(DW,M) the_str_comb_Inst(
                clk,rst_n,
                combs_data[k],combs_valid[k],combs_ready[k],
                combs_data[k+1],combs_valid[k+1],combs_ready[k+1]
            );
        end
    endgenerate
    // Q1.(DW-1)
    wire signed [DW-1:0] attn = (1.0 / GAIN * 2.0**(DW-1));
    assign m_axis_tdata=((2*DW)'(combs_data[N])*(2*DW)'(attn)) >>> (DW-1);
    assign m_axis_tvalid=combs_valid[N];
    assign combs_ready[N]=m_axis_tready;
endmodule