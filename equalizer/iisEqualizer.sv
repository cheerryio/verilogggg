`ifndef __IIS_EQUALIZER_SV__
`define __IIS_EQUALIZER_SV__
`timescale 1ps/1ps

module Counter #(
	parameter integer N = 128
)(
	input wire clk,
	input wire rst,
	input wire en,
	output logic [$clog2(N)-1:0] cnt,
	output logic co
);
	always_ff @( posedge clk ) begin
		if(rst) cnt <= '0;
		else if(en) begin
			if(cnt < N-1) cnt <= cnt + 1;
			else cnt <= '0;
		end
	end
	assign co = en && cnt == N - 1 && !rst;
endmodule

module I2sClk #(
	parameter integer MCK_TO_SCK = 8,
	parameter integer SCK_TO_WS = 64
)(
	input wire mck,
	output logic sck,
	output logic ws,
	output logic [$clog2(MCK_TO_SCK)-1:0] sck_cnt,
	output logic [$clog2(SCK_TO_WS)-1:0] ws_cnt,
	output logic sck_fall,
	output logic sck_before_rise,   // one cycle before sck rise
	output logic frame_sync
);
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

	assign frame_sync = ws_cnt == 0 && sck_cnt == (MCK_TO_SCK / 2 - 1);

endmodule

module LM4811_Volumn #(
	parameter integer DLY = 5096
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
		else if(dly_cnt != 0)
		begin
			dly_cnt <= dly_cnt + 1;
		end
		else if(dly_cnt == DLY - 1)
		begin
		  dly_cnt <= '0;
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
	input wire clk,rst_n,en,
	input wire signed [DW-1:0] in,
	input wire lup_en,ldown_en,mup_en,mdown_en,hup_en,hdown_en,
	output logic signed [DW-1:0] out
);
	logic [DW-1:0] low_out,middle_out,high_out;
	logic [DW-1:0] low_gain_out,middle_gain_out,high_gain_out;
	logic signed [DW-1 : 0] lgain,mgain,hgain;

	IirFilter #(
		.DW(DW),.FW(FW),
		.GAIN(0.02551772),.NUM('{1,1,0}),.DEN('{-0.94896457,0})
	)
	theLowIirFilter(
		.clk(clk),.rst(1'b0),.en(en),
		.in(in),.out(low_out)
	);
	IirFilter #(
		.DW(DW),.FW(FW),
		.GAIN(0.12150990),.NUM('{1,0,-1}),.DEN('{-1.74185363,0.75698019})
	)theMiddleIirFilter(
		.clk(clk),.rst(1'b0),.en(en),
		.in(in),.out(middle_out)
	);
	IirFilter #(
		.DW(DW),.FW(FW),
		.GAIN(0.85829493),.NUM('{1,-1,0}),.DEN('{-0.71658987,0})
	)theHighIirFilter(
		.clk(clk),.rst(1'b0),.en(en),
		.in(in),.out(high_out)
	);

	task automatic EqualizerGain(
		input up,input down,
		input rst_n,
		ref logic signed [DW-1:0] gain
	);
		if(!rst_n)
		begin	
			gain = 32'h0000_4000;
		end
		else if(up)
		begin
			if(gain > 32'h0000_f800)
			begin
				gain = 32'h0000_f800;
			end
			else
			begin
				gain = gain + 32'h0000_0800;
			end
		end
		else if(down)
		begin
			if(gain < 32'h0000_0000)
			begin
				gain = 32'h0000_0000;
			end
			else
			begin
				gain = gain - 32'h0000_0800;
			end
		end
	endtask

	// drive lgain,mgain,hgain
	always_ff @( posedge clk ) begin
	   EqualizerGain(lup_en,ldown_en,rst_n,lgain);
	   EqualizerGain(mup_en,mdown_en,rst_n,mgain);
	   EqualizerGain(hup_en,hdown_en,rst_n,hgain);
	end

	assign low_gain_out    = ((DW+DW)'(low_out)    * (DW+DW)'(lgain)) >>> 14;
	assign middle_gain_out = ((DW+DW)'(middle_out) * (DW+DW)'(mgain)) >>> 14;
	assign high_gain_out   = ((DW+DW)'(high_out)   * (DW+DW)'(hgain)) >>> 14;
	assign out = low_gain_out + middle_gain_out + high_gain_out;

endmodule

module I2s_Equalizer_v1_0_S00_AXIS #(
	parameter integer C_S_AXIS_TDATA_WIDTH	= 32,
	parameter integer MCK_TO_SCK = 8,
	parameter integer SCK_TO_WS = 64
)(
	// AXI STREAM INTERFACE
	input wire S_AXIS_ACLK,
	input wire S_AXIS_ARESETN,
	output logic S_AXIS_TREADY,
	input wire [C_S_AXIS_TDATA_WIDTH - 1 : 0] S_AXIS_TDATA,
	input wire [(C_S_AXIS_TDATA_WIDTH/8) - 1 : 0] S_AXIS_TSTRB,
	input wire S_AXIS_TLAST,
	input wire S_AXIS_TVALID,

	input wire mck,
	output logic mck_o,
	output logic sck,
	output logic ws,
	output logic sdata,
	input wire lup,mup,hup,ldown,mdown,hdown,
	input wire lm4811_up,lm4811_down,
	output logic lm4811_clk,lm4811_ud
);
	logic [$clog2(MCK_TO_SCK)-1:0] sck_cnt;
	logic [$clog2(SCK_TO_WS)-1:0] ws_cnt;
	logic sck_before_rise;
	logic sck_fall,frame_sync,frame_sync_dly;
	logic [2 * C_S_AXIS_TDATA_WIDTH - 1:0] shift_reg;
	logic valid_ready,valid_ready_delay;
	logic [C_S_AXIS_TDATA_WIDTH-1 : 0] data;
	logic lm4811_up_en,lm4811_down_en;
	logic lup_en,ldown_en,mup_en,mdown_en,hup_en,hdown_en;
	logic tready;
	
	assign valid_ready = S_AXIS_TVALID && tready;
	assign S_AXIS_TREADY = tready;
	assign mck_o = mck;

	// sck,ws drive
	I2sClk #(.MCK_TO_SCK(MCK_TO_SCK),.SCK_TO_WS(SCK_TO_WS))
	theI2sClk(
		.mck(mck),.sck(sck),.ws(ws),
		.sck_cnt(sck_cnt),.ws_cnt(ws_cnt),
		.sck_fall(sck_fall),.sck_before_rise(sck_before_rise),
		.frame_sync(frame_sync)
	);

	always_ff @( posedge S_AXIS_ACLK ) begin
		frame_sync_dly <= frame_sync;
	end

	// tready drive
	always_ff @( posedge S_AXIS_ACLK ) begin
		if(!S_AXIS_ARESETN)
			tready <= 1'b0;
		else if(frame_sync)
		begin
			tready <= 1'b1;
		end
		else if(S_AXIS_TVALID && tready)
		begin
			tready <= 1'b0;
		end
		else if(tready && sck_cnt == 2)
		begin
			tready <= 1'b0;
		end
	end

	//shift_reg drive
	always_ff @( posedge S_AXIS_ACLK ) begin
		if(!S_AXIS_ARESETN)
			shift_reg <= '0;
		else if(valid_ready_delay)
		begin
			shift_reg <= {data,data};
		end
		else if(sck_fall && ws_cnt != 0)
		begin
			shift_reg <= {shift_reg[2 * C_S_AXIS_TDATA_WIDTH-2:0],1'b0}; 
		end
	end

	// valid_ready_dly drive S_AXIS_TVALID && tready one cycle delay
	always_ff @( posedge S_AXIS_ACLK ) begin
		valid_ready_delay <= valid_ready;
	end

	// drive volumn up down signal en
	Rising2en #()
	theLm4811UpRising2en(
		S_AXIS_ACLK,lm4811_up,lm4811_up_en
	),theLm4811DownRising2en(
		S_AXIS_ACLK,lm4811_down,lm4811_down_en
	),theLupRising2en(
		S_AXIS_ACLK,lup,lup_en
	),theLdownRising2en(
		S_AXIS_ACLK,ldown,ldown_en
	),theMupRising2en(
		S_AXIS_ACLK,mup,mup_en
	),theMdownRising2en(
		S_AXIS_ACLK,mdown,mdown_en
	),theHupRising2en(
		S_AXIS_ACLK,hup,hup_en
	),theHdownRising2en(
		S_AXIS_ACLK,hdown,hdown_en
	);

	LM4811_Volumn #()
	theLM4811_Volumn(
		.mck(S_AXIS_ACLK),
		.up(lm4811_up_en),.down(lm4811_down_en),
		.lm4811_ud(lm4811_ud),
		.lm4811_clk(lm4811_clk)
	);

	TriLevelEqualizer #(.DW(C_S_AXIS_TDATA_WIDTH),.FW(8))
	theTriLevelEqualizer(
		.clk(S_AXIS_ACLK),.rst_n(S_AXIS_ARESETN),.en(valid_ready),
		.in(S_AXIS_TDATA),
		.lup_en(lup_en),.ldown_en(ldown_en),
		.mup_en(mup_en),.mdown_en(mdown_en),
		.hup_en(hup_en),.hdown_en(hdown_en),
		.out(data)
	);
	
	// sdata drive
	assign sdata = shift_reg[2 * C_S_AXIS_TDATA_WIDTH-1];
endmodule

module TestI2sEqualizerAXIS #(

)(

);
	logic clk;
	initial begin
		clk = 1'b0;
		forever #5 clk = ~clk;
	end
	logic aresetn;
	initial begin
		aresetn = 1'b0;
		#6ps aresetn = 1'b1;
	end
	logic tready;
	localparam TDATA_W = 32;
	logic [TDATA_W-1:0] tdata = 32'haaaabbbb;
	logic tvalid;
	initial begin
		tvalid = 1'b0;
		# 10 tvalid = 1'b1;
	end
	logic mck_o,sck,ws,sdata;
	logic lup,ldown,mup,mdown,hup,hdown;
	logic lm4811_up,lm4811_down,lm4811_clk,lm4811_ud;
	initial begin
	   lm4811_up = 1'b0;
	   #100 lm4811_up = 1'b1;
	   #40 lm4811_up = 1'b0;  
	end
	I2s_Equalizer_v1_0_S00_AXIS #(.C_S_AXIS_TDATA_WIDTH(32))
	theMyI2s(
		.S_AXIS_ACLK(clk),.S_AXIS_ARESETN(aresetn),
		.S_AXIS_TREADY(tready),.S_AXIS_TDATA(tdata),
		.S_AXIS_TSTRB(),.S_AXIS_TLAST(),
		.S_AXIS_TVALID(tvalid),
		.mck(clk),.mck_o(mck_o),.sck(sck),.ws(ws),
		.sdata(sdata),
		.lup(lup),.ldown(ldown),
		.mup(mup),.mdown(mdown),
		.hup(hup),.hdown(hdown),
		.lm4811_up(lm4811_up),.lm4811_down(lm4811_down),
		.lm4811_clk(lm4811_clk),.lm4811_ud(lm4811_ud)
	);
endmodule
`endif