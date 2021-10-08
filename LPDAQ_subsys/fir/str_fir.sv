`timescale 1ns/10ps

module str_fir_tb #();
    localparam integer LC_DW=12;
    localparam integer FREQ_DW = 32;
    bit clk,rst_n;
    bit ivalid,iready,ovalid,oready;
    initial begin
        forever #50 clk=~clk;
    end
    initial begin
        rst_n=0;
        #100 rst_n=1;
    end
    initial begin
        ivalid=1;
        oready=1;
    end
    real freqr = 1e6, fstepr = 49e6/(1e-3*100e6); // from 1MHz to 50MHz in 1ms
    always@(posedge clk) begin
        if(!rst_n) freqr = 1e6;
        else freqr += fstepr;
    end
    logic signed [FREQ_DW-1:0] freq;
    always@(posedge clk) begin
        freq <= 2.0**32 * freqr / 100e6; // frequency to freq control word
    end
    logic signed [FREQ_DW-1:0] phase = '0;
    logic signed [LC_DW-1:0] in;
    orthDds #(FREQ_DW,LC_DW,13) theOrthDdsInst(clk,rst_n,ivalid&iready,freq,phase,in);
    logic signed [LC_DW-1:0] filtered;
    str_fir #(LC_DW, 27, '{ -0.005646,  0.006428,  0.019960,  0.033857,  0.036123,
                      0.016998, -0.022918, -0.068988, -0.097428, -0.087782,
                     -0.036153,  0.039431,  0.106063,  0.132519,  0.106063,
                      0.039431, -0.036153, -0.087782, -0.097428, -0.068988,
                     -0.022918,  0.016998,  0.036123,  0.033857,  0.019960,
                      0.006428, -0.005646
    })the_str_fir_Inst(
        clk,rst_n,
        (LC_DW)'(integer'(in*0.9)),
        ivalid,iready,
        filtered,
        ovalid,oready
    );
endmodule

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
    logic ish,osh;
    localparam N = TAPS - 1;
    logic signed [DW-1 : 0] coef[TAPS];
    logic signed [DW-1 : 0] prod[TAPS];
    logic signed [DW-1 : 0] delay[TAPS];
    assign ish=s_axis_tvalid&s_axis_tready;
    assign osh=m_axis_tvalid&m_axis_tready;
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
        for(genvar t = 0; t < TAPS; t++) begin
            assign coef[t] = COEF[t] * 2.0**(DW-1.0);
        end
    endgenerate
    generate
        for(genvar t = 0; t < TAPS; t++) begin
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