`timescale 1ns/10ps

module str_fir #(
    parameter integer DW = 24,
    parameter integer TAPS = 8,
    parameter real COEF[TAPS] = '{TAPS{0.124}}
)(
    input wire clk,rst_n,
    input wire signed [DW-1:0] s_axis_tdata,    // Q1.23
    input wire s_axis_tvalid,
    output logic s_axis_tready,
    output logic signed [DW-1:0] m_axis_tdata,  // Q1.23
    output logic m_axis_tvalid,
    input wire m_axis_tready
);
    wire ish=s_axis_tvalid&s_axis_tready;
    wire osh=m_axis_tvalid&m_axis_tready;
    localparam N=TAPS-1;
    logic signed [DW-1:0] coef[TAPS];
    logic signed [DW-1:0] prod[TAPS];
    logic signed [DW-1:0] delay[TAPS];
    assign s_axis_tready=osh|~m_axis_tvalid;
    always_ff @( posedge clk ) begin
        if(!rst_n) begin
            m_axis_tvalid<=1'b0;
        end
        else begin
            if(ish) begin
                m_axis_tvalid<=1'b1;
            end
            else if(osh) begin
                m_axis_tvalid<=1'b0;
            end
        end
    end
    generate
        for(genvar t=0;t<TAPS;t++) begin
            assign coef[t]=COEF[t]*2.0**(DW-1.0);
        end
    endgenerate
    generate
        for(genvar t=0;t<TAPS;t++) begin
            always_ff @( posedge clk ) begin
                if(!rst_n) begin
                    prod[t]<='0;
                end
                else begin
                    if(ish) begin
                        prod[t]=((2*DW)'(s_axis_tdata)*(2*DW)'(coef[t]))>>>(DW-1);
                    end
                end
            end
        end
    endgenerate
    generate
        for(genvar t = 0; t < TAPS; t++) begin
            always_ff@(posedge clk) begin
                if(!rst_n) begin
                    delay[t]<='0;
                end
                else begin
                    if(ish) begin
                        if(t == 0) begin
                            delay[0]<=prod[N-t];
                        end
                        else begin
                            delay[t]<=prod[N-t]+delay[t-1];
                        end
                    end
                end
            end
        end
    endgenerate
    assign m_axis_tdata=delay[N];
endmodule