`ifndef __IISTRANSRECV_SV__
`define __IISTRANSRECV_SV__
`timescale 1ps/1ps

module Counter #(
    parameter integer N = 64
)(
    input wire clk,rst,en,
    output logic [$clog2(N) - 1:0] cnt,
    output logic co
);
    always_ff @( posedge clk ) begin
        if(rst)
        begin
            cnt <= '0;
        end
        else
        begin
            if(en)
            begin
                if(cnt < N)
                begin
                    cnt <= cnt + 1'b1;
                end
                else
                begin
                    cnt <= '0;
                end
            end
        end
    end

    assign co = cnt == N - 1;

endmodule

module I2sClk #(
    parameter integer MCK_TO_SCK = 8,
    parameter integer SCK_TO_WS = 64
)(
    input wire mck,
    output logic sck,
    output logic ws,
    output logic sck_fall,
    output logic sck_before_rise,
    output logic frame_sync
);
    logic [$clog2(MCK_TO_SCK)-1:0] sck_cnt;
    logic [$clog2(SCK_TO_WS)-1:0] ws_cnt;
    logic ws_co;

    Counter #(.N(MCK_TO_SCK))
    theSckCounter(
        .clk(mck),
        .rst(1'b0),.en(1'b1),
        .cnt(sck_cnt),.co(sck_fall)
    );
    Counter #(.N(SCK_TO_WS))
    theWsCounter(
        .clk(mck),
        .rst(1'b0),.en(sck_fall),
        .cnt(ws_cnt),.co(ws_co)
    );
    assign sck = sck_cnt >= (MCK_TO_SCK / 2);
    assign ws = ws_cnt >= (SCK_TO_WS / 2);
    assign sck_before_rise = sck_cnt == (MCK_TO_SCK / 2 - 1);
    assign frame_sync = ws_cnt == 0 && sck_before_rise;
endmodule

module IisTransmitter #(
    parameter integer DW = 32
)(
    input wire mck,sck,ws,
    input wire frame_sync,sck_fall,sck_before_rise,
    input wire valid,
    output logic ready,
    input wire [DW - 1:0] data[1:0],
    output logic sdout
);
    logic [DW*2-1:0] shift_reg;

    // ready drive
    always_ff @( posedge mck) begin
        if(frame_sync)
        begin
            ready <= 1'b1;
        end
        else if(sck_before_rise)
        begin
            ready <= 1'b0;
        end
        else if(valid && ready && sck_fall)
        begin
            ready <= 1'b0;
        end
    end

    // shift_reg drive
    always_ff @( posedge mck ) begin
        if(valid && ready && sck_fall)
        begin
            shift_reg <= {data[1],data[0]};
        end
        else if(sck_fall)
        begin
            shift_reg <= shift_reg << 1;
        end
    end
    assign sdout = shift_reg[DW*2-1];
endmodule

module IisReceiver #(
    parameter integer DW = 32
)(
    input wire mck,sck,ws,
    input wire frame_sync,sck_fall,sck_before_rise,
    input wire ready,
    output logic valid,
    output logic [DW - 1:0] data[1:0],
    input wire sdin
);
    logic [DW * 2 - 1:0] shift_reg;
    logic frame_sync_dly,frame_sync_dly2;

    // drive frame_sync_dly according to frame_sync
    always_ff @( posedge mck ) begin
        frame_sync_dly <= frame_sync;
    end

    // drive valid
    always_ff @( posedge mck ) begin
        if(frame_sync_dly)
        begin
            valid <= 1'b1;
        end
        else if(valid && ready && sck_fall)
        begin
            valid <= 1'b0;
        end
    end

    // drive shift_reg
    always_ff @( posedge mck ) begin
        if(sck_before_rise)
        begin
            shift_reg <= {shift_reg[DW*2-2:0],sdin}; 
        end
    end

    // drive data
    always_ff @( posedge mck ) begin
        if(frame_sync_dly)
        begin
            {data[1],data[0]} <= shift_reg;
        end
    end
endmodule

module LM4811_Volumn #(
    parameter integer DLY = 128
)(
    input wire mck,
    input wire up,down, // en for on cycle of mck
    output logic lm4811_ud,
    output logic lm4811_clk
);
    logic [$clog2(DLY) - 1:0] dly_cnt;
    // drive lm4811_ud
    always_ff @( posedge mck ) begin
        if(up)
        begin
            lm4811_ud <= 1'b1;
        end
        else if(down)
        begin
            lm4811_ud <= 1'b0;
        end
    end

    // drive lm4811_clk
    always_ff @( posedge mck ) begin
        if(up || down)
        begin
            lm4811_clk <= 1'b0;
        end
        else if(dly_cnt == DLY - 1)
        begin
            lm4811_clk <= 1'b1;
        end
    end

    // drive dly_cnt
    always_ff @( posedge mck ) begin
        if(up || down)
        begin
            dly_cnt <= 1;
        end
        else if(dly_cnt < DLY - 1)
        begin
            dly_cnt <= dly_cnt + 1;
        end
        else
        begin
            dly_cnt <= '0;
        end
    end
endmodule

module Rising2en #(

)(
    input wire clk,
    input wire in,
    output logic en
);
    logic [1:0] dly;
    always_ff @( posedge clk ) begin
        dly <= {dly[0],in};
    end
    assign en = ~dly[1] && dly[0];
endmodule

module IirFilter #(
    parameter integer DW = 32,
    parameter integer FW = 8,
    parameter real GAIN, real NUM[3], real DEN[2]
)(
    input wire clk,
    input wire rst,en,
    input wire signed [DW-1:0] in,
    output logic signed [DW-1:0] out
);
    wire signed [DW-1:0] n0,n1,n2,d1,d2,g,pn0,pn1,pn2;
    wire signed [DW-1:0] o;
    wire signed [DW-1:0] pd1;
    wire signed [DW-1:0] pd2;
    assign n0 = (NUM[0] * 2.0**FW);
    assign n1 = (NUM[1] * 2.0**FW);
    assign n2 = (NUM[2] * 2.0**FW);
    assign d1 = (DEN[0] * 2.0**FW);
    assign d2 = (DEN[1] * 2.0**FW);
    assign g  = (GAIN   * 2.0**FW);

    logic signed [DW-1:0] z1, z0;
    assign pn0 = ((DW+DW)'(in) * (DW+DW)'(n0)) >>> FW;
    assign pn1 = ((DW+DW)'(in) * (DW+DW)'(n1)) >>> FW;
    assign pn2 = ((DW+DW)'(in) * (DW+DW)'(n2)) >>> FW;
    assign pd1 = ((DW+DW)'(o ) * (DW+DW)'(d1)) >>> FW;
    assign pd2 = ((DW+DW)'(o ) * (DW+DW)'(d2)) >>> FW;
    assign o = pn0 + z0;

    always_ff @( posedge clk ) begin
        if(rst)
        begin
            z1 <= '0;
            z0 <= '0;
            out <= '0;
        end
        else if(en)
        begin
            z1 <= pn2 - pd2;
            z0 <= pn1 - pd1 + z1;
            out <= ((DW+DW)'(o ) * (DW+DW)'(g)) >>> FW;
        end
    end
endmodule

module TriLevelEqualizer #(
    parameter integer DW = 32,
    parameter integer FW = 8
)(
    input wire clk,
    input wire signed [DW-1:0] in,
    input wire frame_sync,
    input wire signed [DW-1:0] lgain,mgain,hgain,
    output logic signed [DW-1:0] out
);
    logic [DW-1:0] low_out,middle_out,high_out;
    logic [DW-1:0] low_gain_out,middle_gain_out,high_gain_out;
    logic frame_sync_dly,frame_sync_dly2;
    always_ff @( posedge clk ) begin
        frame_sync_dly <= frame_sync;
    end
    always_ff @( posedge clk ) begin
        frame_sync_dly2 <= frame_sync_dly;
    end
    IirFilter #(
        .DW(DW),.FW(FW),
        .GAIN(0.02551772),.NUM('{1,1,0}),.DEN('{-0.94896457,0})
    )
    theLowIirFilter(
        .clk(clk),.rst(1'b0),.en(frame_sync_dly2),
        .in(in),.out(low_out)
    );
    IirFilter #(
        .DW(DW),.FW(FW),
        .GAIN(0.12150990),.NUM('{1,0,-1}),.DEN('{-1.74185363,0.75698019})
    )theMiddleIirFilter(
        .clk(clk),.rst(1'b0),.en(frame_sync_dly2),
        .in(in),.out(middle_out)
    );
    IirFilter #(
        .DW(DW),.FW(FW),
        .GAIN(0.85829493),.NUM('{1,-1,0}),.DEN('{-0.71658987,0})
    )theHighIirFilter(
        .clk(clk),.rst(1'b0),.en(frame_sync_dly2),
        .in(in),.out(high_out)
    );
    assign low_gain_out    = ((DW+DW)'(low_out)    * (DW+DW)'(lgain)) >>> 12;
    assign middle_gain_out = ((DW+DW)'(middle_out) * (DW+DW)'(mgain)) >>> 12;
    assign high_gain_out   = ((DW+DW)'(high_out)   * (DW+DW)'(hgain)) >>> 12;
    assign out = low_gain_out + middle_gain_out + high_gain_out;
endmodule

module IisTransRecvEqualizerGain #(

)(
    input wire mck,rst_n,
    input wire up,down,
    input wire lup,ldown,
    input wire mup,mdown,
    input wire hup,hdown,
    output logic lm4811_clk,lm4811_ud,
    output logic signed [31:0] lgain,mgain,hgain
);
    logic up_en,down_en,lup_en,ldown_en,mup_en,mdown_en,hup_en,hdown_en;
    Rising2en theUpRising2en(mck,up,up_en);
    Rising2en theDownRising2en(mck,down,down_en);
    Rising2en theLupRising2en(mck,lup,lup_en);
    Rising2en theLdownRising2en(mck,ldown,ldown_en);
    Rising2en theMupRising2en(mck,mup,mup_en);
    Rising2en theMdownRising2en(mck,mdown,mdown_en);
    Rising2en theHupRising2en(mck,hup,hup_en);
    Rising2en theHdownRising2en(mck,hdown,hdown_en);
    LM4811_Volumn #(.DLY(5096))
    theLM4811_Volumn(
        .mck(mck),
        .up(up_en),.down(down_en), // en for on cycle of mck
        .lm4811_clk(lm4811_clk),.lm4811_ud(lm4811_ud)
    );
    always_ff @( posedge mck ) begin
        if(!rst_n)
            lgain <= 32'h0000_1000;
        else
        begin
            if(lup_en)
            begin
                if(lgain < 32'h0000_f000)
                    lgain <= lgain + 32'h0000_1000;
            end
            else if(ldown_en)
                if(lgain > 32'h0000_0000)
                    lgain <= lgain - 32'h0000_1000;
        end
    end
    always_ff @( posedge mck ) begin
        if(!rst_n)
            mgain <= 32'h0000_1000;
        else
        begin
            if(mup_en)
            begin
                if(mgain < 32'h0000_f000)
                    mgain <= mgain + 32'h0000_1000;
            end
            else if(mdown_en)
                if(mgain > 32'h0000_0000)
                    mgain <= mgain - 32'h0000_1000;
        end
    end
    always_ff @( posedge mck ) begin
        if(!rst_n)
            hgain <= 32'h0000_1000;
        else
        begin
            if(hup_en)
            begin
                if(hgain < 32'h0000_f000)
                    hgain <= hgain + 32'h0000_1000;
            end
            else if(hdown_en)
                if(hgain > 32'h0000_0000)
                    hgain <= hgain - 32'h0000_1000;
        end
    end
endmodule

module IisTransRecvEqualizer #(

)(
    input wire mck,rst_n,
    output wire mck_o,sck,ws1,ws2,
    input wire sdin,
    output logic sdout,
    input wire up,down,lup,ldown,mup,mdown,hup,hdown,
    output logic lm4811_clk,lm4811_ud,
    output logic signed [31:0] lgain,mgain,hgain
);
    logic ws,sck_fall,sck_before_rise,frame_sync;
    logic ready,valid;
    logic [31:0] data[1:0];
    logic [31:0] e_data[1:0];
    assign mck_o = mck;
    assign ws1 = ws;
    assign ws2 = ws;
    // iis clk
    I2sClk #()
    theI2sClk(
        .mck(mck),.sck(sck),.ws(ws),
        .sck_fall(sck_fall),.sck_before_rise(sck_before_rise),
        .frame_sync(frame_sync)
    );
    // receiver
    IisReceiver #()
    theIisRecv(
        .mck(mck),.sck(sck),.ws(ws),
        .frame_sync(frame_sync),.sck_fall(sck_fall),.sck_before_rise(sck_before_rise),
        .ready(ready),.valid(valid),
        .sdin(sdin),
        .data(data)
    );
    IisTransRecvEqualizerGain #()
    theIisTransRecvEqualizerGain(
        mck,rst_n,
        up,down,lup,ldown,mup,mdown,hup,hdown,
        lm4811_clk,lm4811_ud,
        lgain,mgain,hgain
    );
    TriLevelEqualizer #(.DW(32),.FW(8))
    theTriLevelEqualizerLeft(
        .clk(mck),
        .in(data[0]),
        .frame_sync(frame_sync),
        .lgain(lgain),.mgain(mgain),.hgain(hgain),
        .out(e_data[0])
    );
    TriLevelEqualizer #(.DW(32),.FW(8))
    theTriLevelEqualizerRight(
        .clk(mck),
        .in(data[1]),
        .frame_sync(frame_sync),
        .lgain(lgain),.mgain(mgain),.hgain(hgain),
        .out(e_data[1])
    );
    IisTransmitter #()
    theIisTransmitter(
        .mck(mck),.sck(sck),.ws(ws),
        .frame_sync(frame_sync),.sck_fall(sck_fall),.sck_before_rise(sck_before_rise),
        .ready(ready),.valid(valid),
        .sdout(sdout),
        .data(e_data)
    );
endmodule

module IisTransRecvNormal #(

)(
    input wire mck,rst_n,
    output wire mck_o,sck,ws1,ws2,
    input wire sdin,
    output logic sdout
);
    logic ws,sck_fall,sck_before_rise,frame_sync;
    logic ready,valid;
    logic [31:0] data[1:0];
    assign mck_o = mck;
    assign ws1 = ws;
    assign ws2 = ws;
    // iis clk
    I2sClk #()
    theI2sClk(
        .mck(mck),.sck(sck),.ws(ws),
        .sck_fall(sck_fall),.sck_before_rise(sck_before_rise),
        .frame_sync(frame_sync)
    );
    // receiver
    IisReceiver #()
    theIisReceiver(
        .mck(mck),.sck(sck),.ws(ws),
        .frame_sync(frame_sync),.sck_fall(sck_fall),.sck_before_rise(sck_before_rise),
        .ready(ready),.valid(valid),
        .sdin(sdin),
        .data(data)
    );
    IisTransmitter #()
    theIisTransmitter(
        .mck(mck),.sck(sck),.ws(ws),
        .frame_sync(frame_sync),.sck_fall(sck_fall),.sck_before_rise(sck_before_rise),
        .ready(ready),.valid(valid),
        .sdout(sdout),
        .data(data)
    );
endmodule

module TestIisTransRecvNormal #(

)(

);
    logic clk;
    initial begin
        clk = '0;
        forever #5 clk = ~clk;
    end
    logic rst_n;
    initial begin
        rst_n = 1'b1;
        #20 rst_n = 1'b0;
        #20 rst_n = 1'b1;
    end
    logic mck_o,sck,ws1,ws2;
    logic sdin;
    always_ff @( posedge sck ) begin
        sdin <= $random();
    end
    logic sdout;
    IisTransRecvNormal #()
    theIisTransRecvNormal(
        .mck(clk),.rst_n(rst_n),
        .mck_o(mck_o),.sck(sck),.ws1(ws1),.ws2(ws2),
        .sdin(sdin),.sdout(sdout)
    );
endmodule

module TestIisTransRecvEqualizer #(

)(
    
);
    logic clk;
    initial begin
        clk = '0;
        forever #5 clk = ~clk;
    end
    logic rst_n;
    initial begin
        rst_n = 1'b1;
        #20 rst_n = 1'b0;
        #20 rst_n = 1'b1;
    end
    logic mck_o,sck,ws1,ws2;
    logic sdin;
    always_ff @( posedge clk ) begin
        sdin <= $random();
    end
    logic sdout;
    logic up,down,lup,ldown,mup,mdown,hup,hdown;
    initial begin
        ldown <= 1'b0;
        #500 ldown <= 1'b1;
        #50 ldown <= 1'b0;
    end
    initial begin
        lup <= 1'b0;
    end
    logic lm4811_clk,lm4811_ud;
    IisTransRecvEqualizer #()
    theIisTransRecvEqualizer(
        .mck(clk),.rst_n(rst_n),
        .mck_o(mck_o),.sck(sck),.ws1(ws1),.ws2(ws2),
        .sdin(sdin),.sdout(sdout),
        .up(up),.down(down),.lup(lup),.ldown(ldown),
        .mup(mup),.mdown(mdown),.hup(hup),.hdown(hdown),
        .lm4811_clk(lm4811_clk),.lm4811_ud(lm4811_ud)
    );
endmodule

module TestIirFilter #(

)(

);
    logic [31:0] out;
    logic clk;
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end
    IirFilter #(
        .DW(32),.FW(8),
        .GAIN(0.02551772),.NUM('{1,1,0}),.DEN('{-0.94896457,0})
    )
    theTestIirFilter(
        .clk(clk),.rst(1'b0),.en(1'b1),
        .in(32'hffce8d00),.out(out)
    );
endmodule
`endif